#include "math_lib.h"
#include <iostream>

int compute(int a, int b) {
    // V1 版本：简单的加法计算
    return a + b;
}

void print_version() {
    std::cout << "[Dynamic Lib] 当前运行版本: v1.0.0 (基础加法引擎)" << std::endl;
}
