import numpy as np
import copy
import io_port
from queue_scheduler import QS
from output_buffer import OB
from crossbar import Xbar_SchedToPE, Xbar_PEToQ
from processing_element import PE
from coalescing_unit import CU
from scratchpad import SPM
from edge_cache import EC

def update():
    # QS
    io_port.rowDelta = copy.deepcopy(io_port.rowDelta_n)
    io_port.binrowIdx = copy.deepcopy(io_port.binrowIdx_n)
    io_port.rowValid = copy.deepcopy(io_port.rowValid_n)
    io_port.newReady = copy.deepcopy(io_port.newReady_n)
    io_port.searchValue = copy.deepcopy(io_port.searchValue_n)
    # OB
    io_port.rowReady = copy.deepcopy(io_port.rowReady_n)
    io_port.IssDelta = copy.deepcopy(io_port.IssDelta_n)
    io_port.IssIdx = copy.deepcopy(io_port.IssIdx_n)
    io_port.IssValid = copy.deepcopy(io_port.IssValid_n)
    # Xbar_SchedToPE
    io_port.IssReady = copy.deepcopy(io_port.IssReady_n)
    io_port.PEDelta = copy.deepcopy(io_port.PEDelta_n)
    io_port.PEIdx = copy.deepcopy(io_port.PEIdx_n)
    io_port.PEValid = copy.deepcopy(io_port.PEValid_n)
    # PE
    io_port.PEReady = copy.deepcopy(io_port.PEReady_n)
    io_port.proDelta = copy.deepcopy(io_port.proDelta_n)
    io_port.proIdx = copy.deepcopy(io_port.proIdx_n)
    io_port.proValid = copy.deepcopy(io_port.proValid_n)
    io_port.edgeReq = copy.deepcopy(io_port.edgeReq_n)
    io_port.edgeVertIdx = copy.deepcopy(io_port.edgeVertIdx_n)
    io_port.vertReq = copy.deepcopy(io_port.vertReq_n)
    io_port.vertIdx = copy.deepcopy(io_port.vertIdx_n)
    # Xbar_PEToQ
    io_port.proReady = copy.deepcopy(io_port.proReady_n)
    io_port.CUDelta = copy.deepcopy(io_port.CUDelta_n)
    io_port.CUIdx = copy.deepcopy(io_port.CUIdx_n)
    io_port.CUValid = copy.deepcopy(io_port.CUValid_n)
    # CU
    io_port.CUReady = copy.deepcopy(io_port.CUReady_n)
    io_port.searchIdx = copy.deepcopy(io_port.searchIdx_n)
    io_port.newDelta = copy.deepcopy(io_port.newDelta_n)
    io_port.newIdx = copy.deepcopy(io_port.newIdx_n)
    io_port.newValid = copy.deepcopy(io_port.newValid_n)
    # SPM
    io_port.vertResp = copy.deepcopy(io_port.vertResp_n)
    io_port.vertValid = copy.deepcopy(io_port.vertValid_n)
    # EC
    io_port.edgeResp = copy.deepcopy(io_port.edgeResp_n)
    io_port.edgeValid = copy.deepcopy(io_port.edgeValid_n)
    io_port.edgeEnd = copy.deepcopy(io_port.edgeEnd_n)

if __name__ == "__main__":

    io_port.init()

    QS0 = QS()
    OB0 = OB()
    Xbar0 = Xbar_SchedToPE()
    PE0 = PE()
    Xbar1 = Xbar_PEToQ()
    CU0 = CU()
    SPM0 = SPM()
    EC0 = EC()

    for i in range(100):
        print("[Clock", i, "]")
        QS0.one_clock()
        OB0.one_clock()
        Xbar0.one_clock()
        PE0.one_clock()
        Xbar1.one_clock()
        CU0.one_clock()
        SPM0.one_clock()
        EC0.one_clock()

        update()
