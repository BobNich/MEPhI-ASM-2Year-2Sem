#include <stdio.h>
#include <math.h>
#include <stdbool.h>

float custom(float x, float e) {
    
    float a_term = (x * x * x) / 8;
    float b_term = 8;
    
    float term = a_term * b_term;
    float sum = term;
    
    int i = 1;
    
    while (fabs(term) > e)
    {
        a_term = a_term * (-1) * (x * x) / ((2 * i + 2) * (2 * i + 3));
        b_term = 9 * b_term + 8;
        
        float term = a_term * b_term;
        
        if (!isfinite(term)) {
            printf("Term became infinity.\n");
            return sum;
        }
        else if (fabs(term) > e) {
            sum += term;
            i += 1;
        } else {
            return sum;
        }
    }
    
    return sum;
}

int main(int argc, char* argv[]) {
    
    float x;
    float e;
    
    printf("Input x: ");
    scanf("%f", &x);
    printf("Input e: ");
    scanf("%f", &e);

    float customResult = custom(x, e);
    float libraryResult = pow(sin(x), 3);

    printf("Custom result: %f\n", customResult);
    printf("Library result: %f\n", libraryResult);

    return 0;
}