import numpy as np
import io_port
from cache_controller import CC
from edge_cache import EC

def update():
    # cc
    io_port.cc_ready = io_port.cc_ready_n
    # cache
    io_port.cache_rdData = io_port.cache_rdData_n
    io_port.cacheValid = io_port.cacheValid_n

if __name__ == "__main__":

    io_port.init()
    CC0 = CC()
    EC0 = EC(csr_filename='csr.txt')

    # perform a continuous circular write
    io_port.pe_reqValid = [1, 1, 1, 1]
    io_port.pe_reqAddr = [64, 96, 64 ,96]
    io_port.pe_wrData = [0, 0, 0, 0]
    io_port.pe_wrEn = [0, 0, 0, 0]

    for i in range(0,13):
        CC0.one_clock()
        EC0.one_clock()
        update()
        print('cycle ' + str(i) + ': ')
        print('data = ' + str(io_port.cache_rdData))
        print('cc_ready = ' + str(io_port.cc_ready))