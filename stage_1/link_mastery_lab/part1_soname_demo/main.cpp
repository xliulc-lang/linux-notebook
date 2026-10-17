#include <iostream>
#include <chrono>
#include <thread>
#include "math_lib.h"

int main() {
    std::cout << "========================================" << std::endl;
    std::cout << " 主程序启动，准备调用共享动态库 libmath.so" << std::endl;
    std::cout << "========================================" << std::endl;

    for (int i = 1; i <= 5; ++i) {
        print_version();
        int res = compute(10, 20);
        std::cout << "第 " << i << " 次计算: compute(10, 20) = " << res << std::endl;
        std::cout << "----------------------------------------" << std::endl;
        std::this_thread::sleep_for(std::chrono::seconds(1));
    }

    std::cout << "主程序运行结束。" << std::endl;
    return 0;
}
