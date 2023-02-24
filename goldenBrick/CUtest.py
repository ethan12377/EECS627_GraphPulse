import io_port
import numpy as np
from coalescing_unit import CU

io_port.init()
CU0 = CU()

def print_CU():     
    print(f"CUreg[0]: CUregValid |CUIdxreg |CUDeltareg |CUregtag       ")
    print(f"|       {CU0.CUregValid[0][0]}  |{CU0.CUIdxreg[0][0]}   |{CU0.CUDeltareg[0][0]} |{CU0.CUregtag[0][0]}")
    print(f"CUreg[1]: CUregValid |CUIdxreg |CUDeltareg |CUregtag       ")
    print(f"|       {CU0.CUregValid[0][1]}  |{CU0.CUIdxreg[0][1]}   |{CU0.CUDeltareg[0][1]} |{CU0.CUregtag[0][1]}")
    print("CU_in_buf: delta, idx, valid")
    print(f"CUreg[2]: CUregValid |CUIdxreg |CUDeltareg |CUregtag       ")
    print(f"|       {CU0.CUregValid[0][2]}  |{CU0.CUIdxreg[0][2]}   |{CU0.CUDeltareg[0][2]} |{CU0.CUregtag[0][2]}")
    
    print('\n')
    print("CU_in_buf: delta, idx, valid")
    print(CU0.CU_in_buf[0])
    print("CU_out_buf: delta, idx, valid")
    print(CU0.CU_out_buf[0])
    print('\n')
    
    print(f'input:')
    print(f"|io_port.CUDelta |io_port.CUIdx |io_port.CUValid")
    print(f"|{io_port.CUDelta[0]}  |{io_port.CUIdx[0]}   |{io_port.CUValid[0]}")
   
    print(f'output:')
    print("CUReady_n[0] = ", io_port.CUReady_n[0])
    print(f"searchIdx_n[0] |searchValid_n[0]   ")
    print(f"{io_port.searchIdx_n[0]}    |{io_port.searchValid_n[0]}")
    print(f"newDelta_n[0] |newIdx_n[0] |newValid_n[0]  ")
    print(f"{io_port.newDelta_n[0]} |{io_port.newIdx_n[0]}  |{io_port.newValid_n[0]}", )
    print("cuclean_n[0] = ", io_port.cuclean_n[0])



io_port.initialFinish = 0
io_port.searchValid = io_port.searchValid_n
io_port.CUDelta = np.array([1, 1, 1, 1, 1, 1, 1, 1])
io_port.CUIdx = np.array([0, 37, 74, 111, 147, 182, 217, 252])
io_port.CUValid = np.zeros(8)
io_port.state = np.array([0, 0, 0, 0, 0, 0, 0, 0])
print("-------------------------------------------------------------")
print("Cycle0:")
CU0.one_clock()
print_CU()
print("-------------------------------------------------------------")

io_port.cuclean = np.copy(io_port.cuclean_n)
io_port.initialFinish = 0
io_port.searchValid = io_port.searchValid_n
io_port.CUDelta = np.array([2, 2, 2, 2, 2, 2, 2, 2])
io_port.CUIdx = np.array([0, 37, 74, 111, 147, 182, 217, 252])
io_port.CUValid = np.ones(8)
io_port.state = np.array([0, 0, 0, 0, 0, 0, 0, 0])
print("-------------------------------------------------------------")
print("Cycle1:")
CU0.one_clock()
print_CU()
print("-------------------------------------------------------------")

# initial finished
io_port.cuclean = np.copy(io_port.cuclean_n)
io_port.initialFinish = 1
io_port.searchValid = io_port.searchValid_n
io_port.CUDelta = np.array([3, 3, 3, 3, 3, 3, 3, 3])
io_port.CUIdx = np.array([0, 37, 74, 111, 147, 182, 217, 252])
io_port.CUValid = np.ones(8)
io_port.state = np.array([0, 0, 0, 0, 0, 0, 0, 0])
print("-------------------------------------------------------------")
print("Cycle2:")
CU0.one_clock()
print_CU()
print("-------------------------------------------------------------")

io_port.cuclean = np.copy(io_port.cuclean_n)
io_port.initialFinish = 1
io_port.searchValid = io_port.searchValid_n
io_port.CUDelta = np.array([4, 4, 4, 4, 4, 4, 4, 4])
io_port.CUIdx = np.array([0, 37, 74, 111, 147, 182, 217, 252])
io_port.CUValid = np.ones(8)
io_port.state = np.array([3, 1, 1, 1, 1, 1, 1, 1])
print("-------------------------------------------------------------")
print("Cycle3:")
CU0.one_clock()
print_CU()
print("-------------------------------------------------------------")

io_port.cuclean = np.copy(io_port.cuclean_n)
io_port.initialFinish = 1
io_port.CUDelta = np.array([5, 5, 5, 5, 5, 5, 5, 5])
io_port.CUIdx = np.array([0, 37, 74, 111, 147, 182, 217, 252])
io_port.CUValid = np.ones(8)
io_port.state = np.array([3, 1, 1, 1, 1, 1, 1, 1])
print("-------------------------------------------------------------")
print("Cycle4:")
CU0.one_clock()
print_CU()
print("-------------------------------------------------------------")

io_port.cuclean = np.copy(io_port.cuclean_n)
io_port.initialFinish = 1
io_port.searchValid = io_port.searchValid_n
io_port.CUDelta = np.array([6, 6, 6, 6, 6, 6, 6, 6])
io_port.CUIdx = np.array([0, 37, 74, 111, 147, 182, 217, 252])
io_port.CUValid = np.ones(8)
io_port.state = np.array([3, 1, 1, 1, 1, 1, 1, 1])
# io_port.searchValue = np.array([2, 2, 2, 2, 2, 2, 2, 2])
# io_port.searchValueValid = np.array([1, 1, 1, 1, 1, 1, 1, 1])
print("-------------------------------------------------------------")
print("Cycle5:")
CU0.one_clock()
print_CU()
print("-------------------------------------------------------------")

io_port.cuclean = np.copy(io_port.cuclean_n)
io_port.initialFinish = 1
io_port.searchValid = io_port.searchValid_n
io_port.CUDelta = np.array([7, 7, 7, 7, 7, 7, 7, 7])
io_port.CUIdx = np.array([0, 37, 74, 111, 147, 182, 217, 252])
io_port.CUValid = np.ones(8)
io_port.state = np.array([3, 2, 1, 1, 1, 1, 1, 1])
io_port.searchValue = np.array([100, 2, 2, 2, 2, 2, 2, 2])
io_port.searchValueValid = np.ones(8)
print("-------------------------------------------------------------")
print("Cycle6:")
CU0.one_clock()
print_CU()
print("-------------------------------------------------------------")


io_port.cuclean = np.copy(io_port.cuclean_n)
io_port.initialFinish = 1
io_port.searchValid = io_port.searchValid_n
io_port.CUDelta = np.array([8, 8, 8, 8, 8, 8, 8, 8])
io_port.CUIdx = np.array([0, 37, 74, 111, 147, 182, 217, 252])
io_port.CUValid = np.ones(8)
io_port.state = np.array([3, 2, 1, 1, 1, 1, 1, 1])

print("-------------------------------------------------------------")
print("Cycle7:")
CU0.one_clock()
print_CU()
print("-------------------------------------------------------------")



