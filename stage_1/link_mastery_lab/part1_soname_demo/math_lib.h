#ifndef MATH_LIB_H
#define MATH_LIB_H

#ifdef __cplusplus
extern "C" {
#endif

// 计算接口
int compute(int a, int b);

// 打印当前动态库的版本信息
void print_version();

#ifdef __cplusplus
}
#endif

#endif // MATH_LIB_H
