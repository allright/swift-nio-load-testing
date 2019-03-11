//
// Created by Andrey Syvrachev on 2018-12-28.
//

#include "PeriodicTimer.h"
#include <functional>

using namespace asio;

PeriodicTimer::PeriodicTimer(asio::io_context &io_context) : io_context_(io_context) {
}

PeriodicTimer::~PeriodicTimer() {
    stop();
}

void PeriodicTimer::start(const steady_timer::duration& period,std::function<void()> lambda) {
    timer_.reset(new steady_timer(io_context_));
    timer_->expires_after(period);

    timer_->async_wait([this,period,lambda](auto& ec) {
        lambda();
        this->start(period,lambda);
    });
}

void PeriodicTimer::stop(){
    if (timer_) {
        timer_->cancel();
    }
}

