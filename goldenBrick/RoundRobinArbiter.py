import time
import numpy as np
# bin_priority = 4
class RoundRobinArbiter:
    def __init__(self, row_num):

        self.bin_priority = []
        self.granded_bin = None
        self.granded_bin_valid = None

        self.bin_priority = []
        for i in range(row_num):
            self.bin_priority.append(i)
    
    def request(self, requester_id):
        granded_prority = len(self.bin_priority)
        next_prority = self.bin_priority
        self.granded_bin_valid = 0
        if requester_id.any():
            self.granded_bin_valid = 1 
            for i in range(len(requester_id)):
                if requester_id[i]:
                    if self.bin_priority[i] < granded_prority:
                        granded_prority = self.bin_priority[i]
                        self.granded_bin = i
                    # print(f"update grand_priority{granded_prority}")
                    # print(f"update self.bin_priority{self.bin_priority}") 
            for j in range(len(self.bin_priority)):
                next_prority[j] = (self.bin_priority[j] + len(self.bin_priority) - granded_prority - 1) % len(self.bin_priority)
        self.bin_priority =next_prority    

        if self.granded_bin_valid:
            print(f"row {self.granded_bin} granted access")
            print(f"New priority {self.bin_priority}")
        else:
            print(f"no bin granded")
            
        return (self.granded_bin, self.granded_bin_valid)
                 

# # test the Round Robin Arbiter
# bin_priority = 8
# arbiter = RoundRobinArbiter(bin_priority)
# # print(arbiter.bin_priority)

# request0 = [0,1,0,0,0,0,0,0]
# request1 = [1,0,1,0,0,0,0,1]
# request2 = [0,1,0,0,0,0,0,0]
# request3 = [0,1,0,1,0,0,0,0]
# arbiter.request(request0)
# time.sleep(1)
# arbiter.request(request1)
# time.sleep(1)
# arbiter.request(request2)
# time.sleep(1)
# arbiter.request(request3)
# time.sleep(1)
# arbiter.request([0,0,0,0,0,0,0,0])

