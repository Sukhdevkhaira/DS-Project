import qiskit
import ansatz
import time
import numpy as np


# Benchmark from quanvolutional1 to quanvolutional19

for i in [1,1,1,1]:
    timess = []
    for num_qubits in range(3, 4):
        function_name = f'quanvolutional{i}'
        times = []
        for t in range(0, 100):
            start = time.time()
            qc = qiskit.QuantumCircuit(num_qubits) 
            qc = getattr(ansatz, function_name)(qc)
            qc = qiskit.transpile(qc, basis_gates=['h', 's', 'cx', 'rx', 'ry', 'rz'], optimization_level=3)
            state = qiskit.quantum_info.Statevector.from_instruction(qc)
            end = time.time()
            times.append(end-start)
        timess.append(np.mean(times))
        print(np.mean(times))
    # np.savetxt(f'result/quanv/quanv{i}.txt', timess)