import numpy as np
import io_port
from output_buffer import OB
from crossbar import Xbar_SchedToPE
import copy

PE_timer = np.zeros(4)
PE_timer_n = np.zeros(4)

np.random.seed(0)

def QS_input():
    if io_port.rowValid == 1:
        if io_port.rowReady == 1:
            io_port.rowValid_n = np.uint8(np.random.randint(2))
            if io_port.rowValid_n == 1:
                for i in range(8):
                    set_zero = np.random.randint(10)
                    if set_zero < 3:
                        io_port.rowDelta_n[i] = 0
                    else:
                        io_port.rowDelta_n[i] = np.random.rand()
                io_port.binrowIdx_n = np.uint8(np.random.randint(32))
            else:
                io_port.rowDelta_n = np.zeros(8)
                io_port.binrowIdx_n = np.uint8(0)
    else:
        io_port.rowValid_n = np.uint8(np.random.randint(2))
        if io_port.rowValid_n == 1:
            for i in range(8):
                set_zero = np.random.randint(10)
                if set_zero < 3:
                    io_port.rowDelta_n[i] = 0
                else:
                    io_port.rowDelta_n[i] = np.random.rand()
            io_port.binrowIdx_n = np.uint8(np.random.randint(32))
        else:
            io_port.rowDelta_n = np.zeros(8)
            io_port.binrowIdx_n = np.uint8(0)

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
    # QS
    io_port.rowDelta = copy.deepcopy(io_port.rowDelta_n)
    io_port.binrowIdx = copy.deepcopy(io_port.binrowIdx_n)
    io_port.rowValid = copy.deepcopy(io_port.rowValid_n)
    # OB
    io_port.rowReady = copy.deepcopy(io_port.rowReady_n)
    # Xbar_SchedToPE
    io_port.IssReady = copy.deepcopy(io_port.IssReady_n)
    io_port.PEIdx   = copy.deepcopy(io_port.PEIdx_n)
    io_port.PEValid = copy.deepcopy(io_port.PEValid_n)
    io_port.PEDelta = copy.deepcopy(io_port.PEDelta_n)
    io_port.IssReady = copy.deepcopy(io_port.IssReady_n)
    # PE
    io_port.PEReady = copy.deepcopy(io_port.PEReady_n)
    
if __name__ == "__main__":
    fd = open('../Xbar_SchedToPE_ground_truth.txt', 'w')
    
    for i in range(4):
        print(f'IssDelta[{i}] IssIdx[{i}] IssValid[{i}] IssReady[{i}]', end=' ', file=fd)
    for i in range(4):
        print(f'PEDelta[{i}] PEIdx[{i}] PEValid[{i}] PEReady[{i}]', end=' ', file=fd)
    print('',end='\n', file=fd)
    
    io_port.init()

    OB0 = OB()
    Xbar0 = Xbar_SchedToPE()
    io_port.PEReady_n = np.ones(4, dtype=np.uint8)
    io_port.PEReady = np.ones(4, dtype=np.uint8)
    
    for i in range(200):
        print("[Clock", i, "]")

        
        QS_input()
        OB0.one_clock()
        Xbar0.one_clock()
        PE_input()

        for j in range(4):
            print(hex(io_port.IssDelta[j].view('H'))[2:].zfill(4), hex(io_port.IssIdx[j])[2:].zfill(2), io_port.IssValid[j], io_port.IssReady[j], end=' ', file=fd)
        for j in range(4):
            print(hex(io_port.PEDelta[j].view('H'))[2:].zfill(4), hex(io_port.PEIdx[j])[2:].zfill(2), io_port.PEValid[j], io_port.PEReady[j], end=' ', file=fd)
        print('',end='\n', file=fd)

        update()
        Xbar0.update()
        OB0.update()
        PE_timer = copy.deepcopy(PE_timer_n)
