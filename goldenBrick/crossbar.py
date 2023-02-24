import io_port
import numpy as np
from queue import Queue
import copy

class Xbar_SchedToPE:

    def __init__(self, num_input = 4, num_output = 4, num_stages = 1):
        # Reconfigurable Parameters
        self.num_input = num_input
        self.num_output = num_output
        if num_stages <= 0:
            self.num_stages = 1
        else:
            self.num_stages = num_stages

        # Freelist: Track the free (not busy) PEs
        self.freelist = Queue(maxsize=self.num_output)
        # for output_idx in range(self.num_output):
        #     self.freelist.put_nowait(output_idx)

        # PE allocation
        self.PE_alloc = np.zeros(self.num_input, dtype=np.uint8)
        self.PE_alloc_n = np.zeros(self.num_input, dtype=np.uint8)

        # Locks to prevent PEs to be inserted to freelist wrongly
        self.PELock = np.zeros(self.num_output, dtype=np.uint8)
        self.PELock_n = np.zeros(self.num_output, dtype=np.uint8)

        # Pipeline stages
        self.PEDelta_stages = Queue(maxsize=self.num_stages+1)
        self.PEIdx_stages   = Queue(maxsize=self.num_stages+1)
        self.PEValid_stages = Queue(maxsize=self.num_stages+1)
        for stage_idx in range(self.num_stages):
            self.PEDelta_stages.put_nowait(np.zeros(self.num_output, dtype=np.float16))
            self.PEIdx_stages.put_nowait(np.zeros(self.num_output, dtype=np.uint8))
            self.PEValid_stages.put_nowait(np.zeros(self.num_output, dtype=np.uint8))


    def one_clock(self):
        # input:
        #   io_port.IssDelta
        #   io_port.IssIdx
        #   io_port.IssValid
        #   io_port.PEReady

        # TODO: update *_n

        print('Freelist = ', list(self.freelist.queue))
        print('PELock = ', list(self.PELock))

        # Clear the first entry in pipeline
        PEDelta_tmp    = np.zeros(self.num_output, dtype=np.float16)
        PEIdx_tmp      = np.zeros(self.num_output, dtype=np.uint8)
        PEValid_tmp    = np.zeros(self.num_output, dtype=np.uint8)
        for output_idx in range(self.num_output):
            PEDelta_tmp[output_idx] = np.float16(0)
            PEIdx_tmp[output_idx]   = np.uint8(0)
            PEValid_tmp[output_idx] = np.uint8(0)

        # Clear the ready signal to scheduler
        for input_idx in range(self.num_input):
            io_port.IssReady_n[input_idx] = np.uint8(0)

        # Allocate target PE for each valid input and remove one entry from freelist
        self.PE_alloc_n= np.zeros(self.num_input, dtype=np.uint8)
        for input_idx in range(self.num_input):
            if self.freelist.empty() == 0:
                if io_port.IssValid[input_idx] == 1 and io_port.IssReady[input_idx] == 0:
                    # Handshake
                    io_port.IssReady_n[input_idx] = np.uint8(1)
                    # Pop an entry from freelist
                    self.PE_alloc_n[input_idx] = self.freelist.get_nowait()
                else:
                    break
            else:
                break

        # Route the input to allocated output
        for input_idx in range(self.num_input):
            if io_port.IssValid[input_idx] == 1 and io_port.IssReady[input_idx] == 1:
                PEDelta_tmp[self.PE_alloc[input_idx]] = io_port.IssDelta[input_idx]
                PEIdx_tmp[self.PE_alloc[input_idx]] = io_port.IssIdx[input_idx]
                PEValid_tmp[self.PE_alloc[input_idx]] = io_port.IssValid[input_idx]

        self.PEDelta_stages.put_nowait(PEDelta_tmp)
        self.PEIdx_stages.put_nowait(PEIdx_tmp)
        self.PEValid_stages.put_nowait(PEValid_tmp)
        # print('PEDelta_stages = ', list(self.PEDelta_stages.queue))
        # print('PEIdx_stages = ', list(self.PEIdx_stages.queue))
        # print('PEValid_stages = ', list(self.PEValid_stages.queue))


        # convergence condition (PEValid is all 0s)
        io_port.xbar1_empty = 1
        for vals in self.PEValid_stages.queue:
            if np.any(vals):
                io_port.xbar1_empty = 0

        # The oldest entry in pipeline is assigned to output
        io_port.PEDelta_n = self.PEDelta_stages.get_nowait()
        io_port.PEIdx_n = self.PEIdx_stages.get_nowait()
        io_port.PEValid_n = self.PEValid_stages.get_nowait()

        # Freelist operations
        for output_idx in range(self.num_output):

            # Insert a new entry if the PE is not locked and is ready
            if io_port.PEReady[output_idx] == 1 and self.PELock[output_idx] == 0:
                # Insert
                self.freelist.put_nowait(output_idx)
                # Lock the allocated PE to prevent wrong insertion
                self.PELock_n[output_idx] = np.uint8(1)

            # Remove lock if the corresponding PE complete a handshake
            if io_port.PEValid[output_idx] == 1 and io_port.PEReady[output_idx] == 1:
                self.PELock_n[output_idx] = np.uint8(0)

        # print('Freelist = ', list(self.freelist.queue))
        # print('PELock = ', list(self.PELock))

        self.print_signals()


    def print_signals(self):
        for i in range(self.num_input):
            print('IssDelta[',i,'] = ', np.around(io_port.IssDelta[i], 3),'\tIssIdx[', i, '] = ', io_port.IssIdx[i], '\tIssValid[', i, '] = ', io_port.IssValid[i], '\tIssReady[', i, '] = ', io_port.IssReady[i], '\tPE_alloc[', i, '] = ', self.PE_alloc[i])

        for i in range(self.num_input):
            print('PEDelta[',i,'] = ', np.around(io_port.PEDelta[i], 3),'\tPEIdx[', i, '] = ', io_port.PEIdx[i], '\tPEValid[', i, '] = ', io_port.PEValid[i], '\tPEReady[', i, '] = ', io_port.PEReady[i])
        print('PEDelta_stages = ', list(self.PEDelta_stages.queue))
        print('PEIdx_stages = ', list(self.PEIdx_stages.queue))
        print('PEValid_stages = ', list(self.PEValid_stages.queue))

    def update(self):
        self.PELock = copy.deepcopy(self.PELock_n)
        self.PE_alloc = copy.deepcopy(self.PE_alloc_n)


class Xbar_PEToQ:

    def __init__(self, num_input = 8, num_output = 8, num_stages = 1, bin_lsb =3, bin_w = 3):
        # Reconfigurable parameters
        self.num_input = num_input
        self.num_output = num_output
        if num_stages <= 0:
            self.num_stages = 1
        else:
            self.num_stages = num_stages
        self.bin_lsb = bin_lsb
        self.bin_mask = np.uint8(2 ** bin_w - 1)

        # Arbiter internal signals (combinational)
        self.arb_request = np.zeros(self.num_output, dtype=np.uint8)
        self.arb_mask = np.zeros(self.num_output, dtype=np.uint8)
        self.arb_mask_n = np.zeros(self.num_output, dtype=np.uint8)
        self.init_mask = np.uint8(2 ** self.num_input - 1)
        for output_idx in range(self.num_output):
            self.arb_mask[output_idx] = self.init_mask  # masks are initialized to all 1s
            self.arb_mask_n[output_idx] = self.init_mask  # masks are initialized to all 1s
        self.arb_grant = np.zeros(self.num_output, dtype=np.uint8)
        # self.arb_grant_n = np.zeros(self.num_output, dtype=np.uint8)
        self.bin_lock = np.zeros(self.num_output, dtype=np.uint8)
        self.bin_lock_n = np.zeros(self.num_output, dtype=np.uint8)

        # Pipeline stages
        self.CUDelta_stages = Queue(maxsize=self.num_stages+1)
        self.CUIdx_stages   = Queue(maxsize=self.num_stages+1)
        self.CUValid_stages = Queue(maxsize=self.num_stages+1)
        for stage_idx in range(self.num_stages):
            self.CUDelta_stages.put_nowait(np.zeros(self.num_output, dtype=np.float16))
            self.CUIdx_stages.put_nowait(np.zeros(self.num_output, dtype=np.uint8))
            self.CUValid_stages.put_nowait(np.zeros(self.num_output, dtype=np.uint8))

    def one_clock(self):
        # input:
        #   io_port.proDelta
        #   io_port.proIdx
        #   io_port.proValid
        #   io_port.CUReady

        # TODO: update *_n

        # Input Switches

        # Clear requests in the previous cycle
        self.arb_request = np.zeros(self.num_output, dtype=np.uint8)

        # Iterate through the inputs and route the requests to output channels
        for input_idx in range(self.num_input):
            if io_port.proValid[input_idx] == 0:
                continue
            if io_port.proReady[input_idx] == 1:
                continue
            # Bin index decides output channel
            bin_idx = ((io_port.proIdx[input_idx] >> self.bin_lsb) & self.bin_mask)
            print('idx = ', io_port.proIdx[input_idx], '\tshifted = ', np.binary_repr(io_port.proIdx[input_idx] >> self.bin_lsb),'\tbin_idx = ', bin_idx)
            self.arb_request[bin_idx] = self.arb_request[bin_idx] | np.uint8(1 << input_idx)

        # Output Arbiters

        # Clear grants in the previous cycle
        self.arb_grant = np.zeros(self.num_output, dtype=np.uint8)

        # Iterate through the outputs and arbitrate
        for output_idx in range(self.num_output):

            # Bin not ready to receive new event
            if io_port.CUReady[output_idx] == 0:
                continue

            # Bin is dealing with a transmitting event:
            if self.bin_lock[output_idx] == 1:
                continue

            # No request to send to the bin
            if self.arb_request[output_idx] == 0:
                continue

            masked = self.arb_mask[output_idx] & self.arb_request[output_idx]
            shifted = np.uint8(0)
            if masked == 0:
                shifted = self.arb_request[output_idx]
            else:
                shifted = masked

            for req_idx in range(self.num_input):
                if shifted & np.uint8(1) == 1:
                    self.arb_grant[output_idx] = np.uint8(1 << req_idx)
                    break
                else:
                    shifted = shifted >> 1

        # Clear proReady in previous cycle
        io_port.proReady_n = np.zeros(self.num_input, dtype=np.uint8)

        # Transmit Inputs to Outputs
        CUDelta_tmp = np.zeros(self.num_output, dtype=np.float16)
        CUIdx_tmp = np.zeros(self.num_output, dtype=np.uint8)
        CUValid_tmp = np.zeros(self.num_output, dtype=np.uint8)

        for output_idx in range(self.num_output):
            if self.arb_grant[output_idx] == 0:
                continue
            else:
                for input_idx in range(self.num_input):
                    if self.arb_grant[output_idx] & np.uint8(1 << input_idx) != 0:
                        CUDelta_tmp[output_idx] = io_port.proDelta[input_idx]
                        CUIdx_tmp[output_idx] = io_port.proIdx[input_idx]
                        CUValid_tmp[output_idx] = io_port.proValid[input_idx]
                        io_port.proReady_n[input_idx] = np.uint8(1)
                        # Lock the output (bin) to suppress arbitration in the next cycle
                        self.bin_lock_n[output_idx] = np.uint8(1)
                        break

        # Update mask
        self.arb_mask_n = np.zeros(self.num_output, dtype=np.uint8)
        for output_idx in range(self.num_output):
            arb_grant_tmp = self.arb_grant[output_idx]
            if arb_grant_tmp == 0:
                self.arb_mask_n[output_idx] = copy.deepcopy(self.arb_mask[output_idx])
            else:
                self.arb_mask_n[output_idx] = self.init_mask
                while arb_grant_tmp != 0:
                    self.arb_mask_n[output_idx] = self.arb_mask_n[output_idx] << 1
                    arb_grant_tmp = arb_grant_tmp >> 1

        # Pipelining
        self.CUDelta_stages.put_nowait(CUDelta_tmp)
        self.CUIdx_stages.put_nowait(CUIdx_tmp)
        self.CUValid_stages.put_nowait(CUValid_tmp)

        # convergence condition (CUValid is all 0s)
        io_port.xbar2_empty = 1
        for vals in self.CUValid_stages.queue:
            if np.any(vals):
                io_port.xbar2_empty = 0

        io_port.CUDelta_n = self.CUDelta_stages.get_nowait()
        io_port.CUIdx_n = self.CUIdx_stages.get_nowait()
        io_port.CUValid_n = self.CUValid_stages.get_nowait()

        # Release bin_lock if handshake at output
        for output_idx in range(self.num_output):
            if io_port.CUValid[output_idx] == 1:
                self.bin_lock_n[output_idx] = np.uint8(0)

        self.print_signals()


    def print_signals(self):
        for i in range(self.num_input):
            print('proDelta[',i,'] = ', np.around(io_port.proDelta[i], 3),'\tproIdx[', i, '] = ', io_port.proIdx[i], '\tproValid[', i, '] = ', io_port.proValid[i], '\tproReady[', i, '] = ', io_port.proReady[i])
        # print('CUDelta_stages = ', list(self.CUDelta_stages.queue))
        # print('CUIdx_stages = ', list(self.CUIdx_stages.queue))
        # print('CUValid_stages = ', list(self.CUValid_stages.queue))

        for i in range(self.num_output):
            print('Arbiter[', i, ']: request = ', np.binary_repr(self.arb_request[i], self.num_input), '\tgrant = ', np.binary_repr(self.arb_grant[i], self.num_input), '\tmask = ', np.binary_repr(self.arb_mask[i], self.num_input), '\tlock = ', self.bin_lock[i])

        # for i in range(self.num_output):
        #     print('arb_grant_n[', i, '] = ', np.binary_repr(self.arb_grant_n[i]), '\tarb_mask_n[', i, '] = ', np.binary_repr(self.arb_mask_n[i]))
        for i in range(self.num_input):
            print('CUDelta[',i,'] = ', np.around(io_port.CUDelta[i], 3),'\tCUIdx[', i, '] = ', io_port.CUIdx[i], '\tCUValid[', i, '] = ', io_port.CUValid[i], '\tCUReady[', i, '] = ', io_port.CUReady[i])


    def update(self):
        # self.arb_grant = copy.deepcopy(self.arb_grant_n)
        self.arb_mask = copy.deepcopy(self.arb_mask_n)
        self.bin_lock = copy.deepcopy(self.bin_lock_n)
