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
        colIndexVals = np.genfromtxt('csr.txt', delimiter=',')[0][:-1]
        rowIndexVals = np.genfromtxt('csr.txt', delimiter=',')[1]
        for i in range(0, len(rowIndexVals)): # row index are always one element longer than col index
            if i < len(colIndexVals):
                self.colIndex[i] = colIndexVals[i]
            self.rowIndex[i] = rowIndexVals[i]

    def one_clock(self):
        if io_port.cc_reqAddr == 128: # invalid addr
            io_port.cache_rdData_n = 0
            io_port.cacheValid_n = 0
        elif io_port.cc_wrEn: # write
            if io_port.cc_reqAddr < 64:
                self.vertexValues[io_port.cc_reqAddr*4 : (io_port.cc_reqAddr+1)*4] = io_port.cc_wrData[0:4]
            elif io_port.cc_reqAddr < 96:
                self.colIndex[(io_port.cc_reqAddr-64)*8 : (io_port.cc_reqAddr-63)*8] = io_port.cc_wrData
            else:
                self.rowIndex[(io_port.cc_reqAddr-96)*8 : (io_port.cc_reqAddr-95)*8] = io_port.cc_wrData
        else:
            io_port.cacheValid_n = 1
            if io_port.cc_reqAddr < 64: # return 4 values at once
                io_port.cache_rdData_n = self.vertexValues[io_port.cc_reqAddr*4 : (io_port.cc_reqAddr+1)*4]
            elif io_port.cc_reqAddr < 96: # return 8 values at once
                io_port.cache_rdData_n = self.rowIndex[(io_port.cc_reqAddr-64)*8 : (io_port.cc_reqAddr-63)*8]
            else:
                io_port.cache_rdData_n = self.colIndex[(io_port.cc_reqAddr-96)*8 : (io_port.cc_reqAddr-95)*8]
