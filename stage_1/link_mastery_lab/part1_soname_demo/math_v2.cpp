#include "math_lib.h"
#include <iostream>

int compute(int a, int b) {
    // V2 版本：全新算法（乘方/高阶计算，这里演示为乘法）
    return a * b;
}

void print_version() {
    std::cout << "[Dynamic Lib] 当前运行版本: v2.0.0 (性能增强版乘法引擎)" << std::endl;
}
