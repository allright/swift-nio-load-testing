//
// Created by Andrey Syvrachev on 2019-01-15.
//

#ifndef PERF_TEST_CONTEXT_H
#define PERF_TEST_CONTEXT_H

#include <asio.hpp>

class Context {
public:
    Context();
    asio::io_context& context();

private:
    asio::io_context context_;
    asio::signal_set signals_;
};


#endif //PERF_TEST_CONTEXT_H
