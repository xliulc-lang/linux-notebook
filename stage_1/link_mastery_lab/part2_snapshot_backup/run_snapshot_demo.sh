#!/bin/bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DIR"

echo "=================================================="
echo " 实验二：硬链接在极速增量快照备份中的应用 (类似 Time Machine)"
echo "=================================================="

# 清理旧数据
rm -rf my_project backup_*

echo ">>> 1. 创建原始工程目录 my_project，包含若干大文件..."
mkdir -p my_project
echo "代码文件 A：版本 1" > my_project/main.cpp
# 生成一个 10MB 的模拟大文件
head -c 10M </dev/urandom > my_project/big_asset.bin

echo "原始工程大小及 inode 状态："
ls -li my_project

echo -e "\n>>> 2. 进行第一次快照备份 (backup_day1)..."
# 使用 cp -al: 对所有文件创建硬链接，而非真实复制数据块
cp -al my_project backup_day1

echo "检查 backup_day1 的 inode："
ls -li backup_day1
echo "可以看到：backup_day1/big_asset.bin 的 inode 与原始文件完全相同！硬链接数变为 2！"

echo -e "\n>>> 3. 查看磁盘占用情况："
du -sh my_project backup_day1
echo "由于硬链接共享数据块，backup_day1 实际新增磁盘占用几乎为 0！"

echo -e "\n>>> 4. 模拟第二天开发：修改了 main.cpp，但 big_asset.bin 保持不变..."
# 注意：若直接向源文件写内容会影响硬链接，因此在增量备份体系中通常会替换或重新写入
rm my_project/main.cpp
echo "代码文件 A：版本 2 (修复严重 Bug)" > my_project/main.cpp

echo -e "\n>>> 5. 进行第二次快照备份 (backup_day2)..."
cp -al my_project backup_day2

echo -e "\n>>> 6. 对比三个版本的 main.cpp 与 big_asset.bin 的硬链接状态："
echo "--- main.cpp (已修改，inode 各自独立) ---"
ls -li my_project/main.cpp backup_day1/main.cpp backup_day2/main.cpp

echo -e "\n--- big_asset.bin (未修改，三者共享同一个 10MB 数据块，链接计数变为 3) ---"
ls -li my_project/big_asset.bin backup_day1/big_asset.bin backup_day2/big_asset.bin

echo -e "\n【实验二成功】体会到硬链接如何实现'秒级创建快照、零重复数据占用'！"
