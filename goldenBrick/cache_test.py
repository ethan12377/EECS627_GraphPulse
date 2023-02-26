import numpy as np
import io_port
from cache_controller import CC
from edge_cache import EC
from vertex_cache import VC

def update():
    # cc
    io_port.cc_ec_ready = io_port.cc_ec_ready_n
    io_port.cc_vc_ready = io_port.cc_vc_ready_n
    # cache
    io_port.vc_rdData = io_port.vc_rdData_n
    io_port.ec_rdData = io_port.ec_rdData_n

if __name__ == "__main__":

    io_port.init()
    CC_VC = CC(cache_name='vc')
    CC_EC = CC(cache_name='ec')
    EC0 = EC(csr_filename='csr.txt')
    VC0 = VC()

    # write some stuff to vertex cache
    io_port.pe_ec_reqValid = [0, 0, 0, 0]
    io_port.pe_ec_reqAddr = [0, 0, 0, 0]

    io_port.pe_vc_reqAddr = [0, 1, 2, 3]
    io_port.pe_vc_reqValid = [1, 1, 1, 1]
    io_port.pe_wrData = [0.1, 0.2, 0.3, 0.4]
    io_port.pe_wrEn = [1, 1, 1, 1]

    for i in range(0,4):
        CC_VC.one_clock()
        CC_EC.one_clock()
        EC0.one_clock()
        VC0.one_clock()
        update()
        print('cycle ' + str(i) + ': ')
        print('addr = ' + str(io_port.cc_vc_vertexAddr))
        print('data = ' + str(io_port.cc_vc_wrData))
        print('wren = ' + str(io_port.cc_vc_wrEn))
        print('cc_ec_ready = ' + str(io_port.cc_ec_ready))
        print('cc_vc_ready = ' + str(io_port.cc_vc_ready))
        print()

    # read data out
    io_port.pe_wrEn = [0, 0, 0, 0]

    for i in range(4,8):
        CC_VC.one_clock()
        CC_EC.one_clock()
        EC0.one_clock()
        VC0.one_clock()
        update()
        print('cycle ' + str(i) + ': ')
        print('data = ' + str(io_port.vc_rdData))
        print('cc_ec_ready = ' + str(io_port.cc_ec_ready))
        print('cc_vc_ready = ' + str(io_port.cc_vc_ready))
        print()

    # read edge data
    io_port.pe_ec_reqValid = [1, 1, 1, 1]
    io_port.pe_ec_reqAddr = [0, 8192, 0, 8192]
    io_port.pe_vc_reqValid = [0, 0, 0, 0]

    # print(EC0.colIndex[0:16])
    # print(EC0.rowIndex[0:16])
    for i in range(8,12):
        CC_VC.one_clock()
        CC_EC.one_clock()
        EC0.one_clock()
        VC0.one_clock()
        update()
        print('cycle ' + str(i) + ': ')
        print('addr = ' + str(io_port.cc_ec_edgeAddr))
        print('data = ' + str(io_port.ec_rdData))
        print('cc_ec_ready = ' + str(io_port.cc_ec_ready))
        print('cc_vc_ready = ' + str(io_port.cc_vc_ready))
        print()
