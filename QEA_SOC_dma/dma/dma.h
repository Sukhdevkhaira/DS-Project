

#ifndef DMA_H
#define DMA_H

/*************************** HEADER FILES ***************************/
#include <stdio.h>
#include <stdint.h>
#include <unistd.h>
#include <time.h>
#include <errno.h>
#include <sys/types.h>
/**************************** DATA TYPES ****************************/

/*********************** FUNCTION DECLARATIONS **********************/


static int test_dma(char *devname, uint64_t addr, uint64_t aperture,
		    uint64_t size, uint64_t offset, uint64_t count,
		    char *filename, char *);
			
uint64_t getopt_integer(char *optarg);

ssize_t read_to_buffer(char *fname, int fd, char *buffer, uint64_t size,
			uint64_t base);
			
ssize_t write_from_buffer(char *fname, int fd, char *buffer, uint64_t size,
			uint64_t base);
			
static int timespec_check(struct timespec *t);

void timespec_sub(struct timespec *t1, struct timespec *t2);			
#endif   
