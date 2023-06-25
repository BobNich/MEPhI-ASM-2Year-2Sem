#include <stdio.h>

extern void invert_image(char *input_filename, char *output_filename);

int main(int argc, char *argv[]) {
    if (argc != 3) {
        printf("Please, use: %s $input_file$ $output_file$\n", argv[0]);
        return 1;
    }

    invert_image(argv[1], argv[2]);

    return 0;
}