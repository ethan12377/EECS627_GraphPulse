import numpy as np


class Priority_Encoder:

    def __init__(self):
        self.priority_bin = 0
        self.num_rowValid = np.zeros(8)

    def priority(self, rowValid):
        for i in range(rowValid.shape[0]):
            self.temp = 0
            for j in range(rowValid.shape[1]):
                self.temp += rowValid[i][j]
            self.num_rowValid[i] = self.temp

        string = "num_rowValid "
        print(string, self.num_rowValid)

        self.temp = 0    
        for i in range(len(self.num_rowValid)):
            if(self.num_rowValid[i] > self.temp):
                self.temp = self.num_rowValid[i]
                self.priority_bin = i
