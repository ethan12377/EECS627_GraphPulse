import io_port
import numpy as np
from enum import Enum


class PE:

    def __init__(self, pe_id, fpu_pipe_depth):
        self.pe_id = pe_id # use id to differentiate the four pes
        self.threshold = 0.1 # TODO: should set a global variable for this?

        # status
        self.ready = 1
        self.ruw_complete = 0

        # FPU parameters
        self.fpu_pipe_depth = fpu_pipe_depth
        self.fpu_value_pipe = np.zeros(fpu_pipe_depth + 1, dtype=np.float16)
        self.fpu_valid_pipe = np.zeros(fpu_pipe_depth + 1)
        self.fpu_status_pipe = np.zeros(fpu_pipe_depth + 1) # 0: idle, 1: ruw, 2: prodelta

        # storing values that are being worked on for the current operation
        self.curr_delta = np.float16(0.0)
        self.curr_idx = 0
        self.curr_vertex_value = np.float16(0.0)
        self.curr_vertex_value_ready = 0

        # FSM
        self.states = Enum('states',['IDLE', 'RUW', 'EVGEN'])
        self.curr_state = self.states.IDLE
        self.next_state = self.states.IDLE

        # start and end for extracting adjacency list
        self.start = 0
        self.end = 0
        self.start_ready = 0
        self.end_ready = 0
        
        # status for cache requests
        self.vc_req_status = 0 # 0: idle, 1: waiting for read, 2: waiting for write
        self.ec_req_status = 0 # 0: idle, 1: start, 2: end, 3: col_index_word

        # parameters for propagate event generation
        self.curr_evgen_idx = 0
        self.curr_propagate_delta = np.float16(0.0)
        self.curr_prodelta_ready = 0

        self.curr_col_idx_word = [0, 0, 0, 0, 0, 0, 0, 0]
        self.curr_col_idx_word_tag = 0
        self.curr_col_idx_word_valid = 0

        self.first_event_generated = 0
        self.proport0_done = 0
        self.proport1_done = 0
    
    def clear_status_regs(self):
        self.vc_req_status = 0
        self.ec_req_status = 0
        self.ruw_complete = 0
        self.first_event_generated = 0
        self.proport0_done = 0
        self.proport1_done = 0
        self.start_ready = 0
        self.end_ready = 0
        self.curr_vertex_value_ready = 0
        self.curr_prodelta_ready = 0
    
    def hold_vc_req(self):
        io_port.pe_vc_reqAddr_n[self.pe_id] = io_port.pe_vc_reqAddr[self.pe_id]
        io_port.pe_vc_reqValid_n[self.pe_id] = io_port.pe_vc_reqValid[self.pe_id]
        io_port.pe_wrEn_n[self.pe_id] = io_port.pe_wrEn[self.pe_id]
        io_port.pe_wrData_n[self.pe_id] = io_port.pe_wrData[self.pe_id]
    
    def hold_ec_req(self):
        io_port.pe_ec_reqAddr_n[self.pe_id] = io_port.pe_ec_reqAddr[self.pe_id]
        io_port.pe_ec_reqValid_n[self.pe_id] = io_port.pe_ec_reqValid[self.pe_id]
    
    def hold_propagate_events(self, port): # port is either 0 or 1
        io_port.proDelta_n[self.pe_id*2 + port] = io_port.proDelta[self.pe_id*2 + port]
        io_port.proIdx_n[self.pe_id*2 + port] = io_port.proIdx[self.pe_id*2 + port]
        io_port.proValid_n[self.pe_id*2 + port] = io_port.proValid[self.pe_id*2 + port]

    def one_clock(self):
        self.curr_state = self.next_state
       
        # pipelined fpu
        for i in range(self.fpu_pipe_depth-1, -1, -1):
            self.fpu_value_pipe[i+1] = self.fpu_value_pipe[i]
            self.fpu_valid_pipe[i+1] = self.fpu_valid_pipe[i]
            self.fpu_status_pipe[i+1] = self.fpu_status_pipe[i]
        
        # default relevant outputs to zero, overwrite when necessary
        io_port.pe_ec_reqValid_n[self.pe_id] = 0
        io_port.pe_vc_reqValid_n[self.pe_id] = 0
        io_port.pe_wrEn_n[self.pe_id] = 0
        self.fpu_valid_pipe[0] = 0
        self.fpu_status_pipe[0] = 0
        io_port.proValid_n[self.pe_id*2] = 0
        io_port.proValid_n[self.pe_id*2+1] = 0

        #############################
        ### FSM STATES DEFINITION ###
        #############################
        
        ##### IDLE state #####
        if self.curr_state == self.states.IDLE:
            # default to clear all status registers
            self.ready = 1
            self.clear_status_regs()
            if io_port.PEValid[self.pe_id] != 0: # incoming valid event
                # set status to busy
                self.ready = 0
                # store current event
                self.curr_delta = io_port.PEDelta[self.pe_id]
                self.curr_idx = io_port.PEIdx[self.pe_id]
                # send read vertex value request to cc_vc
                io_port.pe_vc_reqAddr_n[self.pe_id] = self.curr_idx // 4
                io_port.pe_wrEn_n[self.pe_id] = 0
                io_port.pe_vc_reqValid_n[self.pe_id] = 1
                self.vc_req_status = 1
                # if delta over threshold, send 'start' request to cc_ec
                if self.curr_delta > self.threshold:
                    io_port.pe_ec_reqAddr_n[self.pe_id] = self.curr_idx // 4 + 8192
                    io_port.pe_ec_reqValid_n[self.pe_id] = 1
                    self.ec_req_status = 1
            else:
                self.next_state = self.states.IDLE
        
        ##### RUW state #####
        if self.curr_state == self.states.RUW:
            ### check vc mem request ###
            if io_port.cc_vc_ready[self.pe_id] == 1:
                if self.vc_req_status == 1: # read fulfilled
                    # send data into fpu
                    self.vc_req_status = 0
                    self.fpu_value_pipe[0] = io_port.vc_rdData + self.curr_delta
                    self.fpu_valid_pipe[0] = 1
                    self.fpu_status_pipe[0] = 1
                elif self.vc_req_status == 2: # write fulfilled
                    # clear vc status
                    self.vc_req_status = 0
                    self.ruw_complete = 1
            else:
                if self.vc_req_status != 0: # active read or write waiting on vc
                    self.hold_vc_req()
            
            ### check ec mem request ###
            if io_port.cc_ec_ready[self.pe_id] == 1:
                if self.ec_req_status == 1: # read start fulfilled
                    # store start
                    self.start = io_port.ec_rdData[self.curr_idx % 4]
                    self.curr_evgen_idx = self.start
                    self.start_ready = 1
                    # check if start and end are in the same word
                    if self.curr_idx % 4 != 3:
                        self.end = io_port.ec_rdData[self.curr_idx % 4 + 1]
                        self.end_ready = 1
                        if self.end != self.start: 
                            # grab a col index word from ec
                            io_port.pe_ec_reqAddr_n[self.pe_id] = self.start // 8
                            io_port.pe_ec_reqValid_n[self.pe_id] = 1
                            self.curr_col_idx_word_tag = self.start // 8
                            self.ec_req_status = 3
                        else:
                            self.ec_req_status = 0
                    else:
                        io_port.pe_ec_reqAddr_n[self.pe_id] = self.curr_idx // 4 + 8192 + 1
                        io_port.pe_ec_reqValid_n[self.pe_id] = 1
                        self.ec_req_status = 2
                elif self.ec_req_status == 2: # read end fulfilled
                    self.end = io_port.ec_rdData[0]
                    self.end_ready = 1
                    if self.end != self.start: 
                        # grab a col index word from ec
                        io_port.pe_ec_reqAddr_n[self.pe_id] = self.start // 8
                        io_port.pe_ec_reqValid_n[self.pe_id] = 1
                        self.curr_col_idx_word_tag = self.start // 8
                        self.ec_req_status = 3
                    else:
                        self.ec_req_status = 0
                elif self.ec_req_status == 3: # read col index word fulfilled
                    self.curr_col_idx_word = io_port.ec_rdData
                    self.curr_col_idx_word_valid = 1
                    self.ec_req_status = 0
            else:
                if self.ec_req_status != 0: # active read waiting on ec
                    self.hold_ec_req()
            
            ### check fpu ###
            if self.fpu_valid_pipe[self.fpu_pipe_depth] == 1:
                if self.fpu_status_pipe[self.fpu_pipe_depth] == 1: # ruw result obtained
                    # store result
                    self.curr_vertex_value = self.fpu_value_pipe[self.fpu_pipe_depth]
                    self.curr_vertex_value_ready = 1
                    # write result to vc
                    io_port.pe_vc_reqAddr_n[self.pe_id] = self.curr_idx // 4
                    io_port.pe_wrEn_n[self.pe_id] = 1
                    io_port.pe_vc_reqValid_n[self.pe_id] = 1
                    io_port.pe_wrData_n[self.pe_id] = self.fpu_value_pipe[self.fpu_pipe_depth]
                    self.vc_req_status = 2
                elif self.fpu_status_pipe[self.fpu_pipe_depth] == 2: # prodelta obtained
                    self.curr_propagate_delta = self.fpu_value_pipe[self.fpu_pipe_depth]
                    self.curr_prodelta_ready = 1
            
            ### check if ready to calculate prodelta ###
            if self.start_ready == 1 and self.end_ready == 1 and self.start != self.end and self.curr_vertex_value_ready == 1:
                self.fpu_value_pipe[0] = self.curr_vertex_value / (self.end - self.start)
                self.fpu_valid_pipe[0] = 1
                self.fpu_status_pipe[0] = 2
            
            ### determine next state ###
            if self.ruw_complete == 1:
                if self.curr_delta < self.threshold: # no propagation because delta below threshold
                    self.next_state = self.states.IDLE
                elif (self.start_ready == 1 and self.end_ready == 1 and self.start == self.end): # no propagation because no adjacency
                    self.next_state = self.states.IDLE
                else: # still waiting on necessary calculations to be completed
                    self.next_state = self.states.RUW
            elif self.curr_prodelta_ready == 1 and self.curr_col_idx_word_valid == 1: # data ready for evgen
                self.next_state = self.states.EVGEN
            else:
                self.next_state = self.states.RUW

        ##### EVGEN state #####
        if self.curr_state == self.states.EVGEN:
            # hold vc write request from ruw if incomplete
            if self.ruw_complete == 0:
                if io_port.cc_vc_ready[self.pe_id]:
                    self.ruw_complete = 1
                else:
                    self.hold_vc_req()
            
            # check ec request
            if io_port.cc_ec_ready[self.pe_id] == 1:
                if self.ec_req_status == 3: # col index word read fulfilled
                    self.curr_col_idx_word = io_port.ec_rdData
                    self.curr_col_idx_word_valid = 1
                    self.ec_req_status = 0
            elif self.ec_req_status != 0:
                self.hold_ec_req()

            # port 0 operations
            if self.curr_evgen_idx < self.end: # ongoing event generation
                if io_port.proReady[2*self.pe_id] == 1: # ready to receive new event
                    if self.curr_col_idx_word_valid == 1 and self.curr_col_idx_word_tag == self.curr_col_idx_word: # curr idx is in curr word
                        if self.curr_evgen_idx == self.start: # first iteration, generate a clear event
                            self.first_event_generated = 1
                            io_port.proDelta_n[2*self.pe_id] = 0 - self.curr_vertex_value
                            io_port.proIdx_n[2*self.pe_id] = self.curr_idx
                            io_port.proValid_n[2*self.pe_id] = 1
                        else:
                            io_port.proDelta_n[2*self.pe_id] = self.curr_propagate_delta
                            io_port.proIdx_n[2*self.pe_id] = self.curr_col_idx_word[self.curr_evgen_idx % 8]
                            io_port.proValid_n[2*self.pe_id] = 1
                            self.curr_evgen_idx += 1
                    else: # curr idx is not in curr word. Invalidate curr word and request ec for new word
                        self.curr_col_idx_word_valid = 0
                        # request a row word from the memory
                        io_port.pe_ec_reqAddr_n[self.pe_id] = self.curr_evgen_idx // 8
                        self.curr_col_idx_word_tag = self.curr_evgen_idx // 8
                        self.ec_req_status = 3
                else: # not ready to receive new event, hold current event
                    self.hold_propagate_events(0)
            elif self.curr_evgen_idx == self.end and self.proport0_done == 0: # reach the end of evgen, wait for fulfill
                if io_port.proReady[2*self.pe_id] == 1:
                    self.proport0_done = 1
                else:
                    self.hold_propagate_events(0)
                    
            # port 1 operations
            if self.curr_evgen_idx < self.end: # ongoing event generation
                if io_port.proReady[2*self.pe_id+1] == 1: # ready to receive new event
                    if self.curr_col_idx_word_valid == 1 and self.curr_col_idx_word_tag == self.curr_col_idx_word: # curr idx is in curr word
                        io_port.proDelta_n[2*self.pe_id+1] = self.curr_propagate_delta
                        io_port.proIdx_n[2*self.pe_id+1] = self.curr_col_idx_word[self.curr_evgen_idx % 8]
                        io_port.proValid_n[2*self.pe_id+1] = 1
                        self.curr_evgen_idx += 1
                    else: # curr idx is not in curr word. Invalidate curr word and request ec for new word
                        self.curr_col_idx_word_valid = 0
                        # request a row word from the memory
                        io_port.pe_ec_reqAddr_n[self.pe_id+1] = self.curr_evgen_idx // 8
                        self.curr_col_idx_word_tag = self.curr_evgen_idx // 8
                        self.ec_req_status = 3
                else: # not ready to receive new event, hold current event
                    self.hold_propagate_events(1)
            elif self.curr_evgen_idx == self.end and self.proport1_done == 0: # reach the end of evgen, wait for fulfill
                if io_port.proReady[2*self.pe_id+1] == 1:
                    self.proport1_done = 1
                else:
                    self.hold_propagate_events(1)

            # next state
            if self.proport0_done == 1 and self.proport1_done == 1 and self.ruw_complete == 1: # finished fulfilling last event
                self.next_state = self.states.IDLE
            else:
                self.next_state = self.states.EVGEN
        
        # update processor status
        io_port.PEReady_n[self.pe_id] = self.ready



           
            