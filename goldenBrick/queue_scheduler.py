import io_port
import copy
import numpy as np

from RoundRobinArbiter import RoundRobinArbiter


class QS:
    def __init__(self):

        self.queue = np.zeros((8, 4, 8), dtype=np.float16)
        self.rowValid_matrix = np.zeros((8, 4), dtype=np.uint8)
        # init bin arbiter
        self.RRArbiter = RoundRobinArbiter(8)
        # init priority encoder
        self.reading_bin = 0
        self.reading_bin_n = 0
        self.readen = 0
        self.readen_n = 0
        # state:
        # I for Initial
        # C for search and write event from CU
        # B for bin selected
        # W for selected_bin waiting for CU clean
        # R for selected_bin reading

        self.qs_state = 'I'
        self.qs_state_n = 'I'

        self.binValid = np.zeros((8), dtype=np.uint8)
        self.binValid_n = np.zeros((8), dtype=np.uint8)


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
        self.reading_bin = copy.deepcopy(self.reading_bin_n)
        self.readen = copy.deepcopy(self.readen_n)
        self.qs_state = copy.deepcopy(self.qs_state_n)
        self.binValid = self.binValid_n

        self.update_qs_state()

        for i in range(8):
            self.bin_func(i)




    def update_qs_state(self):
        # initial state
        if not io_port.initialFinish:
            self.qs_state_n = self.qs_state
        else:
            io_port.queue_empty_n = 0
            self.readen_n = self.readen
            if (self.qs_state == 'I'):
                # initial finish
                self.qs_state_n = 'C' #CU
            elif (self.qs_state == 'C'):
                (self.reading_bin_n, reading_bin_n_valid) = self.RRArbiter.request(self.binValid)
                # if new bin selected, enter W or R state
                if (reading_bin_n_valid):
                    self.qs_state_n = 'B'
                    # update binselected
                    io_port.binselected_n = np.zeros((8),dtype=np.uint8)
                    io_port.binselected_n[self.reading_bin_n] = 1
                else:
                    # if no bin selected, all bin empty stay in C state
                    self.qs_state_n = self.qs_state
                    io_port.binselected_n = np.zeros((8),dtype=np.uint8)
                    io_port.queue_empty_n = 1
            elif (self.qs_state == 'B'):
                    self.qs_state_n = 'W'

            elif (self.qs_state == 'W'):
                if io_port.cuclean[self.reading_bin]:
                    self.qs_state_n = 'R'
                    self.readen_n = 1
                else:
                    self.qs_state_n = self.qs_state
            elif (self.qs_state == 'R'):
                # if the bin is empty now, change to 'C' state

                if(self.binValid[self.reading_bin] == 0):
                    self.qs_state_n = 'C'
                    self.readen_n = 0
                else:
                    self.qs_state_n = self.qs_state

            else:
                print('no such state!!!')

    def bin_func(self, bin_idx):
        # if bin_selected and readen, read to outputbuffer
        # otherwise, do nothing and wait
        if (io_port.binselected[bin_idx]) and (self.readen):
            self.read_row(bin_idx)
        # if bin not selected, search and write with cu
        else:
            self.search_for_event(bin_idx)
            self.write_from_cu(bin_idx)

        self.binValid_n = self.bin_valid_cal(self.rowValid_matrix)

    # read to output_buffer
    def read_row(self, bin_idx):
        if io_port.cuclean[bin_idx]:
            if(io_port.rowReady):
                # select row
                read_rowidx_n = self.prior_encoder(self.rowValid_matrix[bin_idx][:])
                if (read_rowidx_n == 4):# return invalid row, all row empty
                    io_port.binrowIdx_n = 0
                    io_port.rowDelta_n = 0
                    io_port.rowValid_n = 0
                else:
                    io_port.binrowIdx_n = bin_idx * 4 + read_rowidx_n
                    io_port.rowDelta_n = np.copy(self.queue[:][bin_idx][read_rowidx_n])
                    io_port.rowValid_n = self.rowValid_matrix[bin_idx][read_rowidx_n]
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
        row = int(idx //64)
        bin = int((idx - row*64) // 8)
        col = int(idx - row*64 - bin *8)
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
        rowValid_array = np.zeros((4))
        binValid_array = np.zeros((8))
        for i in range(rowValid_matrix.shape[0]):
            rowValid_array = rowValid_matrix[i][:]
            if rowValid_array.any():
                binValid_array[i] = 1
        return binValid_array

    def prior_encoder(self, rowValid_array):
        for i in range(len(rowValid_array)):
            if (rowValid_array[i]):
                return i
        return 4
