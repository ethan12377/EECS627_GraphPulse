import io_port
import numpy as np

class EVQ:
    def __init__(self, num_of_cores):
        self.valid_queue = np.zeros(256, dtype=int)
        self.delta_queue = np.zeros(256, dtype=np.float16)
        self.empty = 1
        self.scan_idx = 0
        self.waiting_for_pe = 1 # at startup, wait for all pe to be ready (complete initialization)
        self.num_of_cores = num_of_cores
    
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
        # reactivation for multicore and single core
        # comment one of them out
        if self.waiting_for_pe == 1 and all(ready == 1 for ready in io_port.PEReady[0:self.num_of_cores]):
        # if self.waiting_for_pe == 1 and io_port.PEReady[0] == 1:
            self.waiting_for_pe = 0
            self.scan_idx = 0
        
        # insertion
        # assume always ready
        io_port.proReady_n = [1, 1, 1, 1, 1, 1, 1, 1]
        for i in range(0, 8):
            if io_port.proValid[i] == 1:
                self.insert_event(idx=io_port.proIdx[i], delta=io_port.proDelta[i])

        # removal
        for curr_pe_id in range(0, 4):
            if io_port.PEReady[curr_pe_id] == 1:
                if self.waiting_for_pe == 0: # active scanning. output new event to pe if found
                    # default to invalid
                    io_port.PEValid_n[curr_pe_id] = 0
                    io_port.PEDelta_n[curr_pe_id] = 0
                    io_port.PEIdx_n[curr_pe_id] = 0
                    # scan for next nearest available event until the end of queue
                    for curr_index in range(self.scan_idx, 256):
                        self.scan_idx = curr_index
                        if self.valid_queue[curr_index] == 1:
                            # output to io
                            io_port.PEValid_n[curr_pe_id] = 1
                            io_port.PEDelta_n[curr_pe_id] = self.delta_queue[curr_index]
                            io_port.PEIdx_n[curr_pe_id] = curr_index
                            # remove event
                            self.remove_event(curr_index)
                            # increment scan idx for next scan
                            self.scan_idx += 1
                            break
                    # check if reaching the end of scanning
                    if self.scan_idx >= 255:
                        self.waiting_for_pe = 1
                else: # not scanning. invalidate current outputs
                    io_port.PEValid_n[curr_pe_id] = 0
                    io_port.PEDelta_n[curr_pe_id] = 0
                    io_port.PEIdx_n[curr_pe_id] = 0
            else:
                self.hold_curr_event(curr_pe_id)
        
        # update empty
        if all(v == 0 for v in self.valid_queue):
            self.empty = 1
        else: 
            self.empty = 0
                
                        