//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftNIO open source project
//
// Copyright (c) 2017-2018 Apple Inc. and the SwiftNIO project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftNIO project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//
import NIO
import NIOOpenSSL

// First argument is the program path
let arguments = CommandLine.arguments
let cert = arguments.dropFirst().first
let key = arguments.dropFirst().dropFirst().first

let arg1 = arguments.dropFirst().dropFirst().dropFirst().first
let arg2 = arguments.dropFirst().dropFirst().dropFirst().dropFirst().first


let cores = 1 //System.coreCount
print("number of threads: \(cores)")

let configuration = TLSConfiguration.forServer(certificateChain: [.file(cert!)], privateKey: .file(key!))
let sslContext = try! SSLContext(configuration: configuration)


let group = MultiThreadedEventLoopGroup(numberOfThreads:cores)
let bootstrap = ServerBootstrap(group: group)
        // Specify backlog and enable SO_REUSEADDR for the server itself
        .serverChannelOption(ChannelOptions.backlog, value: 1024)
        .serverChannelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)

        // Set the handlers that are appled to the accepted Channels
        .childChannelInitializer { channel in
            // Ensure we don't read faster than we can write by adding the BackPressureHandler into the pipeline.
            let handler = try! OpenSSLServerHandler(context: sslContext)
            return channel.pipeline.add(handler: handler).then {
                channel.pipeline.add(handler: IdleStateHandler(readTimeout: .seconds(60))).then {
                    channel.pipeline.add(handler: BackPressureHandler()).then {
                        channel.pipeline.add(handler: EchoHandler())
                    }
                }
            }
        }

        // Enable TCP_NODELAY and SO_REUSEADDR for the accepted Channels
        .childChannelOption(ChannelOptions.socket(IPPROTO_TCP, TCP_NODELAY), value: 1)
        .childChannelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
        .childChannelOption(ChannelOptions.maxMessagesPerRead, value: 16)
        .childChannelOption(ChannelOptions.recvAllocator, value: AdaptiveRecvByteBufferAllocator())
defer {
    try! group.syncShutdownGracefully()
}



let defaultHost = "::1"
let defaultPort = 9999

enum BindTo {
    case ip(host: String, port: Int)
    case unixDomainSocket(path: String)
}

let bindTarget: BindTo
switch (arg1, arg1.flatMap(Int.init), arg2.flatMap(Int.init)) {
case (.some(let h), _ , .some(let p)):
    /* we got two arguments, let's interpret that as host and port */
    bindTarget = .ip(host: h, port: p)
case (.some(let portString), .none, _):
    /* couldn't parse as number, expecting unix domain socket path */
    bindTarget = .unixDomainSocket(path: portString)
case (_, .some(let p), _):
    /* only one argument --> port */
    bindTarget = .ip(host: defaultHost, port: p)
default:
    bindTarget = .ip(host: defaultHost, port: defaultPort)
}



let channel = try { () -> Channel in
    switch bindTarget {
    case .ip(let host, let port):
        return try bootstrap.bind(host: host, port: port).wait()
    case .unixDomainSocket(let path):
        return try bootstrap.bind(unixDomainSocketPath: path).wait()
    }
}()

_ = group.next().scheduleRepeatedTask(initialDelay: .seconds(1), delay: .seconds(1)) { _ in
    print(handlersCount.load())
}


print("Server started and listening on \(channel.localAddress!)")

// This will never unblock as we don't close the ServerChannel
try channel.closeFuture.wait()

print("Server closed")
