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

#include "../util_lib/utils.c"

#define START_BASE_PHYS  0x08000000
#define FINISH_BASE_PHYS 0x0C000000
#define CTX_BASE_PHYS    0x80000000
#define STATE_BASE_PHYS  0xC0000000

#define PATH_BUFFER_SIZE 256

int main() {
	uint32_t address_state = STATE_BASE_PHYS;
	uint32_t address_gate_ctx = CTX_BASE_PHYS;
	uint32_t address_start = START_BASE_PHYS;
	uint32_t address_finish = FINISH_BASE_PHYS;
	char res_sub_folder_file_name[PATH_BUFFER_SIZE];
	char gate_file_name[PATH_BUFFER_SIZE];
	char res_file_name[PATH_BUFFER_SIZE];

	int min_qubits = 3;
	int max_qubits = 17;
	int min_quanv = 1;
	int max_quanv = 19;

	create_folder("results");

	clock_t start = clock();

	for(int i = min_qubits; i <= max_qubits; i++) {
		snprintf(res_sub_folder_file_name, PATH_BUFFER_SIZE, "./results/quantum_circuit_data_%d_qubits/", i);
		create_folder(res_sub_folder_file_name);
		for(int j = min_quanv; j <= max_quanv; j++) {
			snprintf(gate_file_name, PATH_BUFFER_SIZE, "../../fast-psr/hardware/gate_ctx_for_sim/quantum_circuit_data_%d_qubits/output_hex_%d_qubits_quanvolutional_%d.txt", i, i, j);
			snprintf(res_file_name, PATH_BUFFER_SIZE, "./results/quantum_circuit_data_%d_qubits/result_%d_qubits_quanvolutional_%d.txt", i, i, j);

            // printf("Saved result file path: %s\n", res_file_name);

			int n_qubits = i;
			uint32_t n_states = 1 << n_qubits;

			uint64_t *raw_result = fpga_exe(i, j, address_state, address_gate_ctx, address_start, address_finish);
			uint64_t *result = rearrange_state(raw_result, i);
			save_res_to_file(res_file_name, result, n_states);
		}
	}

	clock_t end = clock();
    double elapsed_time = (double)(end - start) / CLOCKS_PER_SEC;

    printf("\nExecution time: %.6f seconds\n", elapsed_time);

	return 0;
}