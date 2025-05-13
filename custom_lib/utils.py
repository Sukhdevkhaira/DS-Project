import os
import numpy as np
from . import fixed_point_handler

def read_file(file_name):
    lines = []
    with open(file_name, 'r') as file:
        for line in file:
            lines.append(line.strip())

    return lines

def write_file(file_name, lines):
    with open(file_name, 'w') as file:
        for line in lines:
            file.write(line + '\n')

def create_folder(saved_folder):
    try:
        os.mkdir(saved_folder)
        print(f"Directory '{saved_folder}' created successfully.")
    except FileExistsError:
        print(f"Directory '{saved_folder}' already exists.")
    except PermissionError:
        print(f"Permission denied: Unable to create '{saved_folder}'.")
    except Exception as e:
        print(f"An error occurred: {e}")

def fidelity(state1: np.ndarray, state2: np.ndarray):
    state1 = np.expand_dims(state1, axis=0)
    state2 = np.expand_dims(state2, axis=0)
    return (np.abs(np.inner(np.conjugate(state1), state2))**2)[0][0]

def mse(state1: np.ndarray, state2: np.ndarray):
    return np.mean(np.abs(state1 - state2)**2)

def tensor_product(matrix_a, matrix_b):
    return np.kron(matrix_a, matrix_b)

def cx_matrix_normal(n_qubit, ctrl_pos, target_pos):
  M = np.array([[1, 0], [0, 0]])
  P = np.array([[0, 0], [0, 1]])
  X = np.array([[0, 1], [1, 0]])
  I = np.array([[1, 0], [0, 1]])

  left_side_gate = np.array([])
  right_side_gate = np.array([])

  for i in range(n_qubit):
    if(i != ctrl_pos):
      left_side_gate = np.append(left_side_gate, np.array(["I"]))

      if(i != target_pos):
        right_side_gate = np.append(right_side_gate, np.array(["I"]))
      else:
        right_side_gate = np.append(right_side_gate, np.array(["X"]))
    else:
      left_side_gate = np.append(left_side_gate, np.array(["M"]))
      right_side_gate = np.append(right_side_gate, np.array(["P"]))

  left_side = np.array([])
  right_side = np.array([])

  for i in range(n_qubit):
    if(i == 0):
      if(left_side_gate[i] == "I"):
        left_side = I
      elif (left_side_gate[i] == "M"):
        left_side = M

      if(right_side_gate[i] == "I"):
        right_side = I
      elif (right_side_gate[i] == "P"):
        right_side = P
      elif (right_side_gate[i] == "X"):
        right_side = X
    else:
      if(left_side_gate[i] == "I"):
        left_side = tensor_product(left_side, I)
      elif (left_side_gate[i] == "M"):
        left_side = tensor_product(left_side, M)

      if(right_side_gate[i] == "I"):
        right_side = tensor_product(right_side, I)
      elif (right_side_gate[i] == "P"):
        right_side = tensor_product(right_side, P)
      elif (right_side_gate[i] == "X"):
        right_side = tensor_product(right_side, X)

  return left_side + right_side

def cx_matrix_formula(n, control, target):
    # Size of the matrix
    size = 2**n
    # Initialize the matrix as a zero matrix
    cx_matrix = np.zeros((size, size), dtype=int)

    # Iterate over all row indices
    for i in range(size):
        # Convert row index to binary representation
        binary_i = format(i, f'0{n}b')
        # Check if the control qubit is |1⟩
        if binary_i[control] == '1':
            # Flip the target qubit to get the column index
            binary_j = binary_i[:target] + ('1' if binary_i[target] == '0' else '0') + binary_i[target+1:]

            # print(binary_i)
            # print(binary_i[:target])
            # print(('1' if binary_i[target] == '0' else '0'))
            # print(binary_i[target+1:])
            # print(binary_i[:target] + ('1' if binary_i[target] == '0' else '0') + binary_i[target+1:])
            j = int(binary_j, 2)
            # Place a 1 at position (i, j)
            cx_matrix[i, j] = 1

            # print(i, j)
        else:
            # If control qubit is |0⟩, the target qubit remains unchanged
            cx_matrix[i, i] = 1

    return cx_matrix

def create_full_gate_matrix(gate_matrix, gate_pos, n_qubit):
    I_matrix = np.array([[1, 0], [0, 1]])
    
    matrix_u = []
    for i in range(n_qubit):
        if(i == 0):
            if(i == gate_pos):
                matrix_u = gate_matrix
            else:
                matrix_u = I_matrix
        else:
            if(i == gate_pos):
                matrix_u = tensor_product(matrix_u, gate_matrix)
            else:
                matrix_u = tensor_product(matrix_u, I_matrix)

    return matrix_u

def gate_computation(state_vector, gate_matrix, gate_pos, n_qubit):
    I_matrix = np.array([[1, 0], [0, 1]])
    
    matrix_u = []
    for i in range(n_qubit):
        if(i == 0):
            if(i == gate_pos):
                matrix_u = gate_matrix
            else:
                matrix_u = I_matrix
        else:
            if(i == gate_pos):
                matrix_u = tensor_product(matrix_u, gate_matrix)
            else:
                matrix_u = tensor_product(matrix_u, I_matrix)
    # print("matrix_u:", matrix_u)
    return np.dot(matrix_u, state_vector)

def quantum_circuit_computation(n_qubit=3, n_quanv=1):
    ctx_link = '../hardware/gate_ctx_for_sim/quantum_circuit_data_' + str(n_qubit) + '_qubits/' + 'output_' + str(n_qubit) + '_qubits' + '_quanvolutional_' + str(n_quanv) + '.txt'
    gate_ctx_data = read_file(ctx_link)

    I_matrix = np.array([[1, 0], [0, 1]], dtype=complex)
    Dense_matrix = np.array([[0, 0], [0, 0]], dtype=complex)

    state_vector = np.zeros(2**n_qubit, dtype=complex)
    state_vector[0] = 1

    bit_width = 32
    fraction_width = 30

    sub_idx = 0
    gate_type = 1 # 0: Sprase, 1: Dense, 2: CX
    num_of_gates = 0
    gate_count = 0
    for index, line in enumerate(gate_ctx_data):
        if index == 0: # Number of gates
            num_of_gates = int(line.strip())
            print(f"=> Number of gates: {num_of_gates}")
        else:
            if(sub_idx == 0): # Process gate type
                print(f"==================== Gate {gate_count} ====================")
                gate_count = gate_count + 1
                gate_type = int(line.strip())
                sub_idx = sub_idx + 1
            elif(sub_idx == 1):
                if(gate_type == 1): # Process dense gate position
                    pos = n_qubit-1-int(line.strip())
                    # pos = int(line.strip())
                    print(f"====> Dense gate | Pos: {pos}")
                    sub_idx = sub_idx + 1
                elif(gate_type == 2): # Process CX gate position
                    sub_idx = 0
                    ctrl_pos, tgt_pos = line.strip("{}").split(", ")
                    ctrl_pos = n_qubit-1-int(ctrl_pos)
                    tgt_pos = n_qubit-1-int(tgt_pos)
                    # ctrl_pos = int(ctrl_pos)
                    # tgt_pos = int(tgt_pos)

                    print(f"====> CX gate | Ctrl Pos: {ctrl_pos} | Tgt Pos: {tgt_pos}")

                    cx_matrix = cx_matrix_formula(n_qubit, ctrl_pos, tgt_pos)
                    state_vector = np.dot(cx_matrix, state_vector)

                    print(f"State vector after CX gate:")
                    for i in range(2**n_qubit):
                        real_part = state_vector[i].real
                        imaginary_part = state_vector[i].imag

                        real_part_binary = fixed_point_handler.convert_fixedpoint_to_binary(number=real_part, bit_width=bit_width, dot_position=fraction_width)
                        imaginary_part_binary = fixed_point_handler.convert_fixedpoint_to_binary(number=imaginary_part, bit_width=bit_width, dot_position=fraction_width)

                        real_part_hex = fixed_point_handler.binary_to_hex(binary_str=real_part_binary, bit_width=bit_width)
                        imaginary_part_hex = fixed_point_handler.binary_to_hex(binary_str=imaginary_part_binary, bit_width=bit_width)
                        print(f"Complex number: {state_vector[i]} | Hex form: {real_part_hex[2:]+imaginary_part_hex[2:]}")
            else: # Process dense gate entries
                if(gate_type):
                    if(line[0] == '('):
                        line = line.strip("()")
                        
                    line = line.strip("")
                    compl_num = complex(line)

                    if(sub_idx == 2):
                        Dense_matrix[0][0] = compl_num
                    elif(sub_idx == 3):
                        Dense_matrix[0][1] = compl_num
                    elif(sub_idx == 4):
                        Dense_matrix[1][0] = compl_num
                    elif(sub_idx == 5):
                        Dense_matrix[1][1] = compl_num

                        full_dense_matrix = create_full_gate_matrix(gate_matrix=Dense_matrix, gate_pos=pos, n_qubit=n_qubit)
                        state_vector = np.dot(full_dense_matrix, state_vector)
                        print(f"State vector after Dense gate:")
                        for i in range(2**n_qubit):
                            real_part = state_vector[i].real
                            imaginary_part = state_vector[i].imag

                            real_part_binary = fixed_point_handler.convert_fixedpoint_to_binary(number=real_part, bit_width=bit_width, dot_position=fraction_width)
                            imaginary_part_binary = fixed_point_handler.convert_fixedpoint_to_binary(number=imaginary_part, bit_width=bit_width, dot_position=fraction_width)

                            real_part_hex = fixed_point_handler.binary_to_hex(binary_str=real_part_binary, bit_width=bit_width)
                            imaginary_part_hex = fixed_point_handler.binary_to_hex(binary_str=imaginary_part_binary, bit_width=bit_width)
                            print(f"Complex number: {state_vector[i]} | Hex form: {real_part_hex[2:]+imaginary_part_hex[2:]}")

                    if(sub_idx < 5):
                        sub_idx = sub_idx + 1
                    else:
                        sub_idx = 0

def quantum_circuit_res_sim(n_qubit=3, ctx_link='', state_link='./result.txt', is_txt=False):
    gate_ctx_data = read_file(ctx_link)

    Dense_matrix = np.array([[0, 0], [0, 0]], dtype=complex)

    state_vector = np.zeros(2**n_qubit, dtype=complex)
    state_vector[0] = 1

    bit_width = 32
    fraction_width = 30

    sub_idx = 0
    gate_type = 1 # 0: Sprase, 1: Dense, 2: CX
    num_of_gates = 0
    gate_count = 0
    for index, line in enumerate(gate_ctx_data):
        if index == 0: # Number of gates
            num_of_gates = int(line.strip())
            # print(f"=> Number of gates: {num_of_gates}")
        else:
            if(sub_idx == 0): # Process gate type
                # print(f"==================== Gate {gate_count} ====================")
                gate_count = gate_count + 1
                gate_type = int(line.strip())
                sub_idx = sub_idx + 1
            elif(sub_idx == 1):
                if(gate_type == 1): # Process dense gate position
                    pos = n_qubit-1-int(line.strip())
                    # print(f"====> Dense gate | Pos: {pos}")
                    sub_idx = sub_idx + 1
                elif(gate_type == 2): # Process CX gate position
                    sub_idx = 0
                    ctrl_pos, tgt_pos = line.strip("{}").split(", ")
                    ctrl_pos = n_qubit-1-int(ctrl_pos)
                    tgt_pos = n_qubit-1-int(tgt_pos)

                    # print(f"====> CX gate | Ctrl Pos: {ctrl_pos} | Tgt Pos: {tgt_pos}")

                    cx_matrix = cx_matrix_formula(n_qubit, ctrl_pos, tgt_pos)
                    state_vector = np.dot(cx_matrix, state_vector)

                    # print(f"State vector after CX gate:")
                    for i in range(2**n_qubit):
                        real_part = state_vector[i].real
                        imaginary_part = state_vector[i].imag

                        real_part_binary = fixed_point_handler.convert_fixedpoint_to_binary(number=real_part, bit_width=bit_width, dot_position=fraction_width)
                        imaginary_part_binary = fixed_point_handler.convert_fixedpoint_to_binary(number=imaginary_part, bit_width=bit_width, dot_position=fraction_width)

                        real_part_hex = fixed_point_handler.binary_to_hex(binary_str=real_part_binary, bit_width=bit_width)
                        imaginary_part_hex = fixed_point_handler.binary_to_hex(binary_str=imaginary_part_binary, bit_width=bit_width)
                        # print(f"Complex number: {state_vector[i]} | Hex form: {real_part_hex[2:]+imaginary_part_hex[2:]}")
            else: # Process dense gate entries
                if(gate_type):
                    if(line[0] == '('):
                        line = line.strip("()")
                        
                    line = line.strip("")
                    compl_num = complex(line)

                    if(sub_idx == 2):
                        Dense_matrix[0][0] = compl_num
                    elif(sub_idx == 3):
                        Dense_matrix[0][1] = compl_num
                    elif(sub_idx == 4):
                        Dense_matrix[1][0] = compl_num
                    elif(sub_idx == 5):
                        Dense_matrix[1][1] = compl_num

                        full_dense_matrix = create_full_gate_matrix(gate_matrix=Dense_matrix, gate_pos=pos, n_qubit=n_qubit)
                        state_vector = np.dot(full_dense_matrix, state_vector)
                        # print(f"State vector after Dense gate:")
                        for i in range(2**n_qubit):
                            real_part = state_vector[i].real
                            imaginary_part = state_vector[i].imag

                            real_part_binary = fixed_point_handler.convert_fixedpoint_to_binary(number=real_part, bit_width=bit_width, dot_position=fraction_width)
                            imaginary_part_binary = fixed_point_handler.convert_fixedpoint_to_binary(number=imaginary_part, bit_width=bit_width, dot_position=fraction_width)

                            real_part_hex = fixed_point_handler.binary_to_hex(binary_str=real_part_binary, bit_width=bit_width)
                            imaginary_part_hex = fixed_point_handler.binary_to_hex(binary_str=imaginary_part_binary, bit_width=bit_width)
                            # print(f"Complex number: {state_vector[i]} | Hex form: {real_part_hex[2:]+imaginary_part_hex[2:]}")

                    if(sub_idx < 5):
                        sub_idx = sub_idx + 1
                    else:
                        sub_idx = 0
    if(is_txt):
        np.savetxt(state_link, state_vector)
    else:
        np.save(state_link, state_vector)