import io_port
import numpy as np

NUM_MEM_TAGS = 16
MEM_LATENCY_IN_CYCLES = 10

class EMEM:
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

        self.loaded_data = np.zeros((NUM_MEM_TAGS,8))
        self.cycles_left = np.zeros(NUM_MEM_TAGS)
        self.waiting_for_bus = np.zeros(NUM_MEM_TAGS)

    def one_clock():
        io_port.emem_tag_n = 0
        io_port.emem_rsp_n = 0
        io_port.emem_data_n = np.zeros(8, dtype=int)
        bus_filled = 0
        acquire_tag = (io_port.mc_em_cmd==1 or io_port.mc_em_cmd==2)

        for i in range(NUM_MEM_TAGS):
            if self.cycles_left[i] > 0:
                self.cycles_left[i] = self.cycles_left[i] - 1
            elif (acquire_tag and !self.waiting_for_bus[i]):
                io_port.emem_rsp_n = i+1
                acquire_tag = 0
                self.cycles_left[i] = MEM_LATENCY_IN_CYCLES

                if (io_port.mc_em_cmd==1):
                    self.waiting_for_bus[i] = 1
                    if io_port.mc_em_addr < 8192:
                        self.loaded_data[i,:] = self.colIndex[io_port.mc_em_addr * 8 : io_port.mc_em_addr * 8 + 8]
                    elif io_port.mc_em_addr < 8256: # row index
                        self.loaded_data[i,0:4] =
                        self.rowIndex[(io_port.mc_em_addr-8192) * 4 :
                                (io_port.mc_em_addr-8192) * 4 + 4] # check with Peter
                    else:
                        self.loaded_data[i,:] = np.zeros(8, dtype=int)
                else: # no store case
                    pass

            if (self.cycles_left[i]==0 and self.waiting_for_bus[i] and !bus_filled):
                bus_filled = 1
                io_port.emem_tag_n = i+1
                io_port.emem_data_n = self.loaded_data[i]
                self.waiting_for_bus[i] = 0
