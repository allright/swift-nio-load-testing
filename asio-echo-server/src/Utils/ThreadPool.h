//
// Created by Andrey Syvrachev on 2019-01-14.
//

#ifndef PERF_TEST_THREADPOOL_H
#define PERF_TEST_THREADPOOL_H

#include <asio.hpp>

class ThreadPool {
public:
    ThreadPool(asio::io_context& context, int threads);
    ~ThreadPool();

private:
    asio::thread_pool pool_;
};


#endif //PERF_TEST_THREADPOOL_H
