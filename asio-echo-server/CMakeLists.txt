cmake_minimum_required(VERSION 3.0)
project(asio_echo_server)

set(CMAKE_CXX_STANDARD 14)

add_definitions(-DASIO_STANDALONE)
include_directories("include")

file(GLOB_RECURSE CPP_FILES src/*.cpp)
add_executable(asio_echo_server ${CPP_FILES})
if (UNIX)
    target_link_libraries(asio_echo_server pthread)
endif (UNIX)