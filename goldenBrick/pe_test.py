import numpy as np
import io_port
from cache_controller import CC
from edge_cache import EC
from vertex_cache import VC
from processing_element_new import PE
import copy

def update():
    # cc
    io_port.cc_ec_ready = copy.deepcopy(io_port.cc_ec_ready_n)
    io_port.cc_vc_ready = copy.deepcopy(io_port.cc_vc_ready_n)
    # cache
    io_port.vc_rdData = copy.deepcopy(io_port.vc_rdData_n)
    io_port.ec_rdData = copy.deepcopy(io_port.ec_rdData_n)
    # pe
    io_port.PEReady = copy.deepcopy(io_port.PEReady_n)
    io_port.proDelta = copy.deepcopy(io_port.proDelta_n)
    io_port.proIdx = copy.deepcopy(io_port.proIdx_n)
    io_port.proValid = copy.deepcopy(io_port.proValid_n)
    io_port.pe_vc_reqAddr = copy.deepcopy(io_port.pe_vc_reqAddr_n)
    io_port.pe_ec_reqAddr = copy.deepcopy(io_port.pe_ec_reqAddr_n)
    io_port.pe_wrData = copy.deepcopy(io_port.pe_wrData_n)
    io_port.pe_wrEn = copy.deepcopy(io_port.pe_wrEn_n)
    io_port.pe_vc_reqValid = copy.deepcopy(io_port.pe_vc_reqValid_n)
    # print(str(io_port.pe_vc_reqValid))
    io_port.pe_ec_reqValid = copy.deepcopy(io_port.pe_ec_reqValid_n)
    # print(str(io_port.pe_ec_reqValid))

def print_pe_status():
    print('##### PE #####')
    print('state = \t' + str(PE0.curr_state))
    print('ready = \t' + str(io_port.PEReady[0]))
    print('initializing = \t' + str(PE0.initializing))
    print('### FPU ###')
    print('fpu value pipe = \t' + str(PE0.fpu_value_pipe))
    print('fpu status pipe = \t' + str(PE0.fpu_status_pipe))
    print('### INPUTS ###')
    print('event valid = \t' +str(io_port.PEValid))
    print('event delta = \t' +str(io_port.PEDelta))
    print('event index = \t' +str(io_port.PEIdx))
    print('### MEM OUTPUTS ###')
    print('vc req addr = \t' + str(io_port.pe_vc_reqAddr))
    print('vc req valid = \t' + str(io_port.pe_vc_reqValid))
    print('vc req wren = \t' + str(io_port.pe_wrEn))
    print('ec req addr = \t' + str(io_port.pe_ec_reqAddr))
    print('ec req valid = \t' + str(io_port.pe_ec_reqValid))
    print('### EVGEN OUTPUTS ###')
    print('start = \t' + str(PE0.start))
    print('end = \t' + str(PE0.end))
    print('curr_evgen_idx = \t' + str(PE0.curr_evgen_idx))
    print('proIdx = \t' + str(io_port.proIdx))
    print('proValid = \t' + str(io_port.proValid))
    print('proDelta = \t' + str(io_port.proDelta))
    print()

def print_cc_status():
    print('##### CC #####')
    print('CC_VC:')
    print('vc_addr = \t' + str(io_port.cc_vc_vertexAddr))
    print('vc_rddata = \t' + str(io_port.vc_rdData))
    print('vc_wren = \t' + str(io_port.cc_vc_wrEn))
    print('vc_wrdata = \t' + str(io_port.cc_vc_wrData))
    print('cc_vc_ready = \t' + str(io_port.cc_vc_ready))
    print('CC_EC:')
    print('ec_addr = \t' + str(io_port.cc_ec_edgeAddr))
    print('ec_rddata = \t' + str(io_port.ec_rdData))
    print('cc_ec_ready = \t' + str(io_port.cc_ec_ready))
    print()

def print_system_status(cycle):
    print('###################')
    print('##### CYCLE ' + str(cycle) + ' #####')
    print('###################')
    print()
    print_pe_status()
    # print_cc_status()
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
    PE0 = PE(pe_id=0, fpu_pipe_depth=3, threshold=0.001, damping_factor=0.85, num_of_vertices=2)

    # TODO: create a simple graph to test on
    # TODO: send in a stimulus to start the FSM in PE
    # TODO: create a function to print out system status

    curr_cycle = 0
    print_range = [0, 20]

    # send_event(pe_id=0, vertex_idx=0, delta=np.float16(0.25))
    PE0.one_clock()
    CC_VC.one_clock()
    CC_EC.one_clock()
    EC0.one_clock()
    VC0.one_clock()
    update()
    if curr_cycle >= print_range[0] and curr_cycle <= print_range[1]:
        print_system_status(curr_cycle)
    curr_cycle += 1

    for i in range(curr_cycle, curr_cycle + 10):
        # default to no valid input into the PEs
        io_port.PEValid = np.zeros(4)
        # insert event here
        print(str(io_port.proValid))
        PE0.one_clock()
        CC_VC.one_clock()
        CC_EC.one_clock()
        EC0.one_clock()
        VC0.one_clock()
        update()
        if i >= print_range[0] and i <= print_range[1]:
            print_system_status(i)
        curr_cycle += 1
    
    io_port.proReady[0] = 1
    io_port.proReady[1] = 1

    for i in range(curr_cycle, curr_cycle + 10):
        # default to no valid input into the PEs
        io_port.PEValid = np.zeros(4)
        # insert event here
        PE0.one_clock()
        CC_VC.one_clock()
        CC_EC.one_clock()
        EC0.one_clock()
        VC0.one_clock()
        update()
        if i >= print_range[0] and i <= print_range[1]:
            print_system_status(i)
        curr_cycle += 1