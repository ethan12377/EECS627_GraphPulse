import io_port
import numpy as np
from enum import Enum

# reduce function:      fpu add

#                         (fpu)    (8-bit integer)  
# propagate function:   d * delta / (end - start)


class PE:

    def __init__(self, pe_id, threshold, fpu_pipe_depth, damping_factor, num_of_vertices):
        self.pe_id = int(pe_id) # use id to differentiate the four pes
        self.threshold = threshold
        self.damping_factor = damping_factor
        self.num_of_vertices = int(num_of_vertices)

        # status
        self.ready = int(0)
        self.ruw_complete = int(0)
        self.initializing = int(1)

        # initialization parameters
        self.init_value = np.float16(0.0)
        self.init_value_denom = np.float16(0.0)
        self.init_value_ready = int(0)
        self.init_value_denom_ready = int(0)

        # FPU parameters
        self.fpu_pipe_depth = fpu_pipe_depth
        self.fpu_value_pipe = np.zeros(fpu_pipe_depth + 1, dtype=np.float16)
        self.fpu_status_pipe = np.zeros(fpu_pipe_depth + 1, dtype=int) # 0: invalid; 1: ruw; 2: prodelta, init value (INIT); 3: d * delta, init value denom (INIT)

        # storing values that are being worked on for the current operation
        self.curr_delta = np.float16(0.0)
        self.curr_idx = int(0)
        # self.curr_vertex_value = np.float16(0.0)
        # self.curr_vertex_value_ready = 0

        # FSM
        self.states = Enum('states',['INIT', 'IDLE', 'RUW', 'EVGEN'])
        self.curr_state = self.states.INIT
        self.next_state = self.states.INIT

        # start and end for extracting adjacency list
        self.start = int(0)
        self.end = int(0)
        self.start_ready = int(0)
        self.end_ready = int(0)
        
        # status for cache requests
        self.vc_req_status = int(0) # 0: idle, 1: waiting for read, 2: waiting for write
        self.ec_req_status = int(0) # 0: idle, 1: start, 2: end, 3: col_index_word

        # parameters for propagate event generation
        self.curr_evgen_idx = int(0)
        self.curr_prodelta_numerator = np.float16(0.0)
        self.curr_prodelta_numerator_ready = int(0)
        self.curr_prodelta_denom = np.float16(0.0)
        self.curr_prodelta_denom_ready = 0
        self.curr_prodelta = np.float16(0.0)
        self.curr_prodelta_ready = int(0)

        self.curr_col_idx_word = [0, 0, 0, 0, 0, 0, 0, 0]
        self.curr_col_idx_word_tag = int(0)
        self.curr_col_idx_word_valid = int(0)

        self.proport_done = [0, 0]
    
    def clear_status_regs(self):
        self.ruw_complete = 0
        self.initializing = 0

        self.vc_req_status = 0
        self.ec_req_status = 0
        
        self.proport_done = [0, 0]
        self.start_ready = 0
        self.end_ready = 0
        self.curr_prodelta_numerator_ready = 0
        self.curr_prodelta_denom_ready = 0
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
    
    def propagate_evgen(self, port): # port is either 0 or 1
        if self.curr_evgen_idx < self.end: # ongoing event generation
            if io_port.proValid[self.pe_id + port] == 0 or io_port.proReady[2*self.pe_id + port] == 1: # ready to gnerate or receive new event
                if self.initializing == 1: # initializing events, use initialization value
                    io_port.proDelta_n[2*self.pe_id + port] = self.init_value
                    io_port.proIdx_n[2*self.pe_id + port] = self.curr_evgen_idx
                    io_port.proValid_n[2*self.pe_id + port] = 1
                    self.curr_evgen_idx += 1
                elif self.curr_col_idx_word_valid == 1 and self.curr_col_idx_word_tag == self.curr_evgen_idx // 8: # curr idx is in curr word
                    io_port.proDelta_n[2*self.pe_id + port] = self.curr_prodelta
                    io_port.proIdx_n[2*self.pe_id + port] = self.curr_col_idx_word[int(self.curr_evgen_idx % 8)]
                    io_port.proValid_n[2*self.pe_id + port] = 1
                    self.curr_evgen_idx += 1
                else: # curr idx is not in curr word. Invalidate curr word and request ec for new word
                    self.curr_col_idx_word_valid = 0
                    # request a row word from the memory
                    io_port.pe_ec_reqAddr_n[self.pe_id] = self.curr_evgen_idx // 8
                    self.curr_col_idx_word_tag = self.curr_evgen_idx // 8
                    self.ec_req_status = 3
            else: # not ready to receive new event, hold current event
                self.hold_propagate_events(port)
        elif self.curr_evgen_idx == self.end and self.proport_done[port] == 0: # reach the end of evgen, wait for fulfill
            # if only generated 1 event, then port 1 is automatically done
            if (port == 1 and self.end - self.start == 1) or io_port.proReady[2*self.pe_id + port] == 1:
                self.proport_done[port] = 1
            else:
                self.hold_propagate_events(port)
    
    def one_clock(self):
        self.curr_state = self.next_state
       
        # pipelined fpu
        for i in range(self.fpu_pipe_depth-1, -1, -1):
            self.fpu_value_pipe[i+1] = self.fpu_value_pipe[i]
            self.fpu_status_pipe[i+1] = self.fpu_status_pipe[i]
        
        # default relevant outputs to zero, overwrite when necessary
        io_port.pe_ec_reqValid_n[self.pe_id] = 0
        io_port.pe_vc_reqValid_n[self.pe_id] = 0
        io_port.pe_wrEn_n[self.pe_id] = 0
        self.fpu_value_pipe[0] = 0
        self.fpu_status_pipe[0] = 0
        io_port.proValid_n[self.pe_id*2] = 0
        io_port.proValid_n[self.pe_id*2+1] = 0

        #############################
        ### FSM STATES DEFINITION ###
        #############################
        
        ##### INIT state #####
        # initialization: generate initialization event of (idx, (1-d)/N) for all vertices
        if self.curr_state == self.states.INIT:
            # set initializing status reg
            self.initializing = 1
            self.ready = 0 # not ready for upstream events yet
            
            if np.count_nonzero(self.fpu_status_pipe) == 0 and self.init_value_ready == 0: # no ongoing calculation inside of the fpu at startup
                # calculate initial value denominator
                self.fpu_value_pipe[0] = 1 - self.damping_factor
                self.fpu_status_pipe[0] = 3
            
            # check fpu status
            if self.fpu_status_pipe[self.fpu_pipe_depth] == 2: # init value ready
                self.init_value = self.fpu_value_pipe[self.fpu_pipe_depth]
                self.init_value_ready = 1
            elif self.fpu_status_pipe[self.fpu_pipe_depth] == 3: # init value denom ready
                # calculate initialization value
                self.fpu_value_pipe[0] = self.fpu_value_pipe[self.fpu_pipe_depth] / self.num_of_vertices
                self.fpu_status_pipe[0] = 2
            
            # start ev gen when init value ready
            if self.init_value_ready == 1:
                self.start = int(0)
                self.end = self.num_of_vertices
                self.curr_evgen_idx = int(0)
                self.next_state = self.states.EVGEN
            else:
                self.next_state = self.states.INIT


        ##### IDLE state #####
        if self.curr_state == self.states.IDLE:
            # default to clear all status registers
            self.ready = 1
            self.clear_status_regs()
            self.fpu_status_pipe = np.zeros(self.fpu_pipe_depth + 1, dtype=int) # clear potential leftover calculations
            if io_port.PEValid[self.pe_id] == 1: # incoming valid event
                # set status to busy
                self.ready = 0
                # store current event
                self.curr_delta = io_port.PEDelta[self.pe_id]
                self.curr_idx = io_port.PEIdx[self.pe_id]
                # send read vertex value request to cc_vc
                io_port.pe_vc_reqAddr_n[self.pe_id] = self.curr_idx
                io_port.pe_wrEn_n[self.pe_id] = 0
                io_port.pe_vc_reqValid_n[self.pe_id] = 1
                self.vc_req_status = 1
                # check if delta over threshold
                if self.curr_delta > self.threshold:
                    # send 'start' request to cc_ec
                    io_port.pe_ec_reqAddr_n[self.pe_id] = self.curr_idx // 4 + 8192
                    io_port.pe_ec_reqValid_n[self.pe_id] = 1
                    self.ec_req_status = 1
                    # calculate d * delta to prepare for propagate calculation
                    self.fpu_value_pipe[0] = self.damping_factor * self.curr_delta
                    self.fpu_status_pipe[0] = 3
                # go to RUW
                self.next_state = self.states.RUW
            else:
                self.ready = 1
                self.next_state = self.states.IDLE
        
        ##### RUW state #####
        if self.curr_state == self.states.RUW:
            ### check vc mem request ###
            if io_port.cc_vc_ready[self.pe_id] == 1:
                if self.vc_req_status == 1: # read fulfilled
                    # send data into fpu
                    self.vc_req_status = 0
                    self.fpu_value_pipe[0] = io_port.vc_rdData + self.curr_delta
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
            if self.fpu_status_pipe[self.fpu_pipe_depth] != 0:
                if self.fpu_status_pipe[self.fpu_pipe_depth] == 1: # ruw result obtained
                    # write result to vc
                    io_port.pe_vc_reqAddr_n[self.pe_id] = self.curr_idx
                    io_port.pe_wrEn_n[self.pe_id] = 1
                    io_port.pe_vc_reqValid_n[self.pe_id] = 1
                    io_port.pe_wrData_n[self.pe_id] = self.fpu_value_pipe[self.fpu_pipe_depth]
                    self.vc_req_status = 2
                elif self.fpu_status_pipe[self.fpu_pipe_depth] == 2: # prodelta obtained
                    self.curr_prodelta = self.fpu_value_pipe[self.fpu_pipe_depth]
                    self.curr_prodelta_ready = 1
                elif self.fpu_status_pipe[self.fpu_pipe_depth] == 3: # prodelta denominator obtained
                    self.curr_prodelta_numerator = self.fpu_value_pipe[self.fpu_pipe_depth]
                    self.curr_prodelta_numerator_ready = 1
            
            ### check if ready to calculate prodelta denominator ###
            if self.start_ready == 1 and self.end_ready == 1 and self.curr_prodelta_denom_ready == 0:
                if self.start == self.end: # sink detected, distribute pagerank among all other vertices
                    self.start = 0
                    self.end = self.num_of_vertices
                    self.curr_prodelta_denom = self.num_of_vertices
                else: # regular vertex with adjacencies
                    self.curr_prodelta_denom = self.end - self.start
                self.curr_prodelta_denom_ready = 1

            ### check if ready to calculate prodelta ###
            if self.curr_prodelta_numerator_ready == 1 and self.curr_prodelta_denom_ready == 1:
                self.fpu_value_pipe[0] = self.curr_prodelta_numerator / self.curr_prodelta_denom
                self.fpu_status_pipe[0] = 2
            
            ### determine next state ###
            if self.ruw_complete == 1:
                if self.curr_delta < self.threshold: # no propagation because delta below threshold
                    self.ready = 1
                    self.next_state = self.states.IDLE
                elif (self.start_ready == 1 and self.end_ready == 1 and self.start == self.end): # no propagation because no adjacency
                    self.ready = 1
                    self.next_state = self.states.IDLE
                else: # still waiting on necessary calculations to be completed
                    self.next_state = self.states.RUW
            elif self.curr_prodelta_ready == 1 and self.curr_col_idx_word_valid == 1: # data ready for evgen
                self.curr_evgen_idx = self.start
                self.next_state = self.states.EVGEN
            else:
                self.next_state = self.states.RUW

        ##### EVGEN state #####
        if self.curr_state == self.states.EVGEN:
            # hold vc write request from ruw if incomplete
            if self.ruw_complete == 0:
                if io_port.cc_vc_ready[self.pe_id] == 1:
                    self.vc_req_status = 0
                    self.ruw_complete = 1
                elif self.vc_req_status != 0:
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
            self.propagate_evgen(0)
                    
            # port 1 operations
            self.propagate_evgen(1)

            # next state
            if self.proport_done == [1, 1] and (self.initializing == 1 or self.ruw_complete == 1): # finished fulfilling last event
                # clear initializing status
                self.initializing = 0
                self.ready = 1
                self.next_state = self.states.IDLE
            else:
                self.next_state = self.states.EVGEN
        
        # update processor status to io
        io_port.PEReady_n[self.pe_id] = self.ready



           
            