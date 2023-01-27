import io_port
import numpy as np

class Xbar_SchedToPE:

    def __init__(self):
        pass

    def one_clock(self):
        # input:
        #   io_port.IssDelta
        #   io_port.IssIdx
        #   io_port.IssValid
        #   io_port.PEReady

        # TODO: update *_n
        io_port.IssReady_n = io_port.IssReady
        io_port.PEDelta_n = io_port.PEDelta
        io_port.PEIdx_n = io_port.PEIdx
        io_port.PEValid_n = io_port.PEValid


class Xbar_PEToQ:

    def __init__(self):
        pass

    def one_clock(self):
        # input:
        #   io_port.proDelta
        #   io_port.proIdx
        #   io_port.proValid
        #   io_port.CUReady

        # TODO: update *_n
        io_port.proReady_n = io_port.proReady
        io_port.CUDelta_n = io_port.CUDelta
        io_port.CUIdx_n = io_port.CUIdx
        io_port.CUValid_n = io_port.CUValid
