#include <stdio.h>
#include <math.h>

#define float_format "%f"

#define msg_scan_x "Input x: "
#define msg_scan_precision "Input precision: "

#define msg_lib_result "Lib result: %f\n"
#define msg_custom_result "Custom result: %f\n"

#define ZERO 0.0f
#define ONE 1.0f
#define TWO 2.0f
#define THREE 3.0f
#define FOUR 4.0f

void scan(float *x, float *precision) {
    printf(msg_scan_x);
    scanf(float_format, x);
    printf(msg_scan_precision);
    scanf(float_format, precision);
}

void print(float result_lib, float result_custom) {
    printf(msg_lib_result, result_lib);
    printf(msg_custom_result, result_custom);
}

float lib(float x) {
    float res = sin(x);
    return pow(res, THREE);
}

int custom_fact(int n) {
    int res = n;
    while (n > 1) {
        n -= 1;
        res *= n;
    }
    return res;
}

float custom_pow(float x, float p) {
    float res = x;
    while (p > 1) {
        res *= x;
        p -= 1;
    }
    return res;
}

float series_member(float x, int n) {
    float res = custom_pow(-ONE, n + ONE);
    res *= custom_pow(THREE, TWO * n) - ONE;
    res *= custom_pow(x, TWO * n + ONE);
    res /= custom_fact(TWO * n + ONE);
    return res;
}

float custom(float x, float precision) {
    int n = 0;
    float res = ZERO, member;
    do {
        n += 1;
        member = series_member(x, n);
        res += member;
    } while (fabs(member) >= precision);
    return res * THREE / FOUR;
}

int main() {
    float x, precision;
    scan(&x, &precision);
    print(lib(x), custom(x, precision));
}
