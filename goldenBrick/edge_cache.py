import io_port
import numpy as np

# TODO: define cache organization
#   - Width of each word
#   - organization of address space
#   - initialization
#   - marking unused address space

# 255 valid vertices (id=0-254), id=255 represents invalid
# this way, there will be 256 row indices

# word width: 64
# total bits: 256*16 (vertex data) + 256*8 (colIndex) + 256*8 (rowIndex) = 8,192 bits
# number of bits needed for addr: 8,192/64 = 7 bits
# TODO: use PE to generate 7 bit addresses 
# Addr[6:5] == 2'b0x: data req
# Addr[6:5] == 2'b10: col index req
# Addr[6:5] == 2'b11: row index req

class EC:

    def __init__(self, csr_filename):
        self.vertexValues = np.zeros(256, dtype=np.float16)
        self.colIndex = np.zeros(256)
        self.rowIndex = np.zeros(256)

        # read a file to initialize the graph into the cache
        with open(csr_filename) as f:
            colIndexVals = f.readline()[:-1].split(',')
            rowIndexVals = f.readline()[:-1].split(',')
            for i in range(0, len(rowIndexVals)): # row index are always one element longer than col index
                if i < len(colIndexVals):
                    self.colIndex[i] = colIndexVals[i]
                self.rowIndex = rowIndexVals[i]

    def one_clock(self):
        if io_port.reqAddr < 64: # return 4 values at once
            io_port.cacheResp_n = self.vertexValues[io_port.reqAddr*4 : (io_port.reqAddr+1)*4]
            io_port.cacheValid_n = 1
        elif io_port.reqAddr < 96: # return 8 values at once
            io_port.cacheResp_n = self.rowIndex[(io_port.reqAddr-64)*8 : (io_port.reqAddr-63)*8]
            io_port.cacheValid_n = 1
        elif io_port.reqAddr < 128: # return 8 values at once
            io_port.cacheResp_n = self.colIndex[(io_port.reqAddr-96)*8 : (io_port.reqAddr-95)*8]
            io_port.cacheValid_n = 1
        else: #io_port.reqAddr == 128
            io_port.cacheResp_n = 0
            io_port.cacheValid_n = 0
