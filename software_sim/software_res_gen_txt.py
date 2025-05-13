import numpy as np
import sys
sys.path.append('..')
from custom_lib import quantum_circuit_ctx_generator, utils, verilog, fixed_point_handler


quantum_circuit_idx_range = np.arange(1, 20, 1)
qubit_num_idx_range = np.arange(3, 18, 1)

utils.create_folder('./result')

quantum_circuit_idx_range = np.arange(1, 20, 1)
qubit_num_idx_range = np.arange(3, 18, 1)

utils.create_folder('./result')

for qubit_num_idx in qubit_num_idx_range:
    saved_folder = './result/quantum_circuit_data_' + str(qubit_num_idx) + '_qubits/'
    utils.create_folder(saved_folder)
    for quantum_circuit_idx in quantum_circuit_idx_range:
        print('===> Processing quantum circuit with ' + str(qubit_num_idx) + ' qubits and ' + str(quantum_circuit_idx) + ' quanvolutional')
        ctx_link = '../hardware/gate_ctx_for_sim/quantum_circuit_data_' + str(qubit_num_idx) + '_qubits/' + 'output_' + str(qubit_num_idx) + '_qubits' + '_quanvolutional_' + str(quantum_circuit_idx) + '.txt'
        state_state = saved_folder + 'output_' + str(qubit_num_idx) + '_qubits' + '_quanvolutional_' + str(quantum_circuit_idx) + '.txt'
        utils.quantum_circuit_res_sim(n_qubit=qubit_num_idx, ctx_link=ctx_link, state_link=state_state, is_txt=True)
