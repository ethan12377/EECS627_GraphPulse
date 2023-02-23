import io_port
import numpy as np
from coalescing_unit import CU
from queue_scheduler import QS

io_port.init()
CU0 = CU()
QS0 = QS()

def print_CU():     
    
    print(f"CUreg[0]: CUregValid |CUDeltareg    |CUIdxreg")
    print(f"|         {CU0.CUregValid[0][0]}  |{CU0.CUDeltareg[0][0]}   |{CU0.CUIdxreg[0][0]} ")
    print(f"CUreg[1]: CUregValid |CUDeltareg ")
    print(f"|         {CU0.CUregValid[0][1]}  |{CU0.CUDeltareg[0][1]}   |{CU0.CUIdxreg[0][1]} ")
    print(f"CUreg[2]: CUregValid |CUDeltareg ")
    print(f"|         {CU0.CUregValid[0][2]}  |{CU0.CUDeltareg[0][2]}   |{CU0.CUIdxreg[0][2]} ")
        
    

    print('\n')
    print("CU_in_buf: delta, idx, valid")
    print(CU0.CU_in_buf[0])

    print('\n')

    
    print(f'input:')
    print(f"|io_port.CUDelta |io_port.CUIdx |io_port.CUValid")
    print(f"|{io_port.CUDelta[0]}  |{io_port.CUIdx[0]}   |{io_port.CUValid[0]}")
   
    print(f'output:')
    print(f"CUReady_n[0] = ", io_port.CUReady_n[0])
    print(f"cuclean_n= ", io_port.cuclean_n)
    print(f"searchIdx_n[0] |searchValid_n[0]   ")
    print(f"{io_port.searchIdx_n[0]}    |{io_port.searchValid_n[0]}")
    print(f"newDelta_n[0] |newIdx_n[0] |newValid_n[0]  ")
    print(f"{io_port.newDelta_n[0]} |{io_port.newIdx_n[0]}  |{io_port.newValid_n[0]}")
    

def print_qs():
    print("io_port.rowDelta_n: ", io_port.rowDelta_n)
    print("io_port.binrowIdx_n: ", io_port.binrowIdx_n)
    print("rowValid_n: ",io_port.rowValid_n)
    print("Queue1: ")
    print(QS0.queue)
    print("rowValid_matrix1: ")
    print(QS0.rowValid_matrix)
    print("reading_bin_n = ", QS0.reading_bin_n)
    print("readen_n = ", QS0.readen_n)

    print("initialFinish: ", io_port.initialFinish)
    print("qs_state_n: ", QS0.qs_state_n)
    print("binValid_n", QS0.binValid_n)
    print("queue_empty_n: ", io_port.queue_empty_n)
    print("binselected_n:", io_port.binselected_n)

def next_state_copy():
    io_port.binselected = np.copy(io_port.binselected_n)
    io_port.queue_empty = np.copy(io_port.queue_empty_n)

    io_port.searchValueValid = np.copy(io_port.searchValueValid_n)
    io_port.searchValue = np.copy(io_port.searchValue_n)
    io_port.searchIdx = np.copy(io_port.searchIdx_n) 
    io_port.searchValid = np.copy(io_port.searchValid_n) 

    io_port.newDelta = np.copy(io_port.newDelta_n)
    io_port.newIdx = np.copy(io_port.newIdx_n)
    io_port.newValid = np.copy(io_port.newValid_n)

    io_port.cuclean = np.copy(io_port.cuclean_n) 
    io_port.CUReady = np.copy(io_port.CUReady_n) 



print("Initial: ")
next_state_copy()
io_port.initialFinish = 0

io_port.CUDelta = np.array([1, 1, 1, 1, 1, 1, 1, 1])
io_port.CUIdx = np.array([0, 37, 74, 111, 147, 182, 217, 252])
io_port.CUValid = np.zeros(8)

io_port.rowReady = 1
print('\n')
print("-------------------------------------------------------------")
print("Cycle0:")
QS0.one_clock()
CU0.one_clock()
print_qs()
print_CU()
print("-------------------------------------------------------------")
print('\n')
io_port.initialFinish = 0
next_state_copy()

io_port.rowReady = 1
io_port.CUDelta = np.array([2, 2, 2, 2, 2, 2, 2, 2])
io_port.CUIdx = np.array([0, 37, 74, 111, 147, 182, 217, 252])
io_port.CUValid = np.ones(8)
print('\n')
print("-------------------------------------------------------------")
print("Cycle1:")
QS0.one_clock()
CU0.one_clock()
print_qs()
print_CU()
print("-------------------------------------------------------------")
print('\n')

print("initial finished")
io_port.initialFinish = 1
next_state_copy()

io_port.rowReady = 1
io_port.CUDelta = np.array([3, 3, 3, 3, 3, 3, 3, 3])
io_port.CUIdx = np.array([0, 37, 74, 111, 147, 182, 217, 252])
io_port.CUValid = np.ones(8)
print('\n')
print("-------------------------------------------------------------")
print("Cycle2:")
QS0.one_clock()
CU0.one_clock()
print_qs()
print_CU()
print("-------------------------------------------------------------")
print('\n')
io_port.initialFinish = 1
next_state_copy()

io_port.rowReady = 1
io_port.CUDelta = np.array([4, 4, 4, 4, 4, 4, 4, 4])
io_port.CUIdx = np.array([0, 37, 74, 111, 147, 182, 217, 252])
io_port.CUValid = np.ones(8)

print('\n')
print("-------------------------------------------------------------")
print("Cycle3:")
QS0.one_clock()
CU0.one_clock()
print_qs()
print_CU()
print("-------------------------------------------------------------")
print('\n')
io_port.initialFinish = 1
next_state_copy()

io_port.rowReady = 1
io_port.CUDelta = np.array([5, 5, 5, 5, 5, 5, 5, 5])
io_port.CUIdx = np.array([0, 37, 74, 111, 147, 182, 217, 252])
io_port.CUValid = np.ones(8)
print('\n')
print("-------------------------------------------------------------")
print("Cycle4:")
QS0.one_clock()
CU0.one_clock()
print_qs()
print_CU()
print("-------------------------------------------------------------")
print('\n')
io_port.initialFinish = 1
next_state_copy()

io_port.rowReady = 1
io_port.CUDelta = np.array([6, 6, 6, 6, 6, 6, 6, 6])
io_port.CUIdx = np.array([0, 37, 74, 111, 147, 182, 217, 252])
io_port.CUValid = np.ones(8)
print('\n')
print("-------------------------------------------------------------")
print("Cycle5:")
QS0.one_clock()
CU0.one_clock()
print_qs()
print_CU()
print("-------------------------------------------------------------")
print('\n')

io_port.initialFinish = 1
next_state_copy()

io_port.rowReady = 1
io_port.CUDelta = np.array([7, 7, 7, 7, 7, 7, 7, 7])
io_port.CUIdx = np.array([0, 37, 74, 111, 147, 182, 217, 252])
io_port.CUValid = np.ones(8)
print('\n')
print("-------------------------------------------------------------")
print("Cycle6:")
QS0.one_clock()
CU0.one_clock()
print_qs()
print_CU()
print("-------------------------------------------------------------")
print('\n')

io_port.initialFinish = 1
next_state_copy()

io_port.rowReady = 1
io_port.CUDelta = np.array([8, 8, 8, 8, 8, 8, 8, 8])
io_port.CUIdx = np.array([0, 37, 74, 111, 147, 182, 217, 252])
io_port.CUValid = np.ones(8)
print('\n')
print("-------------------------------------------------------------")
print("Cycle7:")
QS0.one_clock()
CU0.one_clock()
print_qs()
print_CU()
print("-------------------------------------------------------------")
print('\n')


