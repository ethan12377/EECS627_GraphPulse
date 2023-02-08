import io_port
import numpy as np

# TODO: off chip mem should be able to write to cache via cache controller?

class CC:

    def __init__(self):
        self.latest_gnt = 3

    def one_clock(self):
        # rotating priority, valid-inspecting selector
        io_port.cc_ready_n = [0, 0, 0, 0]
        if (io_port.pe_reqValid != 0).all():
            if io_port.pe_reqValid[(self.latest_gnt + 1) % 4] == 1:
                io_port.cc_ready_n[(self.latest_gnt + 1) % 4] = 1
                self.latest_gnt = (self.latest_gnt + 1) % 4
            elif io_port.pe_reqValid[(self.latest_gnt + 2) % 4] == 1:
                io_port.cc_ready_n[(self.latest_gnt + 2) % 4] = 1
                self.latest_gnt = (self.latest_gnt + 2) % 4
            elif io_port.pe_reqValid[(self.latest_gnt + 3) % 4] == 1:
                io_port.cc_ready_n[(self.latest_gnt + 3) % 4] = 1
                self.latest_gnt = (self.latest_gnt + 3) % 4
            else: # io_port.pe_reqValid[self.latest_gnt] == 1:
                io_port.cc_ready_n[self.latest_gnt] = 1
        
            # mux
            io_port.cc_reqAddr = io_port.pe_reqAddr[self.latest_gnt]
            io_port.cc_wrEn = io_port.pe_wrEn[self.latest_gnt]
            io_port.cc_wrData = io_port.pe_wrData[self.latest_gnt]
