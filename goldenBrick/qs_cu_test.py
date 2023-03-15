import numpy as np
import io_port
from coalescing_unit import CU
from queue_scheduler import QS
import copy

np.random.seed(0)

def Xbar_PEToQ_input():
    for i in range(8):
        io_port.CUDelta_n[i] = np.random.rand()
        io_port.CUIdx_n[i] = np.uint8(np.random.randint(4) * 64 + i * 8 + np.random.randint(8))
        io_port.CUValid_n[i] = np.uint8(np.random.randint(2))

def OB_input():
    io_port.rowReady_n = np.uint8(np.random.randint(2))

def update():
    # Xbar_PEToQ
    io_port.CUDelta = copy.deepcopy(io_port.CUDelta_n)
    io_port.CUIdx = copy.deepcopy(io_port.CUIdx_n)
    io_port.CUValid = copy.deepcopy(io_port.CUValid_n)

    # OB
    io_port.rowReady =  copy.deepcopy(io_port.rowReady_n)

    # QS
    io_port.initialFinish = copy.deepcopy(io_port.initialFinish_0)
    # io_port.initialFinish_0 = np.uint8(io_port.initialFinish_n[0] and io_port.initialFinish_n[1] and io_port.initialFinish_n[2] and io_port.initialFinish_n[3])
    io_port.rowDelta = copy.deepcopy(io_port.rowDelta_n)
    io_port.binrowIdx = copy.deepcopy(io_port.binrowIdx_n)
    io_port.rowValid = copy.deepcopy(io_port.rowValid_n)
    io_port.queue_empty = copy.deepcopy(io_port.queue_empty_n)
    io_port.binselected = copy.deepcopy(io_port.binselected_n)

    # CU
    io_port.CUReady = copy.deepcopy(io_port.CUReady_n)

    io_port.searchValueValid = np.copy(io_port.searchValueValid_n)
    io_port.searchValue = np.copy(io_port.searchValue_n)
    io_port.searchIdx = np.copy(io_port.searchIdx_n)
    io_port.searchValid = np.copy(io_port.searchValid_n)

    io_port.newDelta = np.copy(io_port.newDelta_n)
    io_port.newIdx = np.copy(io_port.newIdx_n)
    io_port.newValid = np.copy(io_port.newValid_n)

    io_port.cuclean = np.copy(io_port.cuclean_n)

if __name__ == "__main__":
    fd = open('qs_cu_ground_truth.txt', 'w')

    print(f'initialFinish', end=' ', file=fd)

    for i in range(8):
        print(f'CUDelta[{i}] CUIdx[{i}] CUValid[{i}]', end=' ', file=fd)

    print(f'rowReady', end=' ', file=fd)

    print(f'rowValid binIdx rowIdx', end=' ', file=fd)

    # for i in range(8):
    #     print(f'rowDelta[{i}]', end=' ', file=fd)
    
    for i in range(8):
        print(f'CUReady[{i}]', end=' ', file=fd)



    print('',end='\n', file=fd)

    io_port.init()
    CU0 = CU()
    QS0 = QS()

    initial = np.uint8(np.random.randint(50, 75))

    for i in range(500):
        print("[Clock", i, "]")
        
        if(i < initial):
            io_port.initialFinish_0 = np.int8(0)
        else:
            io_port.initialFinish_0 = np.int8(1)

        Xbar_PEToQ_input()
        QS0.one_clock()
        CU0.one_clock()
        OB_input()

        print(io_port.initialFinish, end=' ', file=fd)

        for j in range(8):
            print(hex(io_port.CUDelta[j].view('H'))[2:].zfill(4), hex(io_port.CUIdx[j])[2:].zfill(2), io_port.CUValid[j], end=' ', file=fd)
        
        print(io_port.rowReady, end=' ', file=fd)

        print(io_port.rowValid, np.uint8(io_port.binrowIdx / 4), np.uint8(io_port.binrowIdx % 4), end=' ', file=fd)
        
        # for j in range(8):
        #     print(hex(io_port.rowDelta[j].view('H'))[2:].zfill(4), end=' ', file=fd)

        for j in range(8):
            print(io_port.CUReady[j], end=' ', file=fd)

        # for j in range(8):
        #     print(io_port.cuclean[j], end=' ', file=fd)

        # for j in range(8):
        #     print(hex(io_port.searchIdx[j])[2:].zfill(2), io_port.searchValid[j], end=' ', file=fd)
        

        print('',end='\n', file=fd)

        update()
