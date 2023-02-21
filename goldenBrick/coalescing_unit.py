import io_port
import numpy as np

class CU:

    def __init__(self):

        # CUdelta, CUIdx, CUValid --> searchIdx_n
        #     reg0 (CUdelta, CUIdx, CUclean)
        # searchidx --> searchVlaue_n
        #     reg1 (CUdelta, CUIdx, CUclean)
        # searchValue + CUdelta --> newDelta_n
        #     reg2 (CUdelta, CUIdx, CUclean) --> output

        # CUregtag: 0~3
        self.CUregValid = np.zeros((8,3))
        self.CUIdxreg = np.zeros((8,3))
        self.CUDeltareg = np.zeros((8,3))
        self.CUregtag = np.zeros((8,3))

        self.CUregValid_n = np.zeros((8,3))
        self.CUIdxreg_n = np.zeros((8,3))
        self.CUDeltareg_n = np.zeros((8,3))
        self.CUregtag_n = np.zeros((8,3))

        # CU_in_buf stores events from crossbar as a tuple (delta, id, state)
        # say each CU has a buffer of 4 events
        self.CU_in_buf = np.zeros((8,4))
        self.CU_in_buf_n = np.zeros((8,4))
        # CU_out_buf stores last 3 output events as a tuple (delta, id, valid)
        # say each CU has a buffer of 4 events
        self.CU_out_buf = np.zeros((8,3))
        self.CU_out_buf_n = np.zeros((8,3))


    def one_clock(self):
        # input:
        #   io_port.CUDelta
        #   io_port.CUIdx
        #   io_port.CUValid
        #   io_port.searchIdx

        # TODO: update *_n

        # io_port.CUReady_n = io_port.CUReady
        #io_port.searchIdx_n = io_port.searchIdx
        #io_port.searchValid_n_n
        #io_port.newDelta_n = io_port.newDelta
        #io_port.newIdx_n = io_port.newIdx
        #io_port.newValid_n = io_port.newValid
        self.coalescing_unit(0)
        self.coalescing_unit(1)
        self.coalescing_unit(2)
        self.coalescing_unit(3)
        self.coalescing_unit(4)
        self.coalescing_unit(5)
        self.coalescing_unit(6)
        self.coalescing_unit(7)
        

        self.CUregValid = np.copy(self.CUregValid_n)
        self.CUIdxreg = np.copy(self.CUIdxreg_n)
        self.CUDeltareg = np.copy(self.CUDeltareg_n)
        self.CUregtag = np.copy(self.CUregtag_n)

        self.CU_in_buf_n = np.copy(self.CU_in_buf_n)
        self.CU_out_buf_n = np.copy(self.CU_out_buf_n)
          




    def coalescing_unit(self, bin_idx):
        # bypass during initial 
        if not io_port.initialFinish:
            io_port.CUReady_n[bin_idx] = 1
            io_port.newDelta_n[bin_idx] = np.copy(io_port.CUDelta[bin_idx])
            io_port.newIdx_n[bin_idx] = np.copy(io_port.CUIdx[bin_idx])
            io_port.newValid_n[bin_idx] = np.copy(io_port.CUValid[bin_idx])

        else:
            # issue new event and update reg0_n
            # output: io_port.searchIdx_n
            # output: io_port.searchValid_n
            self.issue_new_event(bin_idx) 

            # update reg1_n
            self.update_reg1(bin_idx)

            # take searchValue if valid and add
            # update reg2_n
            self.update_reg2(bin_idx)

            # update CUclean_n
            if (self.CUregValid[0] == 0) and (self.CUregValid[1] == 0):
                io_port.cuclean_n = 1
            else:
                io_port.cuclean_n = 0

            # update CU_out_buf and output
            # output: io_port.newDelta_n
            # output: io_port.newIdx_n
            # output: io_port.newValid_n
            self.update_out_buf(bin_idx)

            # take event from crossbar  
            # output: io_port.CUReady_n 
            self.take_event(bin_idx)

            # when buf is full cu can not take new event from crossbar
            if (self.CU_in_buf_n[bin_idx].any(0)):
                io_port.CUReady_n[bin_idx] = 1
            else:
                io_port.CUReady_n[bin_idx] = 0


    # take event from crossbar    
    def take_event(self, bin_idx):
        # take new event from crossbar if valid and has space in buf
        if (self.CU_in_buf[bin_idx].any(0)):
            io_port.CUReady_n[bin_idx] = 1
            if io_port.CUValid[bin_idx]:
                self.CU_in_buf_n[bin_idx][0] = (io_port.CUDelta[bin_idx], io_port.CUIdx[bin_idx], io_port.CUValid[bin_idx])  
                self.CU_in_buf_n[bin_idx][1:] = np.copy(self.CU_in_buf[bin_idx][:-1])
              

    # prepare: output: io_port.searchIdx_n
    # prepare: output: io_port.searchValid_n
    # update reg0~2
    def prepare_new_event(self, bin_idx):
        io_port.searchValid_n = 0
        if self.CU_in_buf[bin_idx]:
            # take the first-in event
            non_zero_indices = np.nonzero(self.CU_in_buf[bin_idx])[0]
            if len(non_zero_indices) > 0:
                (new_Delta, new_idx, new_Valid) = self.CU_in_buf[bin_idx][non_zero_indices[-1]]
            else:
                new_idx = 0
                new_Delta = 0
                new_Valid = 0

            # update reg0
            self.CUregValid_n[bin_idx][0] = new_Valid
            self.CUIdxreg_n[bin_idx][0] = new_idx
            self.CUDeltareg_n[bin_idx][0] = new_Delta

            if new_idx  == self.CUIdxreg[0]:
                self.CUregtag_n[bin_idx][0] = 1
            elif new_idx  == self.CUIdxreg[1]:
                self.CUregtag_n[bin_idx][0] = 2
            elif new_idx  == self.CUIdxreg[2]:
                self.CUregtag_n[bin_idx][0] = 3 
            else:
                self.CUregtag_n[bin_idx][0] = 0
                io_port.searchIdx_n = new_idx
                io_port.searchValid_n = 1
                
            # remove from buf
            self.CU_in_buf[bin_idx][non_zero_indices[-1]] = 0
                  
            
            


    # issue new event     
    # update or keep reg0_n
    def issue_new_event(self, bin_idx):
        # if last event was accepted by Q or no valid event, prepare new event
        if (io_port.state == 1) or (io_port.searchValid == 0) :     
            # prepare and update reg0
            self.prepare_new_event(bin_idx)
        else:
            # if last event was not accepted by Q but valid, keep searchidx and reg0
            io_port.searchIdx_n = np.copy(io_port.searchIdx)
            io_port.searchValid_n = np.copy(io_port.searchValid)
            # keep reg0 
            # in this situation, the self.CUregtag MUST be 0 and this event is not forwarded. Self.CUregtag_n can keep as 0
            self.CUregValid_n[bin_idx][0] = np.copy(self.CUregValid[bin_idx][0])
            self.CUIdxreg_n[bin_idx][0] = np.copy(self.CUIdxreg[bin_idx][0])
            self.CUDeltareg_n[bin_idx][0] = np.copy(self.CUDeltareg[bin_idx][0])
            self.CUregtag_n[bin_idx][0] = np.copy(self.CUregtag[bin_idx][0])


    

    #update register
    def update_reg1(self, bin_idx):
        # update reg1
        self.CUregValid_n[bin_idx][1] = np.copy(self.CUregValid[bin_idx][0])
        self.CUIdxreg_n[bin_idx][1] = np.copy(self.CUIdxreg[bin_idx][0])
        self.CUDeltareg_n[bin_idx][1] = np.copy(self.CUDeltareg[bin_idx][0])
        self.CUregtag_n[bin_idx][1] = np.copy(self.CUregtag[bin_idx][0])
        
    def update_reg2(self, bin_idx):
        # update reg2
        # how to add two element from nparray
        # take oprand from io_port.searchValue
        if (self.CUregtag[bin_idx][1] == 0):
            self.CUDeltareg_n[bin_idx][2] = self.CUDeltareg[bin_idx][1] + io_port.searchValue
        # take oprand from cu_out_buf
        elif (self.CUregtag[bin_idx][1] == 1):
            self.CUDeltareg_n[bin_idx][2] = self.CUDeltareg[bin_idx][1] + self.CU_out_buf[bin_idx][2][0]
        elif (self.CUregtag[bin_idx][1] == 2):
            self.CUDeltareg_n[bin_idx][2] = self.CUDeltareg[bin_idx][1] + self.CU_out_buf[bin_idx][1][0]
        elif (self.CUregtag[bin_idx][1] == 3):
            self.CUDeltareg_n[bin_idx][2] = self.CUDeltareg[bin_idx][1] + self.CU_out_buf[bin_idx][0][0]

        self.CUregValid_n[bin_idx][2] = np.copy(self.CUregValid[bin_idx][1])
        self.CUIdxreg_n[bin_idx][2] = np.copy(self.CUIdxreg[bin_idx][1])
        self.CUregtag_n[bin_idx][2] = np.copy(self.CUregtag[bin_idx][1])

    


    # update CU_out_buf and CU output
    def update_out_buf(self, bin_idx):

        self.CU_out_buf_n[bin_idx][0] = np.copy(self.CU_out_buf[bin_idx][1])
        self.CU_out_buf_n[bin_idx][1] = np.copy(self.CU_out_buf[bin_idx][2])

        # assign the adder result into out_buf and output at the same time
        self.CU_out_buf_n[bin_idx][2] = (self.CUDeltareg_n[bin_idx][2],self.CUIdxreg_n[bin_idx][2], self.CUregValid_n[bin_idx][2])

        io_port.newDelta_n[bin_idx] = self.CUDeltareg_n[bin_idx][2]
        io_port.newIdx_n[bin_idx] = self.CUIdxreg_n[bin_idx][2]
        io_port.newValid_n[bin_idx] = self.CUregValid_n[bin_idx][2]
         
            

                    







