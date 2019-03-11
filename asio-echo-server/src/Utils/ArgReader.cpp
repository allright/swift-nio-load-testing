//
// Created by Andrey Syvrachev on 2019-01-10.
//
#include <iostream>
#include "ArgReader.h"
#include <exception>

class StrException: public std::exception
{
public:
    StrException(const char* ex): ex_(ex) {}
//    const char* what() const explicit {
//        return ex_;
//    }
private:
    const char* ex_;
};

ArgReader::ArgReader(int argc, char *argv[]) : i_(1), argc_(argc), argv_(argv) {
}

bool ArgReader::isEnd() {
    return i_ >= argc_;
}

const char *ArgReader::nextStr() {
    if (isEnd())
        throw StrException("no argument!");
    return argv_[i_++];
}

int ArgReader::nextInt() {
    if (isEnd())
        throw StrException("no argument!");
    return std::atoi(argv_[i_++]);
}

const char* ArgReader::nextStr(const char* val) {
    if (isEnd())
        return val;
    return argv_[i_++];
}

int ArgReader::nextInt(int val) {
    if (isEnd())
        return val;
    return std::atoi(argv_[i_++]);
}