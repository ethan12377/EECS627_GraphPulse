import io_port
import numpy as np

class SPM:

    def __init__(self):
        pass

    def one_clock(self): # TODO: memory I/O
        # input:
        #   io_port.vertReq
        #   io_port.vertIdx

        # TODO: update *_n
        io_port.vertResp_n = io_port.vertResp
        io_port.vertValid_n = io_port.vertValid
