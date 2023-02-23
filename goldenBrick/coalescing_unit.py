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
        self.CUregValid = np.zeros((8,3), dtype=np.uint8)
        self.CUIdxreg = np.zeros((8,3), dtype=np.float16)
        self.CUDeltareg = np.zeros((8,3), dtype=np.float16)
        # self.CUregtag = np.zeros((8,3))

        self.CUregValid_n = np.zeros((8,3), dtype=np.uint8)
        self.CUIdxreg_n = np.zeros((8,3), dtype=np.float16)
        self.CUDeltareg_n = np.zeros((8,3), dtype=np.float16)
        # self.CUregtag_n = np.zeros((8,3))

        # CU_in_buf stores events from crossbar as a tuple (delta, id, valid)
        # say each CU has a buffer of 4 events???
        self.CU_in_buf = np.zeros((8,4,3), dtype=np.float16)
        self.CU_in_buf_n = np.zeros((8,4,3), dtype=np.float16)
        # # CU_out_buf stores last 3 output events as a tuple (delta, id, valid)
        # self.CU_out_buf = np.zeros((8,3,3))
        # self.CU_out_buf_n = np.zeros((8,3,3))


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

        self.CUregValid = np.copy(self.CUregValid_n)
        self.CUIdxreg = np.copy(self.CUIdxreg_n)
        self.CUDeltareg = np.copy(self.CUDeltareg_n)
        # self.CUregtag = np.copy(self.CUregtag_n)

        self.CU_in_buf = np.copy(self.CU_in_buf_n)
        # self.CU_out_buf = np.copy(self.CU_out_buf_n)


        self.coalescing_unit(0)
        self.coalescing_unit(1)
        self.coalescing_unit(2)
        self.coalescing_unit(3)
        self.coalescing_unit(4)
        self.coalescing_unit(5)
        self.coalescing_unit(6)
        self.coalescing_unit(7)









    def coalescing_unit(self, bin_idx):
        # bypass during initial
        if not io_port.initialFinish:
            io_port.CUReady_n[bin_idx] = 1
            io_port.newDelta_n[bin_idx] = np.copy(io_port.CUDelta[bin_idx])
            io_port.newIdx_n[bin_idx] = np.copy(io_port.CUIdx[bin_idx])
            io_port.newValid_n[bin_idx] = np.copy(io_port.CUValid[bin_idx])
            io_port.cuclean_n[bin_idx] = 0
        else:
            # issue new event and update reg0_n
            # output: io_port.searchIdx_n
            # output: io_port.searchValid_n
            self.take_and_issue_new_event(bin_idx)

            # update reg1_n
            self.update_reg1(bin_idx)

            # take searchValue if valid and add
            # update reg2_n
            self.update_reg2(bin_idx)

            # update output
            # output: io_port.newDelta_n
            # output: io_port.newIdx_n
            # output: io_port.newValid_n
            self.update_output(bin_idx)


             # output: io_port.CUclean_n
             # if all reg clean, cu clean next clean
            if (self.CUregValid[bin_idx][0] == 0) and (self.CUregValid[bin_idx][1] == 0) and (self.CUregValid[bin_idx][2] == 0) and (io_port.newValid[bin_idx] ==0) :
                io_port.cuclean_n[bin_idx] = 1
            else:
                io_port.cuclean_n[bin_idx] = 0

            # output: io_port.CUReady_n
            if (self.CU_in_buf[bin_idx][3][2] == 0):
                io_port.CUReady_n[bin_idx] = 1
            else:
                io_port.CUReady_n[bin_idx] = 0

            # output: io_port.cu_empty_n
            if(io_port.cuclean[bin_idx] == 0) and (np.all(self.CU_in_buf[bin_idx,:,2]) == 0) and (io_port.CUValid[bin_idx] == 0) and (io_port.newValid[bin_idx] ==0):
                io_port.cu_empty_n[bin_idx] = 1
            else:
                io_port.cu_empty_n[bin_idx] = 0





    # take event from crossbar
    def take_event(self, bin_idx):
        # take new event from crossbar if valid and has space in buf
        if (io_port.CUReady[bin_idx]):
            if io_port.CUValid[bin_idx]:
                self.CU_in_buf_n[bin_idx][0][0] = io_port.CUDelta[bin_idx]
                self.CU_in_buf_n[bin_idx][0][1] = io_port.CUIdx[bin_idx]
                self.CU_in_buf_n[bin_idx][0][2] = io_port.CUValid[bin_idx]
                self.CU_in_buf_n[bin_idx][1:] = np.copy(self.CU_in_buf[bin_idx][:-1])


    def prepare_new_event(self, bin_idx):
        # take the first-in event
        non_zero_indices = np.nonzero(self.CU_in_buf[bin_idx,:,2])[0]
        # print("CU_in_buf: delta, idx, valid")
        # print(self.CU_in_buf[bin_idx])
        # print(self.CU_in_buf[bin_idx,:,2])
        # print(non_zero_indices)
        # print(non_zero_indices)
        if len(non_zero_indices) > 0 :
            (new_Delta, new_idx, new_Valid) = self.CU_in_buf[bin_idx][non_zero_indices[-1]]
            self.CUIdxreg_n[bin_idx][0] =  new_idx
            self.CUDeltareg_n[bin_idx][0] = new_Delta
            # if conflict, stall
            if (new_idx  == self.CUIdxreg[bin_idx][0]) and (self.CUregValid[bin_idx][0]):
                self.CUregValid_n[bin_idx][0] = 0
            elif (new_idx  == self.CUIdxreg[bin_idx][1]) and (self.CUregValid[bin_idx][1]):
                self.CUregValid_n[bin_idx][0] = 0
            elif (new_idx  == self.CUIdxreg[bin_idx][2]) and (self.CUregValid[bin_idx][2]):
                self.CUregValid_n[bin_idx][0] = 0
            else:
                self.CUregValid_n[bin_idx][0] = new_Valid
                # remove from buf
                self.CU_in_buf_n[bin_idx][non_zero_indices[-1]][0] = 0
                self.CU_in_buf_n[bin_idx][non_zero_indices[-1]][1] = 0
                self.CU_in_buf_n[bin_idx][non_zero_indices[-1]][2] = 0

        else:
            self.CUDeltareg_n[bin_idx][0] = 0
            self.CUIdxreg_n[bin_idx][0] = 0
            self.CUregValid_n[bin_idx][0] = 0

    # take event and issue new event
    # update reg0
    def take_and_issue_new_event(self, bin_idx):
        # if  prepare new event

        if (io_port.binselected[bin_idx] == 0):
            # prepare and update reg0

            self.prepare_new_event(bin_idx)
        else:
            self.CUDeltareg_n[bin_idx][0] = 0
            self.CUIdxreg_n[bin_idx][0] = 0
            self.CUregValid_n[bin_idx][0] = 0

        # take event
        self.take_event(bin_idx)

        if (self.CUregValid_n[bin_idx][0]):
            io_port.searchIdx_n[bin_idx] = self.CUIdxreg_n[bin_idx][0]
            io_port.searchValid_n[bin_idx] = self.CUregValid_n[bin_idx][0]
        else:
            io_port.searchIdx_n[bin_idx] = 0
            io_port.searchValid_n[bin_idx] = 0


    # update reg1
    def update_reg1(self, bin_idx):
        self.CUregValid_n[bin_idx][1] = np.copy(self.CUregValid[bin_idx][0])
        self.CUIdxreg_n[bin_idx][1] = np.copy(self.CUIdxreg[bin_idx][0])
        self.CUDeltareg_n[bin_idx][1] = np.copy(self.CUDeltareg[bin_idx][0])

    # update reg2
    def update_reg2(self, bin_idx):
        if (io_port.searchValueValid[bin_idx] == 1):
            self.CUregValid_n[bin_idx][2] = np.copy(self.CUregValid[bin_idx][1])
        else:
            self.CUregValid_n[bin_idx][2] = 0
        self.CUDeltareg_n[bin_idx][2] = np.float16(self.CUDeltareg[bin_idx][1] + io_port.searchValue[bin_idx])
        self.CUIdxreg_n[bin_idx][2] = np.copy(self.CUIdxreg[bin_idx][1])

    # update CU output
    def update_output(self, bin_idx):
        io_port.newDelta_n[bin_idx] = self.CUDeltareg[bin_idx][2]
        io_port.newIdx_n[bin_idx] = self.CUIdxreg[bin_idx][2]
        io_port.newValid_n[bin_idx] = self.CUregValid[bin_idx][2]
