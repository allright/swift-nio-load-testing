//
// Created by Andrey Syvrachev on 2019-03-06.
//

import Foundation
import NIO
import NIOHTTP1
import NIOWebSocket
import NIOConcurrencyHelpers

extension Thread {
    var sname: String {
        return name ?? ""
    }
}

func log(_ s:String) {
    print("[\(Thread.current.sname)] \(s)" )
}

private let handlersCount = Atomic<UInt32>(value:0)
private let handlersAdded = Atomic<UInt32>(value:0)

private let index = Atomic<UInt32>(value:0)

internal final class WebSocketTimeHandler: ChannelInboundHandler {
    typealias InboundIn = WebSocketFrame
    typealias OutboundOut = WebSocketFrame

    private var awaitingClose: Bool = false
    private let id = index.add(1)

    init() {
        _ = handlersCount.add(1)
        log("WebSocketTimeHandler:init   \(id):\(handlersCount.load()):\(handlersAdded.load())")
    }

    deinit {
        _ = handlersCount.sub(1)
        log("WebSocketTimeHandler:deinit \(id):\(handlersCount.load()):\(handlersAdded.load())")
    }

    func handlerAdded(ctx: ChannelHandlerContext) {
        _ = handlersAdded.add(1)
        log("WebSocketTimeHandler:handlerAdded   \(id):\(handlersCount.load()):\(handlersAdded.load())")
        self.sendTime(ctx: ctx)
    }

    func handlerRemoved(ctx: ChannelHandlerContext) {
        _ = handlersAdded.sub(1)
        log("WebSocketTimeHandler:handlerRemoved   \(id):\(handlersCount.load()):\(handlersAdded.load())")
    }

    func userInboundEventTriggered(ctx: ChannelHandlerContext, event: Any) {
        if event is IdleStateHandler.IdleStateEvent {
            log("WebSocketTimeHandler:userInboundEventTriggered (IdleStateEvent) \(id):\(handlersCount.load()):\(handlersAdded.load()) event = \(event)")
            ctx.close(promise: nil)
        }
    }

    public func channelRead(ctx: ChannelHandlerContext, data: NIOAny) {
        let frame = self.unwrapInboundIn(data)

        switch frame.opcode {
        case .connectionClose:
            self.receivedClose(ctx: ctx, frame: frame)
        case .ping:
            self.pong(ctx: ctx, frame: frame)
        case .unknownControl, .unknownNonControl:
            self.closeOnError(ctx: ctx)
        case .text:
            var data = frame.unmaskedData
            let text = data.readString(length: data.readableBytes) ?? ""
            log("WebSocketTimeHandler:text \(id):\(handlersCount.load())  '\(text)'")
        default:
            // We ignore all other frames.
            break
        }
    }

    public func channelReadComplete(ctx: ChannelHandlerContext) {
        ctx.flush()
    }

    private func sendTime(ctx: ChannelHandlerContext) {
        guard ctx.channel.isActive else { return }

        // We can't send if we sent a close message.
        guard !self.awaitingClose else { return }

        // We can't really check for error here, but it's also not the purpose of the
        // example so let's not worry about it.
        let theTime = DispatchTime.now().uptimeNanoseconds
        var buffer = ctx.channel.allocator.buffer(capacity: 12)
        buffer.write(string: "\(theTime)")

        let frame = WebSocketFrame(fin: true, opcode: .text, data: buffer)
        ctx.writeAndFlush(self.wrapOutboundOut(frame)).map {
            ctx.eventLoop.scheduleTask(in: .seconds(1), { self.sendTime(ctx: ctx) })
        }.whenFailure { (_: Error) in
            ctx.close(promise: nil)
        }
    }

    private func receivedClose(ctx: ChannelHandlerContext, frame: WebSocketFrame) {
        // Handle a received close frame. In websockets, we're just going to send the close
        // frame and then close, unless we already sent our own close frame.
        if awaitingClose {
            // Cool, we started the close and were waiting for the user. We're done.
            ctx.close(promise: nil)
        } else {
            // This is an unsolicited close. We're going to send a response frame and
            // then, when we've sent it, close up shop. We should send back the close code the remote
            // peer sent us, unless they didn't send one at all.
            var data = frame.unmaskedData
            let closeDataCode = data.readSlice(length: 2) ?? ctx.channel.allocator.buffer(capacity: 0)
            let closeFrame = WebSocketFrame(fin: true, opcode: .connectionClose, data: closeDataCode)
            _ = ctx.write(self.wrapOutboundOut(closeFrame)).map { () in
                ctx.close(promise: nil)
            }
        }
    }

    private func pong(ctx: ChannelHandlerContext, frame: WebSocketFrame) {
        var frameData = frame.data
        let maskingKey = frame.maskKey

        if let maskingKey = maskingKey {
            frameData.webSocketUnmask(maskingKey)
        }

        let responseFrame = WebSocketFrame(fin: true, opcode: .pong, data: frameData)
        ctx.write(self.wrapOutboundOut(responseFrame), promise: nil)
    }

    private func closeOnError(ctx: ChannelHandlerContext) {
        // We have hit an error, we want to close. We do that by sending a close frame and then
        // shutting down the write side of the connection.
        var data = ctx.channel.allocator.buffer(capacity: 2)
        data.write(webSocketErrorCode: .protocolError)
        let frame = WebSocketFrame(fin: true, opcode: .connectionClose, data: data)
        ctx.write(self.wrapOutboundOut(frame)).whenComplete {
            ctx.close(mode: .output, promise: nil)
        }
        awaitingClose = true
    }
}