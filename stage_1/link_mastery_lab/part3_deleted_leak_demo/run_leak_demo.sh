#!/bin/bash

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DIR"

echo "=================================================="
echo " 实验三：排查'文件已 rm 删除但磁盘空间未释放'故障"
echo "=================================================="

echo ">>> 1. 编译并启动保持文件句柄的服务程序..."
g++ -std=c++11 file_holder.cpp -o file_holder
./file_holder &
PID=$!

# 等待文件生成
sleep 2

echo -e "\n>>> 2. 此时文件正常存在："
ls -lh large_temp_data.log

echo -e "\n>>> 3. 模拟事故：直接在终端执行 rm 删除该大文件..."
rm -f large_temp_data.log

echo -e "\n>>> 4. 再次执行 ls，发现文件确实已经'消失'了："
ls -lh large_temp_data.log 2>/dev/null || echo "文件在目录中已看不到了！"

echo -e "\n>>> 5. 但是为什么磁盘空间依然被占用？使用 lsof 探查真相："
lsof -p $PID | grep "deleted"

echo -e "\n>>> 解析："
echo "可以看到该文件标记为 (deleted)，因为进程 (PID: $PID) 依然持有其文件描述符！"
echo "根据 Linux 内核机制：硬链接数为 0，但引用计数不为 0，数据块绝不释放！"

echo -e "\n>>> 6. 线上自救方案：在不重启进程的前提下释放空间："
FD=$(lsof -p $PID | grep "deleted" | awk '{print $4}' | tr -d 'w')
echo "找到泄露的句柄 FD: $FD，直接向 /proc/$PID/fd/$FD 注入空内容进行清空截断..."
> "/proc/$PID/fd/$FD"

echo "截断后再次检查文件大小："
ls -lh "/proc/$PID/fd/$FD"

# 终止测试进程
kill -9 $PID 2>/dev/null || true
echo -e "\n【实验三成功】掌握了 Linux 文件删除底层机制与线上空间假泄漏排查！"
