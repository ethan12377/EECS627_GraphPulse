import io_port
import numpy as np

from RoundRobinArbiter import RoundRobinArbiter
from priority_encoder import Priority_Encoder


class QS:

    def __init__(self):
        self.queue = np.zeros((8, 8, 4), dtype=np.float16)
        self.rowValid_matrix = np.zeros((8, 4))
        self.RRArbiter = []
        # init priority encoder
        self.prior_encoder = Priority_Encoder()
        # init row arbiter for each bin
        for i in range(8):
            # error here
            self.RRArbiter.append(RoundRobinArbiter(4))
        # search_buf
        self.searchIdx_buf = []
        self.reading_bin = 0
        self.reading_bin_n = 0
    
    
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

        
        self.read_row()
        self.search_for_cu()
        self.write_from_cu()

    # read to output_buffer
    def read_row(self):
        self.reading_bin_n = 8 #init reading_bin
        for i in range(self.rowValid_matrix.shape[0]):
            for j in range(self.rowValid_matrix.shape[1]):
                io_port.rowValid_n += self.rowValid_matrix[i][j]
        if(io_port.rowReady):
            # select bin
            self.prior_encoder.priority(self.rowValid_matrix)
            read_binidx_n = self.prior_encoder.priority_bin
            # select row
            read_rowidx_n = self.RRArbiter[read_binidx_n].request(self.rowValid_matrix[read_binidx_n, :])
            # if row valid[0,0,0,0]???
            # if (self.rowValid_matrix[read_binidx_n, read_rowidx_n]):
            io_port.rowDelta_n = self.queue[:][read_binidx_n][read_rowidx_n]
            io_port.binrowIdx_n = read_binidx_n*4 + read_rowidx_n
            # remove after read
            self.rowValid_matrix[read_binidx_n, read_rowidx_n] = 0
            self.queue[:][read_binidx_n][read_rowidx_n] = np.zeros(8, dtype=np.float16)
            self.reading_bin_n = read_binidx_n

    # search/read event for cu given each Idx:
    # if exist in buf, return false, stall cu search
    # need to consider whether the bin is read by read_row at the same cycle
    def search_for_event(self, eventIdx):
        if eventIdx in self.searchIdx_buf:
            return False
        else:
            # change the def of io_port.searchIdx
            self.searchIdx_buf.append(eventIdx)
            search_col = int(eventIdx //32)
            search_bin = int((eventIdx - search_col*32) // 4)
            search_row = int(eventIdx - search_col*32 - search_bin *4)
            if search_bin == self.reading_bin_n:
                return False
            else:
                return self.queue[search_col][search_bin][search_row]

    def search_for_cu(self):
        for idx in io_port.searchIdx:
            event = self.search_for_event(idx)
            if event: 
                io_port.searchValue_n = event
            else:
                #how to stall if event is false???
                #one more valid, ready pair
                io_port.searchValue_n = False
        
    # write event from cu
    # writing to the same row at the same time not allowed
    def write_from_cu(self):
        new_write_Idx = np.zeros((8,3),dtype=int)
        writing_bin_buf = np.zeros((8),dtype=int)
        for i in range(8):
            new_write_Idx[i][0] = int(io_port.newIdx[i] //32)
            new_write_Idx[i][1] = int((io_port.newIdx[i] - new_write_Idx[i][0]*32) // 4)
            new_write_Idx[i][2] = int(io_port.newIdx[i] - new_write_Idx[i][0]*32 - new_write_Idx[i][1] *4)
        for i in range(8):
            # if the bin is read by outputbuf or cu, write need to stall
            self.reading_bin = int(io_port.binrowIdx // 4)
            if new_write_Idx[i][1] == self.reading_bin or new_write_Idx[i][1] in io_port.searchIdx[:][1]:
                io_port.newReady_n[i] == 0
            # if the bin is not being read, write to array
            else:
                io_port.newReady_n[i] == 1
                if io_port.newValid[i]:
                    self.queue[new_write_Idx[i]] = io_port.newDelta[i]
                    if io_port.newIdx[i] in self.searchIdx_buf:
                        self.searchIdx_buf.remove(new_write_Idx[i]) 