import io_port
import numpy as np
from queue import Queue 

class Xbar_SchedToPE:
    
    def __init__(self, num_input = 4, num_output = 4, num_stages = 1):
        self.num_input = num_input
        self.num_output = num_output
        self.freelist = Queue(maxsize=num_output)
        for pe_idx in range(num_output):
            self.freelist.put_nowait(pe_idx)
        self.PEReady_shifter = [np.zeros(num_output) for _ in range(2)]
        self.PEReady_posedge = np.zeros(num_output)
        # self.PE_alloc = np.zeros(num_output)
        self.arb_request = np.zeros(num_output)
        self.arb_mask = np.zeros(num_output)
        for output_idx in range(self.num_output):
            self.arb_mask[output_idx] = 15  # masks are initialized to all 1s
        self.arb_grant = np.zeros(num_output)
        self.num_stages = num_stages
        self.PEDelta_stages = [np.zeros(num_output) for _ in range(num_stages - 1)]
        self.PEIdx_stages = [np.zeros(num_output) for _ in range(num_stages - 1)]
        self.PEValid_stages = [np.zeros(num_output) for _ in range(num_stages - 1)]

    def one_clock(self):
        # input:
        #   io_port.IssDelta
        #   io_port.IssIdx
        #   io_port.IssValid
        #   io_port.PEReady

        # TODO: update *_n

        if self.freelist.empty() == 1:
            io_port.IssReady_n = 0
            io_port.PEDelta_n = 0
            io_port.PEIdx_n = 0
            io_port.PEValid_n = 0
        else:
            
            # Allocate PEs to valid input events
            input_idx = 0
            while self.freelist.empty() == 1 and input_idx < self.num_input:
                
                if io_port.IssValid[input_idx] == 1:
                    PE_alloc = self.freelist.get_nowait()
                    self.arb_request[PE_alloc] = self.arb_request[PE_alloc] | (1 << input_idx)
                    
                input_idx = input_idx + 1
            
            # Propagate through pipeline stages
            if self.num_stages > 1:
                for stage in range(1, self.num_stages):
                    self.PEDelta_stages[self.num_stages - stage] = self.PEDelta_stages[self.num_stages - stage - 1]
                    self.PEIdx_stages[self.num_stages - stage] = self.PEIdx_stages[self.num_stages - stage - 1]
                    self.PEValid_stages[self.num_stages - stage] = self.PEValid_stages[self.num_stages - stage - 1]
            
            # Input Switches
            
            # Clear requests in the previous cycle
            self.arb_request = np.zeros(self.num_output)    
            # Iterate through the inputs and route the requests to output channels
            for input_ch in range(self.num_input):
                if io_port.proValid[input_ch] == 0:
                    continue
                # Bin index decides output channel
                bin_idx = ((io_port.proIdx[input_ch] & (7 << 2)) >> 2)
                self.arb_request[bin_idx] = self.arb_request[bin_idx] | (1 << input_ch)
            
            # Output Arbiters
            
            # Clear grants in the previous cycle
            self.arb_grant = np.zeros(self.num_output)
            # Iterate through the outputs and arbitrate
            for output_ch in range(self.num_output):
                
                if self.arb_request[output_ch] == 0:
                    continue
                
                masked = self.arb_mask[output_ch] & self.arb_request[output_ch]
                shifted = 0
                if masked == 0:
                    shifted = self.arb_request[output_ch]
                else:
                    shifted = masked
                    
                for req_idx in range(self.num_input):
                    if shifted & 1 == 1:
                        self.arb_grant[output_ch] = 1 << req_idx
                        break
                    else:
                        shifted = shifted >> 1
                        
            # Transmit Inputs to Outputs
            io_port.IssReady_n = 0
            for output_ch in range(self.num_output):
                if self.arb_grant[output_ch] == 0:
                    continue
                else:
                    for input_ch in range(self.num_input):
                        if self.arb_grant[input_ch] & 1 == 1:
                            self.PEDelta_stages[0][output_ch] = io_port.proDelta[input_ch]
                            self.PEIdx_stages[0][output_ch] = io_port.proIdx[input_ch]
                            self.PEValid_stages[0][output_ch] = 1
                            io_port.IssReady_n[input_ch] = 1
                            break
                        
            io_port.PEDelta_n = self.PEDelta_stages[self.num_stages - 1]
            io_port.PEIdx_n = self.PEIdx_stages[self.num_stages - 1]
            io_port.PEValid_n = self.PEValid_stages[self.num_stages - 1]
        
        # Insert new available PE index to the freelist
        for pe_idx in range(self.num_output):
            self.PEReady_shifter[pe_idx][1] = self.PEReady_shifter[pe_idx][0]
            self.PEReady_shifter[pe_idx][0] = io_port.PEReady[pe_idx]
            self.PEReady_posedge[pe_idx] = ((self.PEReady_shifter[0] == 1) and (self.PEReady_shifter[1] == 0))
            if self.PEReady_posedge[pe_idx] == True:
                self.freelist.put_nowait(pe_idx)
        

class Xbar_PEToQ:
    
    def __init__(self, num_input = 8, num_output = 8, num_stages = 1):
        self.num_input = num_input
        self.num_output = num_output
        self.arb_request = np.zeros(num_output)
        self.arb_mask = np.zeros(num_output)
        for output_idx in range(self.num_output):
            self.arb_mask[output_idx] = 15  # masks are initialized to all 1s
        self.arb_grant = np.zeros(num_output)
        self.num_stages = num_stages
        self.CUDelta_stages = [np.zeros(num_output) for _ in range(num_stages - 1)]
        self.CUIdx_stages = [np.zeros(num_output) for _ in range(num_stages - 1)]
        self.CUValid_stages = [np.zeros(num_output) for _ in range(num_stages - 1)]
        io_port.proReady = 0
        io_port.CUDelta = 0
        io_port.CUIdx = 0
        io_port.CUValid = 0

    def one_clock(self):
        # input:
        #   io_port.proDelta
        #   io_port.proIdx
        #   io_port.proValid
        #   io_port.CUReady

        # TODO: update *_n
        
        # Propagate through pipeline stages
        if self.num_stages > 1:
            for stage in range(1, self.num_stages):
                self.CUDelta_stages[self.num_stages - stage] = self.CUDelta_stages[self.num_stages - stage - 1]
                self.CUIdx_stages[self.num_stages - stage] = self.CUIdx_stages[self.num_stages - stage - 1]
                self.CUValid_stages[self.num_stages - stage] = self.CUValid_stages[self.num_stages - stage - 1]
        
        # Input Switches
        
        # Clear requests in the previous cycle
        self.arb_request = np.zeros(self.num_output)    
        # Iterate through the inputs and route the requests to output channels
        for input_ch in range(self.num_input):
            if io_port.proValid[input_ch] == 0:
                continue
            # Bin index decides output channel
            bin_idx = ((io_port.proIdx[input_ch] & (7 << 2)) >> 2)
            self.arb_request[bin_idx] = self.arb_request[bin_idx] | (1 << input_ch)
        
        # Output Arbiters
        
        # Clear grants in the previous cycle
        self.arb_grant = np.zeros(self.num_output)      
        # Iterate through the outputs and arbitrate
        for output_ch in range(self.num_output):
            
            if self.arb_request[output_ch] == 0:
                continue
            
            masked = self.arb_mask[output_ch] & self.arb_request[output_ch]
            shifted = 0
            if masked == 0:
                shifted = self.arb_request[output_ch]
            else:
                shifted = masked
                
            for req_idx in range(self.num_input):
                if shifted & 1 == 1:
                    self.arb_grant[output_ch] = 1 << req_idx
                    break
                else:
                    shifted = shifted >> 1
                    
        # Transmit Inputs to Outputs
        io_port.proReady_n = 0
        for output_ch in range(self.num_output):
            if self.arb_grant[output_ch] == 0:
                continue
            else:
                for input_ch in range(self.num_input):
                    if self.arb_grant[input_ch] & 1 == 1:
                        self.CUDelta_stages[0][output_ch] = io_port.proDelta[input_ch]
                        self.CUIdx_stages[0][output_ch] = io_port.proIdx[input_ch]
                        self.CUValid_stages[0][output_ch] = 1
                        io_port.proReady_n[input_ch] = 1
                        break
                
        io_port.CUDelta_n = self.CUDelta_stages[self.num_stages - 1]
        io_port.CUIdx_n = self.CUIdx_stages[self.num_stages - 1]
        io_port.CUValid_n = self.CUValid_stages[self.num_stages - 1]