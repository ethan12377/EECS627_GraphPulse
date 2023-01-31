import io_port
import numpy as np
# import sys
# sys.path.append('../../Qscheduler')
# import error
from Qscheduler.RoundRobinArbiter import RoundRobinArbiter
from Qscheduler.priority_encoder import Priority_Encoder

class QS:

    def __init__(self):
        self.queue = np.zeros((8, 8, 4), dtype=np.float16)
        self.rowValid_matrix = np.zeros((8, 4))
        # init read row parameters
        self.rowDelta = np.zeros((8), dtype=np.float16)
        self.binrowIdx = [8,4] #[bin, row]
        self.rowValid = 0
        self.rowDelta_n = np.zeros((8), dtype=np.float16)
        self.binrowIdx_n = []
        self.rowValid_n = 0
        # init row arbiter for each bin
        for i in range(8):
            self._RRArbiter[i] = RoundRobinArbiter(4) # error here
        # init priority encoder
        self.prior_encoder = Priority_Encoder()

        # search_buf
        self.searchIdx_buf = []

        


    def one_clock(self):
        # input:
        #   io_port.rowReady
        #   io_port.newDelta
        #   io_port.newIdx
        #   io_port.newValid
        #   io_port.searchIdx
        QS.read_row()
        QS.search_for_cu()
        QS.write_from_cu()

        # TODO: update *_n
        # io_port.rowDelta_n = io_port.rowDelta
        # io_port.binrowIdx_n = io_port.binrowIdx
        # io_port.rowValid_n = io_port.rowValid
        # io_port.newReady_n = io_port.newReady
        # io_port.searchValue_n = io_port.searchValue

    
    
    # read to output_buffer
    def read_row(self):
        # select bin
        self.prior_encoder.priority(self.rowValid_matrix)
        read_binidx = self.prior_encoder.priority_bin
        # select row
        read_rowidx = self.RRArbiter[read_binidx].request(self.rowValid_matrix[read_binidx, :])
        if io_port.rowReady:
            self.rowDelta_n = self.queue[:][read_binidx][read_rowidx]
            self.binrowIdx_n = [read_binidx, read_rowidx]
            self.rowValid_n = 1
        else:
            self.rowValid_n = 0


    
    # search/read event for cu given each Idx:
    # if exist in buf, return false, stall cu search
    def search_for_event(self, eventIdx):
        if eventIdx in self.searchIdx_buf:
            return False
        else:
            self.searchIdx_buf.append(eventIdx)
            search_col = eventIdx[0]
            search_bin = eventIdx[1]
            search_row = eventIdx[2]    
            return self.queue[search_col][search_bin][search_row]
    
    def search_for_cu(self):
        for idx in io_port.searchIdx:
            event = QS.search_for_event(idx)
            if event: 
                io_port.searchValue_n = event
            else:
                #how to stall if event is false
                io_port.searchValue_n = False



    # write event from cu
    # writing to the same row at the same time not allowed
    def write_from_cu(self):
        
        for i in range(8):
            if io_port.newValid[i]:
                # if the bin is read by outputbuf or cu, write need to stall
                if io_port.newIdx[i][0] == io_port.binrowIdx or io_port.newIdx[i][0] in io_port.searchIdx[:][1]:
                    io_port.newReady_n[i] == 0
                    io_port.newDelta_n[i] = io_port.newDelta[i]
                    io_port.newIdx_n[i] = io_port.newIdx[i]
                    io_port.newValid_n[i] = io_port.newValid[i]
                # if the bin is not being read, write to array
                else:
                    self.queue[io_port.newIdx[i]] = io_port.newDelta[i]
                    io_port.newReady_n[i] == 1
                    if io_port.newIdx[i] in self.searchIdx_buf:
                        self.searchIdx_buf.remove(io_port.newIdx[i])
            else:
                io_port.newReady_n[i] == 1



