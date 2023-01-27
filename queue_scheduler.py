import io_port
import numpy as np

class QS:

    def __init__(self):
        self.queue = np.zeros((8, 8, 4), dtype=np.float16)

    def one_clock(self):
        # input:
        #   io_port.rowReady
        #   io_port.newDelta
        #   io_port.newIdx
        #   io_port.newValid

        # TODO: update *_n
        io_port.rowDelta_n = io_port.rowDelta
        io_port.binrowIdx_n = io_port.binrowIdx
        io_port.rowValid_n = io_port.rowValid
