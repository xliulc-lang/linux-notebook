#include <iostream>
#include <fstream>
#include <chrono>
#include <thread>
#include <unistd.h>

int main() {
    std::cout << ">>> 模拟服务进程启动, PID: " << getpid() << std::endl;
    
    // 打开一个大文件并持续保持句柄不关闭
    const char* filename = "large_temp_data.log";
    std::ofstream ofs(filename, std::ios::out | std::ios::binary);
    if (!ofs.is_open()) {
        std::cerr << "打开文件失败" << std::endl;
        return 1;
    }

    std::cout << ">>> 正在写入 50MB 垃圾数据到 " << filename << " ..." << std::endl;
    std::string chunk(1024 * 1024, 'X'); // 1MB 数据块
    for (int i = 0; i < 50; ++i) {
        ofs.write(chunk.data(), chunk.size());
    }
    ofs.flush();
    std::cout << ">>> 写入完成！此时文件已被打开，进程将维持该句柄打开状态 60 秒..." << std::endl;
    std::cout << ">>> 请在另一个终端执行 rm -f " << filename << " 并观察磁盘空间！" << std::endl;

    for (int i = 60; i > 0; --i) {
        std::this_thread::sleep_for(std::chrono::seconds(1));
    }

    std::cout << ">>> 进程主动关闭文件并退出..." << std::endl;
    ofs.close();
    return 0;
}
