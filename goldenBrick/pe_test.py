import numpy as np
import io_port
from cache_controller import CC
from edge_cache import EC
from processing_element import PE

def update():
    # cc
    io_port.cc_ready = io_port.cc_ready_n
    # cache
    io_port.cache_rdData = io_port.cache_rdData_n
    io_port.cacheValid = io_port.cacheValid_n
    # pe
    io_port.PEReady = io_port.PEReady_n
    io_port.proDelta = io_port.proDelta_n
    io_port.proIdx = io_port.proIdx_n
    io_port.proValid = io_port.proValid_n
    io_port.pe_reqAddr = io_port.pe_reqAddr_n
    io_port.pe_wrData = io_port.pe_wrData_n
    io_port.pe_wrEn = io_port.pe_wrEn_n
    io_port.pe_reqValid = io_port.pe_reqValid_n

if __name__ == "__main__":

    io_port.init()
    CC0 = CC()
    EC0 = EC(csr_filename='csr.txt')
    # for now, just test single processor
    PE0 = PE(pe_id=0, fpu_pipe_depth=2)

    # TODO: create a simple graph to test on
    # TODO: send in a stimulus to start the FSM in PE

    for i in range(0,4):
        CC0.one_clock()
        EC0.one_clock()
        PE0.one_clock()
        update()