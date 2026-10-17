#include <iostream>
#include <vector>
#include <thread>
#include <chrono>
#include <cstring>
#include <unistd.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <atomic>

std::atomic<long long> total_requests{0};
std::atomic<int> active_connections{0};

void handle_client(int client_fd) {
    active_connections++;
    char buffer[1024];
    while (true) {
        std::memset(buffer, 0, sizeof(buffer));
        int bytes = read(client_fd, buffer, sizeof(buffer) - 1);
        if (bytes <= 0) break;

        total_requests++;
        // 回显内容并在末尾加上 ACK
        std::string response = "ACK: " + std::string(buffer);
        write(client_fd, response.c_str(), response.length());
    }
    close(client_fd);
    active_connections--;
}

int main() {
    int port = 8080;
    int server_fd = socket(AF_INET, SOCK_STREAM, 0);
    if (server_fd < 0) {
        perror("socket failed");
        return 1;
    }

    int opt = 1;
    setsockopt(server_fd, SOL_SOCKET, SO_REUSEADDR, &opt, sizeof(opt));

    sockaddr_in address{};
    address.sin_family = AF_INET;
    address.sin_addr.s_addr = INADDR_ANY;
    address.sin_port = htons(port);

    if (bind(server_fd, (struct sockaddr*)&address, sizeof(address)) < 0) {
        perror("bind failed");
        return 1;
    }

    if (listen(server_fd, 128) < 0) {
        perror("listen failed");
        return 1;
    }

    std::cout << "========================================\n";
    std::cout << " [Server] TCP 微服务启动成功! 端口: " << port << "\n";
    std::cout << " [Server] 进程 PID: " << getpid() << "\n";
    std::cout << "========================================\n";

    // 状态统计线程：每隔 1 秒打印一次服务状态
    std::thread status_thread([]() {
        while (true) {
            std::this_thread::sleep_for(std::chrono::seconds(1));
            std::cout << "[Dashboard] 活跃连接: " << active_connections.load() 
                      << " | 累计处理请求: " << total_requests.load() << std::endl;
        }
    });
    status_thread.detach();

    while (true) {
        sockaddr_in client_addr{};
        socklen_t addrlen = sizeof(client_addr);
        int client_fd = accept(server_fd, (struct sockaddr*)&client_addr, &addrlen);
        if (client_fd < 0) continue;

        std::thread(handle_client, client_fd).detach();
    }

    close(server_fd);
    return 0;
}
