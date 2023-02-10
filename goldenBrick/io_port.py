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

    # to coalescing unit
    global newReady, newReady_n
    global searchValue, searchValue_n
    newReady = np.zeros(8)
    searchValue = np.zeros(8, dtype=np.float16)

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
    PEReady_n = np.zeros(4)

    # to crossbar2
    global proDelta, proDelta_n
    global proIdx, proIdx_n
    global proValid, proValid_n
    proDelta = np.zeros(8, dtype=np.float16)
    proDelta_n = np.zeros(8, dtype=np.float16)
    proIdx = np.zeros(8)
    proIdx_n = np.zeros(8)
    proValid = np.zeros(8)
    proValid_n = np.zeros(8)

    # to cache controller
    global pe_vc_reqAddr, pe_vc_reqAddr_n
    global pe_ec_reqAddr, pe_ec_reqAddr_n
    global pe_wrData, pe_wrData_n
    global pe_wrEn, pe_wrEn_n
    global pe_vc_reqValid, pe_vc_reqValid_n
    global pe_ec_reqValid, pe_ec_reqValid_n
    pe_vc_reqAddr = np.zeros(4)
    pe_vc_reqAddr_n = np.zeros(4)
    pe_ec_reqAddr = np.zeros(4)
    pe_ec_reqAddr_n = np.zeros(4)
    pe_wrData = np.zeros(4, dtype=np.float16)
    pe_wrData_n = np.zeros(4, dtype=np.float16)
    pe_wrEn = np.zeros(4)
    pe_wrEn_n = np.zeros(4)
    pe_vc_reqValid = np.zeros(4)
    pe_vc_reqValid_n = np.zeros(4)
    pe_ec_reqValid = np.zeros(4)
    pe_ec_reqValid_n = np.zeros(4)

    # to scratchpad
    # global vertReq, vertReq_n
    # global vertIdx, vertIdx_n
    # vertReq = np.zeros(4)
    # vertIdx = np.zeros(4)

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

    # to queue
    global searchIdx, searchIdx_n
    global newDelta, newDelta_n
    global newIdx, newIdx_n
    global newValid, newValid_n
    searchIdx = np.zeros(8)
    newDelta = np.zeros(8, dtype=np.float16)
    newIdx = np.zeros(8)
    newValid = np.zeros(8)

    ##############################
    ### Output from scratchpad ###
    ##############################

    # to PE
    global vc_rdData, vc_rdData_n
    # global vertValid, vertValid_n
    # vertResp = np.zeros(4)
    # vertValid = np.zeros(4)

    # TODO: memory I/O

    #########################
    ### Output from cache ###
    #########################
    
    global vc_rdData, vc_rdData_n, ec_rdData, ec_rdData_n
    # global edgeEnd, edgeEnd_n
    vc_rdData = np.float16(0.0)
    vc_rdData_n = np.float16(0.0)
    ec_rdData = np.zeros(8)
    ec_rdData_n = np.zeros(8)

    # edgeEnd = np.zeros(4)

    # TODO: memory I/O

    ####################################
    ### Output from Cache controller ###
    ####################################
    # to vertex cache
    global cc_vc_vertexAddr, cc_vc_wrEn, cc_vc_wrData
    cc_vc_vertexAddr = 0
    cc_vc_wrEn = 0
    cc_vc_wrData = np.float16(0.0)

    # to edge cache
    global cc_ec_edgeAddr
    cc_ec_edgeAddr = 0

    # to PE
    global cc_ec_ready, cc_ec_ready_n, cc_vc_ready, cc_vc_ready_n
    cc_ec_ready = np.zeros(4)
    cc_ec_ready_n = np.zeros(4)
    cc_vc_ready = np.zeros(4)
    cc_vc_ready_n = np.zeros(4)
