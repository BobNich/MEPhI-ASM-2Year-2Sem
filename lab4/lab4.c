#include <stdio.h>
#include <math.h>

FILE* file;

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
        fprintf(file, "%i - %f\n", i, term);

        if (fabs(term) > e) {
            sum += term;
            i += 1;
        } else {
            return sum;
        }
    }
    
    return sum;
}

int main(int argc, char* argv[]) {
    
    if (argc < 2) {
        printf("Usage: ./program <filename>\n");
        return 1;
    }
    
    float x;
    float e;
    const char* filename = argv[1];

    printf("Input x: ");
    scanf("%f", &x);
    printf("Input e: ");
    scanf("%f", &e);

    file = fopen(filename, "w");
    float customResult = custom(x, e);
    fclose(file);
    
    float libraryResult = pow(sin(x), 3);

    printf("Custom result: %f\n", customResult);
    printf("Library result: %f\n", libraryResult);

    return 0;
}
