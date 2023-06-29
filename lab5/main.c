#include <stdio.h>
#include "process_image.h"

extern void invert_image(unsigned char *image_data, int width, int height, int channels);

int main(int argc, char *argv[]) {
    if (argc != 3) {
        printf("Please, use: %s $input_file$ $output_file$\n", argv[0]);
        return 1;
    }

    process_image(argv[1], argv[2]);

    return 0;
}