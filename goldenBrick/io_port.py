import numpy as np

def init():

    #############################################
    ### Output from event queue and scheduler ###
    #############################################

    # to output buffer
    global rowDelta, rowDelta_n
    global binrowIdx, binrowIdx_n
    global rowValid, rowValid_n
    rowDelta = np.zeros(8, dtype=np.float16)
    binrowIdx = 0
    rowValid = 0
    rowDelta_n = np.zeros(8, dtype=np.float16)
    binrowIdx_n = 0
    rowValid_n = 0

    # to coalescing unit
    global newReady, newReady_n
    global searchValue, searchValue_n
    newReady = np.zeros(8)
    searchValue = np.zeros(8, dtype=np.float16)
    newReady_n = np.zeros(8)
    searchValue_n = np.zeros(8, dtype=np.float16)

    #################################
    ### Output from output buffer ###
    #################################

    # to scheduler
    global rowReady, rowReady_n
    rowReady = False
    rowReady_n = False

    # to crossbar1
    global IssDelta, IssDelta_n
    global IssIdx, IssIdx_n
    global IssValid, IssValid_n
    IssDelta = np.zeros(4, dtype=np.float16)
    IssIdx = np.zeros(4)
    IssValid = np.zeros(4)
    IssDelta_n = np.zeros(4, dtype=np.float16)
    IssIdx_n = np.zeros(4)
    IssValid_n = np.zeros(4)

    #############################
    ### Output from crossbar1 ###
    #############################

    # to output buffer
    global IssReady, IssReady_n
    IssReady = np.zeros(4)
    IssReady_n = np.zeros(4)

    # to PE
    global PEDelta, PEDelta_n
    global PEIdx, PEIdx_n
    global PEValid, PEValid_n
    PEDelta = np.zeros(4, dtype=np.float16)
    PEIdx = np.zeros(4)
    PEValid = np.zeros(4)
    PEDelta_n = np.zeros(4, dtype=np.float16)
    PEIdx_n = np.zeros(4)
    PEValid_n = np.zeros(4)

    ###########################
    ### Output from PE (x4) ###
    ###########################

    # to crossbar1
    global PEReady, PEReady_n
    PEReady = np.zeros(4)
    PEReady_n = np.zeros(4)

    # to crossbar2
    global proDelta, proDelta_n
    global proIdx, proIdx_n
    global proValid, proValid_n
    proDelta = np.zeros(8, dtype=np.float16)
    proIdx = np.zeros(8)
    proValid = np.zeros(8)
    proDelta_n = np.zeros(8, dtype=np.float16)
    proIdx_n = np.zeros(8)
    proValid_n = np.zeros(8)

    # to edge cache
    global edgeReq, edgeReq_n
    global edgeVertIdx, edgeVertIdx_n
    edgeReq = np.zeros(4)
    edgeVertIdx = np.zeros(4)
    edgeReq_n = np.zeros(4)
    edgeVertIdx_n = np.zeros(4)

    # to scratchpad
    global vertReq, vertReq_n
    global vertIdx, vertIdx_n
    vertReq = np.zeros(4)
    vertIdx = np.zeros(4)
    vertReq_n = np.zeros(4)
    vertIdx_n = np.zeros(4)

    #############################
    ### Output from crossbar2 ###
    #############################

    # to PE
    global proReady, proReady_n
    proReady = np.zeros(8)
    proReady_n = np.zeros(8)

    # to CU
    global CUDelta, CUDelta_n
    global CUIdx, CUIdx_n
    global CUValid, CUValid_n
    CUDelta = np.zeros(8, dtype=np.float16)
    CUIdx = np.zeros(8)
    CUValid = np.zeros(8)
    CUDelta_n = np.zeros(8, dtype=np.float16)
    CUIdx_n = np.zeros(8)
    CUValid_n = np.zeros(8)

    ###################################
    ### Output from coalescing unit ###
    ###################################

    # to crossbar2
    global CUReady, CUReady_n
    CUReady = np.zeros(8)
    CUReady_n = np.zeros(8)

    # to queue
    global searchIdx, searchIdx_n
    global newDelta, newDelta_n
    global newIdx, newIdx_n
    global newValid, newValid_n
    searchIdx = np.zeros(8)
    newDelta = np.zeros(8, dtype=np.float16)
    newIdx = np.zeros(8)
    newValid = np.zeros(8)
    searchIdx_n = np.zeros(8)
    newDelta_n = np.zeros(8, dtype=np.float16)
    newIdx_n = np.zeros(8)
    newValid_n = np.zeros(8)

    ##############################
    ### Output from scratchpad ###
    ##############################

    # to PE
    global vertResp, vertResp_n
    global vertValid, vertValid_n
    vertResp = np.zeros(4)
    vertValid = np.zeros(4)
    vertResp_n = np.zeros(4)
    vertValid_n = np.zeros(4)

    # TODO: memory I/O

    ##############################
    ### Output from edge cache ###
    ##############################
    # to PE
    global edgeResp, edgeResp_n
    global edgeValid, edgeValid_n
    global edgeEnd, edgeEnd_n
    edgeResp = np.zeros(4)
    edgeValid = np.zeros(4)
    edgeEnd = np.zeros(4)
    edgeResp_n = np.zeros(4)
    edgeValid_n = np.zeros(4)
    edgeEnd_n = np.zeros(4)

    # TODO: memory I/O
