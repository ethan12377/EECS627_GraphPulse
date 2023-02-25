import copy
import numpy as np
import io_port
from crossbar import Xbar_SchedToPE

PE_timer = np.zeros(4)
PE_timer_n = np.zeros(4)

np.random.seed(0)

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
        print('PEDelta[0]', np.around(io_port.PEDelta[i], 3), ' PEIdx[0]', io_port.PEIdx[i], ' PEValid[0]', io_port.PEValid[i], ' PEReady[0]', io_port.PEReady[i])
    
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
    
    fd = open('Xbar_SchedToPE_ground_truth.txt', 'w')
    
    for i in range(4):
        print(f'IssDelta[{i}] IssIdx[{i}] IssValid[{i}] IssReady[{i}]', end=' ', file=fd)
    for i in range(4):
        print(f'PEDelta[{i}] PEIdx[{i}] PEValid[{i}] PEReady[{i}]', end=' ', file=fd)
    print('\n', file=fd)

    
    for i in range(200):
        print("[Clock", i, "]")
        OB_input()
        Xbar0.one_clock()
        PE_input()
        
        for j in range(4):
            print(hex(io_port.IssDelta[j].view('H'))[2:].zfill(4), hex(io_port.IssIdx[j])[2:].zfill(2), io_port.IssValid[j], io_port.IssReady[j], end=' ', file=fd)
        for j in range(4):
            print(hex(io_port.PEDelta[j].view('H'))[2:].zfill(4), hex(io_port.PEIdx[j])[2:].zfill(2), io_port.PEValid[j], io_port.PEReady[j], end=' ', file=fd)
        print('\n', file=fd)
        
        update()
        Xbar0.update()
        PE_timer = copy.deepcopy(PE_timer_n)
        