import io_port
import numpy as np

# behavior:
# 1. scan for nearest valid from scan_idx
# 2. give that to the output
# 3. update scan_idx to the latest index scanned

# TODO: this queue can only be used with one processor. To use with multiprocessor, need to implement
#       round-based scanning to make sure that only one event per vertex is ever in flight

class EVQ:
    def __init__(self, queue_size):
        self.size = queue_size
        self.valid_queue = np.zeros(queue_size, dtype=int)
        self.delta_queue = np.zeros(queue_size, dtype=np.float16)
        self.scan_idx = 0
    
    def insert_event(self, idx, delta):
        self.valid_queue[idx] = 1
        self.delta_queue[idx] = self.delta_queue[idx] + delta # always try to coalesce

    def remove_event(self, idx):
        self.valid_queue[idx] = 0
        self.delta_queue[idx] = 0
    
    def hold_curr_event(self, port):
        io_port.PEDelta_n[port] = io_port.PEDelta[port]
        io_port.PEValid_n[port] = io_port.PEValid[port]
        io_port.PEIdx_n[port] = io_port.PEIdx[port]
    
    def one_clock(self):
        # insertion
        # assume always ready
        io_port.proReady_n = [1, 1, 1, 1, 1, 1, 1, 1]
        for i in range(0, 8):
            if io_port.proValid[i] == 1:
                self.insert_event(idx=io_port.proIdx[i], delta=io_port.proDelta[i])

        # removal
        for curr_pe_id in range(0, 4):
            if io_port.PEReady[curr_pe_id] == 1:
                # default to invalid
                io_port.PEValid_n[curr_pe_id] = 0
                # scan for next available event
                for i in range(self.scan_idx, self.scan_idx + 256):
                    curr_index = i if i < 256 else (i - 256)
                    if self.valid_queue[curr_index] == 1:
                        # output to io
                        io_port.PEValid_n[curr_pe_id] = 1
                        io_port.PEDelta_n[curr_pe_id] = self.delta_queue[curr_index]
                        io_port.PEIdx_n[curr_pe_id] = curr_index
                        # remove event
                        self.remove_event(curr_index)
                        self.scan_idx = curr_index
                        break
            else:
                self.hold_curr_event(curr_pe_id)
                
                        