import io_port
import numpy as np

from RoundRobinArbiter import RoundRobinArbiter
from priority_encoder import Priority_Encoder


class QS:
    def __init__(self):
        self.queue = np.zeros((8, 8, 4), dtype=np.float16)
        self.rowValid_matrix = np.zeros((8, 4))

        # init bin arbiter
        self.RRArbiter = RoundRobinArbiter(8)
        # init priority encoder
        self.prior_encoder = Priority_Encoder()

        self.reading_bin_n = 0
        self.reading_row_n = 0
        # ???
        self.reading_bin = 0

        # 0 for output buffer
        # 1 for CU
        # 2 for chosen as next reading_bin but waiting for CU clean
        self.state = np.zeros((8))
        self.state_n = np.zeros((8))

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
        
        self.state = self.state_n
        for i  in range(len(self.state)):

            if(self.state[i] == 1):
                self.search_for_event(io_port.searchIdx[i])
                self.write_from_cu(i)

            elif((self.state[i] == 0)):
                self.read_row(i, io_port.cuclean[i])
                # if the bin is empty now, change to another bin
                binValid = self.bin_valid_cal(self.rowValid_matrix)
                if binValid[i] == 0:
                    (self.reading_bin_n, reading_bin_n_valid) = self.RRArbiter.request(binValid)
                    if reading_bin_n_valid:
                        self.state_n[i] = 1
                        if io_port.cuclean[[self.reading_bin_n]]:
                            #if cu is already clean for this bin, enter read_row
                            #otherwise, wait until cuclean
                            self.state_n[self.reading_bin_n] = 0
                        else:
                            self.state_n[self.reading_bin_n] = 2
                    else:
                        print(f"all bin clean, finish!!")

            elif((self.state[i] == 2)):
                #need to deal with the situation that cu is not 
                self.search_for_event(io_port.searchIdx[i])
                self.write_from_cu(i)
                # Once the cu is clean, change to read_row state
                if io_port.cuclean[[i]]:
                    self.state_n[self.reading_bin_n] = 0
            else:
                print(f"undefined state!!")



    # read to output_buffer
    def read_row(self, bin_idx,cuclean):
        if cuclean:
           if(io_port.rowReady): 
            # select row
            read_rowidx_n = self.prior_encoder.priority(self.rowValid_matrix[bin_idx][:])
            io_port.binrowIdx_n = bin_idx * 4 + read_rowidx_n
            io_port.rowDelta_n = self.queue[:][bin_idx][read_rowidx_n]
             # remove after read
            self.rowValid_matrix[bin_idx, read_rowidx_n] = 0
            self.queue[:][bin_idx][read_rowidx_n] = np.zeros(8, dtype=np.float16)
        else:
            # cu is not clean yet
            print(f"wrong state!! cu not clean yet!! cannot read_row")



    
    
    # search/read event for each cu given Idx:
    def search_for_event(self, eventIdx):
        [search_col, search_bin, search_row] = self.idx_trans(eventIdx)
        io_port.searchValue_n[search_bin] = self.queue[search_col][search_bin][search_row]


    # write event from each cu
    # do we need new_ready anymore???
    def write_from_cu(self,bin_idx):
        [write_col, write_bin, write_row] = self.idx_trans(io_port.newIdx[bin_idx])
        io_port.newReady_n[bin_idx] == 1
        if io_port.newValid[bin_idx]:
            self.queue[write_col][write_bin][write_row] = io_port.newDelta[bin_idx]

                
    def idx_trans(self, idx):
        col = int(idx //32)
        bin = int((idx - col*32) // 4)
        row = int(idx - col*32 - bin *4)
        return [col, bin, row]
    
    def bin_valid_cal(self, rowValid_matrix:np.ndarray):
        rowValid = np.zeros((4))
        binValid = np.zeros((8))
        for i in range(rowValid_matrix.shape[0]):
            rowValid = rowValid_matrix[i][:] 
            if rowValid.any():
                binValid[i] = 1
        return binValid


    # print function
    # print("i = ", i)
    # new_write_Idx[i][0] = int(io_port.newIdx[i] // 32)
    # print("column = ",new_write_Idx[i][0])
    # new_write_Idx[i][1] = int((io_port.newIdx[i] - new_write_Idx[i][0]*32) // 4)
    # print("bin = ",new_write_Idx[i][1])
    # new_write_Idx[i][2] = int(io_port.newIdx[i] - new_write_Idx[i][0]*32 - new_write_Idx[i][1] *4)
    # print("row = ",new_write_Idx[i][2])