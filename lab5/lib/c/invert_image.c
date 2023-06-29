#define STB_IMAGE_IMPLEMENTATION
#define STB_IMAGE_WRITE_IMPLEMENTATION

#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include "stb_image.h"
#include "stb_image_write.h"

int process_image(char *input_filename, char *output_filename) {
    int width, height, channels;
    unsigned char *image_data = stbi_load(input_filename, &width, &height, &channels, 0);
    if (!image_data) {
        printf("Error loading image: %s\n", stbi_failure_reason());
        return 0;
    }

    time_t start = clock();
    invert_image(image_data, width, height, channels);
    printf("Time: %f\n", ((double) clock() - start) / CLOCKS_PER_SEC);

    if (!stbi_write_bmp(output_filename, width, height, channels, image_data)) {
        printf("Error writing output image: %s\n", stbi_failure_reason());
        free(image_data);
        return 0;
    }

    free(image_data);
    return 1;
}

void invert_image(unsigned char *image_data, int width, int height, int channels) {
    int pixel_count = width * height;
    for (int i = 0; i < pixel_count; i++) {
        image_data[(i * channels) + 0] = image_data[(i * channels) + 0] ^ 0xff;
        image_data[(i * channels) + 1] = image_data[(i * channels) + 1] ^ 0xff;
        image_data[(i * channels) + 2] = image_data[(i * channels) + 2] ^ 0xff; 
    }
}