//
// Created by Andrey Syvrachev on 2019-01-16.
//

#include "TCPListener.h"
#include "TCPConnection.h"
#include <log.hpp>

using namespace asio;


TCPListener::TCPListener(asio::io_context &io_context,
                         ip::tcp::endpoint &localEp)
        : acceptor_(io_context, localEp, true, 10000) {

    startAccept();
}

void TCPListener::startAccept() {
    auto connection = std::shared_ptr<TCPConnection>(new TCPConnection(acceptor_.get_io_context(),current_id));

    connection->onClose = [this](uint64_t id) {
            acceptor_.get_io_context().post([this,id] {
                mutex_.lock();
                connections_.erase(id);
             //   LOG_INF("removed connection: " << current_id << " left: " << connections_.size());
                mutex_.unlock();
            });
        };

    mutex_.lock();
    connections_[current_id++] = connection;
    mutex_.unlock();

    acceptor_.async_accept(connection->socket(), [this, connection](error_code ec) {
        if (ec.value() == 0) {
            //  LOG_INF("accept from: " << connection->socket().remote_endpoint());
            connection->start();
            startAccept();
        } else {
            LOG_INF("TCPListener accept error: " << ec.value());
        }
    });
}
