#!/bin/bash
# 一键搭建 3 窗格 C++ 后端微服务工作台

SESSION_NAME="backend_lab"
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 检查是否存在已有的 tmux 会话
tmux has-session -t $SESSION_NAME 2>/dev/null
if [ $? -eq 0 ]; then
    echo "会话 $SESSION_NAME 已存在，直接附加上去..."
    tmux attach -t $SESSION_NAME
    exit 0
fi

echo "正在自动化初始化 tmux 开发工作台 [$SESSION_NAME]..."

# 1. 预先编译服务端和客户端
cd "$DIR"
echo "正在编译 server.cpp 和 client.cpp ..."
g++ -std=c++11 -pthread server.cpp -o server
g++ -std=c++11 -pthread client.cpp -o client
chmod +x monitor.sh

# 2. 创建新会话，初始窗口命名为 'dev'，先不直接进入 (-d 参数)
tmux new-session -d -s $SESSION_NAME -n dev

# 3. 将窗口左右水平切分 (左边 55%，右边 45%)
#    pane 0 在左边，pane 1 在右边
tmux split-window -h -p 45 -t $SESSION_NAME:dev

# 4. 把左边的 pane 0 再上下切分成上下两个 (上 60%，下 40%)
tmux select-pane -t $SESSION_NAME:dev.0
tmux split-window -v -p 40 -t $SESSION_NAME:dev.0

# 现在的布局结构：
# --------------------------------
# | 左上 (Pane 0): Server 运行   | 右边 (Pane 2):   |
# --------------------------------| 实时系统监控     |
# | 左下 (Pane 1): 压测客户端    | (monitor.sh)     |
# --------------------------------

# 5. 向各个 Pane 发送初始运行指令 (send-keys C-m 代表回车)
# Pane 0: 启动 Server
tmux send-keys -t $SESSION_NAME:dev.0 "cd $DIR && ./server" C-m

# Pane 1: 准备好客户端测试提示
tmux send-keys -t $SESSION_NAME:dev.1 "cd $DIR" C-m
tmux send-keys -t $SESSION_NAME:dev.1 "echo '【压测客户端窗格】已准备就绪！'" C-m
tmux send-keys -t $SESSION_NAME:dev.1 "echo '输入命令回车发起压测：./client 30 100'" C-m

# Pane 2: 启动监控脚本
tmux send-keys -t $SESSION_NAME:dev.2 "cd $DIR && ./monitor.sh" C-m

# 默认将光标焦点置于左下角的 Pane 1，方便开发者直接敲命令
tmux select-pane -t $SESSION_NAME:dev.1

# 6. 进入 tmux 工作台
tmux attach-session -t $SESSION_NAME
