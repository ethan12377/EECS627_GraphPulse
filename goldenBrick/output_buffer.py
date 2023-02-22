import io_port
import numpy as np
from collections import deque
import copy

class OB:

    def __init__(self, num_col = 8, num_output = 4, depth = 16, num_fifo_in = 4):
        
        self.num_col = num_col
        self.num_output = num_output
        self.depth = depth
        self.num_fifo_in = num_fifo_in
        self.fifo_in_cycle = np.ceil(num_col / num_fifo_in)
        
        self.offset = np.zeros(self.num_col, dtype=np.uint8)
        self.buf_Delta = np.zeros(self.num_col, dtype=np.float16)
        self.buf_Idx = np.zeros(self.num_col, dtype=np.uint8)
        self.buf_Valid = np.uint8(0)
        self.buf_Delta_n = np.zeros(self.num_col, dtype=np.float16)
        self.buf_Idx_n = np.zeros(self.num_col, dtype=np.uint8)
        self.buf_Valid_n = np.uint8(0)
        
        self.fifo_Delta = deque(maxlen=self.depth)
        self.fifo_Idx = deque(maxlen=self.depth)
        
        self.fifo_Delta_n = deque(maxlen=self.depth)
        self.fifo_Idx_n = deque(maxlen=self.depth)

        self.fifo_in_cnt = np.uint8(0)
        self.fifo_in_cnt_n = np.uint8(0)
        

    def one_clock(self):
        # input:
        #   io_port.rowDelta
        #   io_port.binrowIdx
        #   io_port.rowValid
        #   io_port.IssReady

        # TODO: update *_n
        
        self.offset = np.zeros(self.num_col, dtype=np.uint8)
        self.buf_Delta_n = copy.deepcopy(self.buf_Delta)
        self.buf_Idx_n = copy.deepcopy(self.buf_Idx)
        self.buf_Valid_n = copy.deepcopy(self.buf_Valid)
        
        self.fifo_Delta_n = copy.deepcopy(self.fifo_Delta)
        self.fifo_Idx_n = copy.deepcopy(self.fifo_Idx)

        io_port.rowReady_n = np.uint8(0)
        
        # Assign the oldest events to the output
        for output_idx in range(self.num_output):
            if output_idx < len(self.fifo_Delta):
                io_port.IssDelta[output_idx] = copy.deepcopy(self.fifo_Delta[output_idx])
                io_port.IssIdx[output_idx] = copy.deepcopy(self.fifo_Idx[output_idx])
                io_port.IssValid[output_idx] = np.uint8(1)
            else:
                io_port.IssDelta[output_idx] = np.float16(0)
                io_port.IssIdx[output_idx] = np.uint8(0)
                io_port.IssValid[output_idx] = np.uint8(0)
                
        # Pop events from the queue is handshake success
        for output_idx in range(self.num_output):
            if io_port.IssValid[output_idx] == 1 and io_port.IssReady[output_idx] == 1:
                self.fifo_Delta_n.popleft()
                self.fifo_Idx_n.popleft()
            else:
                break
                
        if len(self.fifo_Delta) < (self.depth - self.num_fifo_in):
            # Insert bubble free events into the fifo
            if self.buf_Valid == 1:
                for col_idx in range(self.fifo_in_cnt*self.num_fifo_in, (self.fifo_in_cnt + 1) *self.num_fifo_in):
                    if self.buf_Delta[col_idx] != 0:
                        self.fifo_Delta_n.append(self.buf_Delta[col_idx])
                        self.fifo_Idx_n.append(self.buf_Idx[col_idx])

                if self.fifo_in_cnt == self.fifo_in_cycle - 1:
                    self.fifo_in_cnt_n = np.uint8(0)
                    self.buf_Valid_n = np.uint8(0)
                else:
                    self.fifo_in_cnt_n = self.fifo_in_cnt + 1
                        
        # Get row data from scheduler and remove bubbles
        if io_port.rowValid == 1 and io_port.rowReady == 1:
            print('handshake')
            self.buf_Valid_n = np.uint8(0)
            for col_idx in range(self.num_col):
                if col_idx < (self.num_col - 1):
                    if io_port.rowDelta[col_idx] == 0:
                        self.offset[col_idx + 1] = self.offset[col_idx] + 1
                    else:
                        self.offset[col_idx + 1] = copy.deepcopy(self.offset[col_idx])
                self.buf_Delta_n[col_idx - self.offset[col_idx]] = io_port.rowDelta[col_idx]
                self.buf_Idx_n[col_idx - self.offset[col_idx]] = col_idx + (io_port.binrowIdx * self.num_col)
                self.buf_Valid_n = np.uint8(1)
                print('offset[', col_idx, '] = ', self.offset[col_idx])
        
        # Assert rowReady signal
        if self.buf_Valid_n == 0:
            io_port.rowReady_n = np.uint8(1)
                        
        self.print_signals()
                
    def update(self):
        self.fifo_Delta = copy.deepcopy(self.fifo_Delta_n)
        self.fifo_Idx = copy.deepcopy(self.fifo_Idx_n)
        self.buf_Delta = copy.deepcopy(self.buf_Delta_n)
        self.buf_Idx = copy.deepcopy(self.buf_Idx_n)
        self.buf_Valid = copy.deepcopy(self.buf_Valid_n)
        self.fifo_in_cnt = copy.deepcopy(self.fifo_in_cnt_n)
        
    def print_signals(self):
        
        #   io_port.rowDelta
        #   io_port.binrowIdx
        #   io_port.rowValid
        #   io_port.IssReady
        print('binrowIdx = ', io_port.binrowIdx, '\trowValid = ', io_port.rowValid, '\trowReady = ', io_port.rowReady, '\trowDelta = ', np.around(io_port.rowDelta, 3))
        print('buf_Valid = ', self.buf_Valid, '\tbuf_Idx = ', self.buf_Idx, '\tbuf_Delta = ', np.around(self.buf_Delta,3))
        print('fifo_Idx = ', self.fifo_Idx, '\tfifo_Delta = ', self.fifo_Delta)
        # for i in range(self.num_output):
        #     print('IssDelta[',i,'] = ', np.around(io_port.IssDelta[i], 3),'\tIssIdx[', i, '] = ', io_port.IssIdx[i], '\tIssValid[', i, '] = ', io_port.IssValid[i], '\tIssReady[', i, '] = ', io_port.IssReady[i])
        
            