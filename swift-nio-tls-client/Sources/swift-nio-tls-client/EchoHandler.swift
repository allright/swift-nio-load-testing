//
// Created by Andrey Syvrachev on 2019-03-04.
//

import NIO
import NIOConcurrencyHelpers

let line = "test"

var connected = UnsafeEmbeddedAtomic<UInt32>(value: 0)
var received = UnsafeEmbeddedAtomic<UInt32>(value: 0)
var active = UnsafeEmbeddedAtomic<UInt32>(value: 0)

internal final class EchoHandler: ChannelInboundHandler {
    public typealias InboundIn = ByteBuffer
    public typealias OutboundOut = ByteBuffer
    private var numBytes = 0
    let id = connected.add(1)

    init() {

        print("EchoHandler:init \(id):\(received.load())")
    }

    deinit {
 //       connected.sub(1)
        print("EchoHandler:deinit \(id):\(received.load())")
    }


    public func channelRead(ctx: ChannelHandlerContext, data: NIOAny) {
        var byteBuffer = self.unwrapInboundIn(data)
        _ = received.add(1)
        print("EchoHandler:channelRead \(id):\(received.load())")

        //    print("Received: '\(byteBuffer.readableBytes)' back from the server, closing channel.")

        numBytes -= byteBuffer.readableBytes
//
//        assert(numBytes >= 0)
//
        if numBytes == 0 {
            if let string = byteBuffer.readString(length: byteBuffer.readableBytes) {
                print("Received: '\(string)' back from the server, closing channel.")
            } else {
                print("Received the line back from the server, closing channel")
            }
//            ctx.close(promise: nil)
        }
    }

    public func errorCaught(ctx: ChannelHandlerContext, error: Error) {
        print("error: ", error)

        // As we are not really interested getting notified on success or failure we just pass nil as promise to
        // reduce allocations.
        ctx.close(promise: nil)
    }

    public func channelActive(ctx: ChannelHandlerContext) {
        _ = active.add(1)
        print("EchoHandler:channelActive \(id):\(active.load())")

        //print("\(connected.load()): Client connected to \(ctx.remoteAddress!)")
//
        // We are connected. It's time to send the message to the server to initialize the ping-pong sequence.

        ctx.eventLoop.scheduleRepeatedTask(initialDelay: .seconds(5), delay: .seconds(5)) { [weak self] (task: RepeatedTask) -> Void in
            guard let `self` = self else { return}

            var buffer = ctx.channel.allocator.buffer(capacity: line.utf8.count)
            buffer.write(string: line)
            self.numBytes = buffer.readableBytes
            ctx.writeAndFlush(self.wrapOutboundOut(buffer), promise: nil)
        }


    }
}