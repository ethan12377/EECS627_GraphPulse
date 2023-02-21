import io_port
import numpy as np
from coalescing_unit import CU

io_port.init()
CU0 = CU()

def print_CU():
    print("CUreg")
    print(CU0.CUreg)
    print("CUregValid")
    print(CU0.CUregValid)
    print("CUregIdx")
    print(CU0.CUregIdx)


CU0.one_clock()
print_CU()