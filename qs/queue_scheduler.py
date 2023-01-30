import io_port
import numpy as np

class QS:

    def __init__(self):
        self.queue = np.zeros((8, 8, 4), dtype=np.float16)
        self.output_bin = 8
        self.output_row = 4
        self.row_valid = np.zeros((8, 4))


    def one_clock(self):
        # input:
        #   io_port.rowReady
        #   io_port.newDelta
        #   io_port.newIdx
        #   io_port.newValid
        #   io_port.searchValue

        # TODO: update *_n
        io_port.rowDelta_n = io_port.rowDelta
        io_port.binrowIdx_n = io_port.binrowIdx
        io_port.rowValid_n = io_port.rowValid
        io_port.newReady_n = io_port.newReady
        io_port.searchValue_n = io_port.searchValue

    
    
    # read to output_buffer
    def read_row(self, output_ready):
        
    
    # search event for cu given each Idx:
    # if exist in buf, return false, stall cu search
    def search_for_cu(self, searchIdx, searchIdx_buf):
        if searchIdx in searchIdx_buf:
            return False
        else:
            searchIdx_buf.append(searchIdx)

            search_col = searchIdx[0]
            search_bin = searchIdx[1]
            search_row = searchIdx[2]
    
            return self.queue[search_col][search_bin][search_row]

    # write event from cu
    # writing to the same row at the same time not allowed
    def write_from_cu(row):
