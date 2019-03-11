#ifndef LOG
#define LOG

#include <asio.hpp> // TODO: REMOVE LATER!
#include <iostream>

inline std::string timestamp() {
    //get the time
    std::chrono::system_clock::time_point tp = std::chrono::system_clock::now();
    std::time_t tt = std::chrono::system_clock::to_time_t(tp);
    std::tm gmt{}; gmtime_r(&tt, &gmt);
    std::chrono::duration<double> fractional_seconds =
            (tp - std::chrono::system_clock::from_time_t(tt)) + std::chrono::seconds(gmt.tm_sec);
    //format the string
    std::string buffer("year/mo/dy hr:mn:sc.xxxxxx");
    sprintf(&buffer.front(), "%04d/%02d/%02d %02d:%02d:%09.6f", gmt.tm_year + 1900, gmt.tm_mon + 1,
            gmt.tm_mday, gmt.tm_hour, gmt.tm_min, fractional_seconds.count());
    return buffer;
}

inline std::string log_level(const char* level) {
    std::ostringstream s;
    s << timestamp() << " " << level << " [" << std::this_thread::get_id() << "] ";
    return s.str();
}

#define LOG_DBG(x) std::cout << log_level("DBG") << x << std::endl
#define LOG_WRN(x) std::cout << log_level("WRL") << x << std::endl
#define LOG_ERR(x) std::cerr << log_level("ERR") << x << std::endl
#define LOG_INF(x) std::cout << log_level("INF") << x << std::endl

#endif
