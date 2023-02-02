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

    # perform 4 writes
    io_port.pe_reqValid = [1, 1, 1, 1]
    io_port.pe_reqAddr = [64, 65, 96 ,97]
    io_port.pe_wrData = [[1, 2, 3, 4, 5, 6, 7, 8], \
                         [9, 10, 11, 12, 13, 14, 15, 16], \
                         [17, 18, 19, 20, 21, 22, 23, 24], \
                         [25, 26, 27, 28, 29, 30, 31, 32]]
    io_port.pe_wrEn = [1, 1, 1, 1]

    for i in range(0,4):
        CC0.one_clock()
        EC0.one_clock()
        update()
        print('cycle ' + str(i) + ': ')
        print('addr = ' + str(io_port.cc_reqAddr))
        print('data = ' + str(io_port.cc_wrData))
        print('cc_ready = ' + str(io_port.cc_ready))
        print()

    # read data out
    io_port.pe_wrEn = [0, 0, 0, 0]

    for i in range(4,8):
        CC0.one_clock()
        EC0.one_clock()
        update()
        print('cycle ' + str(i) + ': ')
        print('addr = ' + str(io_port.cc_reqAddr))
        print('data = ' + str(io_port.cache_rdData))
        print('cc_ready = ' + str(io_port.cc_ready))
        print()