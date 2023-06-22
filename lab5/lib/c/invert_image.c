#define STB_IMAGE_IMPLEMENTATION
#define STB_IMAGE_WRITE_IMPLEMENTATION

#include <stdio.h>
#include "stb_image.h"
#include "stb_image_write.h"

int invert_image(char *input_filename, char *output_filename) {
    FILE *input = fopen(input_filename, "rb");
    if (input == NULL) {
        perror("Error opening input file");
        return 1;
    }
    int width, height, channels;
    unsigned char *image = stbi_load_from_file(input, &width, &height, &channels, 0);

    if (image == NULL) {
        printf("Couldn't load image\n");
        return 1;
    }

    unsigned char *inverted_image = (unsigned char *) malloc(width * height);

    for (int i = 0; i < width * height * channels; i++) {
        inverted_image[i] = 255 - image[i];
    }

    stbi_write_bmp(output_filename, width, height, 1, inverted_image);

    stbi_image_free(image);
    free(inverted_image);
    
    return 0;
}