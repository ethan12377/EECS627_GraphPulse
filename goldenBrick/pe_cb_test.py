import copy
import numpy as np
import io_port
from crossbar import Xbar_SchedToPE
from cache_controller import CC
from edge_cache import EC
from vertex_cache import VC
from processing_element import PE
# from evqueue_multicore import EVQ
from output_buffer import OB
from crossbar import Xbar_PEToQ

CU_timer = np.zeros(8)
CU_timer_n = np.zeros(8)

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
            
def CU_input():
    for i in range(8):
        print('CUDelta[', i, '] = ', np.around(io_port.CUDelta[i], 3), '\tCUIdx[', i, '] = ', io_port.CUIdx[i], '\tCUValid[', i, '] = ', io_port.CUValid[i], '\tCUReady[', i, '] = ', io_port.CUReady[i])
    
        io_port.CUReady_n[i] = np.int8(1)
    # for i in range(8):
    #     if io_port.CUReady[i] == np.int8(0):
    #         if CU_timer[i] < (2 + np.random.randint(4)):
    #             CU_timer_n[i] = CU_timer[i] + 1
    #         else:
    #             CU_timer_n[i] = 0
    #             io_port.CUReady_n[i] = np.int8(1)
    #     else:
    #         if io_port.CUValid[i] == np.int8(1):
    #             io_port.CUReady_n[i] = np.int8(0)

def update():
    
    # QS
    io_port.rowDelta = copy.deepcopy(io_port.rowDelta_n)
    io_port.binrowIdx = copy.deepcopy(io_port.binrowIdx_n)
    io_port.rowValid = copy.deepcopy(io_port.rowValid_n)
    # OB
    io_port.rowReady = copy.deepcopy(io_port.rowReady_n)
    io_port.IssDelta = copy.deepcopy(io_port.IssDelta_n)
    io_port.IssIdx   = copy.deepcopy(io_port.IssIdx_n)
    io_port.IssValid = copy.deepcopy(io_port.IssValid_n)
    # Xbar_SchedToPE
    io_port.PEDelta = copy.deepcopy(io_port.PEDelta_n)
    io_port.PEIdx   = copy.deepcopy(io_port.PEIdx_n)
    io_port.PEValid = copy.deepcopy(io_port.PEValid_n)
    io_port.IssReady = copy.deepcopy(io_port.IssReady_n)
    
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
    io_port.pe_ec_reqValid = copy.deepcopy(io_port.pe_ec_reqValid_n)
    
    # Xbar_PEToQ
    io_port.CUDelta = copy.deepcopy(io_port.CUDelta_n)
    io_port.CUIdx = copy.deepcopy(io_port.CUIdx_n)
    io_port.CUValid = copy.deepcopy(io_port.CUValid_n)
    io_port.proReady = copy.deepcopy(io_port.proReady_n)  
    
    # CU
    io_port.CUReady = copy.deepcopy(io_port.CUReady_n)
    
def print_pe_status(pe_id):
    print('##### PE ' + str(pe_id) + ' #####')
    print('state = \t' + str(PE_cores[pe_id].curr_state))
    print('ready = \t' + str(io_port.PEReady[pe_id]))
    print('initializing = \t' + str(PE_cores[pe_id].initializing))
    print('curr index = \t' + str(PE_cores[pe_id].curr_idx))
    print('curr_delta = \t' + str(PE_cores[pe_id].curr_delta))
    print('ruw complete = \t' + str(PE_cores[pe_id].ruw_complete))
    print('### FPU ###')
    print('fpu value pipe = \t' + str(PE_cores[pe_id].fpu_value_pipe))
    print('fpu status pipe = \t' + str(PE_cores[pe_id].fpu_status_pipe))
    print('### INPUTS ###')
    print('event valid = \t' +str(io_port.PEValid[pe_id]))
    print('event delta = \t' +str(io_port.PEDelta[pe_id]))
    print('event index = \t' +str(io_port.PEIdx[pe_id]))
    print('### MEM OUTPUTS ###')
    print('vc req addr = \t' + str(io_port.pe_vc_reqAddr[pe_id]))
    print('vc req valid = \t' + str(io_port.pe_vc_reqValid[pe_id]))
    print('vc req wren = \t' + str(io_port.pe_wrEn[pe_id]))
    print('ec req addr = \t' + str(io_port.pe_ec_reqAddr[pe_id]))
    print('ec req valid = \t' + str(io_port.pe_ec_reqValid[pe_id]))
    print('### EVGEN OUTPUTS ###')
    print('start = \t' + str(PE_cores[pe_id].start))
    print('end = \t' + str(PE_cores[pe_id].end))
    print('curr_evgen_idx = \t' + str(PE_cores[pe_id].curr_evgen_idx))
    print('curr_col_idx_word = \t' + str(PE_cores[pe_id].curr_col_idx_word))
    print('proIdx = \t' + str(io_port.proIdx[2*pe_id : 2*pe_id+1]))
    print('proValid = \t' + str(io_port.proValid[2*pe_id : 2*pe_id+1]))
    print('proDelta = \t' + str(io_port.proDelta[2*pe_id : 2*pe_id+1]))
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

def print_queue_status():
    print('##### QUEUE #####')
    # print('waiting for pe = \t' + str(EVQ0.waiting_for_pe))
    print('pe valid = \t' + str(io_port.PEValid))
    print('pe idx = \t' + str(io_port.PEIdx))
    print('pe delta = \t' + str(io_port.PEDelta))

def print_vc_content(addr_start, addr_end):
    print('##### VC #####')
    for addr in range(addr_start, addr_end):
        print('vc addr ' + str(addr) + ' = \t' + str(VC0.vertexValues[addr]))

def print_system_status(cycle):
    print('###################')
    print('##### CYCLE ' + str(cycle) + ' #####')
    print('###################')
    print()
    print_pe_status(0)
    print_pe_status(1)
    print_pe_status(2)
    print_pe_status(3)
    # print_cc_status()
    print_queue_status()
    print_vc_content(0, EC0.num_of_vertices)
    print()
    
if __name__ == "__main__":
    io_port.init()
    OB0 = OB()
    Xbar0 = Xbar_SchedToPE()
    CC_VC = CC(cache_name='vc')
    CC_EC = CC(cache_name='ec')
    EC0 = EC(csr_filename='csr.txt')
    VC0 = VC()
    # test all four cores at the same time
    curr_num_of_cores = 4
    # EVQ0 = EVQ(num_of_cores=curr_num_of_cores)
    PE0 = PE(pe_id=0, fpu_pipe_depth=3, threshold=1e-6, damping_factor=0.85, num_of_vertices=EC0.num_of_vertices, num_of_cores=curr_num_of_cores)
    PE1 = PE(pe_id=1, fpu_pipe_depth=3, threshold=1e-6, damping_factor=0.85, num_of_vertices=EC0.num_of_vertices, num_of_cores=curr_num_of_cores)
    PE2 = PE(pe_id=2, fpu_pipe_depth=3, threshold=1e-6, damping_factor=0.85, num_of_vertices=EC0.num_of_vertices, num_of_cores=curr_num_of_cores)
    PE3 = PE(pe_id=3, fpu_pipe_depth=3, threshold=1e-6, damping_factor=0.85, num_of_vertices=EC0.num_of_vertices, num_of_cores=curr_num_of_cores)
    PE_cores = [PE0, PE1, PE2, PE3]
    Xbar1 = Xbar_PEToQ()

    curr_cycle = 0
    timeout_cycle_num = 20
    # print_range = [0, 50]
    print_range = [4995, 5000]
    
    # run until convergence
    # while EVQ0.empty != 1 or not all(v == 1 for v in io_port.PEReady):
    #     if curr_cycle >= timeout_cycle_num:
    #         break
    for i in range(30):
        print("[Clock", i, "]")
        QS_input()
        OB0.one_clock()
        Xbar0.one_clock()
        PE0.one_clock()
        PE1.one_clock()
        PE2.one_clock()
        PE3.one_clock()
        CC_VC.one_clock()
        CC_EC.one_clock()
        EC0.one_clock()
        VC0.one_clock()
        # EVQ0.one_clock()
        Xbar1.one_clock()
        CU_input()
        update()
        Xbar0.update()
        OB0.update()
        Xbar1.update()
        CU_timer = copy.deepcopy(CU_timer_n)
        # if curr_cycle >= print_range[0] and curr_cycle <= print_range[1]:
        # print_system_status(curr_cycle)
        # curr_cycle += 1
    
    print()
    if curr_cycle <= timeout_cycle_num:
        print(' ### Convergence reached at cycle ' + str(curr_cycle) + ' ###')
    else: # timeout
        print(' ### TIMEOUT AT CYCLE ' + str(curr_cycle) + ' ###')
    print()
    print_vc_content(0, EC0.num_of_vertices)
    print()