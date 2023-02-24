import io_port
import numpy as np
from queue_scheduler import QS

io_port.init()
QS0 = QS()


#test write_from_cu()
# io_port.newDelta = np.array([1, 2, 3, 4, 5, 6, 7, 8])
# io_port.newIdx = np.array([0, 37, 74, 111, 147, 182, 217, 252])
# # io_port.newValid = np.zeros(8)
# io_port.newValid = np.ones(8)
# for i in range(len(io_port.newDelta)):
#     QS0.write_from_cu(i)
# print("Queue0: ")
# print(QS0.queue)
# print("rowValid_matrix0: ")
# print(QS0.rowValid_matrix)



# test search_for_event

#io_port.searchIdx = np.array([0, 37, 74, 111, 147, 182, 217, 252])
#for i in range(len(io_port.searchIdx)):
#    QS0.search_for_event(i)
#print("searchValue_n: ", io_port.searchValue_n)



#test read_row

# for i in range(8):
#     io_port.cuclean[i] = 1
#     io_port.rowReady = 1
#     #if(i ==0):
#     #    io_port.rowReady = 0
#     #    io_port.cuclean[i] = 0
#     QS0.read_row(i)
#     print("io_port.rowDelta_n: ", io_port.rowDelta_n)
#     print("io_port.binrowIdx_n: ", io_port.binrowIdx_n)
#     print("rowValid_n: ",io_port.rowValid_n)
#     io_port.cuclean[i] = 0
# print("Queue: ")
# print(QS0.queue)
# print("rowValid_matrix: ")
# print(QS0.rowValid_matrix)



# test one_clock
def print_cycle():
    print("io_port.rowDelta_n: ", io_port.rowDelta_n)
    print("io_port.binrowIdx_n: ", io_port.binrowIdx_n)
    print("rowValid_n: ",io_port.rowValid_n)
    print("state_n: ", io_port.state_n)
    print("Queue1: ")
    print(QS0.queue)
    print("rowValid_matrix1: ")
    print(QS0.rowValid_matrix)


# initial
print("Initial: ")
io_port.state = np.zeros(8)
io_port.initialFinish = 0
io_port.newDelta = np.array([1, 1, 1, 1, 1, 1, 1, 1])
io_port.newIdx = np.array([0, 37, 74, 111, 147, 182, 217, 252])
# io_port.newValid = np.zeros(8)
io_port.newValid = np.ones(8)
QS0.one_clock()
print(QS0.queue)
print("rowValid_matrix0: ")
print(QS0.rowValid_matrix)
print("state_n: ", io_port.state_n)

print("Initial will finish: ")
io_port.state = np.copy(io_port.state_n)
io_port.initialFinish = 1
io_port.newDelta = np.array([1, 2, 3, 4, 5, 6, 7, 8])
io_port.newIdx = np.array([0, 37, 74, 111, 147, 182, 217, 252])
# io_port.newValid = np.zeros(8)
io_port.newValid = np.ones(8)
QS0.one_clock()
print(QS0.queue)
print("rowValid_matrix0: ")
print(QS0.rowValid_matrix)
print("state_n: ", io_port.state_n)


print("Cycle1: ")
io_port.state = np.copy(io_port.state_n)
io_port.cuclean = np.array([1, 0, 0, 0, 0, 0, 0, 0])
io_port.rowReady = 1
io_port.newDelta = np.array([0, 9, 0, 0, 0, 0, 0, 9])
io_port.newIdx = np.array([0, 6, 0, 0, 0, 0, 0, 221])
io_port.newValid = np.array([0, 1, 0, 0, 0, 0, 0, 1])
io_port.searchIdx = np.array([0, 37, 74, 111, 147, 182, 217, 252])
io_port.searchValid = np.array([1, 1, 1, 1, 1, 1, 1, 1])
QS0.one_clock()
print_cycle()

print("Cycle2: ")
io_port.state = np.copy(io_port.state_n)
io_port.cuclean = np.array([0, 1, 0, 0, 0, 0, 0, 0])
io_port.rowReady = 1
io_port.newDelta = np.array([0, 10, 0, 0, 0, 0, 0, 0])
io_port.newIdx = np.array([0, 37, 0, 0, 0, 0, 0, 0])
io_port.newValid = np.array([0, 1, 0, 0, 0, 0, 0, 0])
io_port.searchIdx = np.array([0, 6, 0, 0, 0, 0, 0, 221])
io_port.searchValid = np.array([0, 1, 0, 0, 0, 0, 0, 1])
QS0.one_clock()
print_cycle()

print("Cycle3: ")
io_port.state = np.copy(io_port.state_n)
io_port.cuclean = np.array([0, 1, 0, 0, 0, 0, 0, 0])
io_port.rowReady = 0
io_port.newDelta = np.array([0, 0, 11, 0, 0, 0, 0, 0])
io_port.newIdx = np.array([0, 0, 106, 0, 0, 0, 0, 0])
io_port.newValid = np.array([0, 0, 0, 0, 0, 0, 0, 0])
io_port.searchIdx = np.array([0, 37, 0, 0, 0, 0, 0, 0])
io_port.searchValid = np.array([0, 1, 0, 0, 0, 0, 0, 0])
QS0.one_clock()
print_cycle()

print("Cycle4: ")
io_port.state = np.copy(io_port.state_n)
io_port.cuclean = np.array([0, 1, 0, 0, 0, 0, 0, 0])
io_port.rowReady = 1
io_port.newDelta = np.array([0, 0, 11, 0, 0, 0, 0, 0])
io_port.newIdx = np.array([0, 0, 106, 0, 0, 0, 0, 0])
io_port.newValid = np.array([0, 0, 1, 0, 0, 0, 0, 0])
io_port.searchIdx = np.array([0, 37, 0, 0, 0, 0, 0, 0])
io_port.searchValid = np.array([0, 1, 0, 0, 0, 0, 0, 0])
QS0.one_clock()
print_cycle()

print("Cycle5: ")
io_port.state = np.copy(io_port.state_n)
io_port.cuclean = np.array([0, 1, 1, 0, 0, 0, 0, 1])
io_port.rowReady = 1
io_port.newDelta = np.array([12, 0, 0, 0, 0, 0, 0, 0])
io_port.newIdx = np.array([0, 0, 0, 0, 0, 0, 0, 0])
io_port.newValid = np.array([1, 0, 0, 0, 0, 0, 0, 0])
io_port.searchIdx = np.array([0, 0, 106, 0, 0, 0, 0, 221])
io_port.searchValid = np.array([0, 0, 1, 0, 0, 0, 0, 1])
QS0.one_clock()
print_cycle()