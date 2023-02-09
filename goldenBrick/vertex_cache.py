import io_port
import numpy as np

# 8 bit address, 16-bit value
# 0, 2 share port, 1, 3 share port

class VC:

    def __init__(self):
        self.vertexValues = np.zeros(256, dtype=np.float16)

    def one_clock(self):
        if io_port.cc_vc_wrEn:
            self.vertexValues[io_port.cc_vc_vertexAddr] = io_port.cc_vc_wrData
        io_port.vc_rdData_n = self.vertexValues[io_port.cc_vc_vertexAddr]
        
