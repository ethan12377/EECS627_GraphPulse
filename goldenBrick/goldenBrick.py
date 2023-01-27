import numpy as np
import io_port
from queue_scheduler import QS
from output_buffer import OB
from crossbar import Xbar_SchedToPE, Xbar_PEToQ
from processing_element import PE
from coalescing_unit import CU
from scratchpad import SPM
from edge_cache import EC

def update():
    io_port.rowDelta = io_port.rowDelta_n
    io_port.binrowIdx = io_port.binrowIdx_n
    io_port.rowValid = io_port.rowValid_n
    io_port.rowReady = io_port.rowReady_n
    io_port.IssDelta = io_port.IssDelta_n
    io_port.IssIdx = io_port.IssIdx_n
    io_port.IssValid = io_port.IssValid_n
    io_port.IssReady = io_port.IssReady_n
    io_port.PEDelta = io_port.PEDelta_n
    io_port.PEIdx = io_port.PEIdx_n
    io_port.PEValid = io_port.PEValid_n
    io_port.PEReady = io_port.PEReady_n
    io_port.proDelta = io_port.proDelta_n
    io_port.proIdx = io_port.proIdx_n
    io_port.proValid = io_port.proValid_n
    io_port.edgeReq = io_port.edgeReq_n
    io_port.edgeVertIdx = io_port.edgeVertIdx_n
    io_port.vertReq = io_port.vertReq_n
    io_port.vertIdx = io_port.vertIdx_n
    io_port.proReady = io_port.proReady_n
    io_port.CUDelta = io_port.CUDelta_n
    io_port.CUIdx = io_port.CUIdx_n
    io_port.CUValid = io_port.CUValid_n
    io_port.CUReady = io_port.CUReady_n
    io_port.searchIdx = io_port.searchIdx_n
    io_port.newDelta = io_port.newDelta_n
    io_port.newIdx = io_port.newIdx_n
    io_port.newValid = io_port.newValid_n
    io_port.vertResp = io_port.vertResp_n
    io_port.vertValid = io_port.vertValid_n
    io_port.edgeResp = io_port.edgeResp_n
    io_port.edgeValid = io_port.edgeValid_n
    io_port.edgeEnd = io_port.edgeEnd_n

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
