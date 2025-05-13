import numpy as np
import sys
sys.path.append('..')
from custom_lib import quantum_circuit_ctx_generator, utils, verilog

min_qbit_num = 3
max_qbit_num = 17
min_quantum_circuit_idx = 1
max_quantum_circuit_idx = 19

# verilog.hardware_python_sim_all(min_qbit_num=min_qbit_num, max_qbit_num=max_qbit_num, min_quantum_circuit_idx=min_quantum_circuit_idx, max_quantum_circuit_idx=max_quantum_circuit_idx)
verilog.hardware_python_sim_all_new(min_qbit_num=min_qbit_num, max_qbit_num=max_qbit_num, min_quantum_circuit_idx=min_quantum_circuit_idx, max_quantum_circuit_idx=max_quantum_circuit_idx)