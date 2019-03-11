//
// Created by Andrey Syvrachev on 2019-01-16.
//

#ifndef PERF_TEST_TCPLISTENER_H
#define PERF_TEST_TCPLISTENER_H

#include <asio.hpp>
#include <map>
#include <mutex>

class TCPConnection;
class TCPListener {
public:
    TCPListener(asio::io_context& io_context,asio::ip::tcp::endpoint& localEp);

private:
    void startAccept();

    std::mutex mutex_;

    asio::ip::tcp::acceptor acceptor_;
    std::atomic<uint64_t> current_id;

    std::map<uint64_t,std::shared_ptr<TCPConnection>> connections_;
};


#endif //PERF_TEST_TCPLISTENER_H
