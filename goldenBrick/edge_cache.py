import io_port
import numpy as np

class EC:

    def __init__(self):
        pass

    def one_clock(self): # TODO: memory I/O
        # input:
        #   io_port.edgeReq
        #   io_port.edgeVertIdx

        # TODO: update *_n
        io_port.edgeResp_n = io_port.edgeResp
        io_port.edgeValid_n = io_port.edgeValid
        io_port.edgeEnd_n = io_port.edgeEnd
