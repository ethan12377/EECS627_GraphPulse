import io_port
import numpy as np

# 64-bit word. 6 bit addr (64 addresses)
# col index= 256*256*8 = 65536, 8 bit number
# row index = 256 if omit starting zero, 16-bit number (up to 65536)

# 0-8191: col index, 8 items per word
# 8192-8255: row index, 4 items per word

class EC:

    def __init__(self, csr_filename):
        self.colIndex = np.zeros(65536)
        self.rowIndex = np.zeros(256)
        # read file for column index and row index
        with open(csr_filename, 'r') as f:
            colIndexVals = [eval(v) for v in f.readline().split(',')]
            rowIndexVals = [eval(v) for v in f.readline().split(',')]
        # store num of vertices to be used in PE initialization
        self.num_of_vertices = len(rowIndexVals) - 1
        # write results from file read
        for i in range(0, len(colIndexVals)):
            self.colIndex[i] = colIndexVals[i]
        for i in range(0, len(rowIndexVals)):
            self.rowIndex[i] = rowIndexVals[i]

    def one_clock(self):
        if io_port.cc_ec_edgeAddr < 8192: # col index
            io_port.ec_rdData_n = self.colIndex[io_port.cc_ec_edgeAddr * 8 : io_port.cc_ec_edgeAddr * 8 + 8]
        elif io_port.cc_ec_edgeAddr < 8256: # row index
            io_port.ec_rdData_n = self.rowIndex[(io_port.cc_ec_edgeAddr-8192) * 4 : (io_port.cc_ec_edgeAddr-8192) * 4 + 4]
        else:
            io_port.ec_rdData_n = np.zeros(8)