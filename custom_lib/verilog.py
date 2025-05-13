import numpy as np
import shutil
import os
import time
from . import utils

def copy_design_files(min_qbit_num, max_qbit_num, min_quantum_circuit_idx, max_quantum_circuit_idx):
    quantum_circuit_idx_range = np.arange(min_quantum_circuit_idx, max_quantum_circuit_idx+1, 1)
    qubit_num_idx_range = np.arange(min_qbit_num, max_qbit_num+1, 1)

    src_folder = '../hardware/verilog/sample/Design/'

    for qubit_num_idx in qubit_num_idx_range:
        saved_folder_name = '../hardware/verilog/generated_sim_file/quantum_circuit_data_' + str(qubit_num_idx) + '_qubits/'
        utils.create_folder(saved_folder_name)
        for quantum_circuit_idx in quantum_circuit_idx_range:
            dst_folder = saved_folder_name + 'quanvolutional_' + str(quantum_circuit_idx) + '/Design/'
            utils.create_folder(saved_folder_name + 'quanvolutional_' + str(quantum_circuit_idx))
            utils.create_folder(saved_folder_name + 'quanvolutional_' + str(quantum_circuit_idx) + '/Design/')
            
            os.makedirs(dst_folder, exist_ok=True)
            for filename in os.listdir(src_folder):
                src_file = os.path.join(src_folder, filename)
                dst_file = os.path.join(dst_folder, filename)
                if os.path.isfile(src_file): 
                    shutil.copy2(src_file, dst_file)


def copy_design_files_QFT(min_qbit_num, max_qbit_num):
    qubit_num_idx_range = np.arange(min_qbit_num, max_qbit_num+1, 1)

    src_folder = '../hardware/verilog/sample/Design/'

    for qubit_num_idx in qubit_num_idx_range:
        saved_folder_name = '../hardware/verilog/generated_sim_file/QFT/quantum_circuit_data_' + str(qubit_num_idx) + '_qubits/'
        utils.create_folder(saved_folder_name)
        dst_folder = saved_folder_name + '/Design/'
        utils.create_folder(dst_folder)
        
        os.makedirs(dst_folder, exist_ok=True)
        for filename in os.listdir(src_folder):
            src_file = os.path.join(src_folder, filename)
            dst_file = os.path.join(dst_folder, filename)
            if os.path.isfile(src_file): 
                shutil.copy2(src_file, dst_file)


def create_tb(min_qbit_num, max_qbit_num, min_quantum_circuit_idx, max_quantum_circuit_idx):
    txt_file = open('../hardware/verilog/sample/TB/TB_QEA.v')
    data = txt_file.readlines()
    txt_file.close()

    quantum_circuit_idx_range = np.arange(min_quantum_circuit_idx, max_quantum_circuit_idx+1, 1)
    qubit_num_idx_range = np.arange(min_qbit_num, max_qbit_num+1, 1)

    for qubit_num_idx in qubit_num_idx_range:
        saved_folder_name = '../hardware/verilog/generated_sim_file/quantum_circuit_data_' + str(qubit_num_idx) + '_qubits/'
        utils.create_folder(saved_folder_name)
        for quantum_circuit_idx in quantum_circuit_idx_range:
            saved_sub_folder_name = saved_folder_name + 'quanvolutional_' + str(quantum_circuit_idx)
            utils.create_folder(saved_sub_folder_name)
            utils.create_folder(saved_sub_folder_name + '/TB/')
            save_file_name = saved_sub_folder_name + '/TB/' + 'TB_QEA_'+ str(qubit_num_idx) + '_qubits' + '_quanvolutional_' + str(quantum_circuit_idx) + '.v'
            tb_verilog = open(save_file_name, mode='w')

            hex_file = utils.read_file('../hardware/gate_ctx_for_sim/quantum_circuit_data_' + str(qubit_num_idx) + '_qubits/' + 'output_hex_' + str(qubit_num_idx) + '_qubits' + '_quanvolutional_' + str(quantum_circuit_idx) + '.txt')


            for row in range(len(data)):
                if(row == 2):
                    tb_verilog.write('module TB_QEA_' + str(qubit_num_idx) + '_qubits' + '_quanvolutional_' + str(quantum_circuit_idx) + ';\n')
                elif(row == 18):
                    tb_verilog.write('    parameter CTX_LINK = ' + '"..\\\\hardware\\\\gate_ctx_for_sim\\\\quantum_circuit_data_' + str(qubit_num_idx) + '_qubits\\\\' + 'output_hex_'+ str(qubit_num_idx) + '_qubits' + '_quanvolutional_' + str(quantum_circuit_idx) + '.txt";\n')
                elif(row == 42):
                    tb_verilog.write('    integer ins_num = ' + str(len(hex_file)) + ';\n')
                elif(row == 50):
                    tb_verilog.write('        file_time_check = $fopen("' + '..\\\\hardware\\\\verilog\\\\generated_sim_file\\\\quantum_circuit_data_' + str(qubit_num_idx) + '_qubits\\\\' + 'quanvolutional_' + str(quantum_circuit_idx) + '\\\\timestamps_' + str(qubit_num_idx) + '_qubits' + '_quanvolutional_' + str(quantum_circuit_idx) + '.txt", "w");\n')
                elif(row == 58):
                    tb_verilog.write('            i_qbit_num    <= ' + str(qubit_num_idx) + ';\n')
                else:
                    tb_verilog.write(data[row])

            tb_verilog.close()


def create_tb_qft(min_qbit_num, max_qbit_num):
    txt_file = open('../hardware/verilog/sample/TB/TB_QEA.v')
    data = txt_file.readlines()
    txt_file.close()

    qubit_num_idx_range = np.arange(min_qbit_num, max_qbit_num+1, 1)

    utils.create_folder('../hardware/verilog/generated_sim_file/QFT')

    for qubit_num_idx in qubit_num_idx_range:
        saved_folder_name = '../hardware/verilog/generated_sim_file/QFT/quantum_circuit_data_' + str(qubit_num_idx) + '_qubits/'
        utils.create_folder(saved_folder_name)
        saved_sub_folder_name = saved_folder_name + 'TB/'
        utils.create_folder(saved_sub_folder_name)
        save_file_name = saved_sub_folder_name + 'TB_QEA_QFT_'+ str(qubit_num_idx) + '_qubits.v'
        tb_verilog = open(save_file_name, mode='w')

        hex_file = utils.read_file('../hardware/gate_ctx_for_sim/QFT/quantum_circuit_data_' + str(qubit_num_idx) + '_qubits/' + 'output_hex_QFT_' + str(qubit_num_idx) + '_qubits.txt')

        for row in range(len(data)):
            if(row == 2):
                tb_verilog.write('module TB_QEA_QFT_' + str(qubit_num_idx) + '_qubits;\n')
            elif(row == 18):
                tb_verilog.write('    parameter CTX_LINK = ' + '"..\\\\hardware\\\\gate_ctx_for_sim\\\\QFT\\\\quantum_circuit_data_' + str(qubit_num_idx) + '_qubits\\\\' + 'output_hex_QFT_'+ str(qubit_num_idx) + '_qubits.txt";\n')
            elif(row == 42):
                tb_verilog.write('    integer ins_num = ' + str(len(hex_file)) + ';\n')
            elif(row == 50):
                tb_verilog.write('        file_time_check = $fopen("' + '..\\\\hardware\\\\verilog\\\\generated_sim_file\\\\QFT\\\\quantum_circuit_data_' + str(qubit_num_idx) + '_qubits\\\\' + 'timestamps_qft' + str(qubit_num_idx) + '_qubits.txt", "w");\n')
            elif(row == 58):
                tb_verilog.write('            i_qbit_num    <= ' + str(qubit_num_idx) + ';\n')
            else:
                tb_verilog.write(data[row])

        tb_verilog.close()


def hardware_python_sim(design_folder="", tb_folder=""):
    # Set Vivado path (update this to your installation path if needed)
    vivado_bin = r"C:\Xilinx\Vivado\2020.2\bin"

    # Add to PATH temporarily
    os.environ["PATH"] += os.pathsep + vivado_bin

    # List all design files
    design_files = [f for f in os.listdir(design_folder)]
    sim_file = [f for f in os.listdir(tb_folder)][0]

    # Clean previous simulation directory
    if os.path.exists("xsim.dir"):
        shutil.rmtree("xsim.dir")

    # Compile all design files
    for file in design_files:
        cmd = f"xvlog -work work {os.path.join(design_folder, file)}"
        print(f"Running: {cmd}")
        os.system(cmd)

    # Compile the testbench
    tb_file = os.path.join(tb_folder, sim_file)
    os.system(f"xvlog -work work {tb_file}")

    # Elaborate
    command = "xelab work." + sim_file.replace(".v", "") + " -snapshot tb_snapshot"
    os.system(command)

    # Run simulation immediately without interactive mode (-R)
    os.system("xsim tb_snapshot -R")

def hardware_python_sim_all(min_qbit_num, max_qbit_num, min_quantum_circuit_idx, max_quantum_circuit_idx):
    
    txt_file = open('../hardware/verilog/sample/TB/TB_QEA.v')
    data = txt_file.readlines()
    txt_file.close()

    quantum_circuit_idx_range = np.arange(min_quantum_circuit_idx, max_quantum_circuit_idx+1, 1)
    qubit_num_idx_range = np.arange(min_qbit_num, max_qbit_num+1, 1)

    results = []
    for qubit_num_idx in qubit_num_idx_range:
        saved_folder_name = '../hardware/verilog/generated_sim_file/quantum_circuit_data_' + str(qubit_num_idx) + '_qubits/'
        for quantum_circuit_idx in quantum_circuit_idx_range:
            saved_sub_folder_name = saved_folder_name + 'quanvolutional_' + str(quantum_circuit_idx)

            design_folder = saved_sub_folder_name + '/Design/'
            tb_folder = saved_sub_folder_name + '/TB/'

            hardware_python_sim(design_folder=design_folder, tb_folder=tb_folder)

            data = utils.read_file(saved_sub_folder_name + '/timestamps_' + str(qubit_num_idx) + '_qubits' + '_quanvolutional_' + str(quantum_circuit_idx) + '.txt')
            res = str(qubit_num_idx) + '_qubits' + '_quanvolutional_' + str(quantum_circuit_idx) + ": " + data[2].strip("").split(' ')[3] + " ns"

            results.append(res)

    utils.write_file('results.txt', results)


def aggregate_results(min_qbit_num, max_qbit_num, min_quantum_circuit_idx, max_quantum_circuit_idx):
    quantum_circuit_idx_range = np.arange(min_quantum_circuit_idx, max_quantum_circuit_idx+1, 1)
    qubit_num_idx_range = np.arange(min_qbit_num, max_qbit_num+1, 1)

    hard_results = []
    soft_results = []
    final_results = []
    for qubit_num_idx in qubit_num_idx_range:
        saved_folder_name_hard = '../hardware/verilog/generated_sim_file/quantum_circuit_data_' + str(qubit_num_idx) + '_qubits/'
        for quantum_circuit_idx in quantum_circuit_idx_range:
            saved_sub_folder_name_hard = saved_folder_name_hard + 'quanvolutional_' + str(quantum_circuit_idx)

            hard_data = utils.read_file(saved_sub_folder_name_hard + '/timestamps_' + str(qubit_num_idx) + '_qubits' + '_quanvolutional_' + str(quantum_circuit_idx) + '.txt')
            hard_res = float(hard_data[2].strip("").split(' ')[3][:-3])/1000000000
            res = str(qubit_num_idx) + '_qubits' + '_quanvolutional_' + str(quantum_circuit_idx) + ": " + str(hard_res) + " s"
            hard_results.append(res)

            soft_file_name = "../result/quanv/quanv" + str(quantum_circuit_idx) + ".txt"
            soft_data = utils.read_file(soft_file_name)
            soft_res = float(soft_data[qubit_num_idx-3])
            res = str(qubit_num_idx) + '_qubits' + '_quanvolutional_' + str(quantum_circuit_idx) + ": " + str(soft_res) + " s"
            soft_results.append(res)

            print(f"====================== {qubit_num_idx} qbits, quanv{quantum_circuit_idx} circuit ======================")
            print(f"Hardware Result: {hard_res} (s) | Software Result: {soft_res} (s) | Compare: {soft_res/hard_res}")
            final_results.append(f"====================== {qubit_num_idx} qbits, quanv{quantum_circuit_idx} circuit ======================")
            final_results.append(f"Hardware Result: {hard_res} (s) | Software Result: {soft_res} (s) | Compare: {soft_res/hard_res}")

    utils.write_file('hard_results.txt', hard_results)
    utils.write_file('soft_results.txt', soft_results)
    utils.write_file('final_results.txt', final_results)


def hardware_python_sim_all_new(min_qbit_num=3, max_qbit_num=17, min_quantum_circuit_idx=1, max_quantum_circuit_idx=19):
    # Set Vivado path (update this to your installation path if needed)
    vivado_bin = r"C:\Xilinx\Vivado\2020.2\bin"

    # Add to PATH temporarily
    os.environ["PATH"] += os.pathsep + vivado_bin

    # List all design files
    design_folder = "../hardware/verilog/sample/Design/"
    design_files = [f for f in os.listdir(design_folder)]
    
    # Compile all design files first (only need to do this once)
    print("\n========================> Compiling Design Files <========================")
    for file in design_files:
        cmd = f"xvlog -work work {os.path.join(design_folder, file)}"
        print(f"Running: {cmd}")
        os.system(cmd)

    quantum_circuit_idx_range = np.arange(min_quantum_circuit_idx, max_quantum_circuit_idx+1, 1)
    qubit_num_idx_range = np.arange(min_qbit_num, max_qbit_num+1, 1)
    
    # Process each testbench file consecutively
    start_time = time.time()
    for qubit_num_idx in qubit_num_idx_range:
        saved_folder_name = '../hardware/verilog/generated_sim_file/quantum_circuit_data_' + str(qubit_num_idx) + '_qubits/'
        for quantum_circuit_idx in quantum_circuit_idx_range:
            pre_time = time.time()
            tb_folder = saved_folder_name + 'quanvolutional_' + str(quantum_circuit_idx) + '/TB/'
            tb_file_name = 'TB_QEA_'+ str(qubit_num_idx) + '_qubits' + '_quanvolutional_' + str(quantum_circuit_idx) + '.v'

            print(f"\n========================> Start simulation for: {tb_file_name} <========================")

            # # Clean previous simulation directory for this testbench
            # if os.path.exists("xsim.dir"):
            #     shutil.rmtree("xsim.dir")
            
            # Compile the testbench
            tb_file_path = os.path.join(tb_folder, tb_file_name)
            compile_cmd = f"xvlog -work work {tb_file_path}"
            print(f"\n=>>>>>>>>>>>>> Compiling testbench: {compile_cmd}")
            os.system(compile_cmd)
            
            # Extract testbench module name (removing .v extension)
            tb_module = tb_file_name.replace(".v", "")
            
            # Elaborate with a unique snapshot name for this testbench
            snapshot_name = f"tb_snapshot_{tb_module}"
            elab_cmd = f"xelab work.{tb_module} -snapshot {snapshot_name}"
            print(f"\n=>>>>>>>>>>>>> Elaborating: {elab_cmd}")
            os.system(elab_cmd)
            
            # Run simulation
            sim_cmd = f"xsim {snapshot_name} -R"
            print(f"\n=>>>>>>>>>>>>> Simulating: {sim_cmd}")
            os.system(sim_cmd)

            delta_time = (time.time() - pre_time)
            print('Time to process: ', delta_time, 's\n')
            print(f"========================> Finished simulation for: {tb_file_name} <========================\n")

    sum_time = (time.time() - start_time)
    print('Time to process all test times: ', sum_time, 's')
    print("====================================> Finished all simulations <====================================")


def hardware_python_sim_all_new_qft(min_qbit_num=3, max_qbit_num=17):
    # Set Vivado path (update this to your installation path if needed)
    vivado_bin = r"C:\Xilinx\Vivado\2020.2\bin"

    # Add to PATH temporarily
    os.environ["PATH"] += os.pathsep + vivado_bin

    # List all design files
    design_folder = "../hardware/verilog/sample/Design/"
    design_files = [f for f in os.listdir(design_folder)]
    
    # Compile all design files first (only need to do this once)
    print("\n========================> Compiling Design Files <========================")
    for file in design_files:
        cmd = f"xvlog -work work {os.path.join(design_folder, file)}"
        print(f"Running: {cmd}")
        os.system(cmd)

    qubit_num_idx_range = np.arange(min_qbit_num, max_qbit_num+1, 1)
    
    # Process each testbench file consecutively
    start_time = time.time()
    for qubit_num_idx in qubit_num_idx_range:
        saved_folder_name = '../hardware/verilog/generated_sim_file/QFT/quantum_circuit_data_' + str(qubit_num_idx) + '_qubits'
        pre_time = time.time()
        tb_folder = saved_folder_name + '/TB/'
        tb_file_name = 'TB_QEA_QFT_'+ str(qubit_num_idx) + '_qubits.v'

        print(f"\n========================> Start simulation for: {tb_file_name} <========================")

        # # Clean previous simulation directory for this testbench
        # if os.path.exists("xsim.dir"):
        #     shutil.rmtree("xsim.dir")
        
        # Compile the testbench
        tb_file_path = tb_folder + tb_file_name
        compile_cmd = f"xvlog -work work {tb_file_path}"
        print(f"\n=>>>>>>>>>>>>> Compiling testbench: {compile_cmd}")
        os.system(compile_cmd)
        
        # Extract testbench module name (removing .v extension)
        tb_module = tb_file_name.replace(".v", "")
        
        # Elaborate with a unique snapshot name for this testbench
        snapshot_name = f"tb_snapshot_{tb_module}"
        elab_cmd = f"xelab work.{tb_module} -snapshot {snapshot_name}"
        print(f"\n=>>>>>>>>>>>>> Elaborating: {elab_cmd}")
        os.system(elab_cmd)
        
        # Run simulation
        sim_cmd = f"xsim {snapshot_name} -R"
        print(f"\n=>>>>>>>>>>>>> Simulating: {sim_cmd}")
        os.system(sim_cmd)

        delta_time = (time.time() - pre_time)
        print('Time to process: ', delta_time, 's\n')
        print(f"========================> Finished simulation for: {tb_file_name} <========================\n")

    sum_time = (time.time() - start_time)
    print('Time to process all test times: ', sum_time, 's')
    print("====================================> Finished all simulations <====================================")


def create_tb_new(min_qbit_num, max_qbit_num, min_quantum_circuit_idx, max_quantum_circuit_idx):
    txt_file = open('../hardware/verilog/sample/TB/TB_QEA.v')
    data = txt_file.readlines()
    txt_file.close()

    quantum_circuit_idx_range = np.arange(min_quantum_circuit_idx, max_quantum_circuit_idx+1, 1)
    qubit_num_idx_range = np.arange(min_qbit_num, max_qbit_num+1, 1)

    for qubit_num_idx in qubit_num_idx_range:
        saved_folder_name = '../hardware/verilog/check/TB/'
        utils.create_folder(saved_folder_name)
        for quantum_circuit_idx in quantum_circuit_idx_range:
            save_file_name = saved_folder_name + 'TB_QEA_'+ str(qubit_num_idx) + '_qubits' + '_quanvolutional_' + str(quantum_circuit_idx) + '.v'
            tb_verilog = open(save_file_name, mode='w')

            hex_file = utils.read_file('../hardware/gate_ctx_for_sim/quantum_circuit_data_' + str(qubit_num_idx) + '_qubits/' + 'output_hex_' + str(qubit_num_idx) + '_qubits' + '_quanvolutional_' + str(quantum_circuit_idx) + '.txt')


            for row in range(len(data)):
                if(row == 2):
                    tb_verilog.write('module TB_QEA_' + str(qubit_num_idx) + '_qubits' + '_quanvolutional_' + str(quantum_circuit_idx) + ';\n')
                elif(row == 18):
                    tb_verilog.write('    parameter CTX_LINK = ' + '"..\\\\hardware\\\\gate_ctx_for_sim\\\\quantum_circuit_data_' + str(qubit_num_idx) + '_qubits\\\\' + 'output_hex_'+ str(qubit_num_idx) + '_qubits' + '_quanvolutional_' + str(quantum_circuit_idx) + '.txt";\n')
                elif(row == 42):
                    tb_verilog.write('    integer ins_num = ' + str(len(hex_file)) + ';\n')
                elif(row == 50):
                    tb_verilog.write('        file_time_check = $fopen("' + '..\\\\hardware\\\\verilog\\\\generated_sim_file\\\\quantum_circuit_data_' + str(qubit_num_idx) + '_qubits\\\\' + 'quanvolutional_' + str(quantum_circuit_idx) + '\\\\timestamps_' + str(qubit_num_idx) + '_qubits' + '_quanvolutional_' + str(quantum_circuit_idx) + '.txt", "w");\n')
                elif(row == 58):
                    tb_verilog.write('            i_qbit_num    <= ' + str(qubit_num_idx) + ';\n')
                else:
                    tb_verilog.write(data[row])

            tb_verilog.close()
    # for sim_file in os.listdir(tb_folder):
    #     if not sim_file.endswith(".v"):
    #         continue  # Skip non-Verilog files

    #     tb_file = os.path.join(tb_folder, sim_file)

    #     # Compile the testbench file
    #     os.system(f"xvlog -work work {tb_file}")

    #     # Extract testbench module name (filename without extension)
    #     tb_module_name = sim_file.replace(".v", "")

    #     # Elaborate for this testbench
    #     command = f"xelab work.{tb_module_name} -snapshot {tb_module_name}_snapshot"
    #     os.system(command)

    #     # Run simulation for this testbench immediately without interactive mode (-R)
    #     os.system(f"xsim {tb_module_name}_snapshot -R")

    #     print(f"========================> Finished simulation for: {sim_file} <========================")