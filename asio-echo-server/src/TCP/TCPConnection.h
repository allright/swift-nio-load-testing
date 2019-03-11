//
// Created by Andrey Syvrachev on 2019-01-16.
//

#ifndef PERF_TEST_TCPCONNECTION_H
#define PERF_TEST_TCPCONNECTION_H

#include <asio.hpp>

class TCPConnection {
public:
    TCPConnection(asio::io_context& io_context,uint64_t id);

    ~TCPConnection();

    asio::ip::tcp::socket& socket();
    void start();

private:



    void close();

    asio::ip::tcp::socket socket_;
    asio::io_context::strand strand_;
    std::vector<char> packet_;
    asio::mutable_buffer  buffer_;
    asio::mutable_buffer  send_buffer_;

    uint64_t connection_id_;
    void recv();
    void resetWatchDog();
    std::shared_ptr<asio::steady_timer> timer_;
};


#endif //PERF_TEST_TCPCONNECTION_H
