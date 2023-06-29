#include <stdio.h>
#include <math.h>

#define float_format "%f"

#define msg_scan_x "Input x: "
#define msg_scan_precision "Input precision: "

#define msg_lib_result "Lib result: %f\n"
#define msg_custom_result "Custom result: %f\n"

#define msg_file "%-10d %f"

#define ZERO 0.0f
#define MINUS_ONE -1.0f
#define ONE 1.0f
#define TWO 2.0f
#define THREE 3.0f
#define FOUR 4.0f
#define EIGHT 8.0f
#define NINE 9.0f

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

void printToFile(int i, float x) {
    printf(msg_file, i, x);
}

float custom(float x, float precision) {
    
    float a_term = (x * x * x) / EIGHT;
    float b_term = EIGHT;
    float term = a_term * b_term;
    
    float sum = 0;
    int i = 0;
    
    while (fabs(term) > precision) {
        printToFile(i, term);
        sum += term;
        i += 1;
        a_term = a_term * MINUS_ONE * (x * x) / ((TWO * i + TWO) * (TWO * i + THREE));
        b_term = NINE * b_term + EIGHT;
        term = a_term * b_term;
    }
    
    return sum;
}

int main(int argc, char* argv[]) {
    float x, precision;
    scan(&x, &precision);
    print(lib(x), custom(x, precision));
}