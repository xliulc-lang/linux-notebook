#include <iostream>
#include <vector>
#include <thread>
#include <chrono>
#include <cstring>
#include <unistd.h>
#include <sys/socket.h>
#include <arpa/inet.h>

void client_worker(int id, int request_count) {
    int sock = socket(AF_INET, SOCK_STREAM, 0);
    if (sock < 0) return;

    sockaddr_in serv_addr{};
    serv_addr.sin_family = AF_INET;
    serv_addr.sin_port = htons(8080);
    inet_pton(AF_INET, "127.0.0.1", &serv_addr.sin_addr);

    if (connect(sock, (struct sockaddr*)&serv_addr, sizeof(serv_addr)) < 0) {
        close(sock);
        return;
    }

    char buffer[1024];
    for (int i = 0; i < request_count; ++i) {
        std::string msg = "Ping from Client " + std::to_string(id);
        write(sock, msg.c_str(), msg.length());
        int bytes = read(sock, buffer, sizeof(buffer) - 1);
        (void)bytes;
        std::this_thread::sleep_for(std::chrono::milliseconds(50));
    }
    close(sock);
}

int main(int argc, char* argv[]) {
    int concurrency = 10;
    int requests_per_client = 100;

    if (argc >= 2) concurrency = std::stoi(argv[1]);
    if (argc >= 3) requests_per_client = std::stoi(argv[2]);

    std::cout << ">>> 启动并发客户端测试 <<<" << std::endl;
    std::cout << "并发连接数: " << concurrency << "，每个连接发送次数: " << requests_per_client << std::endl;

    std::vector<std::thread> workers;
    for (int i = 0; i < concurrency; ++i) {
        workers.emplace_back(client_worker, i + 1, requests_per_client);
    }

    for (auto& t : workers) {
        t.join();
    }

    std::cout << ">>> 测试完成，所有客户端已断开 <<<" << std::endl;
    return 0;
}
