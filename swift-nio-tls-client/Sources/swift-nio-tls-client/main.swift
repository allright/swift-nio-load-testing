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

import Foundation
import NIO
import NIOConcurrencyHelpers
import Dispatch
import NIOOpenSSL

let group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
let bootstrap = ClientBootstrap(group: group)
        // Enable SO_REUSEADDR.
        .channelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
        .channelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_KEEPALIVE), value: 1)
        .connectTimeout(.seconds(10))
        .channelInitializer { channel in
            do {
                let configuration = TLSConfiguration.forClient()
                let sslContext = try SSLContext(configuration: configuration)
                let handler = try OpenSSLClientHandler(context: sslContext)

                return channel.pipeline.add(handler: handler).then {
                    channel.pipeline.add(handler: EchoHandler())
                }
            }catch {
                print("error: \(error)")
                return channel.pipeline.add(handler: EchoHandler())
            }

        }
defer {
    try! group.syncShutdownGracefully()
}

extension ClientBootstrap {
    func connect(target: ConnectTo) -> EventLoopFuture<Channel> {
        switch target {
        case .ip(let host, let port):
            return bootstrap.connect(host: host, port: port)//.wait()
        case .unixDomainSocket(let path):
            return bootstrap.connect(unixDomainSocketPath: path)//.wait()
        }
    }
}


let to = targetFromCommandLine()

let cMaxConnecting = 1//1024
var connecting = UnsafeEmbeddedAtomic<UInt32>(value: 0)
var connectedF = UnsafeEmbeddedAtomic<UInt32>(value: 0)
var errors = UnsafeEmbeddedAtomic<UInt32>(value: 0)

var closeFutures = [EventLoopFuture<Void>]()


func addOneConnect() -> EventLoopFuture<Channel> {
    _ = connecting.add(1)
  //  print("\(Thread.current.name) connecting: \(connecting.load())")
    return bootstrap
            .connect(target: to)

}


func smartAdd() {
    let connectFuture = addOneConnect()
    closeFutures.append(connectFuture.map {
//        connectedF.add(1)
  //      print("\(Thread.current.name) connected: \(connectedF.load())")
        DispatchQueue.global().async(execute: {
          //  smartAdd()
        })

        $0.closeFuture
    })
}


for _ in 0...cMaxConnecting {
    smartAdd()
}


sleep(1000)

_ = try closeFutures.map { channel -> Void in
    try channel.wait()
}
////
////// Will be closed after we echo-ed back to the server.
////try channel.closeFuture.wait()

print("Client closed")
