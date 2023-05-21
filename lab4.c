#include <stdio.h>
#include <math.h>

char *filename;


void add_file_data(int number, float term) {
    FILE *fp;
    fp = fopen("result.txt", "w");
    fprintf(fp, "%d: %f", number, term);
    fclose(fp);
}

float custom(float x, float e) {
    
    float a1 = (x * x * x) / 8;
    float b1 = 8;
    
    float term = a1 * b1;
    float sum = term;
    
    int i = 1;
    
    while (fabs(term) > e)
    {
        a1 = a1 * (-1) * (x * x) / ((2 * i + 2) * (2 * i + 3));
        b1 = 9 * b1 + 8;
        
        float term = a1 * b1;
        add_file_data(i, term);

        if (fabs(term) > e) {
            sum += term;
            i += 1;
        } else {
            return sum;
        }
    }
    
    return sum;
}

int main(int argc, char *argv[]) {
        
    if (argc == 2) {
       filename = argv[1];
    }
    
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
