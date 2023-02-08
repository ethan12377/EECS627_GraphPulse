import numpy as np
import io_port
from crossbar import Xbar_SchedToPE, Xbar_PEToQ


def OB_input():
    for i in range(4):
        io_port.IssDelta_n[i] = np.random.rand()
        

def PE_input():
    pass

def Xbar_SchedToPE_update():
    # OB
    io_port.IssDelta = io_port.IssDelta_n
    io_port.IssIdx = io_port.IssIdx_n
    io_port.IssValid = io_port.IssValid_n
    # Xbar_SchedToPE
    io_port.IssReady = io_port.IssReady_n
    io_port.PEDelta = io_port.PEDelta_n
    io_port.PEIdx = io_port.PEIdx_n
    io_port.PEValid = io_port.PEValid_n
    # PE
    io_port.PEReady = io_port.PEReady_n
    # # Xbar_PEToQ
    # io_port.proReady = io_port.proReady_n
    # io_port.CUDelta = io_port.CUDelta_n
    # io_port.CUIdx = io_port.CUIdx_n
    # io_port.CUValid = io_port.CUValid_n
    
if __name__ == "__main__":
    io_port.init()
    Xbar0 = Xbar_SchedToPE()
    # Xbar1 = Xbar_PEToQ()
    
    for i in range(100):
        print("[Clock", i, "]")
        Xbar0.one_clock()
        # Xbar1.one_clock()
        
        Xbar_SchedToPE_update()