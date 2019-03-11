//
// Created by Andrey Syvrachev on 2019-01-15.
//

#include "Context.h"

using namespace asio;

Context::Context() : signals_(context_, SIGINT, SIGTERM) {
    signals_.async_wait([&](auto, auto) {
        context_.stop();
    });
}

io_context &Context::context() {
    return context_;
}

