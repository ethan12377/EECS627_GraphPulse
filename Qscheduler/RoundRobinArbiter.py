import time
# row_priority = 4
class RoundRobinArbiter:
    def __init__(self, row_num):
        self.row_priority = []
        for i in range(row_num):
            self.row_priority.append(i)
    
    def request(self, requester_id):
        granded_prority = len(self.row_priority)
        granded_row = None
        next_prority = self.row_priority
        # print(f"init grand_priority{granded_prority}")
        for i in range(len(requester_id)):
            if requester_id[i]:
                if self.row_priority[i] < granded_prority:
                    granded_prority = self.row_priority[i]
                    granded_row = i

                # print(f"update grand_priority{granded_prority}")
                # print(f"update requester_id{requester_id}")
                # print(f"update self.row_priority{self.row_priority}")
        if granded_prority == len(self.row_priority):
            return len(self.row_priority)
        else:
            for j in range(len(self.row_priority)):
                next_prority[j] = (self.row_priority[j] + len(self.row_priority) - granded_prority - 1) % len(self.row_priority)
            self.row_priority =next_prority    

            print(f"row {granded_row} granted access")
            print(f"New priority {self.row_priority}")
            
            return granded_row
                 

# test the Round Robin Arbiter
# row_priority = 4
# arbiter = RoundRobinArbiter(row_priority)
# print(arbiter.row_priority)

# request0 = [1,0,0,0]
# request1 = [1,0,1,0]
# request2 = [0,1,0,0]
# request3 = [0,1,0,1]
# # print(len(request0))
# arbiter.request(request0)
# time.sleep(1)
# arbiter.request(request1)
# time.sleep(1)
# arbiter.request(request2)
# time.sleep(1)
# arbiter.request(request3)
# time.sleep(1)
# arbiter.request([0,0,0,0])

