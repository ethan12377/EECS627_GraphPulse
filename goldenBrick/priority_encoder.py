import numpy as np


class Priority_Encoder:

    def __init__(self):
        self.priority_row = 0

    def priority(self, rowValid_array):
        for i in range(len(rowValid_array)):
            if (rowValid_array[i]):
                return i
        return False