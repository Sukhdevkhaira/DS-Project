import numpy as np
import sys
sys.path.append('..')
from custom_lib import verilog

min_qbit_num = 3
max_qbit_num = 17
min_quantum_circuit_idx = 1
max_quantum_circuit_idx = 19

create_tb = verilog.create_tb_qft(min_qbit_num, max_qbit_num)

copy_design_files = verilog.copy_design_files_QFT(min_qbit_num, max_qbit_num)