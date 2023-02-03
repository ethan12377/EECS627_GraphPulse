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
        self.curr_vertex_value_word_ready = 0

        # FSM
        self.states = Enum('states',['IDLE',
                                     'WAIT_ON_MEM_DATA',
                                     'WAIT_ON_FPU_DATA',
                                     'WAIT_ON_FPU_DATA_ONLY'
                                     'WAIT_ON_FPU_PRODELTA',
                                     'WAIT_ON_MEM_WRITE',
                                     'WAIT_ON_FPU_AND_MEM_IDX',
                                     'EVGEN',
                                     'EVGEN_PAUSE'])
        self.curr_state = self.states.IDLE
        self.next_state = self.states.IDLE

        # start and end for extracting adjacency list
        self.start = 0
        self.end = 0
        self.start_ready = 0
        self.end_ready = 0

        # parameters for propagate event generation
        self.curr_evgen_idx = 0
        self.curr_propagate_delta = 0
    
    def hold_curr_mem_req():
        io_port.pe_reqAddr_n[self.pe_id] = io_port.pe_reqAddr[self.pe_id]
        io_port.pe_reqValid_n[self.pe_id] = io_port.pe_reqValid[self.pe_id]
        io_port.pe_wrEn_n[self.pe_id] = io_port.pe_wrEn[self.pe_id]
        io_port.pe_wrData_n[self.pe_id] = io_port.pe_wrData[self.pe_id]


    def one_clock(self):
        self.curr_state = self.next_state
       
        # pipelined fpu
        for i in range(self.fpu_pipe_depth-1, -1, -1):
            self.fpu_value_pipe[i+1] = self.fpu_value_pipe[i]
            self.fpu_valid_pipe[i+1] = self.fpu_valid_pipe[i]
        
        # default relevant outputs to zero, overwrite if necessary
        # TODO: implement hold while waiting
        io_port.pe_reqValid_n[self.pe_id] = 0
        io_port.pe_wrEn_n[self.pe_id] = 0
        self.fpu_valid_pipe[0] = 0
        io_port.proValid_n = 0

        #############################
        ### FSM STATES DEFINITION ###
        #############################
        
        # IDLE state
        if self.curr_state == self.states.IDLE:
            if io_port.PEValid[self.pe_id] != 0: # incoming valid event
                # set status to busy
                io_port.PEReady_n[self.pe_id] = 0
                # store current event
                self.curr_delta = io_port.PEDelta[self.pe_id]
                self.curr_idx = io_port.PEIdx[self.pe_id]
                # send read vertex value request to cc
                io_port.pe_reqAddr_n[self.pe_id] = self.curr_idx / 4
                io_port.pe_wrEn_n[self.pe_id] = 0
                io_port.pe_reqValid_n[self.pe_id] = 1
                self.next_state = self.states.WAIT_ON_MEM_DATA
            else:
                io_port.PEReady_n[self.pe_id] = 1
                self.next_state = self.states.IDLE
        
        # WAIT_ON_MEM_DATA state
        if self.curr_state == self.states.WAIT_ON_MEM_DATA:
            if io_port.cc_ready[self.pe_id]:
                # temporarily store 64-bit word in the PE
                self.curr_vertex_value_word = io_port.cache_rdData[0:4]
                # send delta into fpu
                self.fpu_value_pipe[0] = self.curr_vertex_value_word[self.curr_idx % 4] + curr_delta
                self.fpu_valid_pipe[0] = 1
                # check propagation
                if curr_delta < self.threshold: # no propagation
                    self.next_state = self.states.WAIT_ON_FPU_DATA_ONLY
                else: # propagation. request start and stop values from mem
                    # send a row index request to the cache
                    io_port.pe_reqAddr_n = self.curr_idx / 8 + 64
                    io_port.pe_wrEn_n[self.pe_id] = 0
                    io_port.pe_reqValid_n[self.pe_id] = 1
                    self.next_state = self.states.WAIT_ON_FPU_AND_MEM_IDX
            else:
                hold_curr_mem_req()
                self.next_state = self.states.WAIT_ON_MEM_DATA
        
        # WAIT_ON_FPU_DATA_ONLY state
        # This state is for when no propagation occurs and we only need to read-update-write
        if self.curr_state = self.states.WAIT_ON_FPU_DATA_ONLY:
            if self.fpu_valid_pipe[self.fpu_pipe_depth] == 1:
                # create update request to write to mem
                self.curr_vertex_value_word[self.curr_idx % 4] = self.fpu_value_pipe[self.fpu_pipe_depth]
                io_port.pe_reqAddr_n = self.curr_idx / 4
                io_port.pe_wrEn_n[self.pe_id] = 1
                io_port.pe_reqValid_n[self.pe_id] = 1
                io_port.pe_wrData_n = self.curr_vertex_value_word
                self.next_state = self.states.WAIT_ON_MEM_WRITE
            else:
                self.next_state = self.states.WAIT_ON_FPU_DATA_ONLY

        # WAIT_ON_FPU_AND_MEM_IDX state
        if self.curr_state == self.states.WAIT_ON_FPU_AND_MEM_IDX:
            if self.fpu_valid_pipe[self.fpu_pipe_depth] == 1 or io_port.cc_ready[self.pe_id]:
                # handling fpu ready
                if self.fpu_valid_pipe[self.fpu_pipe_depth] == 1:
                    self.curr_vertex_value_word[self.curr_idx % 4] = self.fpu_value_pipe[self.fpu_pipe_depth]
                    self.curr_vertex_value_word_ready = 1
                # handling index read ready
                if io_port.cc_ready[self.pe_id]:
                    if self.start_ready != 1: # reading in the first word
                        self.start = io_port.cache_rdData[self.curr_idx % 8]
                        self.start_ready = 1
                        if self.curr_idx % 8 != 7: # start and end are within the same word
                            self.end = io_port.cache_rdData[self.curr_idx % 8 + 1]
                            self.end_ready = 1
                        else: # read end from mem
                            io_port.pe_reqAddr_n = self.curr_idx / 8 + 65
                            io_port.pe_wrEn_n[self.pe_id] = 0
                            io_port.pe_reqValid_n[self.pe_id] = 1
                            self.next_state = self.states.WAIT_ON_FPU_AND_MEM_IDX
                    else: # reading in the second word
                        self.end = io_port.cache_rdData[0]
                        self.end_ready = 1
                # both ready. update to mem and start FPU index calculation
                if self.curr_vertex_value_word_ready == 1 and self.start_ready == 1 and self.end_ready == 1:
                    # send update to mem
                    io_port.pe_reqAddr_n = self.curr_idx / 4
                    io_port.pe_wrEn_n[self.pe_id] = 1
                    io_port.pe_reqValid_n[self.pe_id] = 1
                    io_port.pe_wrData_n = self.curr_vertex_value_word
                    # check if adjacency list contains anything
                    if self.end - self.start != 0:
                        # start FPU index calculation
                        self.fpu_valid_pipe[0] = 1
                        self.fpu_value_pipe[0] = self.fpu_value_pipe[self.fpu_pipe_depth] / (self.end - self.start)
                        self.next_state = self.states.WAIT_ON_FPU_PRODELTA
                    else: # no adjacency. go to wait for mem write
                        self.next_state = WAIT_ON_MEM_WRITE
                # hold current memory request if waiting for index mem request
                else if elf.start_ready != 1 or self.end_ready != 1:
                    hold_curr_mem_req()
            else:
                hold_curr_mem_req()
                self.next_state = self.states.WAIT_ON_FPU_AND_MEM_IDX
        
        # WAIT_ON_FPU_PRODELTA state
        # TODO: need to figure out how to hold mem write request
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
                hold_curr_mem_req()
                self.next_state = self.states.WAIT_ON_MEM_WRITE
        

        # EVGEN state
        # TODO: evgen should issue mem accesses to read contents off of adjacency list
        # TODO: two additional states: evgen pause, wait for mem access for evgen
        if self.curr_state == self.states.EVGEN:
            if io_port.CUReady == [0, 0, 0, 0, 0, 0, 0, 0]:
                self.next_state = self.states.EVGEN_PAUSE
            elif self.curr_evgen_idx == self.start: # first event gen cycle
                # TODO: generate two events per cycle per processor?
                # generate a "clear" event
                io_port.proDelta_n[2*self.pe_id] = 0 - self.fpu_value_pipe[self.fpu_pipe_depth]
                io_port.proIdx_n[2*self.pe_id] = self.curr_idx
                io_port.proValid_n[2*self.pe_id] = 1
                # generate a "propagate" event
                io_port.proDelta_n[2*self.pe_id+1] = self.curr_propagate_delta
                io_port.proIdx_n[2*self.pe_id+1] = self.curr_evgen_idx
                io_port.proValid_n[2*self.pe_id+1] = 1
                # increment
                self.curr_evgen_idx += 2
                self.next_state = self.states.EVGEN
            elif self.curr_evgen_idx < self.end:
                # generate a "propagate" event
                io_port.proDelta_n[2*self.pe_id] = self.curr_propagate_delta
                io_port.proIdx_n[2*self.pe_id] = self.curr_evgen_idx
                io_port.proValid_n[2*self.pe_id] = 1
                self.curr_evgen_idx += 1
                if self.curr_evgen_idx < self.end:
                    # generate a "propagate" event
                    io_port.proDelta_n[2*self.pe_id+1] = self.curr_propagate_delta
                    io_port.proIdx_n[2*self.pe_id+1] = self.curr_evgen_idx
                    io_port.proValid_n[2*self.pe_id+1] = 1
                    self.curr_evgen_idx += 1
                else:
                    io_port.proDelta_n[2*self.pe_id+1] = 0
                    io_port.proIdx_n[2*self.pe_id+1] = 0
                    io_port.proValid_n[2*self.pe_id+1] = 0
            else: # reached the end of evgen
                self.next_state = self.states.IDLE
        
        # EVGEN_PAUSE state
        # TODO: determine the upstream ready signal
        if self.curr_state == self.states.EVGEN_PAUSE:
            if io_port.CUReady != [0, 0, 0, 0, 0, 0, 0, 0]:
                self.next_state = self.states.EVGEN
            else:
                self.next_state = self.states.EVGEN_PAUSE
        
        # TODO: EVGEN_WAIT_FOR_MEM state

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