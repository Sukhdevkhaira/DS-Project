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

#include <sys/mman.h>
#include <sys/stat.h>
#include <sys/time.h>
#include <sys/types.h>
#include <unistd.h>

#include "../dma/dma.h"
#include "../dma/dma_utils.c"


#define COUNT_DEFAULT (1)

int main() {
	char *device = "/dev/xdma0_h2c_0";
	uint64_t address = 0x0000000000000000;
	uint64_t size = 8; // bytes in BRAM to store data
	uint64_t offset = 0;
	char *infname = "datafile0_4K.bin";

	int fpga_fd = open(device, O_RDWR);
	uint64_t *buffer = NULL;
	uint64_t *allocated = NULL;
	int infile_fd = -1;
	infile_fd = open(infname, O_RDONLY);
	
	//printf("infile_fd = %d\n",infile_fd);
	posix_memalign((void **)&allocated, 4096 /*alignment */ , size + 4096); // 
	buffer = allocated + offset;
	ssize_t rc;

	printf("\n========== START TO WRITE DATA INTO THE FPGA ==========");
	printf("\nAddress = 0x%016llx", address);
	printf("\nBuffer size = %d", size);
	
	///**** Write data from file to DMA****///
	
	/*rc = read(infile_fd, buffer, size);
	rc = lseek(fpga_fd, address, SEEK_SET);
	rc = write(fpga_fd, buffer, size);*/
	
	///**** Write data from buffer to DMA****///
	int i;
	printf("\nBuffer =  ");
	for (i = 0; i < size; i++){
		buffer[i] = i;
		printf("0x%016llx ",buffer[i]);
	}

	rc = lseek(fpga_fd, address, SEEK_SET);
	if (rc == -1) {
		printf("\nError: lseek() failed. Could not seek to address 0x%016llx. Error: %s", address, strerror(errno));
	} else if (rc != address) {
		printf("\nWarning: lseek() did not move to the expected address. Moved to 0x%016llx instead of 0x%016llx.", (uint64_t)rc, address);
	} else {
		printf("\nSuccessfully moved file pointer to address 0x%016llx.", address);
	}

	rc = write(fpga_fd, buffer, size);
	if (rc != size) {
		printf("\nError: Data was not written correctly. Expected %d bytes, but wrote %zd bytes.\n", size, rc);
	} else {
		printf("\nData successfully written to FPGA.\n");
	}

	printf("\n======================================================\n");

	///**** Read data from DMA to buffer****///

	// read
	char *device2 = "/dev/xdma0_c2h_0";
	uint64_t address2 = 0x0000000000000000;
	int fpga_fd2 = open(device2, O_RDWR);
	uint64_t *buffer_out = NULL;
	uint64_t *allocated_out = NULL;
	uint64_t offset_out = 0;
	uint64_t size_out = 8; // bytes in BRAM to read data
	
	posix_memalign((void **)&allocated_out, 4096 /*alignment */ , size_out + 4096);
	buffer_out = allocated_out + offset_out;
	
	printf("\n========== START TO READ DATA FROM THE FPGA ==========");
	printf("\nAddress = 0x%016llx", address2);
	printf("\nBuffer size = %d", size_out);

	rc = lseek(fpga_fd2, address2, SEEK_SET);
	if (rc == -1) {
		printf("\nError: lseek() failed. Could not seek to address 0x%016llx. Error: %s", address, strerror(errno));
	} else if (rc != address) {
		printf("\nWarning: lseek() did not move to the expected address. Moved to 0x%016llx instead of 0x%016llx.", (uint64_t)rc, address);
	} else {
		printf("\nSuccessfully moved file pointer to address 0x%016llx.", address);
	}

	rc = read(fpga_fd2, buffer_out, size_out);
	if (rc != size_out) {
		printf("\nError: Data was not read correctly. Expected %d bytes, but read %zd bytes.\n", size_out, rc);
	} else {
		printf("\nData successfully read from FPGA.\n");
	}

	printf("\nBuffer Output =  ");
	for (i = 0; i < size_out; i++){
		printf("0x%016llx ", buffer_out[i]);
	}

	printf("\n======================================================\n");

	return 0;
}