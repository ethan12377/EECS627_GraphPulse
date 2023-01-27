import io_port
import numpy as np

class PE:

    def __init__(self):
        pass

    def one_clock(self):
        # input:
        #   io_port.PEDelta
        #   io_port.PEIdx
        #   io_port.PEValid
        #   io_port.proReady
        #   io_port.edgeResp
        #   io_port.edgeValid
        #   io_port.edgeEnd
        #   io_port.vertResp
        #   io_port.vertValid

        # TODO: update *_n
        io_port.PEReady_n = io_port.PEReady
        io_port.proDelta_n = io_port.proDelta
        io_port.proIdx_n = io_port.proIdx
        io_port.proValid_n = io_port.proValid
        io_port.edgeReq_n = io_port.edgeReq
        io_port.edgeVertIdx_n = io_port.edgeVertIdx
        io_port.vertReq_n = io_port.vertReq
        io_port.vertIdx_n = io_port.vertIdx
