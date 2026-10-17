#!/usr/bin/env python3
"""
生成高度仿真的企业级微服务与网关日志
包含两份日志：
1. nginx_access.log: 标准网关访问日志（包含 IP、请求方式、URL、状态码、响应字节、耗时）
2. application.log: 后端微服务业务日志（包含时间戳、日志级别、TraceID、线程名、消息体、敏感手机号/身份证、慢 SQL、异常调用栈）
"""

import random
import time
from datetime import datetime, timedelta

ips = [
    "192.168.1.102", "192.168.1.105", "10.0.4.15", "172.16.2.88",
    "203.0.113.195", "198.51.100.4", "192.168.1.102", "192.168.1.102", # 制造高频 IP
    "10.0.4.15", "114.114.114.114", "124.70.18.23", "192.168.1.200"
]

urls = [
    ("/api/v1/user/login", "POST"),
    ("/api/v1/user/info", "GET"),
    ("/api/v1/goods/list", "GET"),
    ("/api/v1/goods/detail", "GET"),
    ("/api/v1/order/create", "POST"),
    ("/api/v1/order/pay", "POST"),
    ("/api/v1/health", "GET"),
    ("/api/v1/report/export", "GET")
]

statuses = [200, 200, 200, 200, 200, 200, 200, 302, 400, 401, 404, 500, 502, 504]
log_levels = ["INFO", "INFO", "INFO", "INFO", "WARN", "ERROR"]

def generate_nginx_log(count=3000):
    start_time = datetime(2026, 10, 17, 9, 0, 0)
    lines = []
    trace_ids = []

    for i in range(count):
        cur_time = start_time + timedelta(seconds=i // 5, milliseconds=random.randint(0, 999))
        time_str = cur_time.strftime("%d/%b/%Y:%H:%M:%S +0800")
        ip = random.choice(ips)
        url, method = random.choice(urls)
        
        # 针对特定接口模拟突发 500 报错或慢请求
        if url == "/api/v1/order/pay" and random.random() < 0.35:
            status = random.choice([500, 502])
            cost_ms = random.randint(1200, 3500) # 慢且报错
        elif url == "/api/v1/report/export":
            status = 200
            cost_ms = random.randint(800, 2500)  # 导出接口耗时长
        else:
            status = random.choice(statuses)
            cost_ms = random.randint(15, 350)

        body_bytes = random.randint(128, 65535)
        trace_id = f"trace-{random.randint(100000, 999999)}"
        trace_ids.append((trace_id, cur_time, status, url, ip))

        # Nginx 常用日志格式:
        # $remote_addr - [$time_local] "$request" $status $body_bytes_sent $request_time "$http_user_agent" trace_id=$trace_id
        line = f'{ip} - [{time_str}] "{method} {url} HTTP/1.1" {status} {body_bytes} {cost_ms/1000.0:.3f} "Mozilla/5.0" trace_id={trace_id}'
        lines.append(line)

    with open("nginx_access.log", "w", encoding="utf-8") as f:
        f.write("\n".join(lines) + "\n")
    print(f"已生成 nginx_access.log 共 {count} 行")
    return trace_ids

def generate_app_log(trace_ids):
    lines = []
    for trace_id, cur_time, status, url, ip in trace_ids:
        time_str = cur_time.strftime("%Y-%m-%d %H:%M:%S.%f")[:-3]
        thread_name = f"http-nio-8080-exec-{random.randint(1, 16)}"
        
        # 模拟手机号与身份证号
        phone = f"13{random.randint(100000000, 999999999)}"
        id_card = f"110101199{random.randint(0, 9)}{random.randint(10, 12)}{random.randint(10, 28)}{random.randint(1000, 9999)}"

        if status >= 500:
            lines.append(f"{time_str} [ERROR] [{trace_id}] [{thread_name}] com.service.OrderService: 订单支付扣款失败, phone={phone}, id_card={id_card}, error=Database timeout")
            lines.append(f"{time_str} [ERROR] [{trace_id}] [{thread_name}] java.sql.SQLException: Connection timeout after 3000ms at com.service.dao.PayDao.exec(PayDao.java:42)")
        elif status == 404:
            lines.append(f"{time_str} [WARN]  [{trace_id}] [{thread_name}] com.filter.AuthFilter: 请求路径不存在 url={url}, client_ip={ip}")
        else:
            if random.random() < 0.2:
                lines.append(f"{time_str} [INFO]  [{trace_id}] [{thread_name}] com.service.UserService: 用户登录成功, phone={phone}, token=eyJhbGciOi...")
            else:
                lines.append(f"{time_str} [INFO]  [{trace_id}] [{thread_name}] com.controller.ApiController: 请求处理完成, cost={random.randint(10, 200)}ms")

    with open("application.log", "w", encoding="utf-8") as f:
        f.write("\n".join(lines) + "\n")
    print(f"已生成 application.log 共 {len(lines)} 行")

if __name__ == "__main__":
    t_ids = generate_nginx_log(3000)
    generate_app_log(t_ids)
    print(">>> 模拟日志生成完毕！可开始实操练习。")
