//
// Created by Andrey Syvrachev on 2019-03-06.
//

import Foundation
import NIO
import NIOConcurrencyHelpers


extension Thread {
    var sname: String {
        return name ?? ""
    }
}

func log(_ s:String) {
    print("[\(Thread.current.sname)] \(s)" )
}

let handlersCount = Atomic<UInt32>(value:0)

private let index = Atomic<UInt32>(value:0)

internal final class EchoHandler: ChannelInboundHandler {
    public typealias InboundIn = ByteBuffer
    public typealias OutboundOut = ByteBuffer

    private let id = index.add(1)

    init() {
        _ = handlersCount.add(1)
    //    log("EchoHandler:init   \(id):\(handlersCount.load())")
    }

    deinit {
        _ = handlersCount.sub(1)
   //     log("EchoHandler:deinit \(id):\(handlersCount.load())")
    }

    func userInboundEventTriggered(ctx: ChannelHandlerContext, event: Any) {
        if event is IdleStateHandler.IdleStateEvent {
  //          log("EchoHandler:userInboundEventTriggered \(id):\(handlersCount.load()) event:\(event)")
            ctx.close(promise: nil)
        }
    }

    public func channelRead(ctx: ChannelHandlerContext, data: NIOAny) {
        // As we are not really interested getting notified on success or failure we just pass nil as promise to
        // reduce allocations.

        let buffer = unwrapInboundIn(data)
//
//        // get the number of bytes that are readable
        let readableBytes = buffer.readableBytes
 //       log("EchoHandler:channelRead \(id):\(handlersCount.load()) data = '\(readableBytes) bytes'")
        ctx.write(data, promise: nil)
    }

    // Flush it out. This can make use of gathering writes if multiple buffers are pending
    public func channelReadComplete(ctx: ChannelHandlerContext) {

        // As we are not really interested getting notified on success or failure we just pass nil as promise to
        // reduce allocations.
        ctx.flush()
    }

    public func errorCaught(ctx: ChannelHandlerContext, error: Error) {
      //  log("error: \(error)")

        // As we are not really interested getting notified on success or failure we just pass nil as promise to
        // reduce allocations.
        ctx.close(promise: nil)
    }
}
