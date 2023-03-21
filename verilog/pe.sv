/////////////////////////////////////////////////////////////////////////
//                                                                     //
//  Modulename  :  pe.sv                                               //
//                                                                     //
//  Description :  Processsing element                                 // 
//                                                                     //
/////////////////////////////////////////////////////////////////////////

module pe #(
    parameter           C_PEID             = `PE_NUM_OF_CORES  // default to an invalid value, change this parameter for every PE
) (
    ///////////// INPUTS /////////////////
    input   logic                                   clk_i           ,   //  Clock
    input   logic                                   rst_i           ,   //  Reset
    // number of vertices as int 8 and float16 values, sampled on the negative edge of reset?
    input   logic [15:0]                            num_of_vertices_float16_i,
    input   logic [7:0]                             num_of_vertices_int8_i,
    // from crossbar1
    input   logic [`DELTA_WIDTH-1:0]                PEDelta_i,
    input   logic [`VERTEX_IDX_WIDTH-1:0]           PEIdx_i,
    input   logic                                   PEValid_i,
    // from crossbar2
    input   logic [1:0]                             ProReady_i,
    // from mem controller
    input   logic                                   vertexmem_ack_i,
    input   logic                                   edgemem_ack_i,
    // from mem
    input   logic [3:0]                             vertexmem_resp_i,
    input   logic [3:0]                             vertexmem_tag_i,
    input   logic [63:0]                            vertexmem_data_i,
    input   logic [3:0]                             edgemem_resp_i,
    input   logic [3:0]                             edgemem_tag_i,
    input   logic [63:0]                            edgemem_data_i,
    ///////////// OUTPUTS /////////////////
    // idle status
    output  logic                                   idle_o,
    // to scheduler
    output  logic                                   initialFinish_o,
    // to crossbar 1
    output  logic                                   PEReady_o,
    // to crossbar 2
    output  logic [`DELTA_WIDTH-1:0]                ProDelta0_o,
    output  logic [`VERTEX_IDX_WIDTH-1:0]           ProIdx0_o,
    output  logic                                   ProValid0_o,
    output  logic [`DELTA_WIDTH-1:0]                ProDelta1_o,
    output  logic [`VERTEX_IDX_WIDTH-1:0]           ProIdx1_o,
    output  logic                                   ProValid1_o,
    // to vertex mem controller
    output  logic [`XLEN-1:0]                       pe_vertex_reqAddr_o,
    output  logic                                   pe_vertex_reqValid_o,
    output  logic [`DELTA_WIDTH-1:0]                pe_wrData_o,
    output  logic                                   pe_wrEn_o,
    // to edge mem controller
    output logic [`XLEN-1:0]                        pe_edge_reqAddr_o,
    output logic                                    pe_edge_reqValid_o
);

// ====================================================================
// Local Parameters Declarations Start
// ====================================================================

    localparam           C_THRESHOLD        = `PE_THRESH;
    localparam   [15:0]  C_DAMPING_FACTOR   = `PE_DAMPING_FACTOR;
    localparam           C_NUM_OF_CORES     = `PE_NUM_OF_CORES;

// ====================================================================
// Local Parameters Declarations End
// ====================================================================

// ====================================================================
// Signal Declarations Start
// ====================================================================
    
    // states
    enum {S_INIT, S_IDLE, S_RUW, S_EVGEN} curr_state, next_state;

    // status
    logic ready, ruw_complete, initializing;
    logic initializing_n;
    logic [15:0] num_of_vertices_float16;
    logic [7:0]  num_of_vertices_int8;
    logic ruw_complete_n;

    // initialization
    logic init_value_ready, init_value_denom_ready;
    logic [`DELTA_WIDTH-1:0] init_value, init_value_denom;
    logic init_value_ready_n, init_value_denom_ready_n;
    logic [`DELTA_WIDTH-1:0] init_value_n, init_value_denom_n;

    // FPU
    logic [`DELTA_WIDTH-1:0] fpu_opA, fpu_opB, fpu_result;
    logic [1:0] fpu_op, fpu_status_i, fpu_status_o;
    logic fpu_empty, fpu_clear;

    // converter
    logic [15:0] converter_int16, converter_float16;

    // current event info
    logic [`DELTA_WIDTH-1:0] curr_delta, curr_delta_n;
    logic [`VERTEX_IDX_WIDTH-1:0]  curr_idx, curr_idx_n;

    // adjacency list extraction status
    logic [15:0] adj_list_start, adj_list_end;
    logic adj_list_start_ready, adj_list_end_ready;
    logic [15:0] adj_list_start_n, adj_list_end_n;
    logic adj_list_start_ready_n, adj_list_end_ready_n;

    // mem
    enum {VM_IDLE, VM_READ, VM_WRITE}           vm_req_status, vm_req_status_n;
    enum {EM_IDLE, EM_START, EM_END, EM_WORD}   em_req_status, em_req_status_n;
    logic [3:0] curr_vm_tag, curr_em_tag;
    logic [3:0] curr_vm_tag_n, curr_em_tag_n;
    logic vm_acked, em_acked;
    logic vm_acked_n, em_acked_n;

    // propagate evgen
    logic [15:0] curr_evgen_idx;
    logic [`COL_IDX_WORD_TAG_WIDTH-1:0] curr_col_idx_word_tag;
    logic [`DELTA_WIDTH-1:0] curr_prodelta_numerator, curr_prodelta_denom, curr_prodelta;
    logic [63:0] curr_col_idx_word;
    logic [1:0] proport_done;
    logic curr_prodelta_numerator_ready, curr_prodelta_denom_ready, curr_prodelta_ready, curr_col_idx_word_valid;

    logic [15:0] curr_evgen_idx_n;
    logic [`COL_IDX_WORD_TAG_WIDTH-1:0] curr_col_idx_word_tag_n;
    logic [`DELTA_WIDTH-1:0] curr_prodelta_numerator_n, curr_prodelta_denom_n, curr_prodelta_n;
    logic [63:0] curr_col_idx_word_n;
    logic [1:0] proport_done_n;
    logic curr_prodelta_numerator_ready_n, curr_prodelta_denom_ready_n, curr_prodelta_ready_n, curr_col_idx_word_valid_n;


    // internal nets for outputs
    logic pe_vertex_reqValid_n, pe_edge_reqValid_n, pe_wrEn_n, initialFinish_n;
    logic [1:0]                             ProValid_n;
    logic [1:0][`DELTA_WIDTH-1:0]           ProDelta_n;
    logic [1:0][`VERTEX_IDX_WIDTH-1:0]      ProIdx_n;
    logic [`XLEN-1:0]                       pe_vertex_reqAddr_n;
    logic [`DELTA_WIDTH-1:0]                pe_wrData_n;
    logic [`XLEN-1:0]                       pe_edge_reqAddr_n;
    
// ====================================================================
// Signal Declarations End
// ====================================================================

// ====================================================================
// Module Instantiations Start
// ====================================================================
    // ----------------------------------------------------------------
    // Module name  :   fpu
    // Description  :   fpu
    // ----------------------------------------------------------------
    fpu #(
        .PIPELINE_DEPTH(`PE_FPU_PIPE_DEPTH)
    ) pe_fpu (
        .clk(clk_i),
        .reset(rst_i || fpu_clear),
        .opA(fpu_opA),
        .opB(fpu_opB),
        .op(fpu_op),
        .status_i(fpu_status_i),
        .result(fpu_result),
        .status_o(fpu_status_o),
        .empty_o(fpu_empty)
    );

    // ----------------------------------------------------------------
    // ----------------------------------------------------------------
    // Module name  :   int16_to_float16
    // Description  :   int16 to float16 converter
    // ----------------------------------------------------------------
    int16_to_float16 float16_converter (
        .int16_i(converter_int16),
        .float16_o(converter_float16)
    );

    // ----------------------------------------------------------------


// ====================================================================
// Module Instantiations End
// ====================================================================

// ====================================================================
// RTL Logic Start
// ====================================================================

    assign idle_o = (curr_state == S_IDLE);
    assign ready = (next_state == S_IDLE);
    assign fpu_clear = (next_state == S_IDLE);
    // mem
    // always capture response one cycle after acknowledgement
    assign vm_acked_n                   = (vm_req_status_n == VM_IDLE) ? 1'b0 : 
                                          (vertexmem_ack_i) ? 1'b1 : 
                                          (vertexmem_tag_i == curr_vm_tag) ? 1'b0 : vm_acked;
    assign em_acked_n                   = (em_req_status_n == EM_IDLE) ? 1'b0 :              // default while em is idle
                                          (edgemem_ack_i) ? 1'b1 :                           // capture ack while em ack_i
                                          (edgemem_tag_i == curr_em_tag) ? 1'b0 : em_acked; // clear em_acked when previous req fulfilled
    assign curr_vm_tag_n                = (vm_req_status_n == VM_IDLE) ? 'x : 
                                          (vertexmem_ack_i) ? vertexmem_resp_i : 
                                          (vertexmem_tag_i == curr_vm_tag) ? 'x : curr_vm_tag;
    assign curr_em_tag_n                = (em_req_status_n == EM_IDLE) ? 'x : 
                                          (edgemem_ack_i) ? edgemem_resp_i :
                                          (edgemem_tag_i == curr_em_tag) ? 'x : curr_em_tag;

    // ----------------------------------------------------------------
    // Status Registers
    // ----------------------------------------------------------------
    always_ff @(negedge rst_i)
    begin
        num_of_vertices_float16 <= num_of_vertices_float16_i;
        num_of_vertices_int8    <= num_of_vertices_int8_i;
    end

    always_ff @(posedge clk_i)
    begin
        if (rst_i)
        begin
            ruw_complete                    <= 1'b0;
            initializing                    <= 1'b1;
            // init registers
            init_value_ready                <= 1'b0;
            init_value                      <= 'x;
            init_value_denom_ready          <= 1'b0;
            init_value_denom                <= 'x;
            // curr event registers
            curr_delta                      <= 'x;
            curr_idx                        <= 'x;
            // adjacency list registers
            adj_list_start                  <= 'x;
            adj_list_end                    <= 'x;
            adj_list_start_ready            <= 1'b0;
            adj_list_end_ready              <= 1'b0;
            // mem req status registers
            em_req_status                   <= EM_IDLE;
            vm_req_status                   <= VM_IDLE;
            curr_vm_tag                     <= 'x;
            curr_em_tag                     <= 'x;
            vm_acked                        <= 1'b0;
            em_acked                        <= 1'b0;
            // evgen registers
            curr_evgen_idx                  <= 'x;
            curr_col_idx_word_tag           <= 'x;
            curr_prodelta_numerator         <= 'x;
            curr_prodelta_denom             <= 'x;
            curr_prodelta                   <= 'x;
            curr_col_idx_word               <= 'x;
            curr_prodelta_numerator_ready   <= 1'b0;
            curr_prodelta_denom_ready       <= 1'b0;
            curr_prodelta_ready             <= 1'b0;
            curr_col_idx_word_valid         <= 1'b0;
            proport_done                    <= 2'b00;
        end
        else
        begin
            ruw_complete                    <= ruw_complete_n;
            initializing                    <= initializing_n;
            // init registers
            init_value_ready                <= init_value_ready_n;
            init_value                      <= init_value_n;
            init_value_denom_ready          <= init_value_denom_ready_n;
            init_value_denom                <= init_value_denom_n;
            // curr event registers
            curr_delta                      <= curr_delta_n;
            curr_idx                        <= curr_idx_n;
            // adjacency list registers
            adj_list_start                  <= adj_list_start_n;
            adj_list_end                    <= adj_list_end_n;
            adj_list_start_ready            <= adj_list_start_ready_n;
            adj_list_end_ready              <= adj_list_end_ready_n;
            // mem req status registers
            em_req_status                   <= em_req_status_n;
            vm_req_status                   <= vm_req_status_n;
            curr_vm_tag                     <= curr_vm_tag_n;
            curr_em_tag                     <= curr_em_tag_n;
            vm_acked                        <= vm_acked_n;
            em_acked                        <= em_acked_n;
            // evgen registers
            curr_evgen_idx                  <= curr_evgen_idx_n;
            curr_col_idx_word_tag           <= curr_col_idx_word_tag_n;
            curr_prodelta_numerator         <= curr_prodelta_numerator_n;
            curr_prodelta_denom             <= curr_prodelta_denom_n;
            curr_prodelta                   <= curr_prodelta_n;
            curr_col_idx_word               <= curr_col_idx_word_n;
            curr_prodelta_numerator_ready   <= curr_prodelta_numerator_ready_n;
            curr_prodelta_denom_ready       <= curr_prodelta_denom_ready_n;
            curr_prodelta_ready             <= curr_prodelta_ready_n;
            curr_col_idx_word_valid         <= curr_col_idx_word_valid_n;
            proport_done                    <= proport_done_n;
        end
    end

    // ----------------------------------------------------------------
    // Outputs
    // ----------------------------------------------------------------

    always_ff @(posedge clk_i)
    begin
        if (rst_i)
        begin
            // to scheduler
            initialFinish_o         <= 1'b0;
            // to crossbar 1
            PEReady_o               <= 1'b0;
            // to crossbar 2
            ProDelta0_o             <= 'x;
            ProIdx0_o               <= 'x;
            ProValid0_o             <= 1'b0;
            ProDelta1_o             <= 'x;
            ProIdx1_o               <= 'x;
            ProValid1_o             <= 1'b0;
            // to vertex mem controller
            pe_vertex_reqAddr_o     <= 'x;
            pe_vertex_reqValid_o    <= 1'b0;
            pe_wrData_o             <= 'x;
            pe_wrEn_o               <= 1'b0;
            // to edge mem controller
            pe_edge_reqAddr_o       <= 'x;
            pe_edge_reqValid_o      <= 1'b0;
        end
        else
        begin
            // to scheduler
            initialFinish_o         <= initialFinish_n;
            // to crossbar 1
            PEReady_o               <= ready;
            // to crossbar 2
            ProDelta0_o             <= ProDelta_n[0];
            ProIdx0_o               <= ProIdx_n[0];
            ProValid0_o             <= ProValid_n[0];
            ProDelta1_o             <= ProDelta_n[1];
            ProIdx1_o               <= ProIdx_n[1];
            ProValid1_o             <= ProValid_n[1];
            // to vertex mem controller
            pe_vertex_reqAddr_o     <= pe_vertex_reqAddr_n;
            pe_vertex_reqValid_o    <= pe_vertex_reqValid_n;
            pe_wrData_o             <= pe_wrData_n;
            pe_wrEn_o               <= pe_wrEn_n;
            // to edge mem controller
            pe_edge_reqAddr_o       <= pe_edge_reqAddr_n;
            pe_edge_reqValid_o      <= pe_edge_reqValid_n;
        end
    end

    // ----------------------------------------------------------------
    // FSM
    // ----------------------------------------------------------------
    always_comb
    begin
        // set internal nets to default values/holding, overwrite when necessary
        ////////// status regs //////////
        ruw_complete_n                      = ruw_complete;
        initializing_n                      = initializing;
        // init registers
        init_value_ready_n                  = init_value_ready;
        init_value_n                        = init_value;
        init_value_denom_ready_n            = init_value_denom_ready;
        init_value_denom_n                  = init_value_denom;
        // curr event registers
        curr_delta_n                        = curr_delta;
        curr_idx_n                          = curr_idx;
        // adjacency list registers
        adj_list_start_n                    = adj_list_start;
        adj_list_end_n                      = adj_list_end;
        adj_list_start_ready_n              = adj_list_start_ready;
        adj_list_end_ready_n                = adj_list_end_ready;
        // mem req status registers
        vm_req_status_n                     = vm_req_status;
        em_req_status_n                     = em_req_status;
        // evgen registers
        curr_evgen_idx_n                    = curr_evgen_idx;
        curr_col_idx_word_tag_n             = curr_col_idx_word_tag;
        curr_prodelta_numerator_n           = curr_prodelta_numerator;
        curr_prodelta_denom_n               = curr_prodelta_denom;
        curr_prodelta_n                     = curr_prodelta;
        curr_col_idx_word_n                 = curr_col_idx_word;
        curr_prodelta_numerator_ready_n     = curr_prodelta_numerator_ready;
        curr_prodelta_denom_ready_n         = curr_prodelta_denom_ready;
        curr_prodelta_ready_n               = curr_prodelta_ready;
        curr_col_idx_word_valid_n           = curr_col_idx_word_valid;
        proport_done_n                      = proport_done;
        ////////// top-level outputs //////////
        // to scheduler
        initialFinish_n                     = initialFinish_o;
        // to crossbar 2
        ProDelta_n[0]                       = 'x;
        ProIdx_n[0]                         = 'x;
        ProValid_n[0]                       = 1'b0;
        ProDelta_n[1]                       = 'x;
        ProIdx_n[1]                         = 'x;
        ProValid_n[1]                       = 1'b0;
        // to vertex mem controller
        pe_vertex_reqAddr_n                 = 'x;
        pe_vertex_reqValid_n                = 1'b0;
        pe_wrData_n                         = 'x;
        pe_wrEn_n                           = 1'b0;
        // to edge mem controller
        pe_edge_reqAddr_n                   = 'x;
        pe_edge_reqValid_n                  = 1'b0;
        ////////// fpu inputs //////////
        fpu_opA                             = '0;
        fpu_opB                             = '0;
        fpu_op                              = `FPU_ADD;
        fpu_status_i                        = '0;
        ////////// converter input //////////
        converter_int16                     = '0;

        // capture tags from mem when needed (if acknowledged, capture resp at next posedge)
        
        
        // FSM output behavior definition
        case(curr_state)
            //////////////////// INIT ////////////////////
            S_INIT: begin
                initializing_n = 1'b1;
                if (fpu_empty && ~init_value_ready) // no ongoing calculation inside fpu at startup
                begin
                    // calculate initial value denominator
                    fpu_opA = 16'h3C00; // float16 representation of 1
                    fpu_opB = C_DAMPING_FACTOR;
                    fpu_op = `FPU_SUB;
                    fpu_status_i = 2'd3;
                end
                if (fpu_status_o == 2'd2) // init value ready
                begin
                    init_value_n = fpu_result;
                    init_value_ready_n = 1'b1;
                end
                else if (fpu_status_o == 2'd3) // init value denom ready
                begin
                    // calculate initialization value
                    fpu_opA = fpu_result;
                    fpu_opB = num_of_vertices_float16;
                    fpu_op = `FPU_DIV;
                    fpu_status_i = 2'd2;
                end
                // next-state logic
                if (init_value_ready || init_value_ready_n)
                begin
                    adj_list_start_n = C_PEID;
                    adj_list_end_n = num_of_vertices_int8;
                    curr_evgen_idx_n = C_PEID;
                    next_state = S_EVGEN;
                end
                else next_state = S_INIT;
            end
            //////////////////// IDLE ////////////////////
            S_IDLE: begin
                // clear status regs
                ruw_complete_n                    = 1'b0;
                init_value_ready_n                = 1'b0;
                init_value_denom_ready_n          = 1'b0;
                adj_list_start_ready_n            = 1'b0;
                adj_list_end_ready_n              = 1'b0;
                curr_prodelta_numerator_ready_n   = 1'b0;
                curr_prodelta_denom_ready_n       = 1'b0;
                curr_prodelta_ready_n             = 1'b0;
                curr_col_idx_word_valid_n         = 1'b0;
                proport_done_n                    = 2'b00;

                if (PEValid_i)
                begin
                    // store current event
                    curr_delta_n = PEDelta_i;
                    curr_idx_n = PEIdx_i;
                    // send read vertex value request to vertexmem
                    pe_vertex_reqAddr_n = curr_idx_n;
                    pe_wrEn_n = 1'b0;
                    pe_vertex_reqValid_n = 1'b1;
                    vm_req_status_n = VM_READ;
                    // check if delta over threshold
                    if (curr_delta_n > C_THRESHOLD)
                    begin
                        // request start index from edgemem
                        pe_edge_reqAddr_n = {2'b00, 1'b1, 7'b0, curr_idx_n[7:2]};
                        pe_edge_reqValid_n = 1'b1;
                        em_req_status_n = EM_START;
                        // calculate d * delta to prepare for propagate calculation
                        fpu_opA = C_DAMPING_FACTOR;
                        fpu_opB = curr_delta_n;
                        fpu_op = `FPU_MUL;
                        fpu_status_i = 2'd3;
                    end
                    next_state = S_RUW;
                end
                else next_state = S_IDLE;
            end
            //////////////////// RUW ////////////////////
            S_RUW: begin

                // check vertexmem request
                if (vertexmem_tag_i == curr_vm_tag)
                begin
                    if (vm_req_status_n == VM_READ) // read fulfilled
                    begin
                        vm_req_status_n = VM_IDLE;
                        // send data into fpu
                        fpu_opA = vertexmem_data_i[15:0];
                        fpu_opB = curr_delta;
                        fpu_op = `FPU_ADD;
                        fpu_status_i = 2'd1;
                    end
                    else if (vm_req_status_n == VM_WRITE) // write fulfilled
                    begin
                        vm_req_status_n = VM_IDLE;
                        ruw_complete_n = 1'b1;
                    end
                end
                else if (vm_req_status_n != VM_IDLE && ~vm_acked_n) // hold current vertexmem request while not acknowledged by mem
                begin
                    pe_vertex_reqAddr_n = pe_vertex_reqAddr_o;
                    pe_vertex_reqValid_n = pe_vertex_reqValid_o;
                    pe_wrData_n = pe_wrData_o;
                    pe_wrEn_n = pe_wrEn_o;
                end

                // check edge mem request
                if (edgemem_tag_i == curr_em_tag)
                begin
                    if (em_req_status_n == EM_START) // read start fulfilled
                    begin
                        // store start
                        adj_list_start_n = (curr_idx[1:0] == 2'd0) ? edgemem_data_i[15:0] : 
                                           (curr_idx[1:0] == 2'd1) ? edgemem_data_i[31:16] : 
                                           (curr_idx[1:0] == 2'd2) ? edgemem_data_i[47:32] : 
                                           (curr_idx[1:0] == 2'd3) ? edgemem_data_i[63:48] : 'x;
                        adj_list_start_ready_n = 1'b1;
                        // check if start and end are in the same word
                        if (curr_idx[1:0] != 2'd3) // start and end are in the same word
                        begin
                            adj_list_end_n = (curr_idx[1:0] == 2'd0) ? edgemem_data_i[31:16] : 
                                             (curr_idx[1:0] == 2'd1) ? edgemem_data_i[47:32] : 
                                             (curr_idx[1:0] == 2'd2) ? edgemem_data_i[63:48] : 'x;
                            adj_list_end_ready_n = 1'b1;
                            if (adj_list_end_n != adj_list_start_n)
                            begin
                                // grab a column index word from edgemem
                                pe_edge_reqAddr_n = adj_list_start_n >> 3;
                                pe_edge_reqValid_n = 1'b1;
                                em_req_status_n = EM_WORD;
                                curr_col_idx_word_tag_n = adj_list_start_n[15:3];
                            end
                            else em_req_status_n = EM_IDLE;
                        end
                        else // start and end are not in the same word, send edgemem request for end
                        begin
                            pe_edge_reqAddr_n = {2'b00, 1'b1, 7'b0, curr_idx_n[7:2]} + 1;
                            pe_edge_reqValid_n = 1'b1;
                            em_req_status_n = EM_END;
                        end
                    end
                    else if (em_req_status_n == EM_END) // read end fulfilled
                    begin
                        adj_list_end_n = edgemem_data_i[15:0];
                        adj_list_end_ready_n = 1'b1;
                        if (adj_list_end_n != adj_list_start)
                        begin
                            // grab a column index word from edgemem
                            pe_edge_reqAddr_n = adj_list_start_n >> 3;
                            pe_edge_reqValid_n = 1'b1;
                            em_req_status_n = EM_WORD;
                            curr_col_idx_word_tag_n = adj_list_start_n[15:3];
                        end
                        else em_req_status_n = EM_IDLE;
                    end
                    else if (em_req_status_n == EM_WORD) // read col index word fulfilled
                    begin
                        curr_col_idx_word_n = edgemem_data_i;
                        curr_col_idx_word_valid_n = 1'b1;
                        em_req_status_n = EM_IDLE;
                    end
                end
                else if (em_req_status_n != EM_IDLE && ~em_acked_n) // active read waiting on edgemem
                begin
                    pe_edge_reqAddr_n = pe_edge_reqAddr_o;
                    pe_edge_reqValid_n = pe_edge_reqValid_o;
                end

                // check fpu
                if (fpu_status_o == 2'd1) // ruw result obtained
                begin
                    // write result to vertexmem
                    pe_vertex_reqAddr_n = curr_idx;
                    pe_vertex_reqValid_n = 1'b1;
                    pe_wrEn_n = 1'b1;
                    pe_wrData_n = fpu_result;
                    vm_req_status_n = VM_WRITE;
                end
                else if (fpu_status_o == 2'd2) // prodelta obtained
                begin
                    curr_prodelta_n = fpu_result;
                    curr_prodelta_ready_n = 1'b1;
                end
                else if (fpu_status_o == 2'd3) // prodelta numerator obtained
                begin
                    curr_prodelta_numerator_n = fpu_result;
                    curr_prodelta_numerator_ready_n = 1'b1;
                end

                // check if ready to calculate prodelta denominator
                if (adj_list_start_ready_n && adj_list_end_ready_n && ~curr_prodelta_denom_ready_n)
                begin
                    if (adj_list_start_n == adj_list_end_n) // sink detected, distribute pagerank among all other vertices
                    begin
                        adj_list_start_n = 0;
                        adj_list_end_n = {8'b0, num_of_vertices_int8};
                        converter_int16 = {8'b0, num_of_vertices_int8};
                        curr_prodelta_denom_n = converter_float16;
                    end
                    else 
                    begin
                        converter_int16 = adj_list_end_n - adj_list_start_n;
                        curr_prodelta_denom_n = converter_float16;
                    end
                    curr_prodelta_denom_ready_n = 1'b1;
                end

                // check if ready to calculate prodelta
                if (curr_prodelta_denom_ready_n && curr_prodelta_numerator_ready_n && fpu_status_i == 2'd0) // need to make sure prodelta does not overwrite other calculations
                begin
                    fpu_opA = curr_prodelta_numerator_n;
                    fpu_opB = curr_prodelta_denom_n;
                    fpu_op = `FPU_DIV;
                    fpu_status_i = 2'd2;
                end

                // next state logic
                if (curr_prodelta_ready_n && curr_col_idx_word_valid_n) // data ready for evgen
                begin
                    curr_evgen_idx_n = adj_list_start_n;
                    next_state = S_EVGEN;
                end
                else if (ruw_complete_n)
                begin
                    if (curr_delta_n < C_THRESHOLD) next_state = S_IDLE; // no propagation because delta below threshold
                    else if (adj_list_start_ready_n && adj_list_end_ready_n && adj_list_start_n == adj_list_end_n) next_state = S_IDLE; // no propagation because no adjacency
                    else next_state = S_RUW; // still waiting on necessary calculations to be completed
                end
                else next_state = S_RUW;
            end
            //////////////////// EVGEN ////////////////////
            S_EVGEN: begin
                // hold write request to vertexmem when ruw is not completed
                if (~ruw_complete)
                begin
                    if (vertexmem_tag_i == curr_vm_tag) // write request completed by vertexmem
                    begin
                        vm_req_status_n = VM_IDLE;
                        ruw_complete_n = 1;
                    end
                    else if (vm_req_status_n == VM_WRITE && ~vm_acked_n) //  waiting for vertex cache write, hold request
                    begin
                        pe_vertex_reqAddr_n = pe_vertex_reqAddr_o;
                        pe_vertex_reqValid_n = pe_vertex_reqValid_o;
                        pe_wrEn_n = pe_wrEn_o;
                        pe_wrData_n = pe_wrData_o;
                    end
                    else if (fpu_status_o == 2'd1) // ruw result obtained from FPU, sent write request to vertexmem
                    begin 
                        pe_vertex_reqAddr_n = curr_idx;
                        pe_wrEn_n = 1'b1;
                        pe_vertex_reqValid_n = 1'b1;
                        pe_wrData_n = fpu_result;
                        vm_req_status_n = VM_WRITE;
                    end
                end

                // check edgemem request
                if (edgemem_tag_i == curr_em_tag)
                begin
                    if (em_req_status_n == EM_WORD) // col index word read fulfilled
                    begin
                        curr_col_idx_word_n = edgemem_data_i;
                        curr_col_idx_word_valid_n = 1'b1;
                        // clear existing request
                        em_req_status_n = EM_IDLE;
                        pe_edge_reqValid_n = 1'b0;
                    end
                    else if (em_req_status_n != EM_IDLE && ~em_acked_n) 
                    begin
                        pe_edge_reqAddr_n = pe_edge_reqAddr_o;
                        pe_edge_reqValid_n = pe_edge_reqValid_o;
                    end
                end

                // generate proport 0
                if (curr_evgen_idx_n < adj_list_end) // ongoing event generation
                begin
                    if (~ProValid0_o || ProReady_i[0]) // ready to generate or receive new event
                    begin
                        if (initializing) // initialization event, use initialization value
                        begin
                            ProDelta_n[0] = init_value;
                            ProIdx_n[0] = curr_evgen_idx_n[7:0];
                            ProValid_n[0] = 1'b1;
                            curr_evgen_idx_n = curr_evgen_idx_n + C_NUM_OF_CORES;
                        end
                        else if (curr_col_idx_word_valid_n && curr_col_idx_word_tag_n == curr_evgen_idx_n[15:3]) // curr index in curr valid word
                        begin
                            ProDelta_n[0] = curr_prodelta;
                            ProIdx_n[0] = (curr_evgen_idx_n[2:0] == 3'd0) ? curr_col_idx_word_n[7:0] :
                                          (curr_evgen_idx_n[2:0] == 3'd1) ? curr_col_idx_word_n[15:8] :
                                          (curr_evgen_idx_n[2:0] == 3'd2) ? curr_col_idx_word_n[23:16] :
                                          (curr_evgen_idx_n[2:0] == 3'd3) ? curr_col_idx_word_n[31:24] :
                                          (curr_evgen_idx_n[2:0] == 3'd4) ? curr_col_idx_word_n[39:32] :
                                          (curr_evgen_idx_n[2:0] == 3'd5) ? curr_col_idx_word_n[47:40] :
                                          (curr_evgen_idx_n[2:0] == 3'd6) ? curr_col_idx_word_n[55:48] :
                                          (curr_evgen_idx_n[2:0] == 3'd7) ? curr_col_idx_word_n[63:56] : 'x;
                            ProValid_n[0] = 1'b1;
                            curr_evgen_idx_n = curr_evgen_idx_n + 1;
                        end
                        else // curr idx is not in curr word. Invalidate curr word and request edgemem for new word
                        begin
                            curr_col_idx_word_valid_n = 1'b0;
                            // request a new word from edgemem
                            pe_edge_reqAddr_n = curr_evgen_idx_n >> 3;
                            curr_col_idx_word_tag_n = curr_evgen_idx_n[15:3];
                            em_req_status_n = EM_WORD;
                        end
                    end
                    else // not ready to receive new event. Hold current event.
                    begin
                        ProDelta_n[0] = ProDelta0_o;
                        ProIdx_n[0] = ProIdx0_o;
                        ProValid_n[0] = ProValid0_o;
                    end
                end
                else if (~proport_done[0]) // reached the end of evgen, wait for fulfill
                begin
                    if (ProReady_i[0]) proport_done_n[0] = 1'b1;
                    else // hold current propagate event
                    begin
                        ProDelta_n[0] = ProDelta0_o;
                        ProIdx_n[0] = ProIdx0_o;
                        ProValid_n[0] = ProValid0_o;
                    end
                end
            
                // generate proport 1
                if (curr_evgen_idx_n < adj_list_end) // ongoing event generation, curr_evgen_idx_n already updated by proport 0
                begin
                    if (~ProValid1_o || ProReady_i[1]) // ready to generate or receive new event
                    begin
                        if (initializing) // initialization event, use initialization value
                        begin
                            ProDelta_n[1] = init_value;
                            ProIdx_n[1] = curr_evgen_idx_n;
                            ProValid_n[1] = 1'b1;
                            curr_evgen_idx_n = curr_evgen_idx_n + C_NUM_OF_CORES;
                        end
                        else if (curr_col_idx_word_valid_n && curr_col_idx_word_tag_n == curr_evgen_idx_n[15:3]) // curr index in curr valid word
                        begin
                            ProDelta_n[1] = curr_prodelta;
                            ProIdx_n[1] = (curr_evgen_idx_n[2:0] == 3'd0) ? curr_col_idx_word_n[7:0] :
                                          (curr_evgen_idx_n[2:0] == 3'd1) ? curr_col_idx_word_n[15:8] :
                                          (curr_evgen_idx_n[2:0] == 3'd2) ? curr_col_idx_word_n[23:16] :
                                          (curr_evgen_idx_n[2:0] == 3'd3) ? curr_col_idx_word_n[31:24] :
                                          (curr_evgen_idx_n[2:0] == 3'd4) ? curr_col_idx_word_n[39:32] :
                                          (curr_evgen_idx_n[2:0] == 3'd5) ? curr_col_idx_word_n[47:40] :
                                          (curr_evgen_idx_n[2:0] == 3'd6) ? curr_col_idx_word_n[55:48] :
                                          (curr_evgen_idx_n[2:0] == 3'd7) ? curr_col_idx_word_n[63:56] : 'x;
                            ProValid_n[1] = 1'b1;
                            curr_evgen_idx_n = curr_evgen_idx_n + 1;
                        end
                        else // curr idx is not in curr word. Invalidate curr word and request edgemem for new word
                        begin
                            curr_col_idx_word_valid_n = 1'b0;
                            // request a new word from edgemem
                            pe_edge_reqAddr_n = curr_evgen_idx_n >> 3;
                            curr_col_idx_word_tag_n = curr_evgen_idx_n[15:3];
                            em_req_status_n = EM_WORD;
                        end
                    end
                    else // not ready to receive new event. Hold current event.
                    begin
                        ProDelta_n[1] = ProDelta1_o;
                        ProIdx_n[1] = ProIdx1_o;
                        ProValid_n[1] = ProValid1_o;
                    end
                end
                else if (~proport_done[1]) // reached the end of evgen, wait for fulfill
                begin
                    if (ProReady_i[1] || (adj_list_end - adj_list_start == 1)) proport_done_n[1] = 1'b1; // port 1 is automatically done if only generating 1 event
                    else // hold current propagate event
                    begin
                        ProDelta_n[1] = ProDelta1_o;
                        ProIdx_n[1] = ProIdx1_o;
                        ProValid_n[1] = ProValid1_o;
                    end
                end

                // next state
                if (proport_done_n == 2'b11 && (initializing || ruw_complete)) // finished fulfilling last event
                begin
                    // clear initializing status
                    if (initializing)
                    begin
                        initializing_n = 1'b0;
                        initialFinish_n = 1'b1;
                    end
                    next_state = S_IDLE;
                end
                else next_state = S_EVGEN;
            end

            default: begin// illegal state reached. Reset the entire processor
            end
        endcase
    end

    // ----------------------------------------------------------------
    // FSM State Transitions FF
    // ----------------------------------------------------------------
    always_ff @(posedge clk_i)
        if (rst_i) curr_state <= S_INIT;
        else       curr_state <= next_state;


// ====================================================================
// RTL Logic End
// ====================================================================


endmodule
