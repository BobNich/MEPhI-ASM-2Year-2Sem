#include <stdio.h>
#include <stdlib.h>

void invert_image(unsigned char *image_data, int width, int height, int channels) {
    int pixel_count = width * height;
    for (int i = 0; i < pixel_count; i++) {
        int x = i % width;
        int y = i / width;
        printf("%d, %d", x, y);
        if (x >= y) {
            image_data[(i * channels) + 0] = image_data[(i * channels) + 0] ^ 0xff;
            image_data[(i * channels) + 1] = image_data[(i * channels) + 1] ^ 0xff;
            image_data[(i * channels) + 2] = image_data[(i * channels) + 2] ^ 0xff; 
        }
    }
}