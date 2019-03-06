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

private let handlersCount = Atomic<UInt32>(value:0)
private let activeCount = Atomic<UInt32>(value:0)

private let index = Atomic<UInt32>(value:0)

internal final class EchoHandler: ChannelInboundHandler {
    public typealias InboundIn = ByteBuffer
    public typealias OutboundOut = ByteBuffer

    private let id = index.add(1)

    init() {
        _ = handlersCount.add(1)
        log("EchoHandler:init   \(id):\(handlersCount.load()):\(activeCount.load())")

    }

    deinit {
        _ = handlersCount.sub(1)
        log("EchoHandler:deinit \(id):\(handlersCount.load()):\(activeCount.load())")
    }

    public func channelRead(ctx: ChannelHandlerContext, data: NIOAny) {
        // As we are not really interested getting notified on success or failure we just pass nil as promise to
        // reduce allocations.
        ctx.write(data, promise: nil)
    }

    func channelActive(ctx: ChannelHandlerContext) {
        _ = activeCount.add(1)
        log("EchoHandler:channelActive   \(id):\(handlersCount.load()):\(activeCount.load())")
        ctx.eventLoop.scheduleTask(in: .seconds(30), { [weak self] in
            guard let `self` = self else { return }
            log("EchoHandler:scheduleTask done   \(self.id):\(handlersCount.load()):\(activeCount.load())")
            ctx.close(promise: nil)
        })
    }

    func channelInactive(ctx: ChannelHandlerContext) {
        _ = activeCount.sub(1)
        log("EchoHandler:channelInactive   \(id):\(handlersCount.load()):\(activeCount.load())")
        ctx.close(promise: nil)
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
