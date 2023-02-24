import io_port
import numpy as np

# TODO: off chip mem should be able to write to cache via cache controller?

class CC:

    def __init__(self, cache_name):
        self.latest_gnt = 3
        self.cache_name = cache_name

    def one_clock(self):
        # rotating priority, valid-inspecting selector
        if self.cache_name == 'ec':
            io_port.cc_ec_ready_n = [0, 0, 0, 0]
            if not all(v == 0 for v in io_port.pe_ec_reqValid):
                if io_port.pe_ec_reqValid[(self.latest_gnt + 1) % 4] == 1:
                    io_port.cc_ec_ready_n[(self.latest_gnt + 1) % 4] = 1
                    self.latest_gnt = (self.latest_gnt + 1) % 4
                elif io_port.pe_ec_reqValid[(self.latest_gnt + 2) % 4] == 1:
                    io_port.cc_ec_ready_n[(self.latest_gnt + 2) % 4] = 1
                    self.latest_gnt = (self.latest_gnt + 2) % 4
                elif io_port.pe_ec_reqValid[(self.latest_gnt + 3) % 4] == 1:
                    io_port.cc_ec_ready_n[(self.latest_gnt + 3) % 4] = 1
                    self.latest_gnt = (self.latest_gnt + 3) % 4
                elif io_port.cc_ec_ready[self.latest_gnt] != 1: # and io_port.pe_reqValid[self.latest_gnt] == 1:
                    # should never be ready for two cycles in a row for the same pe
                    io_port.cc_ec_ready_n[self.latest_gnt] = 1
        
            # mux, typecast to avoid compiler error
            io_port.cc_ec_edgeAddr = int(io_port.pe_ec_reqAddr[self.latest_gnt])

        elif self.cache_name == 'vc':
            io_port.cc_vc_ready_n = [0, 0, 0, 0]
            if not all(v == 0 for v in io_port.pe_vc_reqValid):
                if io_port.pe_vc_reqValid[(self.latest_gnt + 1) % 4] == 1:
                    io_port.cc_vc_ready_n[(self.latest_gnt + 1) % 4] = 1
                    self.latest_gnt = (self.latest_gnt + 1) % 4
                elif io_port.pe_vc_reqValid[(self.latest_gnt + 2) % 4] == 1:
                    io_port.cc_vc_ready_n[(self.latest_gnt + 2) % 4] = 1
                    self.latest_gnt = (self.latest_gnt + 2) % 4
                elif io_port.pe_vc_reqValid[(self.latest_gnt + 3) % 4] == 1:
                    io_port.cc_vc_ready_n[(self.latest_gnt + 3) % 4] = 1
                    self.latest_gnt = (self.latest_gnt + 3) % 4
                elif io_port.cc_vc_ready[self.latest_gnt] != 1: # and io_port.pe_reqValid[self.latest_gnt] == 1:
                    io_port.cc_vc_ready_n[self.latest_gnt] = 1
        
            # mux, typecasted to avoid compiler error
            io_port.cc_vc_vertexAddr = int(io_port.pe_vc_reqAddr[self.latest_gnt])
            io_port.cc_vc_wrEn = io_port.pe_wrEn[self.latest_gnt]
            io_port.cc_vc_wrData = io_port.pe_wrData[self.latest_gnt]
        
        else: # should never get here
            io_port.cc_ec_ready_n = [0, 0, 0, 0]
            io_port.cc_vc_ready_n = [0, 0, 0, 0]
