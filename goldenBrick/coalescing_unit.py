import io_port
import numpy as np

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
        io_port.CUReady_n = io_port.CUReady
        io_port.searchIdx_n = io_port.searchIdx
        io_port.newDelta_n = io_port.newDelta
        io_port.newIdx_n = io_port.newIdx
        io_port.newValid_n = io_port.newValid
