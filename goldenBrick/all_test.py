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
from coalescing_unit import CU
from queue_scheduler import QS

CU_timer = np.zeros(8)
CU_timer_n = np.zeros(8)

np.random.seed(0)

def update():
    
    # QS
    io_port.initialFinish = copy.deepcopy(io_port.initialFinish_0)
    io_port.initialFinish_0 = np.uint8(io_port.initialFinish_n[0] and io_port.initialFinish_n[1] and io_port.initialFinish_n[2] and io_port.initialFinish_n[3])
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
    
    io_port.state = np.copy(io_port.state_n)

    io_port.searchValueValid = np.copy(io_port.searchValueValid_n)
    io_port.searchValue = np.copy(io_port.searchValue_n)
    io_port.searchIdx = np.copy(io_port.searchIdx_n) 
    io_port.searchValid = np.copy(io_port.searchValid_n) 

    io_port.newDelta = np.copy(io_port.newDelta_n)
    io_port.newIdx = np.copy(io_port.newIdx_n)
    io_port.newValid = np.copy(io_port.newValid_n)

    io_port.cuclean = np.copy(io_port.cuclean_n) 
    
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
    
def print_CU():     
    print(f"CUreg[0]: CUregValid |CUIdxreg |CUDeltareg |CUregtag       ")
    print(f"|         {CU0.CUregValid[0][0]}  |{CU0.CUIdxreg[0][0]}   |{CU0.CUDeltareg[0][0]} |{CU0.CUregtag[0][0]}")
    print(f"CUreg[1]: CUregValid |CUIdxreg |CUDeltareg |CUregtag       ")
    print(f"|         {CU0.CUregValid[0][1]}  |{CU0.CUIdxreg[0][1]}   |{CU0.CUDeltareg[0][1]} |{CU0.CUregtag[0][1]}")
    print("CU_in_buf: delta, idx, valid")
    print(f"CUreg[2]: CUregValid |CUIdxreg |CUDeltareg |CUregtag       ")
    print(f"|         {CU0.CUregValid[0][2]}  |{CU0.CUIdxreg[0][2]}   |{CU0.CUDeltareg[0][2]} |{CU0.CUregtag[0][2]}")
    
    print('\n')
    print("CU_in_buf: delta, idx, valid")
    print(CU0.CU_in_buf[0])
    print("CU_out_buf: delta, idx, valid")
    print(CU0.CU_out_buf[0])
    print('\n')
    
    print(f'input:')
    print(f"|io_port.CUDelta |io_port.CUIdx |io_port.CUValid")
    print(f"|{io_port.CUDelta[0]}  |{io_port.CUIdx[0]}   |{io_port.CUValid[0]}")
   
    print(f'output:')
    print("CUReady_n[0] = ", io_port.CUReady_n[0])
    print(f"searchIdx_n[0] |searchValid_n[0]   ")
    print(f"{io_port.searchIdx_n[0]}    |{io_port.searchValid_n[0]}")
    print(f"newDelta_n[0] |newIdx_n[0] |newValid_n[0]  ")
    print(f"{io_port.newDelta_n[0]} |{io_port.newIdx_n[0]}  |{io_port.newValid_n[0]}", )
    print("cuclean_n[0] = ", io_port.cuclean_n[0])

def print_qs():
    print("io_port.rowDelta_n: ", io_port.rowDelta_n)
    print("io_port.binrowIdx_n: ", io_port.binrowIdx_n)
    print("rowValid_n: ",io_port.rowValid_n)
    print("state_n: ", io_port.state_n)
    print("Queue1: ")
    print(QS0.queue)
    print("rowValid_matrix1: ")
    print(QS0.rowValid_matrix)
    
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
    CU0 = CU()
    QS0 = QS()
    curr_cycle = 0
    timeout_cycle_num = 20
    # print_range = [0, 50]
    print_range = [4995, 5000]
    
    # run until convergence
    # while EVQ0.empty != 1 or not all(v == 1 for v in io_port.PEReady):
    #     if curr_cycle >= timeout_cycle_num:
    #         break
    for i in range(2000):
        print("[Clock", i, "]")
        # QS_input()
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
        # CU_input()
        update()
        Xbar0.update()
        OB0.update()
        Xbar1.update()
        QS0.one_clock()
        CU0.one_clock()
        CU_timer = copy.deepcopy(CU_timer_n)
        # if curr_cycle >= print_range[0] and curr_cycle <= print_range[1]:
        print_system_status(i)
        # curr_cycle += 1
        print_qs()
        # print_CU()
        print('initialFinish: ', io_port.initialFinish)
    
    print()
    if curr_cycle <= timeout_cycle_num:
        print(' ### Convergence reached at cycle ' + str(curr_cycle) + ' ###')
    else: # timeout
        print(' ### TIMEOUT AT CYCLE ' + str(curr_cycle) + ' ###')
    print()
    print_vc_content(0, EC0.num_of_vertices)
    print()
    