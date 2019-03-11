//
// Created by Andrey Syvrachev on 2019-01-14.
//

#include "ThreadPool.h"

ThreadPool::ThreadPool(asio::io_context& context, int threads) : pool_(threads) {
    for (auto i = 0; i < threads; i++) {
        post(pool_, [&context,i] {
            context.run();
        });
    }
}

ThreadPool::~ThreadPool() {
    pool_.join();
}