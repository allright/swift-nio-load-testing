//
// Created by Andrey Syvrachev on 2019-01-16.
//

#include "TCPConnection.h"
#include <log.hpp>

using namespace asio;


static auto MTU = 100;
std::atomic<uint64_t> count(0);


TCPConnection::TCPConnection(asio::io_context &io_context, uint64_t id)
        : socket_(io_context), strand_(io_context), connection_id_(id), packet_(MTU),
          buffer_(packet_.data(), packet_.size()) {
    //LOG_INF("TCPConnection " << sender_.streamId() << " INCOMING");
    // LOG_INF("[" << connection_id_ << "] TCPConnection:create: " << socket_.remote_endpoint());
    count++;
}

TCPConnection::~TCPConnection() {
    count--;
 //   LOG_INF("[" << connection_id_ << "] TCPConnection:destroy left: " << count);
}


asio::ip::tcp::socket &TCPConnection::socket() {
    return socket_;
}

void TCPConnection::resetWatchDog() {
    if (timer_) {
        timer_->cancel();
    }
    timer_.reset(new steady_timer(strand_.get_io_context()));
    timer_->expires_after(std::chrono::seconds(30));
    timer_->async_wait([this](auto &ec) {
        if (!ec) {
            dispatch(strand_, [&]() {
                socket_.close(); // will close async by error
            });
                //   LOG_INF("[" << connection_id_ << "] TCPConnection watch dog timer: " << ec);
         //   onClose(connection_id_);
        }else {
          //  LOG_ERR("[" << connection_id_ << "] TCPConnection watch dog timer ERR: " << ec);

        }
    });
}


void TCPConnection::start() {
  //  LOG_INF("[" << connection_id_ << "] TCPConnection start: " << socket_.remote_endpoint());
    resetWatchDog();
    recv();
}

//ВОТКНУТЬ PeridoicTimer и закрыть по ошибке!

void TCPConnection::recv() {
    dispatch(strand_, [&]() {
        socket_.async_read_some(buffer_, [&](const error_code &error, size_t bytes_transferred) {
            if (!error) {
                send_buffer_ = mutable_buffer(buffer_.data(),bytes_transferred);
           //     LOG_INF(" TCPConnection recv bytes: " << bytes_transferred << " buf: " << buffer_.size() );
                socket_.async_write_some(send_buffer_, [&](const error_code &error, size_t bytes_transferred) {
                    if (!error) {
                        recv();
                    } else {
              //          LOG_ERR("[" << connection_id_ << "] TCPConnection:recv:send bytes_transferred: "
               //                     << bytes_transferred);
                        onClose(connection_id_);
                    }
                });
                resetWatchDog();
                //  LOG_ERR("[" << connection_id_ << "] TCPConnection:recv bytes_transferred: " << bytes_transferred);

            } else {
             //   LOG_ERR("[" << connection_id_ << "] TCPConnection recv error: " << error);
                //recv();
                onClose(connection_id_);

            }
        });
    });
}

