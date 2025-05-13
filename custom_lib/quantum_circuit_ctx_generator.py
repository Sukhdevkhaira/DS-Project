import qiskit
import ansatz
import numpy as np
from qimax import converter, constant
from . import fixed_point_handler
from . import utils

def generate_quantum_circuit_data(num_qubits=3, quanvolutional_idx=1, basis_gate_list=['h', 's', 'cx', 'rx', 'ry', 'rz'], output_file_path='output.txt'):
    qc = qiskit.QuantumCircuit(num_qubits) 

    if(quanvolutional_idx == 1):
        qc = ansatz.quanvolutional1(qc)
    elif(quanvolutional_idx == 2):
        qc = ansatz.quanvolutional2(qc)
    elif(quanvolutional_idx == 3):
        qc = ansatz.quanvolutional3(qc)
    elif(quanvolutional_idx == 4):
        qc = ansatz.quanvolutional4(qc)
    elif(quanvolutional_idx == 5):
        qc = ansatz.quanvolutional5(qc)
    elif(quanvolutional_idx == 6):
        qc = ansatz.quanvolutional6(qc)
    elif(quanvolutional_idx == 7):
        qc = ansatz.quanvolutional7(qc)
    elif(quanvolutional_idx == 8):
        qc = ansatz.quanvolutional8(qc)
    elif(quanvolutional_idx == 9):
        qc = ansatz.quanvolutional9(qc)
    elif(quanvolutional_idx == 10):
        qc = ansatz.quanvolutional10(qc)
    elif(quanvolutional_idx == 11):
        qc = ansatz.quanvolutional11(qc)
    elif(quanvolutional_idx == 12):
        qc = ansatz.quanvolutional12(qc)
    elif(quanvolutional_idx == 13):
        qc = ansatz.quanvolutional13(qc)
    elif(quanvolutional_idx == 14):
        qc = ansatz.quanvolutional14(qc)
    elif(quanvolutional_idx == 15):
        qc = ansatz.quanvolutional15(qc)
    elif(quanvolutional_idx == 16):
        qc = ansatz.quanvolutional16(qc)
    elif(quanvolutional_idx == 17):
        qc = ansatz.quanvolutional17(qc)
    elif(quanvolutional_idx == 18):
        qc = ansatz.quanvolutional18(qc)
    elif(quanvolutional_idx == 19):
        qc = ansatz.quanvolutional19(qc)
        
    qc = qiskit.transpile(circuits=qc, basis_gates=basis_gate_list, optimization_level=3)
    # qc.draw(output='mpl').savefig('qc.png')

    # Convert to readable files
    texts = []
    texts.append(len(qc.data))
    for gate in qc.data:
        name = gate.name.upper()
        params = None
        wires = converter.get_wires_of_gate(gate)

        if name == 'CX':
            type = 2
        else:
            type = 1
            gate_entries = constant.constant_gate[name]
            if name in ['RX', 'RY', 'RZ']:
                params = gate.params[0]
                gate_entries = gate_entries(params)
        texts.append(type)
        if type == 2:
            texts.append("{" + str(wires[0]) + ", "+ str(wires[1]) + "}")
            # texts.append(wires[1])
        else:
            texts.append(wires[0])
            texts.append(gate_entries[0][0])
            texts.append(gate_entries[0][1])
            texts.append(gate_entries[1][0])
            texts.append(gate_entries[1][1])

    with open(output_file_path, 'w') as f:
        for item in texts:
            f.write("%s\n" % item)


def generate_quantum_circuit_data_with_state_res(num_qubits=3, quanvolutional_idx=1, basis_gate_list=['h', 's', 'cx', 'rx', 'ry', 'rz'], output_file_path='output.txt', output_original_state_path='output_original_state.txt', output_state_path='output_state.txt'):
    qc = qiskit.QuantumCircuit(num_qubits) 

    if(quanvolutional_idx == 1):
        qc = ansatz.quanvolutional1(qc)
    elif(quanvolutional_idx == 2):
        qc = ansatz.quanvolutional2(qc)
    elif(quanvolutional_idx == 3):
        qc = ansatz.quanvolutional3(qc)
    elif(quanvolutional_idx == 4):
        qc = ansatz.quanvolutional4(qc)
    elif(quanvolutional_idx == 5):
        qc = ansatz.quanvolutional5(qc)
    elif(quanvolutional_idx == 6):
        qc = ansatz.quanvolutional6(qc)
    elif(quanvolutional_idx == 7):
        qc = ansatz.quanvolutional7(qc)
    elif(quanvolutional_idx == 8):
        qc = ansatz.quanvolutional8(qc)
    elif(quanvolutional_idx == 9):
        qc = ansatz.quanvolutional9(qc)
    elif(quanvolutional_idx == 10):
        qc = ansatz.quanvolutional10(qc)
    elif(quanvolutional_idx == 11):
        qc = ansatz.quanvolutional11(qc)
    elif(quanvolutional_idx == 12):
        qc = ansatz.quanvolutional12(qc)
    elif(quanvolutional_idx == 13):
        qc = ansatz.quanvolutional13(qc)
    elif(quanvolutional_idx == 14):
        qc = ansatz.quanvolutional14(qc)
    elif(quanvolutional_idx == 15):
        qc = ansatz.quanvolutional15(qc)
    elif(quanvolutional_idx == 16):
        qc = ansatz.quanvolutional16(qc)
    elif(quanvolutional_idx == 17):
        qc = ansatz.quanvolutional17(qc)
    elif(quanvolutional_idx == 18):
        qc = ansatz.quanvolutional18(qc)
    elif(quanvolutional_idx == 19):
        qc = ansatz.quanvolutional19(qc)
        
    qc_trans = qiskit.transpile(circuits=qc, basis_gates=basis_gate_list, optimization_level=3)
    # qc_trans.draw(output='mpl').savefig('qc_trans.png')

    # Convert to readable files
    texts = []
    texts.append(len(qc_trans.data))
    for gate in qc_trans.data:
        name = gate.name.upper()
        params = None
        wires = converter.get_wires_of_gate(gate)
        if name == 'CX':
            type = 2
        else:
            type = 1
            gate_entries = constant.constant_gate[name]
            if name in ['RX', 'RY', 'RZ']:
                params = gate.params[0]
                gate_entries = gate_entries(params)
        texts.append(type)
        if type == 2:
            texts.append("{" + str(wires[0]) + ", "+ str(wires[1]) + "}")
        else:
            texts.append(wires[0])
            texts.append(gate_entries[0][0])
            texts.append(gate_entries[0][1])
            texts.append(gate_entries[1][0])
            texts.append(gate_entries[1][1])

    with open(output_file_path, 'w') as f:
        for item in texts:
            f.write("%s\n" % item)

    phase = np.e**(1j*qc_trans.global_phase)
    if qc_trans.global_phase > np.pi:
        phase *= -1

    # FROM ORIGINAL CIRCUITS
    qc_qiskit_original = qiskit.quantum_info.Statevector.from_instruction(qc).data

    # THIS IS THE EXPECTED OUTPUT
    qc_qiskit_processed = qiskit.quantum_info.Statevector.from_instruction(qc_trans).data/phase

    res_state_0 = np.array(qc_qiskit_original)
    np.savetxt(output_original_state_path, res_state_0)

    res_state_1 = np.array(qc_qiskit_processed)
    np.savetxt(output_state_path, res_state_1)


def qft_Qiskit(num_qubits):
    """QFT on the first n qubits in circuit"""
    def qft_rotations_Qiskit(qc: qiskit.QuantumCircuit, num_qubits):
        """Performs qft on the first n qubits in circuit (without swaps)"""
        if num_qubits == 0:
            return qc
        num_qubits -= 1
        qc.h(num_qubits)
        for j in range(num_qubits):
            
            # qc.rz(np.pi/2**(num_qubits-j) / 2, num_qubits)
            # qc.cx(j, num_qubits)
            # qc.rz(-np.pi/2**(num_qubits-j) / 2, num_qubits)
            # qc.cx(j, num_qubits)
            # qc.rz(+np.pi/2**(num_qubits-j) / 2, num_qubits)
            
            qc.cp(np.pi/2**(num_qubits-j), j, num_qubits)
            # qc.barrier()
        qft_rotations_Qiskit(qc, num_qubits)
    def swap_registers_Qiskit(qc: qiskit.QuantumCircuit, num_qubits):
        for j in range(num_qubits//2):
            qc.cx(j, num_qubits-j-1)
            qc.cx(num_qubits-j-1, j)
            qc.cx(j, num_qubits-j-1)
            # qc.barrier()
        return qc
    qc = qiskit.QuantumCircuit(num_qubits)
    qft_rotations_Qiskit(qc, num_qubits)
    swap_registers_Qiskit(qc, num_qubits)
    return qc


def generate_QFT_quantum_circuit_data_with_state_res(num_qubits=3, output_file_path='output.txt', output_original_state_path='output_original_state.txt', output_state_path='output_state.txt'):
    qc = qft_Qiskit(num_qubits)
    # print(qiskit.quantum_info.Statevector.from_instruction(qc).data)
        
    qc_trans = qiskit.transpile(qc, basis_gates=['h', 's', 'cx', 'rx', 'ry', 'rz'])
    # qc_trans.draw(output='mpl')
    # print(qiskit.quantum_info.Statevector.from_instruction(qc_trans).data)

    # Convert to readable files
    texts = []
    texts.append(len(qc_trans.data))
    for gate in qc_trans.data:
        name = gate.name.upper()
        params = None
        wires = converter.get_wires_of_gate(gate)
        if name == 'CX':
            type = 2
        else:
            type = 1
            gate_entries = constant.constant_gate[name]
            if name in ['RX', 'RY', 'RZ']:
                params = gate.params[0]
                gate_entries = gate_entries(params)
        texts.append(type)
        if type == 2:
            texts.append("{" + str(wires[0]) + ", "+ str(wires[1]) + "}")
        else:
            texts.append(wires[0])
            texts.append(gate_entries[0][0])
            texts.append(gate_entries[0][1])
            texts.append(gate_entries[1][0])
            texts.append(gate_entries[1][1])

    with open(output_file_path, 'w') as f:
        for item in texts:
            f.write("%s\n" % item)

    # phase = np.e**(1j*qc_trans.global_phase)
    # if qc_trans.global_phase > np.pi:
    #     phase *= -1

    # FROM ORIGINAL CIRCUITS
    qc_qiskit_original = qiskit.quantum_info.Statevector.from_instruction(qc).data

    # THIS IS THE EXPECTED OUTPUT
    qc_qiskit_processed = qiskit.quantum_info.Statevector.from_instruction(qc_trans).data

    res_state_0 = np.array(qc_qiskit_original)
    np.savetxt(output_original_state_path, res_state_0)

    res_state_1 = np.array(qc_qiskit_processed)
    np.savetxt(output_state_path, res_state_1)


def generate_quantum_circuit_ctx(n_qubit=3, bit_width=32, fraction_width=30, raw_file_path='output.txt', processed_file_path='output_hex.txt'):
    raw_data = utils.read_file(raw_file_path)
    processed_data = []

    sub_idx = 0
    gate_type = 1 # 0: Sprase, 1: Dense, 2: CX
    for index, line in enumerate(raw_data):
        if index == 0: # Number of gates
            bin_data = fixed_point_handler.int_to_binary(number=int(line.strip()), bit_width=bit_width*2)
            hex_data = fixed_point_handler.binary_to_hex(binary_str=bin_data, bit_width=bit_width*2)
            processed_data.append(hex_data[2:])
        else:
            if(sub_idx == 0): # Process gate type
                gate_type = int(line.strip())

                bin_data = fixed_point_handler.int_to_binary(number=int(line.strip()), bit_width=bit_width*2)
                hex_data = fixed_point_handler.binary_to_hex(binary_str=bin_data, bit_width=bit_width*2)

                sub_idx = sub_idx + 1
                processed_data.append(hex_data[2:])
            elif(sub_idx == 1):
                if(gate_type == 1): # Process dense gate position
                    gate_pos = n_qubit-1-int(line.strip())

                    bin_data = fixed_point_handler.int_to_binary(number=int(gate_pos), bit_width=bit_width*2)
                    hex_data = fixed_point_handler.binary_to_hex(binary_str=bin_data, bit_width=bit_width*2)

                    sub_idx = sub_idx + 1
                    processed_data.append(hex_data[2:])
                elif(gate_type == 2): # Process CX gate position
                    ctrl_pos, tgt_pos = line.strip("{}").split(", ")
                    ctrl_pos = n_qubit-1-int(ctrl_pos)
                    tgt_pos = n_qubit-1-int(tgt_pos)

                    ctrl_pos_binary = fixed_point_handler.int_to_binary(number=int(ctrl_pos), bit_width=bit_width)
                    tgt_pos_binary = fixed_point_handler.int_to_binary(number=int(tgt_pos), bit_width=bit_width)

                    ctrl_pos_hex = fixed_point_handler.binary_to_hex(binary_str=ctrl_pos_binary, bit_width=bit_width)
                    tgt_pos_hex = fixed_point_handler.binary_to_hex(binary_str=tgt_pos_binary, bit_width=bit_width)

                    sub_idx = 0
                    processed_data.append(ctrl_pos_hex[2:]+tgt_pos_hex[2:])
            else: # Process dense gate entries
                if(gate_type):
                    if(line[0] == '('):
                        line = line.strip("()")
                        
                    line = line.strip("")
                    compl_num = complex(line)

                    real_part = compl_num.real
                    imaginary_part = compl_num.imag

                    real_part_binary = fixed_point_handler.convert_fixedpoint_to_binary(number=real_part, bit_width=bit_width, dot_position=fraction_width)
                    imaginary_part_binary = fixed_point_handler.convert_fixedpoint_to_binary(number=imaginary_part, bit_width=bit_width, dot_position=fraction_width)

                    real_part_hex = fixed_point_handler.binary_to_hex(binary_str=real_part_binary, bit_width=bit_width)
                    imaginary_part_hex = fixed_point_handler.binary_to_hex(binary_str=imaginary_part_binary, bit_width=bit_width)

                    if(sub_idx < 5):
                        sub_idx = sub_idx + 1
                    else:
                        sub_idx = 0

                    processed_data.append(real_part_hex[2:]+imaginary_part_hex[2:])

    utils.write_file(processed_file_path, processed_data)