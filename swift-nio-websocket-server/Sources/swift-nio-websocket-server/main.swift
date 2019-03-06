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

import Dispatch
import NIO
import NIOHTTP1
import NIOWebSocket

let websocketResponse = """
                        <!DOCTYPE html>
                        <html>
                          <head>
                            <meta charset="utf-8">
                            <title>Swift NIO WebSocket Test Page</title>
                            <script>
                                var wsconnection = new WebSocket("ws://localhost:8888/websocket");
                                wsconnection.onmessage = function (msg) {
                                    var element = document.createElement("p");
                                    element.innerHTML = msg.data;

                                    var textDiv = document.getElementById("websocket-stream");
                                    textDiv.insertBefore(element, null);
                                };
                            </script>
                          </head>
                          <body>
                            <h1>WebSocket Stream</h1>
                            <div id="websocket-stream"></div>
                          </body>
                        </html>
                        """

private final class HTTPHandler: ChannelInboundHandler {
    typealias InboundIn = HTTPServerRequestPart
    typealias OutboundOut = HTTPServerResponsePart

    private var responseBody: ByteBuffer!

    func channelRegistered(ctx: ChannelHandlerContext) {
        var buffer = ctx.channel.allocator.buffer(capacity: websocketResponse.utf8.count)
        buffer.write(string: websocketResponse)
        self.responseBody = buffer
    }

    func channelUnregistered(ctx: ChannelHandlerContext) {
        self.responseBody = nil
    }

    func channelRead(ctx: ChannelHandlerContext, data: NIOAny) {
        let reqPart = self.unwrapInboundIn(data)

        // We're not interested in request bodies here: we're just serving up GET responses
        // to get the client to initiate a websocket request.
        guard case .head(let head) = reqPart else {
            return
        }

        // GETs only.
        guard case .GET = head.method else {
            self.respond405(ctx: ctx)
            return
        }

        var headers = HTTPHeaders()
        headers.add(name: "Content-Type", value: "text/html")
        headers.add(name: "Content-Length", value: String(self.responseBody.readableBytes))
        headers.add(name: "Connection", value: "close")
        let responseHead = HTTPResponseHead(version: .init(major: 1, minor: 1),
                status: .ok,
                headers: headers)
        ctx.write(self.wrapOutboundOut(.head(responseHead)), promise: nil)
        ctx.write(self.wrapOutboundOut(.body(.byteBuffer(self.responseBody))), promise: nil)
        ctx.write(self.wrapOutboundOut(.end(nil))).whenComplete {
            ctx.close(promise: nil)
        }
        ctx.flush()
    }

    private func respond405(ctx: ChannelHandlerContext) {
        var headers = HTTPHeaders()
        headers.add(name: "Connection", value: "close")
        headers.add(name: "Content-Length", value: "0")
        let head = HTTPResponseHead(version: .init(major: 1, minor: 1),
                status: .methodNotAllowed,
                headers: headers)
        ctx.write(self.wrapOutboundOut(.head(head)), promise: nil)
        ctx.write(self.wrapOutboundOut(.end(nil))).whenComplete {
            ctx.close(promise: nil)
        }
        ctx.flush()
    }
}



let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)

let upgrader = WebSocketUpgrader(shouldUpgrade: { (head: HTTPRequestHead) in HTTPHeaders() },
        upgradePipelineHandler: { (channel: Channel, _: HTTPRequestHead) in
            channel.pipeline.add(handler: WebSocketTimeHandler())
        })

let bootstrap = ServerBootstrap(group: group)
        // Specify backlog and enable SO_REUSEADDR for the server itself
        .serverChannelOption(ChannelOptions.backlog, value: 256)
        .serverChannelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)

        // Set the handlers that are applied to the accepted Channels
        .childChannelInitializer { channel in
            let httpHandler = HTTPHandler()
            let config: HTTPUpgradeConfiguration = (
                    upgraders: [ upgrader ],
                    completionHandler: { _ in
                        channel.pipeline.remove(handler: httpHandler, promise: nil)
                    }
            )
            return channel.pipeline.configureHTTPServerPipeline(withServerUpgrade: config).then {
                channel.pipeline.add(handler: httpHandler)
            }
        }

        // Enable TCP_NODELAY and SO_REUSEADDR for the accepted Channels
        .childChannelOption(ChannelOptions.socket(IPPROTO_TCP, TCP_NODELAY), value: 1)
        .childChannelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)

defer {
    try! group.syncShutdownGracefully()
}

// First argument is the program path
let arguments = CommandLine.arguments
let arg1 = arguments.dropFirst().first
let arg2 = arguments.dropFirst(2).first

let defaultHost = "localhost"
let defaultPort = 8888

enum BindTo {
    case ip(host: String, port: Int)
    case unixDomainSocket(path: String)
}

let bindTarget: BindTo
switch (arg1, arg1.flatMap(Int.init), arg2.flatMap(Int.init)) {
case (.some(let h), _ , .some(let p)):
    /* we got two arguments, let's interpret that as host and port */
    bindTarget = .ip(host: h, port: p)

case (let portString?, .none, _):
    // Couldn't parse as number, expecting unix domain socket path.
    bindTarget = .unixDomainSocket(path: portString)

case (_, let p?, _):
    // Only one argument --> port.
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

guard let localAddress = channel.localAddress else {
    fatalError("Address was unable to bind. Please check that the socket was not closed or that the address family was understood.")
}
print("Server started and listening on \(localAddress)")

// This will never unblock as we don't close the ServerChannel
try channel.closeFuture.wait()

print("Server closed")
