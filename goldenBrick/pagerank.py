import numpy as np
from scipy.sparse import csr_matrix

# Source: wikipedia, chatgpt, some slight modifications by Peter Zhong

# matrix format: adjacency matrix where M_i,j represents the link from 'j' to 'i', such that for all 'j', sum(i, M_i,j) = 1
#                all edges weighted equally

def matrix_to_csr(matrix, filename):
    rows, cols = len(matrix), len(matrix[0])
    indptr = [0]
    col_indices = []
    for row in matrix:
        for col_idx, value in enumerate(row):
            if value == 1:
                col_indices.append(col_idx)
        indptr.append(len(col_indices))
    with open(filename, 'w') as f:
        f.write(str(col_indices)[1:-1] + '\n')
        f.write(str(indptr)[1:-1] + '\n')

# converts regular adjacency matrix to have: 1) equally weighted edges with sum = 1 and 2) no sinks
def csr_to_matrix(filename):
    # read in col index and row index for csr
    with open(filename, 'r') as f:
        col = [eval(v) for v in f.readline().split(',')]
        row = [eval(v) for v in f.readline().split(',')]
    num_of_vertices = len(row) - 1
    data = np.ones(len(col))
    matrix = csr_matrix((data, col, row), shape=(num_of_vertices, num_of_vertices)).toarray()
    # change all edge weights to (1 / num_of_edges)
    for row in matrix:
        no_adjacency = False
        num_of_edges = np.count_nonzero(row)
        if num_of_edges == 0: # sink detected
            num_of_edges = len(row)
            no_adjacency = True
        for i in range(0, len(row)):
            if row[i] != 0 or no_adjacency:
                row[i] = 1 / num_of_edges
    matrix = matrix.transpose()
    return matrix
        
def pagerank(M, num_iterations: int = 100, d: float = 0.85):
    """PageRank algorithm with explicit number of iterations. Returns ranking of nodes (pages) in the adjacency matrix.

    Parameters
    ----------
    M : numpy array
        adjacency matrix where M_i,j represents the link from 'j' to 'i', such that for all 'j'
        sum(i, M_i,j) = 1
    num_iterations : int, optional
        number of iterations, by default 100
    d : float, optional
        damping factor, by default 0.85

    Returns
    -------
    numpy array
        a vector of ranks such that v_i is the i-th rank from [0, 1],
        v sums to 1

    """
    N = M.shape[1]
    v = np.ones(N) / N
    M_hat = (d * M + (1 - d) / N)
    for i in range(num_iterations):
        v = M_hat @ v
    return v

if __name__ == '__main__':
    '''
    adj_matrix = np.array([[0, 1, 0, 0, 0],
                           [0, 0, 1, 0, 0],
                           [0, 0, 0, 1, 0],
                           [0, 0, 0, 0, 1],
                           [1, 0, 0, 0, 0]])
    adj_matrix = np.array([[0, 1],
                           [0, 0]])
    adj_matrix = np.array([[0, 1, 0],
                           [0, 0, 1],
                           [1, 0, 0]])
    '''
    adj_matrix = np.array([[0, 1, 0, 0, 0, 0, 0, 0, 0, 0],
                           [0, 0, 1, 0, 0, 0, 0, 0, 0, 0],
                           [0, 0, 0, 1, 0, 0, 0, 0, 0, 0],
                           [0, 0, 0, 0, 1, 0, 0, 0, 0, 0],
                           [0, 0, 0, 0, 0, 1, 0, 0, 0, 0],
                           [0, 0, 0, 0, 0, 0, 1, 0, 0, 0],
                           [0, 0, 0, 0, 0, 0, 0, 1, 0, 0],
                           [0, 0, 0, 0, 0, 0, 0, 0, 1, 0],
                           [0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
                           [1, 0, 0, 0, 0, 0, 0, 0, 0, 0],])
    matrix_to_csr(adj_matrix, 'csr.txt')
    M = csr_to_matrix('csr.txt')
    v = pagerank(M, 100, 0.85)
    print(str(v))