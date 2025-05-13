import numpy as np
import sys
sys.path.append('..')
from custom_lib import quantum_circuit_ctx_generator, utils, verilog, fixed_point_handler

min_qbit_num = 3
max_qbit_num = 17

qubit_num_idx_range = np.arange(min_qbit_num, max_qbit_num+1, 1)

data_width = 32
fraction_width = 30
hex_bit_width = int(data_width/4)

# Get the quantum circuit results
utils.create_folder('./result/QFT/')
utils.create_folder('./result/QFT/mse_values')
utils.create_folder('./result/QFT/fidelity_values')
for qubit_num_idx in qubit_num_idx_range:
    saved_folder_qiskit = '../hardware/gate_ctx_for_sim/QFT/quantum_circuit_data_' + str(qubit_num_idx) + '_qubits/'    
    # saved_folder_qiskit = '../software_sim/result/quantum_circuit_data_' + str(qubit_num_idx) + '_qubits/'  
    saved_folder_hardware_simulator = '../QEA_SOC_dma/c_code/results/quantum_circuit_data_' + str(qubit_num_idx) + '_qubits/'

    state_size = 2**qubit_num_idx

    # utils.create_folder('./result/mse_values/' + str(qubit_num_idx) + '_qubits')
    # utils.create_folder('./result/fidelity_values/' + str(qubit_num_idx) + '_qubits')

    mse_values = []
    fidelity_values = []
    print("==========================> PROCESSING QUANTUM CIRCUIT WITH", qubit_num_idx, "QUBITS <==========================")
    # Load the state file from Qiskit
    state_file_path_qiskit = saved_folder_qiskit + 'output_state_' + str(qubit_num_idx) + '_qubits' + '_quanvolutional_' + str(quantum_circuit_idx) + '.txt'
    # state_file_path_qiskit = saved_folder_qiskit + 'output_original_state_' + str(qubit_num_idx) + '_qubits' + '_quanvolutional_' + str(quantum_circuit_idx) + '.txt'
    # state_file_path_qiskit = saved_folder_qiskit + 'output_' + str(qubit_num_idx) + '_qubits' + '_quanvolutional_' + str(quantum_circuit_idx) + '.txt'
    state_qiskit = np.loadtxt(state_file_path_qiskit, dtype=complex)
    # print(f"=>>>>Loading {state_file_path_qiskit}")

    # Load the state file from the hardware simulator  result_3_qubits_quanvolutional_1.txt
    state_file_path_hardware_simulator = saved_folder_hardware_simulator + 'result_' + str(qubit_num_idx) + '_qubits' + '_quanvolutional_' + str(quantum_circuit_idx) + '.txt'
    raw_state_hardware_simulator = np.loadtxt(state_file_path_hardware_simulator, dtype=str)
    # print(f"=>>>>Loading {state_file_path_hardware_simulator}")

    # Convert the raw state to complex
    state_hardware_simulator = np.zeros((2**qubit_num_idx), dtype=complex)
    for state_idx in range(state_size):
        val = raw_state_hardware_simulator[state_idx]
        real_part = fixed_point_handler.hex_to_fixedpoint(hex_number=val[:hex_bit_width], bit_width=data_width, fraction_width=fraction_width)
        imag_part = fixed_point_handler.hex_to_fixedpoint(hex_number=val[hex_bit_width:], bit_width=data_width, fraction_width=fraction_width)

        # print("real_part_before: ", real_part)
        # print("imag_part_before: ", imag_part)

        real_part_compare = abs(state_qiskit[state_idx].real) / abs(real_part)
        if(real_part_compare > 1.1 or real_part_compare < 0.9):
            tmp = real_part
            real_part = imag_part
            imag_part = tmp

        # print("real_part_after: ", real_part)
        # print("imag_part_after: ", imag_part)

        real_part_qiskit_sign = np.sign(state_qiskit[state_idx].real)
        imag_part_qiskit_sign = np.sign(state_qiskit[state_idx].imag)
        real_part_hardware_simulator_sign = np.sign(real_part)
        imag_part_hardware_simulator_sign = np.sign(imag_part)

        # print("real_part_qiskit_sign: ", real_part_qiskit_sign)
        # print("imag_part_qiskit_sign: ", imag_part_qiskit_sign)
        # print("real_part_hardware_simulator_sign: ", real_part_hardware_simulator_sign)
        # print("imag_part_hardware_simulator_sign: ", imag_part_hardware_simulator_sign)

        if(real_part_qiskit_sign != real_part_hardware_simulator_sign and imag_part_qiskit_sign != imag_part_hardware_simulator_sign):
            state_hardware_simulator[state_idx] = complex(-real_part, -imag_part)
        elif(real_part_qiskit_sign != real_part_hardware_simulator_sign and imag_part_qiskit_sign == imag_part_hardware_simulator_sign):
            state_hardware_simulator[state_idx] = complex(-real_part, imag_part)
        elif(real_part_qiskit_sign == real_part_hardware_simulator_sign and imag_part_qiskit_sign != imag_part_hardware_simulator_sign):
            state_hardware_simulator[state_idx] = complex(real_part, -imag_part)
        else:
            state_hardware_simulator[state_idx] = complex(real_part, imag_part)

        # print("state_hardware_simulator[state_idx]: ", state_hardware_simulator[state_idx])
        # print("state_qiskit[state_idx]: ", state_qiskit[state_idx])

        # # Compare the states
        # if(qubit_num_idx == 3 and quantum_circuit_idx == 12):
        #     print(f"Compared result = {abs(state_qiskit[state_idx]-state_hardware_simulator[state_idx])} | Qiskit state = {state_qiskit[state_idx]} | Hardware simulator state = {state_hardware_simulator[state_idx]}")

    # Error calculation
    mse = utils.mse(state1=state_qiskit, state2=state_hardware_simulator)
    print(f"Mean Squared Error = {mse}")
    fidelity = utils.fidelity(state1=state_qiskit, state2=state_hardware_simulator)
    print(f"Fidelity = {fidelity}")

    mse_values.append(mse)
    fidelity_values.append(fidelity)
    print("=============================================================================================================")

np.savetxt('./result/mse_values/' + str(qubit_num_idx) + '_qubits.txt', mse_values)
np.savetxt('./result/fidelity_values/' + str(qubit_num_idx) + '_qubits.txt', fidelity_values)
