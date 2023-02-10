import numpy as np
import io_port
from cache_controller import CC
from edge_cache import EC
from vertex_cache import VC
from processing_element_new import PE

def update():
    # cc
    io_port.cc_ec_ready = io_port.cc_ec_ready_n
    io_port.cc_vc_ready = io_port.cc_vc_ready_n
    # cache
    io_port.vc_rdData = io_port.vc_rdData_n
    io_port.ec_rdData = io_port.ec_rdData_n
    # pe
    io_port.PEReady = io_port.PEReady_n
    io_port.proDelta = io_port.proDelta_n
    io_port.proIdx = io_port.proIdx_n
    io_port.proValid = io_port.proValid_n
    io_port.pe_vc_reqAddr = io_port.pe_vc_reqAddr_n
    io_port.pe_ec_reqAddr = io_port.pe_ec_reqAddr_n
    io_port.pe_wrData = io_port.pe_wrData_n
    io_port.pe_wrEn = io_port.pe_wrEn_n
    io_port.pe_vc_reqValid = io_port.pe_vc_reqValid_n
    io_port.pe_ec_reqValid = io_port.pe_ec_reqValid_n

def print_pe_status():
    print('##### PE #####')
    print('state = ' + str(PE0.curr_state))
    print()

def print_cc_status():
    print('##### CC #####')
    print('CC_VC:')
    print('vc_addr = ' + str(io_port.cc_vc_vertexAddr))
    print('vc_rddata = ' + str(io_port.vc_rdData))
    print('vc_wren = ' + str(io_port.cc_vc_wrEn))
    print('vc_wrdata = ' + str(io_port.cc_vc_wrData))
    print('cc_vc_ready = ' + str(io_port.cc_vc_ready))
    print('CC_EC:')
    print('ec_addr = ' + str(io_port.cc_ec_edgeAddr))
    print('ec_rddata = ' + str(io_port.ec_rdData))
    print('cc_ec_ready = ' + str(io_port.cc_ec_ready))
    print()

def print_system_status(cycle):
    print('###################')
    print('##### CYCLE ' + str(cycle) + ' #####')
    print('###################')
    print()
    print_pe_status()
    print_cc_status()
    print()

def send_event(pe_id, vertex_idx, delta):
    io_port.PEValid[pe_id] = 1
    io_port.PEDelta[pe_id] = delta
    io_port.PEIdx[pe_id] = vertex_idx

if __name__ == "__main__":

    io_port.init()
    CC_VC = CC(cache_name='vc')
    CC_EC = CC(cache_name='ec')
    EC0 = EC(csr_filename='csr.txt')
    VC0 = VC()
    # for now, just test single processor
    PE0 = PE(pe_id=0, fpu_pipe_depth=3)

    # TODO: create a simple graph to test on
    # TODO: send in a stimulus to start the FSM in PE
    # TODO: create a function to print out system status

    for i in range(0,2):
        # default to no valid input into the PEs
        io_port.PEValid = np.zeros(4)
        # insert event here
        # send_event(pe_id=0, vertex_idx=0, delta=np.float16(1.0))
        PE0.one_clock()
        CC_VC.one_clock()
        CC_EC.one_clock()
        EC0.one_clock()
        VC0.one_clock()
        update()
        print_system_status(i)