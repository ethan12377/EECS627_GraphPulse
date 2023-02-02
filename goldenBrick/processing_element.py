import io_port
import numpy as np
from enum import Enum


class PE:

    def __init__(self, pe_id, fpu_pipe_depth):
        self.pe_id = pe_id # use id to differentiate the four pes
        self.threshold = 0.1 # TODO: should set a global variable for this?

        # FPU parameters
        self.fpu_pipe_depth = fpu_pipe_depth
        self.fpu_value_pipe = np.zeros(fpu_pipe_depth + 1, dtype=np.float16) # TODO: this should be parametrized to match the verilog
        self.fpu_valid_pipe = np.zeros(fpu_pipe_depth + 1)

        # storing values that are being worked on for the current operation
        self.curr_delta = 0
        self.curr_idx = 0
        self.curr_vertex_value_word = np.zeros(4, dtype=np.float16)

        # FSM
        self.states = Enum('states',['IDLE',
                                     'WAIT_ON_MEM_DATA',
                                     'WAIT_ON_FPU_DATA',
                                     'WAIT_ON_FPU_PRODELTA',
                                     'WAIT_ON_MEM_WRITE',
                                     'WAIT_ON_MEM_IDX',
                                     'EVGEN'])
        self.curr_state = self.states.IDLE
        self.next_state = self.states.IDLE

        # start and end for extracting adjacency list
        self.start = 0
        self.end = 0

        # parameters for propagate event generation
        self.curr_evgen_idx = 0
        self.curr_propagate_delta = 0


    def one_clock(self):
        self.curr_state = self.next_state
       
        # pipelined fpu
        for i in range(self.fpu_pipe_depth-1, -1, -1):
            self.fpu_value_pipe[i+1] = self.fpu_value_pipe[i]
            self.fpu_valid_pipe[i+1] = self.fpu_valid_pipe[i]
        
        # default relevant outputs to zero, overwrite if necessary
        io_port.pe_wrEn_n[self.pe_id] = 0
        self.fpu_valid_pipe[0] = 0
        io_port.proValid_n = 0

        #############################
        ### FSM STATES DEFINITION ###
        #############################
        
        # IDLE state
        if self.curr_state == self.states.IDLE:
            if io_port.PEValid[self.pe_id] != 0: # incoming valid event
                io_port.PEReady_n[self.pe_id] = 0
                self.curr_delta = io_port.PEDelta[self.pe_id]
                self.curr_idx = io_port.PEIdx[self.pe_id]
                # send read vertex value request to cc
                io_port.pe_reqAddr_n[self.pe_id] = self.curr_idx / 4
                io_port.pe_wrEn_n[self.pe_id] = 0
                io_port.pe_reqValid_n[self.pe_id] = 1
                self.fpu_valid_pipe[0] = 0
                # set status to busy
                self.next_state = self.states.WAIT_ON_MEM_DATA
            else:
                self.next_state = self.states.IDLE
        
        # WAIT_ON_MEM_DATA state
        if self.curr_state == self.states.WAIT_ON_MEM_DATA:
            if io_port.cc_ready[self.pe_id]:
                # send delta into fpu
                self.curr_vertex_value_word = io_port.cache_rdData[0:4]
                self.fpu_value_pipe[0] = self.curr_vertex_value_word[self.curr_idx % 4] + curr_delta
                self.fpu_valid_pipe[0] = 1
                # check propagation
                if curr_delta < self.threshold: # no propagation
                    self.next_state = self.states.WAIT_ON_FPU_DATA
                else: # propagation. request start and stop values from mem
                    if self.curr_idx % 8 == 7: # will need to request twice
                        # TODO: double request behavior
                        self.next_state = self.states.WAIT_ON_FPU_DATA
                    else:
                        io_port.pe_reqAddr_n = self.curr_idx / 8 + 64
                        io_port.pe_wrEn_n[self.pe_id] = 0
                        io_port.pe_reqValid_n[self.pe_id] = 1
                    self.next_state = self.states.WAIT_ON_MEM_IDX
            else:
                self.fpu_valid_pipe[0] = 0
                self.next_state = self.states.WAIT_ON_MEM_DATA

        # WAIT_ON_MEM_IDX state
        if self.curr_state == self.states.WAIT_ON_MEM_IDX:
            if io_port.cc_ready[self.pe_id]:
                self.start = io_port.cache_rdData[self.curr_idx % 8]
                if not tworeads:
                    self.end = io_port.cache_rdData[self.curr_idx % 8 + 1]
                else:
                    # TODO: implement double read behavior
                    pass
            else:
                self.next_state = self.states.WAIT_ON_MEM_IDX
        
        # WAIT_ON_FPU_DATA state
        if self.curr_state == self.states.WAIT_ON_FPU_DATA:
            if self.fpu_valid_pipe[self.fpu_pipe_depth] == 1:
                # create update request to write to mem
                self.curr_vertex_value_word[self.curr_idx % 4] = self.fpu_value_pipe[self.fpu_pipe_depth]
                io_port.pe_reqAddr_n = self.curr_idx / 4
                io_port.pe_wrEn_n[self.pe_id] = 1
                io_port.pe_reqValid_n[self.pe_id] = 1
                io_port.pe_wrData_n = self.curr_vertex_value_word
                self.next_state = self.states.WAIT_ON_MEM_WRITE
                # check adjacency
                # TODO: it is possible that FPU finishes data before index retrieval is fulfilled?
                if self.end - self.start != 0:
                    # send calculation result into FPU to calculate delta for propagation
                    self.fpu_valid_pipe[0] = 1
                    # TODO: the result of this need to be retrieved from somewhere
                    self.fpu_value_pipe[0] = self.fpu_value_pipe[self.fpu_pipe_depth] / (self.end - self.start)
                    # generate a "clear" event for the current vertex
                    io_port.proDelta_n = 0 - self.fpu_value_pipe[self.fpu_pipe_depth]
                    io_port.proIdx_n = self.curr_idx
                    io_port.proValid_n = 1
                    # transition into event generation after retrieving result from FPU
                    self.next_state = self.states.WAIT_ON_FPU_PRODELTA
                    self.curr_evgen_idx = start
            else:
                self.next_state = self.states.WAIT_ON_FPU_DATA
        
        # WAIT_ON_FPU_PRODELTA state
        if self.curr_state = WAIT_ON_FPU_PRODELTA:
            if self.fpu_valid_pipe[self.fpu_pipe_depth] == 1:
                self.curr_propagate_delta = self.fpu_value_pipe[self.fpu_pipe_depth]
                self.next_state = self.states.EVGEN
            else:
                self.next_state = WAIT_ON_FPU_PRODELTA
        
        # WAIT_ON_MEM_WRITE state
        if self.curr_state == self.states.WAIT_ON_MEM_WRITE:
            if io_port.cc_ready[self.pe_id]:
                self.next_state = self.states.IDLE
                io_port.PEReady_n[self.pe_id] = 1
            else:
                self.next_state = self.states.WAIT_ON_MEM_WRITE
        

        # EVGEN state
        # TODO: evgen should be stalled if downstream queue is not ready to receive a new event yet
        if self.curr_state == self.states.EVGEN:
            if self.curr_evgen_idx < self.stop:
                # generate a event based on current evgen idx
                io_port.proDelta_n = 0 - self.fpu_value_pipe[self.fpu_pipe_depth]
                io_port.proIdx_n = self.curr_evgen_idx
                io_port.proValid_n = 1
                self.curr_evgen += 1
                self.next_state = self.states.EVGEN
            else: # reached the end of evgen
                self.next_state = self.states.IDLE

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
        io_port.proDelta_n = self.fpu_value_pipe[self.fpu_pipe_depth]
        io_port.proIdx_n = io_port.proIdx
        io_port.proValid_n = self.fpu_valid_pipe[self.fpu_pipe_depth]
        io_port.reqType_n = io_port.reqType # TODO: combinational output to mem?
        io_port.reqAddr_n = io_port.reqAddr