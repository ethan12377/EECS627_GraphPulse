import io_port
import numpy as np

NUM_MEM_TAGS = 16
MEM_LATENCY_IN_CYCLES = 10

class VMEM:
    def __init__(self, csr_filename):
        # initialize all vertex values to zero
        self.vertexValues = np.zeros(256, dtype=np.float16)

        self.loaded_data = np.zeros(NUM_MEM_TAGS, dtype=np.float16)
        self.cycles_left = np.zeros(NUM_MEM_TAGS)
        self.waiting_for_bus = np.zeros(NUM_MEM_TAGS)

    def one_clock():
        io_port.vmem_tag_n = 0
        io_port.vmem_rsp_n = 0
        io_port.vmem_data_n = np.float16(0.0)
        bus_filled = 0
        acquire_tag = (io_port.mc_vm_cmd==1 or io_port.mc_vm_cmd==2)

        for i in range(NUM_MEM_TAGS):
            if self.cycles_left[i] > 0:
                self.cycles_left[i] = self.cycles_left[i] - 1
            elif (acquire_tag and !self.waiting_for_bus[i]):
                io_port.vmem_rsp_n = i+1
                acquire_tag = 0
                self.cycles_left[i] = MEM_LATENCY_IN_CYCLES

                if (io_port.mc_vm_cmd==1):
                    self.waiting_for_bus[i] = 1
                    self.loaded_data[i] = self.vertexValues[io_port.mc_vm_addr]
                else:
                    self.vertexValues[io_port.mc_vm_addr] = io_port.mc_vm_data

            if (self.cycles_left[i]==0 and self.waiting_for_bus[i] and !bus_filled):
                bus_filled = 1
                io_port.vmem_tag_n = i+1
                io_port.vmem_data_n = self.loaded_data[i]
                self.waiting_for_bus[i] = 0
