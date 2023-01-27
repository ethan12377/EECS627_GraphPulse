import io_port
import numpy as np

class OB:

    def __init__(self):
        self.buffer = np.zeros((4, 8), dtype=np.float16)

    def one_clock(self):
        # input:
        #   io_port.rowDelta
        #   io_port.binrowIdx
        #   io_port.rowValid
        #   io_port.IssReady

        # TODO: update *_n
        io_port.rowReady_n = io_port.rowReady
        io_port.IssDelta_n = io_port.IssDelta
        io_port.IssIdx_n = io_port.IssIdx
        io_port.IssValid_n = io_port.IssValid
