import numpy as np
import sys
sys.path.append('..')
from custom_lib import quantum_circuit_ctx_generator, utils

min_qbit_num = 3
max_qbit_num = 17
min_quantum_circuit_idx = 1
max_quantum_circuit_idx = 19

quantum_circuit_idx_range = np.arange(min_quantum_circuit_idx, max_quantum_circuit_idx+1, 1)
qubit_num_idx_range = np.arange(min_qbit_num, max_qbit_num+1, 1)

utils.create_folder('../hardware/gate_ctx_for_sim/QFT/')
for qubit_num_idx in qubit_num_idx_range:
    saved_folder = '../hardware/gate_ctx_for_sim/QFT/quantum_circuit_data_' + str(qubit_num_idx) + '_qubits/'
    utils.create_folder(saved_folder)
    raw_file_path = saved_folder + 'output_QFT_' + str(qubit_num_idx) + '_qubits' + '.txt'
    processed_file_path = saved_folder + 'output_hex_QFT_' + str(qubit_num_idx) + '_qubits' + '.txt'
    state_file_original_path = saved_folder + 'output_original_state_QFT_' + str(qubit_num_idx) + '_qubits' + '.txt'
    state_file_path = saved_folder + 'output_state_QFT_' + str(qubit_num_idx) + '_qubits' + '.txt'
    quantum_circuit_ctx_generator.generate_QFT_quantum_circuit_data_with_state_res(num_qubits=qubit_num_idx, 
                                                                                   output_file_path=raw_file_path, 
                                                                                   output_original_state_path=state_file_original_path, 
                                                                                   output_state_path=state_file_path)
    quantum_circuit_ctx_generator.generate_quantum_circuit_ctx(n_qubit=qubit_num_idx, bit_width=32, fraction_width=30, raw_file_path=raw_file_path, processed_file_path=processed_file_path)