//
// Created by Andrey Syvrachev on 2019-01-10.
//

#ifndef PERF_TEST_ARGREADER_H
#define PERF_TEST_ARGREADER_H


class ArgReader {
public:
    ArgReader(int argc, char* argv[]);

    const char* nextStr();
    int nextInt();

    const char* nextStr(const char* val);
    int nextInt(int val);

    bool isEnd();
private:
    char** argv_;
    int argc_;
    int i_;
};


#endif //PERF_TEST_ARGREADER_H
