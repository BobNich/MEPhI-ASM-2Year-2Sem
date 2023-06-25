#define STB_IMAGE_IMPLEMENTATION
#define STB_IMAGE_WRITE_IMPLEMENTATION

#include <stdio.h>
#include <stdlib.h>
#include "stb_image.h"
#include "stb_image_write.h"

int invert_image(char *input_filename, char *output_filename) {
    int width, height, channels;
    unsigned char *image_data = stbi_load(input_filename, &width, &height, &channels, 0);
    if (!image_data) {
        printf("Error loading image: %s\n", stbi_failure_reason());
        return 0;
    }

    if (channels != 3) {
        printf("Error: Only 24-bit BMP images are supported.\n");
        stbi_image_free(image_data);
        return 0;
    }

    unsigned char *inverted_data = (unsigned char *)malloc(width * height * channels);
    if (!inverted_data) {
        printf("Error allocating memory for inverted image.\n");
        stbi_image_free(image_data);
        return 0;
    }

    // Invert the image
    int pixel_count = width * height;
    for (int i = 0; i < pixel_count; i++) {
        inverted_data[(i * channels) + 0] = 255 - image_data[(i * channels) + 0]; // Red channel
        inverted_data[(i * channels) + 1] = 255 - image_data[(i * channels) + 1]; // Green channel
        inverted_data[(i * channels) + 2] = 255 - image_data[(i * channels) + 2]; // Blue channel
    }

    if (!stbi_write_bmp(output_filename, width, height, channels, inverted_data)) {
        printf("Error writing output image: %s\n", stbi_failure_reason());
        free(inverted_data);
        stbi_image_free(image_data);
        return 0;
    }

    free(inverted_data);
    stbi_image_free(image_data);
    return 1;
}