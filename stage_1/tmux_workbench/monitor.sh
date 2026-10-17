#!/bin/bash
# 实时系统与网络监控小脚本

echo "正在寻找 server 进程..."
while true; do
    PID=$(pgrep -f "^./server" | head -n 1)
    clear
    echo "=================================================="
    echo "     Linux 开发监控仪表盘 (tmux 监控窗格)          "
    echo "=================================================="
    echo "当前时间: $(date '+%Y-%m-%d %H:%M:%S')"
    
    if [ -n "$PID" ]; then
        echo -e "\033[32m[STATUS: 运行中]\033[0m 目标进程 PID: $PID"
        echo "--------------------------------------------------"
        echo "【1. 进程资源监控 (ps)】"
        ps -p $PID -o pid,ppid,%cpu,%mem,nlwp,cmd
        
        echo -e "\n【2. 打开的文件描述符数量 (FD 计数)】"
        FD_COUNT=$(ls -1 /proc/$PID/fd 2>/dev/null | wc -l)
        echo "当前占用 FD 句柄数: $FD_COUNT"

        echo -e "\n【3. 端口 8080 网络连接状态统计】"
        ss -ant | grep ":8080" | awk '{print $1}' | sort | uniq -c
    else
        echo -e "\033[31m[STATUS: 未检测到 ./server 进程运行]\033[0m"
        echo "等待服务启动中..."
    fi
    echo "=================================================="
    echo "提示: 每 1 秒刷新一次，按 Ctrl+C 退出监控"
    sleep 1
done
