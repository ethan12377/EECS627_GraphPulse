import io_port
import numpy as np

from RoundRobinArbiter import RoundRobinArbiter
from priority_encoder import Priority_Encoder


class QS:
    def __init__(self):
        self.queue = np.zeros((8, 4, 8), dtype=np.float16)
        self.rowValid_matrix = np.zeros((8, 4), dtype=np.uint8)
        # init bin arbiter
        self.RRArbiter = RoundRobinArbiter(8)
        # init priority encoder
        self.prior_encoder = Priority_Encoder()
        self.reading_bin_n = 0
        # state:
        # 0 for Initial
        # 1 for CU
        # 2 for chosen as next reading_bin but waiting for CU clean
        # 3 for output buffer


    def one_clock(self):
        # input:
        #   io_port.rowReady
        #   io_port.newDelta
        #   io_port.newIdx
        #   io_port.newValid
        #   io_port.searchValue

        # TODO: update *_n
        # io_port.rowDelta_n = io_port.rowDelta
        # io_port.binrowIdx_n = io_port.binrowIdx
        # io_port.rowValid_n = io_port.rowValid
        # io_port.newReady_n = io_port.newReady
        # io_port.searchValue_n = io_port.searchValue

        # init first reading_bin:
        for i in range(len(io_port.state)):
            if(io_port.state[i] == 0):
                io_port.queue_empty_n= 0
                self.write_from_cu(i)
                if(io_port.initialFinish):
                    if(i == 0):
                        if (io_port.cuclean[i]):
                            io_port.state_n[i] = 3
                        else:
                            io_port.state_n[i] = 2
                        self.RRArbiter.request(np.ones((8), dtype=np.int8))    
                    else:
                        io_port.state_n[i] = 1
                else:
                    io_port.state_n[i] = 0
            elif(io_port.state[i] == 1):
                # io_port.newReady_n[i] = 1
                self.search_for_event(i)
                self.write_from_cu(i)
            elif(io_port.state[i] == 2):
                # io_port.newReady_n[i] = 1
                self.search_for_event(i)
                self.write_from_cu(i)
                if(io_port.cuclean[i]):
                    io_port.state_n[i] = 3
                else:
                    io_port.state_n[i] = 2
            elif(io_port.state[i] == 3):
                # read invalid row
                # io_port.newReady_n[i] = 0
                self.read_row(i)
                # if the bin is empty now, change to another bin
                binValid = self.bin_valid_cal(self.rowValid_matrix)
                if(binValid[i] == 0):
                    (self.reading_bin_n, reading_bin_n_valid) = self.RRArbiter.request(binValid)
                    if(reading_bin_n_valid):
                        io_port.state_n[i] = 1
                        if io_port.cuclean[self.reading_bin_n]:
                            #if cu is already clean for this bin, enter read_row
                            #otherwise, wait until cuclean
                            io_port.state_n[self.reading_bin_n] = 3
                        else:
                            io_port.state_n[self.reading_bin_n] = 2
                    else:
                        print(f"all bin empty, finish!!")
                        io_port.queue_empty_n = 1
                else:
                    io_port.state_n[i] = 3
            else:
                print(f"undefined state!!")

    # read to output_buffer
    def read_row(self, bin_idx):
        if io_port.cuclean[bin_idx]:
            if(io_port.rowReady): 
                # select row
                read_rowidx_n = self.prior_encoder.priority(self.rowValid_matrix[bin_idx][:])
                io_port.binrowIdx_n = bin_idx * 4 + read_rowidx_n
                io_port.rowDelta_n = np.copy(self.queue[:][bin_idx][read_rowidx_n])
                io_port.rowValid_n = self.rowValid_matrix[bin_idx][read_rowidx_n]
                if(io_port.rowValid_n == 0):
                    print(f"read invalid row!!")
                # remove after read
                self.rowValid_matrix[bin_idx, read_rowidx_n] = 0
                self.queue[bin_idx, read_rowidx_n, :] = np.zeros(8, dtype=np.float16)
            else:
                io_port.rowValid_n = 0

        else:
            # cu is not clean yet
            print(f"wrong state!! cu not clean yet!! cannot read_row")
            io_port.rowValid_n = 0


    # write event from each cu
    def write_from_cu(self,bin_idx):
        [write_bin, write_row, write_col] = self.idx_trans(io_port.newIdx[bin_idx])
        if io_port.newValid[bin_idx]:
            if (bin_idx == write_bin):
                self.queue[write_bin][write_row][write_col] = io_port.newDelta[bin_idx]
                self.rowValid_matrix[write_bin][write_row] = 1
            else:
                print(f"write other bins!!")
    
    def idx_trans(self, idx):
        col = int(idx //32)
        bin = int((idx - col*32) // 4)
        row = int(idx - col*32 - bin *4)
        return [bin, row, col]

    # search/read event for each cu given Idx:
    def search_for_event(self, bin_idx):
        io_port.searchValueValid_n[bin_idx] = 0
        [search_bin, search_row, search_col] = self.idx_trans(io_port.searchIdx[bin_idx])
        if(io_port.searchValid[bin_idx]):
            if(bin_idx == search_bin):
                io_port.searchValue_n[bin_idx] = self.queue[search_bin][search_row][search_col]
                io_port.searchValueValid_n[bin_idx] = 1
            else:
                print(f"search_bin: ", {search_bin})
                print(f"searchValid[bin_idx]:", {bin_idx})
                print(f"search other bins!!")

    #check whether bins are valid
    def bin_valid_cal(self, rowValid_matrix:np.ndarray):
        rowValid = np.zeros((4))
        binValid = np.zeros((8))
        for i in range(rowValid_matrix.shape[0]):
            rowValid = rowValid_matrix[i][:] 
            if rowValid.any():
                binValid[i] = 1
        return binValid