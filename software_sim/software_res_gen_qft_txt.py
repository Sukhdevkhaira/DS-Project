import numpy as np
import sys
sys.path.append('..')
from custom_lib import quantum_circuit_ctx_generator, utils, verilog, fixed_point_handler

qubit_num_idx_range = np.arange(3, 18, 1)

utils.create_folder('./result')
utils.create_folder('./result/QFT')

for qubit_num_idx in qubit_num_idx_range:
    saved_folder = './result/QFT/'
    utils.create_folder(saved_folder)
    print('===> Processing quantum QFT circuit with ' + str(qubit_num_idx) + ' qubits')
    ctx_link = '../hardware/gate_ctx_for_sim/QFT/quantum_circuit_data_' + str(qubit_num_idx) + '_qubits/' + 'output_QFT_' + str(qubit_num_idx) + '_qubits.txt'
    state_link = saved_folder + 'output_QFT_' + str(qubit_num_idx) + '_qubits.txt'
    utils.quantum_circuit_res_sim(n_qubit=qubit_num_idx, ctx_link=ctx_link, state_link=state_link, is_txt=True)
