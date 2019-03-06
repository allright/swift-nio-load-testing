//
// Created by Andrey Syvrachev on 2019-03-06.
//

import NIO

internal final class EchoHandler: ChannelInboundHandler {
    public typealias InboundIn = ByteBuffer
    public typealias OutboundOut = ByteBuffer

    public func channelRead(ctx: ChannelHandlerContext, data: NIOAny) {
        // As we are not really interested getting notified on success or failure we just pass nil as promise to
        // reduce allocations.
        ctx.write(data, promise: nil)
    }

    // Flush it out. This can make use of gathering writes if multiple buffers are pending
    public func channelReadComplete(ctx: ChannelHandlerContext) {

        // As we are not really interested getting notified on success or failure we just pass nil as promise to
        // reduce allocations.
        ctx.flush()
    }

    public func errorCaught(ctx: ChannelHandlerContext, error: Error) {
        print("error: ", error)

        // As we are not really interested getting notified on success or failure we just pass nil as promise to
        // reduce allocations.
        ctx.close(promise: nil)
    }
}
