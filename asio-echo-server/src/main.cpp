#include <iostream>
#include <thread>
#include <asio.hpp>
#include "Utils/ThreadPool.h"
#include "Utils/Context.h"
#include <log.hpp>
#include "TCP/TCPListener.h"
#include "Utils/PeriodicTimer.h"
#include "Utils/ArgReader.h"

extern std::atomic<uint64_t> count;

int main(int argc, char* argv[]) {
   // try {

        if (argc < 3) {
            std::cout << "asio-echo-server <threads_count> <ip> <port>" << std::endl;
            std::cout << "threads_count == 0 for automaticaly (by cpu cores)" << std::endl;
            return -1;
        }

        ArgReader argReader(argc, argv);

        auto threads = argReader.nextInt();
        if (threads == 0) {
            threads = std::thread::hardware_concurrency();
        }

        auto bindIp = argReader.nextStr();
        auto bindPort = argReader.nextInt();

        LOG_INF("Thread pool size: " << threads);
        LOG_INF("Bind: " << bindIp << ":" << bindPort);

        Context ctx;

        auto ip = asio::ip::make_address(bindIp);
        auto ep = asio::ip::tcp::endpoint(ip,bindPort);
        TCPListener listener(ctx.context(),ep);

        ThreadPool pool(ctx.context(), threads);
        PeriodicTimer timer(ctx.context());
        timer.start(std::chrono::seconds(2),[&]{
             LOG_INF("Handlers: " << count);
        });

//    } catch (std::exception &e) {
//        LOG_ERR(e.what());
//    }

    usleep(10000000);

    return 0;
}