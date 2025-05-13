#define _BSD_SOURCE
#define _XOPEN_SOURCE 500
#include <assert.h>
#include <fcntl.h>
#include <getopt.h>
#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <errno.h>
#include <time.h>
#include <math.h>

#include <sys/mman.h>
#include <sys/stat.h>
#include <sys/time.h>
#include <sys/types.h>
#include <unistd.h>

#include "../dma/dma.h"
#include "../dma/dma_utils.c"
#include "../util_lib/utils.c"

#define START_BASE_PHYS  0x08000000
#define FINISH_BASE_PHYS 0x0C000000
#define CTX_BASE_PHYS    0x80000000
#define STATE_BASE_PHYS  0xC0000000

int main() {
    int line_count = count_line_of_file("gate_info.txt");

    printf("Line count: %d\n", line_count);

    struct file_info gate_info = read_file("gate_info.txt");

    printf("Number of lines: %llu\n", gate_info.size);

    for (uint64_t i = 0; i < gate_info.size; i++) {
        printf("Line %llu: 0x%016llx\n", i, gate_info.data[i]);
    }

    return 0;
}