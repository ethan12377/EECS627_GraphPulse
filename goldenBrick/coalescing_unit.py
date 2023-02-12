import io_port
import numpy as np
import copy

class CU:

    def __init__(self):
        pass

    def one_clock(self):
        # input:
        #   io_port.CUDelta
        #   io_port.CUIdx
        #   io_port.CUValid
        #   io_port.searchIdx

        # TODO: update *_n
        io_port.CUReady_n = copy.deepcopy(io_port.CUReady)
        io_port.searchIdx_n = copy.deepcopy(io_port.searchIdx)
        io_port.newDelta_n = copy.deepcopy(io_port.newDelta)
        io_port.newIdx_n = copy.deepcopy(io_port.newIdx)
        io_port.newValid_n = copy.deepcopy(io_port.newValid)
