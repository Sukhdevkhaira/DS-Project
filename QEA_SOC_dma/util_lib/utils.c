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

#define PATH_TEMPLATE "../../fast-psr/hardware/gate_ctx_for_sim/quantum_circuit_data_%d_qubits/output_hex_%d_qubits_quanvolutional_%d.txt"
#define PATH_TEMPLATE_QFT "../../fast-psr/hardware/gate_ctx_for_sim/QFT/quantum_circuit_data_%d_qubits/output_hex_QFT_%d_qubits.txt"

struct file_info {
    uint64_t *data;
    uint64_t size;
};

int count_line_of_file(char *filename) {
    FILE *file;
    int line_count = 0;
    char buffer[100]; // 100 characters in maximum

    file = fopen(filename, "r");

    if (file == NULL) {
        printf("Error opening file.\n");
        return 0;
    } else {
        printf("File opened successfully.\n");
    }

    while (fgets(buffer, sizeof(buffer), file) != NULL) {
        line_count++;
    }

    fclose(file);

    return line_count;
}

struct file_info read_file(char *filename) {
    struct file_info file_data;

    uint64_t line_num = count_line_of_file(filename);
    uint64_t *read_data = (uint64_t *)malloc(line_num * sizeof(uint64_t));

    FILE *file;
    char buffer[100]; // 100 characters in maximum

    file = fopen(filename, "r");

    if (file == NULL) {
        printf("Error opening file.\n");
        file_data.data = NULL;
        file_data.size = 0;
        return file_data;
    } else {
        printf("File opened successfully.\n");
    }

    int i = 0;
    while (fgets(buffer, sizeof(buffer), file) != NULL) {
        read_data[i] = strtoull(buffer, NULL, 16);
        i++;
    }

    fclose(file);

    file_data.data = read_data;
    file_data.size = line_num;

    return file_data;
}

void init_write_state(int n_qbit, uint32_t addr) {
	int n_qubits              = n_qbit;
	char *host_to_card_device = "/dev/xdma0_h2c_0";
	int fpga_fd_write         = open(host_to_card_device, O_RDWR);

	uint32_t address_state    = addr;
	uint32_t n_states         = 1 << n_qubits;
	uint32_t state_size       = n_states >> 2;
	uint32_t actual_size      = 32*state_size; // Byte size => 32*state_size bytes

	uint64_t *buffer_write    = NULL;
	uint64_t offset_write     = 0;
	uint64_t *allocated_write = NULL;

	posix_memalign((void **)&allocated_write, 4096 /*alignment */ , actual_size + 4096); // 
	buffer_write = allocated_write + offset_write;

	ssize_t result_code_state_write;

	printf("\n========== START TO WRITE STATE INTO THE FPGA ==========");
	printf("\nAddress     = 0x%08x", address_state);
	printf("\nState Size  = %d", state_size);
	printf("\nActual Size = %d", actual_size);
	
	printf("\nBuffer Write =  \n");

	for (int i = 0; i < state_size; i++) { 
		if(i == 0) {
			buffer_write[i*4+0] = 0x0000000000000000; // 0.0
			buffer_write[i*4+1] = 0x0000000000000000; // 0.0
			buffer_write[i*4+2] = 0x0000000000000000; // 0.0
			buffer_write[i*4+3] = 0x4000000000000000; // 1.0
		} else {
			buffer_write[i*4+0] = 0x0000000000000000; // 0.0
			buffer_write[i*4+1] = 0x0000000000000000; // 0.0
			buffer_write[i*4+2] = 0x0000000000000000; // 0.0
			buffer_write[i*4+3] = 0x0000000000000000; // 0.0
		}

		printf("%016lx, %016lx, %016lx, %016lx \n", buffer_write[i * 4 + 0], buffer_write[i * 4 + 1], buffer_write[i * 4 + 2], buffer_write[i * 4 + 3]);
	}

	result_code_state_write = lseek(fpga_fd_write, address_state, SEEK_SET);
	if (result_code_state_write == -1) {
		printf("\nError: lseek() failed. Could not seek to address 0x%08x. Error: %s", address_state, strerror(errno));
	} else if (result_code_state_write != address_state) {
		printf("\nWarning: lseek() did not move to the expected address. Moved to 0x%08x instead of 0x%08x.", (uint32_t)result_code_state_write, address_state);
	} else {
		printf("\nSuccessfully moved file pointer to address 0x%08x.", address_state);
	}

	result_code_state_write = write(fpga_fd_write, buffer_write, actual_size);
	if (result_code_state_write != actual_size) {
		printf("\nError: Data was not written correctly. Expected %d elements, but wrote %zd elements.", actual_size, result_code_state_write);
	} else {
		printf("\nData successfully written to FPGA.\n");
	}
	printf("\n======================================================\n");

	close(fpga_fd_write);
}

void read_and_write_gate_info(char *filename, uint32_t addr) {
	struct file_info gate_info = read_file(filename);

	char *host_to_card_device = "/dev/xdma0_h2c_0";
	int fpga_fd_write         = open(host_to_card_device, O_RDWR);

	uint32_t address_gate_ctx = addr;
	uint32_t n_gate_ctx       = gate_info.size;
	uint32_t actual_size      = 32*n_gate_ctx; // Byte size => 32*state_size bytes

	uint64_t *buffer_write    = NULL;
	uint64_t offset_write     = 0;
	uint64_t *allocated_write = NULL;

	posix_memalign((void **)&allocated_write, 4096 /*alignment */ , actual_size + 4096); // 
	buffer_write = allocated_write + offset_write;

	ssize_t result_code_gate_write;

	printf("\n========== START TO WRITE GATE CONTEXT INTO THE FPGA ==========");
	printf("\nAddress           = 0x%08x", address_gate_ctx);
	printf("\nGate Context Size = %d", n_gate_ctx);
	printf("\nActual Size       = %d", actual_size);
	
	printf("\nBuffer Write =  \n");

	for (int i = 0; i < n_gate_ctx; i++) { 
		buffer_write[i * 4 + 0] = gate_info.data[i];
		buffer_write[i * 4 + 1] = 0;
		buffer_write[i * 4 + 2] = 0;
		buffer_write[i * 4 + 3] = 0;

		printf("%016lx, %016lx, %016lx, %016lx \n", buffer_write[i * 4 + 0], buffer_write[i * 4 + 1], buffer_write[i * 4 + 2], buffer_write[i * 4 + 3]);
	}

	result_code_gate_write = lseek(fpga_fd_write, address_gate_ctx, SEEK_SET);
	if (result_code_gate_write == -1) {
		printf("\nError: lseek() failed. Could not seek to address 0x%08x. Error: %s", address_gate_ctx, strerror(errno));
	} else if (result_code_gate_write != address_gate_ctx) {
		printf("\nWarning: lseek() did not move to the expected address. Moved to 0x%08x instead of 0x%08x.", (uint32_t)result_code_gate_write, address_gate_ctx);
	} else {
		printf("\nSuccessfully moved file pointer to address 0x%08x.", address_gate_ctx);
	}

	result_code_gate_write = write(fpga_fd_write, buffer_write, actual_size);
	if (result_code_gate_write != actual_size) {
		printf("\nError: Data was not written correctly. Expected %d elements, but wrote %zd elements.", actual_size, result_code_gate_write);
	} else {
		printf("\nData successfully written to FPGA.\n");
	}
	printf("\n======================================================\n");

	close(fpga_fd_write);
}

uint64_t *read_result_state(int n_qbit, uint32_t addr_state) {
	char *card_to_host_device = "/dev/xdma0_c2h_0";
	int fpga_fd_read = open(card_to_host_device, O_RDWR);
	if (fpga_fd_read < 0) {
		printf("Error opening device %s: %s\n", card_to_host_device, strerror(errno));
		return NULL;
	}

	uint32_t address_state = addr_state;
	uint32_t n_states = 1 << n_qbit;
	uint32_t state_size = n_states >> 2;          // Number of 64-bit entries
	uint32_t actual_size = 32 * state_size;        // Total bytes to read (4 x 64-bit per state)

	uint64_t *buffer_read = NULL;

	// Allocate aligned memory (required for DMA on FPGA)
	if (posix_memalign((void **)&buffer_read, 4096, actual_size + 4096) != 0) {
		printf("Error: posix_memalign() failed\n");
		close(fpga_fd_read);
		return NULL;
	}

	printf("\n========== READ THE RESULT STATE FROM THE FPGA ==========");
	printf("\nAddress     = 0x%08x", address_state);
	printf("\nState Size  = %d", state_size);
	printf("\nActual Size = %d", actual_size);

	ssize_t result_code_state_read = lseek(fpga_fd_read, address_state, SEEK_SET);
	if (result_code_state_read == -1) {
		printf("\nError: lseek() failed. Could not seek to address 0x%08x. Error: %s", address_state, strerror(errno));
		free(buffer_read);
		close(fpga_fd_read);
		return NULL;
	} else if ((uint32_t)result_code_state_read != address_state) {
		printf("\nWarning: lseek() did not move to the expected address. Moved to 0x%08x instead of 0x%08x.", (uint32_t)result_code_state_read, address_state);
	}

	result_code_state_read = read(fpga_fd_read, buffer_read, actual_size);
	if (result_code_state_read != actual_size) {
		printf("\nError: Data was not read correctly. Expected %d bytes, but read %zd bytes.", actual_size, result_code_state_read);
		free(buffer_read);
		close(fpga_fd_read);
		return NULL;
	} else {
		printf("\nData successfully read from FPGA.\n");

		printf("\nBuffer Read = \n");
		for (int i = 0; i < state_size; i++) {
			printf("%016lx, %016lx, %016lx, %016lx\n", 
				buffer_read[i * 4 + 0], buffer_read[i * 4 + 1], 
				buffer_read[i * 4 + 2], buffer_read[i * 4 + 3]);
		}
	}
	printf("\n======================================================\n");

	close(fpga_fd_read);

	return buffer_read; // Return the buffer to the caller
}

void start_and_finish(int num_qubit, uint32_t addr_start, uint32_t addr_finish) {
	// =========================================================
	// ================= Write start signal ====================
	// =========================================================
	char *host_to_card_device = "/dev/xdma0_h2c_0";
	int fpga_fd_write         = open(host_to_card_device, O_RDWR);

	uint32_t address_start = addr_start;
	uint32_t actual_size_start      = 32; // Byte size => 32 bytes

	uint64_t *buffer_start    = NULL;
	uint64_t offset_start     = 0;
	uint64_t *allocated_start = NULL;

	posix_memalign((void **)&allocated_start, 4096 /*alignment */ , actual_size_start + 4096); // 
	buffer_start = allocated_start + offset_start;

	ssize_t result_code_start_write;

	printf("\n========== START THE SYSTEM ==========");
	printf("\nAddress           = 0x%08x", address_start);
	printf("\nActual Size       = %d", actual_size_start);
	
	printf("\nBuffer Write =  \n");

	for (int i = 0; i < 1; i++) { 
		buffer_start[i * 4 + 0] = (num_qubit << 1)| 1;
		buffer_start[i * 4 + 1] = 0;
		buffer_start[i * 4 + 2] = 0;
		buffer_start[i * 4 + 3] = 0;

		printf("%016lx, %016lx, %016lx, %016lx \n", buffer_start[i * 4 + 0], buffer_start[i * 4 + 1], buffer_start[i * 4 + 2], buffer_start[i * 4 + 3]);
	}

	result_code_start_write = lseek(fpga_fd_write, address_start, SEEK_SET);
	if (result_code_start_write == -1) {
		printf("\nError: lseek() failed. Could not seek to address 0x%08x. Error: %s", address_start, strerror(errno));
	} else if (result_code_start_write != address_start) {
		printf("\nWarning: lseek() did not move to the expected address. Moved to 0x%08x instead of 0x%08x.", (uint32_t)result_code_start_write, address_start);
	} else {
		printf("\nSuccessfully moved file pointer to address 0x%08x.", address_start);
	}

	result_code_start_write = write(fpga_fd_write, buffer_start, actual_size_start);
	if (result_code_start_write != actual_size_start) {
		printf("\nError: Data was not written correctly. Expected %d elements, but wrote %zd elements.", actual_size_start, result_code_start_write);
	} else {
		printf("\nComputation started\n");
	}
	printf("\n======================================================\n");

	close(fpga_fd_write);
}

void delay(unsigned int secs) {
    unsigned int retTime = time(0) + secs;   // Get finishing time.
	while (time(0) < retTime);               // Loop until it arrives.
}

int create_folder(char *folder_name) {
	int result = mkdir(folder_name, 0777);  // Full permissions on Unix-like systems

	if (result == 0) {
		printf("Folder '%s' created successfully.\n", folder_name);
	} else {
		perror("Failed to create folder");
	}

	return result;
}

uint64_t *fpga_exe(int n_qubit, int num_quanv,
                       uint32_t address_state, uint32_t address_gate_ctx,
                       uint32_t address_start, uint32_t address_finish) {
    // Step 1: Compute required length
    int needed_size = snprintf(NULL, 0, PATH_TEMPLATE, n_qubit, n_qubit, num_quanv) + 1;  // +1 for null terminator

    // Step 2: Allocate memory
    char *gate_file_name = malloc(needed_size);
    // char *gate_file_name = NULL;
    if (gate_file_name == NULL) {
        perror("Failed to allocate memory for file name");
        exit(EXIT_FAILURE);
    }

    // Step 3: Build the string into the dynamic array
    snprintf(gate_file_name, needed_size, PATH_TEMPLATE, n_qubit, n_qubit, num_quanv);

    printf("\nGenerated gate file name: %s\n", gate_file_name);

    // Step 4: Use the dynamically allocated file name
    uint32_t n_state = 1 << n_qubit;
    uint32_t state_size = n_state >> 2;          // Number of 64-bit entries
    uint32_t actual_size = 32 * state_size;        // Total bytes to read (4 x 64-bit per state)

    init_write_state(n_qubit, address_state);
    read_and_write_gate_info(gate_file_name, address_gate_ctx);
    start_and_finish(n_qubit, address_start, address_finish);

    unsigned int delay_time = 2;
    delay(delay_time);

    return read_result_state(n_qubit, address_state);
}

uint64_t *fpga_exe_QFT(int n_qubit, 
	uint32_t address_state, uint32_t address_gate_ctx,
	uint32_t address_start, uint32_t address_finish) {
	// Step 1: Compute required length
	int needed_size = snprintf(NULL, 0, PATH_TEMPLATE_QFT, n_qubit, n_qubit) + 1;  // +1 for null terminator

	// Step 2: Allocate memory
	char *gate_file_name = malloc(needed_size);
	// char *gate_file_name = NULL;
	if (gate_file_name == NULL) {
	perror("Failed to allocate memory for file name");
	exit(EXIT_FAILURE);
	}

	// Step 3: Build the string into the dynamic array
	snprintf(gate_file_name, needed_size, PATH_TEMPLATE_QFT, n_qubit, n_qubit);

	printf("\nGenerated gate file name: %s\n", gate_file_name);

	// Step 4: Use the dynamically allocated file name
	uint32_t n_state = 1 << n_qubit;
	uint32_t state_size = n_state >> 2;          // Number of 64-bit entries
	uint32_t actual_size = 32 * state_size;        // Total bytes to read (4 x 64-bit per state)

	init_write_state(n_qubit, address_state);
	read_and_write_gate_info(gate_file_name, address_gate_ctx);
	start_and_finish(n_qubit, address_start, address_finish);

	unsigned int delay_time = 3;
	delay(delay_time);

	return read_result_state(n_qubit, address_state);
}

uint64_t *rearrange_state(uint64_t *state, int n_qubit) {
	uint32_t n_states = 1 << n_qubit;
	uint32_t state_size = n_states >> 2;          // Number of 64-bit entries
	uint32_t actual_size = 32 * state_size;        // Total bytes to read (4 x 64-bit per state)

	uint64_t *rearranged_state = (uint64_t *)malloc(n_states * sizeof(uint64_t)); // (uint64_t *)malloc(n_states);
	// uint64_t *rearranged_state = NULL;
	if (rearranged_state == NULL) {
		perror("Failed to allocate memory for rearranged state");
		exit(EXIT_FAILURE);
	}

	for (int i = 3; i >=0; i--) {
	    for (int j = 0; j < state_size; j++) {
		    rearranged_state[(3-i)*state_size + j] = state[j*4 + i];
			// printf("rearranged_state[%d] - state[%d]\n", (3-i)*state_size + j, j*4 + i);
		}
	}

	// for (int i = 0; i < state_size; i++) {
	// 	printf("%016lx, %016lx, %016lx, %016lx\n", rearranged_state[i * 4 + 0], rearranged_state[i * 4 + 1], rearranged_state[i * 4 + 2], rearranged_state[i * 4 + 3]);
    // }

	return rearranged_state;
}

void save_res_to_file(char *filename, uint64_t *array, uint32_t length) {
    FILE *file = fopen(filename, "w");
    if (file == NULL) {
        perror("Failed to open file");
        return;
    }

    for (uint32_t i = 0; i < length; i++) {
        fprintf(file, "%016lx\n", array[i]);
    }

    fclose(file);
    printf("Array saved to %s\n", filename);
}