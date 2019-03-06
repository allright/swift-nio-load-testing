//
// Created by Andrey Syvrachev on 2019-03-06.
//

import Foundation
import NIO
import NIOHTTP1
import NIOWebSocket
import NIOConcurrencyHelpers

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

private let handlersCount = Atomic<UInt32>(value:0)
private let index = Atomic<UInt32>(value:0)

internal final class HTTPHandler: ChannelInboundHandler {
    typealias InboundIn = HTTPServerRequestPart
    typealias OutboundOut = HTTPServerResponsePart

    private var responseBody: ByteBuffer!
    private let id = index.add(1)

    init() {
        _ = handlersCount.add(1)
        log("HTTPHandler:init   \(id):\(handlersCount.load())")
    }

    deinit {
        _ = handlersCount.sub(1)
        log("HTTPHandler:deinit \(id):\(handlersCount.load())")
    }

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