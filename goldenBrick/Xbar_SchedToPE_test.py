import copy
import numpy as np
import io_port
from crossbar import Xbar_SchedToPE

PE_timer = np.zeros(4)
PE_timer_n = np.zeros(4)

def OB_input():
    for i in range(4):
        if io_port.IssValid[i] == 1:
            if io_port.IssReady[i] == 1:
                io_port.IssValid_n[i] = np.uint8(np.random.randint(2))
                if io_port.IssValid_n[i] == 1:
                    io_port.IssDelta_n[i] = np.random.rand()
                    io_port.IssIdx_n[i]   = np.uint8(np.random.randint(256))
                else:
                    io_port.IssDelta_n[i] = np.float16(0)
                    io_port.IssIdx_n[i]   = np.uint8(0)
            else:
                io_port.IssDelta_n[i] = io_port.IssDelta[i]
                io_port.IssIdx_n[i]   = io_port.IssIdx[i]  
                io_port.IssValid_n[i] = io_port.IssValid[i]
        else:
            io_port.IssValid_n[i] = np.uint8(np.random.randint(2))
            if io_port.IssValid_n[i] == 1:
                io_port.IssDelta_n[i] = np.random.rand()
                io_port.IssIdx_n[i]   = np.uint8(np.random.randint(256))
            else:
                io_port.IssDelta_n[i] = np.float16(0)
                io_port.IssIdx_n[i]   = np.uint8(0)

def PE_input():
    for i in range(4):
        print('PEDelta[', i, '] = ', np.around(io_port.PEDelta[i], 3), '\tPEIdx[', i, '] = ', io_port.PEIdx[i], '\tPEValid[', i, '] = ', io_port.PEValid[i], '\tPEReady[', i, '] = ', io_port.PEReady[i])
    
    for i in range(4):
        if io_port.PEReady[i] == np.int8(0):
            if PE_timer[i] < (2 + np.random.randint(4)):
                PE_timer_n[i] = PE_timer[i] + 1
            else:
                PE_timer_n[i] = 0
                io_port.PEReady_n[i] = np.int8(1)
        else:
            if io_port.PEValid[i] == np.int8(1):
                io_port.PEReady_n[i] = np.int8(0)

def update():
    # OB
    io_port.IssDelta = copy.deepcopy(io_port.IssDelta_n)
    io_port.IssIdx   = copy.deepcopy(io_port.IssIdx_n)
    io_port.IssValid = copy.deepcopy(io_port.IssValid_n)
    # Xbar_SchedToPE
    io_port.PEDelta = copy.deepcopy(io_port.PEDelta_n)
    io_port.PEIdx   = copy.deepcopy(io_port.PEIdx_n)
    io_port.PEValid = copy.deepcopy(io_port.PEValid_n)
    io_port.IssReady = copy.deepcopy(io_port.IssReady_n)
    # PE
    io_port.PEReady = copy.deepcopy(io_port.PEReady_n)
    
if __name__ == "__main__":
    io_port.init()
    Xbar0 = Xbar_SchedToPE()
    
    io_port.PEReady_n = np.ones(4, dtype=np.uint8)
    io_port.PEReady = np.ones(4, dtype=np.uint8)
    
    for i in range(20):
        print("[Clock", i, "]")
        OB_input()
        Xbar0.one_clock()
        PE_input()
        
        update()
        Xbar0.update()
        PE_timer = copy.deepcopy(PE_timer_n)
        