#!/bin/bash
# 文本三剑客与日志分析实践项目 - 标准参考解答与演练脚本

set -e
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DIR"

# 确保日志已生成
if [ ! -f "nginx_access.log" ] || [ ! -f "application.log" ]; then
    echo ">>> 检测到日志尚未生成，正在执行 generate_logs.py ..."
    python3 generate_logs.py
fi

echo "=================================================="
echo "      文本三剑客实战项目：标准答案与实操演练        "
echo "=================================================="

# ----------------------------------------------------
echo -e "\n\033[33m【关卡 1：应急排障 - 定位 5xx 突发接口】\033[0m"
echo "1.1 找出所有 500/502/504 错误并打印时间、URL、状态码及 trace_id（前 5 行）："
grep -E ' "(GET|POST) [^"]+" (500|502|504) ' nginx_access.log | awk '{print $4, $7, $9, $NF}' | head -n 5

echo -e "\n1.2 统计哪个接口 5xx 报错次数最多："
awk '$9 ~ /^(500|502|504)$/ {print $7}' nginx_access.log | sort | uniq -c | sort -nr

echo -e "\n1.3 从 application.log 中提取 SQLException 及其前 1 行后 2 行上下文（取第 1 个匹配）："
grep -C 2 "SQLException" application.log | head -n 5

# ----------------------------------------------------
echo -e "\n\033[33m【关卡 2：流量画像 - 统计 Top 访问源】\033[0m"
echo "2.1 统计访问量 Top 3 客户端 IP："
awk '{print $1}' nginx_access.log | sort | uniq -c | sort -nr | head -n 3

echo -e "\n2.2 统计非 200 异常状态码分布分布计数："
awk '$9 != 200 {print $9}' nginx_access.log | sort | uniq -c | sort -nr

echo -e "\n2.3 排除健康检查后，访问量最大的 Top 3 业务 API："
grep -v "/api/v1/health" nginx_access.log | awk '{print $7}' | sort | uniq -c | sort -nr | head -n 3

# ----------------------------------------------------
echo -e "\n\033[33m【关卡 3：性能瓶颈 - 慢请求分析与接口平均耗时】\033[0m"
echo "3.1 提取耗时 >= 1.0 秒的最慢前 5 条记录（耗时, URL, 状态码）："
awk '$11 >= 1.0 {print $11, $7, $9}' nginx_access.log | sort -k1,1 -nr | head -n 5

echo -e "\n3.2 【高阶 awk】分组计算各个接口的请求次数与平均耗时："
awk '{
    sum[$7] += $11;
    count[$7]++;
} END {
    printf "%-30s %-12s %-12s\n", "接口 URL", "调用次数", "平均耗时(秒)";
    print "--------------------------------------------------------";
    for (url in count) {
        avg = sum[url] / count[url];
        printf "%-30s %-12d %-12.3f\n", url, count[url], avg;
    }
}' nginx_access.log | sort -k3,3 -nr

# ----------------------------------------------------
echo -e "\n\033[33m【关卡 4：数据合规 - sed 批量正则脱敏】\033[0m"
echo "4.1 使用 sed 正则对手机号(138****1234)和身份证号脱敏："
sed -E \
  -e 's/(1[3-9][0-9])[0-9]{4}([0-9]{4})/\1****\2/g' \
  -e 's/([0-9]{6})[0-9]{8}([0-9]{4})/\1********\2/g' \
  application.log > application_masked.log

echo "脱敏后前 3 行预览："
head -n 3 application_masked.log

# ----------------------------------------------------
echo -e "\n\033[33m【关卡 5：全链路追踪 - trace_id 级联抓取】\033[0m"
echo "5.1 获取网关第一个 502 报错的 trace_id 并利用 xargs 提取后端全链路日志："
FIRST_TRACE=$(grep ' 502 ' nginx_access.log | head -n 1 | awk '{print $NF}' | cut -d'=' -f2)
echo "抓取到的故障 trace_id: $FIRST_TRACE"
echo "该 trace_id 在应用层的日志追踪："
grep "$FIRST_TRACE" application.log

# ----------------------------------------------------
echo -e "\n\033[33m【关卡 6：管道重定向艺术 - tee 与 2>&1 机制】\033[0m"
echo "6.1 使用 tee 同时在屏幕输出并写入 report.txt："
echo "=== 自动化运维快速摘要 ===" | tee report.txt
awk '{print $9}' nginx_access.log | sort | uniq -c | sort -nr | head -n 3 | tee -a report.txt

echo -e "\n6.2 面试经典考点验证：2>&1 的从左到右求值顺序"
echo "[命令 A] ls /tmp /not_exist > /dev/null 2>&1"
echo "解释：标准输出重定向到 /dev/null，然后 2 指向 1 的位置(即 /dev/null)，屏幕完全静默没有任何输出。"
ls /tmp /not_exist > /dev/null 2>&1 || true

echo -e "\n[命令 B] ls /tmp /not_exist 2>&1 > /dev/null"
echo "解释：2 先指向当前 1 的位置(终端屏幕)，然后 1 再指向 /dev/null。所以错误信息依然会漏到屏幕上！"
echo "实际效果如下（你会看到错误信息依然打印出来了）："
ls /tmp /not_exist 2>&1 > /dev/null || true

echo -e "\n=================================================="
echo "   所有关卡验证完毕！请阅读 README.md 深入理解原理   "
echo "=================================================="
