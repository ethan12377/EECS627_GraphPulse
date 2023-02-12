import copy
import numpy as np
import io_port
from crossbar import Xbar_PEToQ

CU_timer = np.zeros(8)
CU_timer_n = np.zeros(8)

def PE_input():
    for i in range(8):
        if io_port.proValid[i] == 1:
            if io_port.proReady[i] == 1:
                io_port.proValid_n[i] = np.uint8(np.random.randint(2))
                if io_port.proValid_n[i] == 1:
                    io_port.proDelta_n[i] = np.random.rand()
                    io_port.proIdx_n[i]   = np.uint8(np.random.randint(256))
                else:
                    io_port.proDelta_n[i] = np.float16(0)
                    io_port.proIdx_n[i]   = np.uint8(0)
            else:
                io_port.proDelta_n[i] = io_port.proDelta[i]
                io_port.proIdx_n[i]   = io_port.proIdx[i]  
                io_port.proValid_n[i] = io_port.proValid[i]
        else:
            io_port.proValid_n[i] = np.uint8(np.random.randint(2))
            if io_port.proValid_n[i] == 1:
                io_port.proDelta_n[i] = np.random.rand()
                io_port.proIdx_n[i]   = np.uint8(np.random.randint(256))
            else:
                io_port.proDelta_n[i] = np.float16(0)
                io_port.proIdx_n[i]   = np.uint8(0)
                    
def CU_input():
    for i in range(8):
        print('CUDelta[', i, '] = ', np.around(io_port.CUDelta[i], 3), '\tCUIdx[', i, '] = ', io_port.CUIdx[i], '\tCUValid[', i, '] = ', io_port.CUValid[i], '\tCUReady[', i, '] = ', io_port.CUReady[i])
    
    for i in range(8):
        if io_port.CUReady[i] == np.int8(0):
            if CU_timer[i] < (2 + np.random.randint(4)):
                CU_timer_n[i] = CU_timer[i] + 1
            else:
                CU_timer_n[i] = 0
                io_port.CUReady_n[i] = np.int8(1)
        else:
            if io_port.CUValid[i] == np.int8(1):
                io_port.CUReady_n[i] = np.int8(0)
                
def update():
    # Xbar_PEToQ
    io_port.CUDelta = copy.deepcopy(io_port.CUDelta_n)
    io_port.CUIdx = copy.deepcopy(io_port.CUIdx_n)
    io_port.CUValid = copy.deepcopy(io_port.CUValid_n)
    io_port.proReady = copy.deepcopy(io_port.proReady_n)
    # PE
    io_port.proDelta = copy.deepcopy(io_port.proDelta_n)
    io_port.proIdx = copy.deepcopy(io_port.proIdx_n)
    io_port.proValid = copy.deepcopy(io_port.proValid_n)
    # CU
    io_port.CUReady = copy.deepcopy(io_port.CUReady_n)
    
if __name__ == "__main__":
    io_port.init()
    Xbar1 = Xbar_PEToQ()
    
    for i in range(10):
        print("[Clock", i, "]")
        PE_input()
        Xbar1.one_clock()
        CU_input()
        
        update()
        Xbar1.update()
        CU_timer = copy.deepcopy(CU_timer_n)
        