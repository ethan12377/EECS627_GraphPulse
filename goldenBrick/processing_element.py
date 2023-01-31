import io_port
import numpy as np

class PE:

    def __init__(self, pe_id, fpu_pipe_depth):
        self.pe_id = pe_id # use id to differentiate the four pes
        self.status = 0 # default to idle on startup
        self.threshold = 0.1 # TODO: should set a global variable for this
        self.fpu_pipe_depth = fpu_pipe_depth
        self.fpu_value_pipe = np.zeros(fpu_pipe_depth + 1, dtype=np.float16) # TODO: this should be parametrized to match the verilog
        self.fpu_valid_pipe = np.zeros(fpu_pipe_depth + 1)

        # write internal nets to default values (all zeros)
        io_port.PEReady_n = io_port.PEReady
        io_port.proDelta_n = io_port.proDelta
        io_port.proIdx_n = io_port.proIdx
        io_port.proValid_n = io_port.proValid
        io_port.reqAddr_n = io_port.reqAddr

    def one_clock(self):

        # take input from output buffer crossbar if valid and ready
        if io_port.PEValid[self.pe_id] != 0 and self.status == 0:
            curr_delta = io_port.PEDelta[self.pe_id]
            curr_idx = io_port.PEIdx[self.pe_id]
            self.fpu_value_pipe[0] = curr_delta + curr_value
            # set status to busy
            self.status = 1
            # request current vertex value from cache
            # TODO: determine cache organization
            # if curr_delta > self.threshold:
            # request current vertex adjacency list
            

        # pipelined fpu
        # TODO: pipeline index through as well
        for i in range(self.fpu_pipe_depth-1, -1, -1):
            self.fpu_value_pipe[i+1] = self.fpu_value_pipe[i]
            self.fpu_valid_pipe[i+1] = self.fpu_valid_pipe[i]

        # input:
        #   io_port.PEDelta
        #   io_port.PEIdx
        #   io_port.PEValid
        #   io_port.proReady
        #   io_port.edgeResp
        #   io_port.edgeValid
        #   io_port.edgeEnd
        #   io_port.vertResp
        #   io_port.vertValid

        # TODO: update *_n
        io_port.PEReady_n[self.pe_id] = self.status
        io_port.proDelta_n = self.fpu_value_pipe[self.fpu_pipe_depth]
        io_port.proIdx_n = io_port.proIdx
        io_port.proValid_n = self.fpu_valid_pipe[self.fpu_pipe_depth]
        io_port.reqType_n = io_port.reqType # TODO: combinational output to mem?
        io_port.reqAddr_n = io_port.reqAddr