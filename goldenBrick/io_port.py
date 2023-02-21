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
    rowDelta_n = np.zeros(8, dtype=np.float16)
    binrowIdx_n = 0
    rowValid = 0
    rowValid_n = 0

    # to coalescing unit
    global newReady, newReady_n
    global searchValue, searchValue_n
    global searchValueValid,searchValueValid_n
    newReady = np.zeros(8)
    newReady_n = np.zeros(8)
    searchValue = np.zeros(8, dtype=np.float16)
    searchValue_n = np.zeros(8, dtype=np.float16)
    searchValueValid = np.zeros(8)
    searchValueValid_n = np.zeros(8)

    # state
    global state, state_n
    state = np.zeros(8)
    state_n = np.zeros(8)

    #################################
    ### Output from output buffer ###
    #################################

    # to scheduler
    global rowReady, rowReady_n
    rowReady = False

    # to crossbar1
    global IssDelta, IssDelta_n
    global IssIdx, IssIdx_n
    global IssValid, IssValid_n
    IssDelta = np.zeros(4, dtype=np.float16)
    IssIdx = np.zeros(4)
    IssValid = np.zeros(4)

    #############################
    ### Output from crossbar1 ###
    #############################

    # to output buffer
    global IssReady, IssReady_n
    IssReady = np.zeros(4)

    # to PE
    global PEDelta, PEDelta_n
    global PEIdx, PEIdx_n
    global PEValid, PEValid_n
    PEDelta = np.zeros(4, dtype=np.float16)
    PEIdx = np.zeros(4)
    PEValid = np.zeros(4)

    ###########################
    ### Output from PE (x4) ###
    ###########################

    # to crossbar1
    global PEReady, PEReady_n
    PEReady = np.zeros(4)

    # to crossbar2
    global proDelta, proDelta_n
    global proIdx, proIdx_n
    global proValid, proValid_n
    proDelta = np.zeros(8, dtype=np.float16)
    proIdx = np.zeros(8)
    proValid = np.zeros(8)

    # to edge cache
    global edgeReq, edgeReq_n
    global edgeVertIdx, edgeVertIdx_n
    edgeReq = np.zeros(4)
    edgeVertIdx = np.zeros(4)

    # to scratchpad
    global vertReq, vertReq_n
    global vertIdx, vertIdx_n
    vertReq = np.zeros(4)
    vertIdx = np.zeros(4)

    # to scheduler
    global initialFinish
    initialFinish = 0

    #############################
    ### Output from crossbar2 ###
    #############################

    # to PE
    global proReady, proReady_n
    proReady = np.zeros(8)

    # to CU
    global CUDelta, CUDelta_n
    global CUIdx, CUIdx_n
    global CUValid, CUValid_n
    CUDelta = np.zeros(8, dtype=np.float16)
    CUIdx = np.zeros(8)
    CUValid = np.zeros(8)

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
    global cuclean, cuclean_n
    global searchValid, searchValid_n
    #???
    global searchReady, searchReady_n
    global searchReadyIdx, searchReadyIdx_n
    #???
    searchIdx = np.zeros(8)
    searchIdx_n = np.zeros(8)
    newDelta = np.zeros(8, dtype=np.float16)
    newDelta_n = np.zeros(8, dtype=np.float16)
    newIdx = np.zeros(8)
    newIdx_n = np.zeros(8)
    newValid = np.zeros(8)
    newValid_n = np.zeros(8)
    cuclean = np.zeros(8)
    cuclean_n = np.zeros(8)
    searchValid = np.zeros(8)
    searchValid_n = np.zeros(8)
    searchReady = np.zeros(8)
    searchReadyIdx = np.zeros(8)

    ##############################
    ### Output from scratchpad ###
    ##############################

    # to PE
    global vertResp, vertResp_n
    global vertValid, vertValid_n
    vertResp = np.zeros(4)
    vertValid = np.zeros(4)

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

    # TODO: memory I/O
