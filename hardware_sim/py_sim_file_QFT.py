import numpy as np
import sys
sys.path.append('..')
from custom_lib import quantum_circuit_ctx_generator, utils, verilog

min_qbit_num = 3
max_qbit_num = 17

verilog.hardware_python_sim_all_new_qft(min_qbit_num=min_qbit_num, max_qbit_num=max_qbit_num)