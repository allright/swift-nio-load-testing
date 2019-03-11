//
// Created by Andrey Syvrachev on 2018-12-28.
//

#ifndef PERF_TEST_PERIODICTIMER_H
#define PERF_TEST_PERIODICTIMER_H

#include <asio.hpp>

class PeriodicTimer {
public:
    PeriodicTimer(asio::io_context& io_context);
    ~PeriodicTimer();

    void start(const asio::steady_timer::duration& period, std::function<void()> lambda);
    void stop();
private:
    asio::io_context& io_context_;
    std::shared_ptr<asio::steady_timer> timer_;
};


#endif //PERF_TEST_PERIODICTIMER_H
