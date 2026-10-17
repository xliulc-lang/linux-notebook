#!/bin/bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DIR"

echo "=================================================="
echo " 实验一：Linux 动态库 SONAME 软链接链条与平滑升级  "
echo "=================================================="

# 清理旧产物
rm -f *.so* main

echo ">>> 1. 编译生成 V1.0.0 动态库 (真实二进制文件)..."
g++ -fPIC -shared -Wl,-soname,libmath.so.1 math_v1.cpp -o libmath.so.1.0.0

echo ">>> 2. 建立软链接 (SONAME 与 Linker Name 链条)..."
# libmath.so.1 (SONAME) -> libmath.so.1.0.0 (真实版本文件)
ln -sf libmath.so.1.0.0 libmath.so.1
# libmath.so (链接器寻找的名) -> libmath.so.1
ln -sf libmath.so.1 libmath.so

echo -e "\n当前目录下的软链接结构："
ls -l libmath.so*

echo -e "\n>>> 3. 编译主程序 main (只链接通用的 -lmath)..."
g++ main.cpp -L. -lmath -Wl,-rpath,'$ORIGIN' -o main

echo -e "\n>>> 4. 运行主程序 (当前链接的是 v1.0.0)..."
./main

echo -e "\n=================================================="
echo ">>> 5. 开始升级：编译 V2.0.0 动态库，但完全不重新编译 main!"
echo "=================================================="
g++ -fPIC -shared -Wl,-soname,libmath.so.1 math_v2.cpp -o libmath.so.2.0.0

echo ">>> 6. 修改软链接指向 V2.0.0 (实现版本平滑切换)..."
ln -sf libmath.so.2.0.0 libmath.so.1

echo -e "\n切换后的软链接结构："
ls -l libmath.so*

echo -e "\n>>> 7. 再次运行同一个 main 可执行文件："
./main

echo -e "\n=================================================="
echo ">>> 8. 一键热回滚：若 V2 有 Bug，将软链接重新指回 V1.0.0"
echo "=================================================="
ln -sf libmath.so.1.0.0 libmath.so.1
echo "回滚后再次运行："
./main
echo -e "\n【实验一成功】体会到软链接在版本解耦和无缝切换中的巨大作用！"
