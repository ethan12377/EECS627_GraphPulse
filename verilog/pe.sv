/////////////////////////////////////////////////////////////////////////
//                                                                     //
//  Modulename  :  pe.sv                                               //
//                                                                     //
//  Description :  Processsing element                                 // 
//                                                                     //
/////////////////////////////////////////////////////////////////////////

// TODO: Reading in num of vertices

module pe #(
    parameter           C_PEID             = `PE_NUM_OF_CORES  // default to an invalid value, change this parameter for every PE
) (
    ///////////// INPUTS /////////////////
    input   logic               clk_i           ,   //  Clock
    input   logic               rst_i           ,   //  Reset
    // number of vertices as int 8 and float16 values, sampled on the negative edge of reset?
    input   logic [15:0]        num_of_vertices_float16_i,
    input   logic [7:0]         num_of_vertices_int8_i,
    // from crossbar1
    input   logic [15:0]        PEDelta_i,
    input   logic [7:0]         PEIdx_i,
    input   logic               PEValid_i,
    // from crossbar2
    input   logic [1:0]         ProReady_i,
    // from mem and mem controllers
    input   logic               vertexmem_ready_i,
    input   logic               edgemem_ready_i,
    input   logic [63:0]        vertexmem_data_i,
    input   logic [63:0]        edgemem_data_i,

    ///////////// OUTPUTS /////////////////
    // idle status
    output  logic               idle_o,
    // to crossbar 1
    output  logic               PEReady_o,
    // to crossbar 2
    output  logic [15:0]        ProDelta0_o,
    output  logic [7:0]         ProIdx0_o,
    output  logic               ProValid0_o,
    output  logic [15:0]        ProDelta1_o,
    output  logic [7:0]         ProIdx1_o,
    output  logic               ProValid1_o,
    // to vertex mem controller
    output  logic [7:0]         pe_vertex_reqAddr_o,
    output  logic               pe_vertex_reqValid_o,
    output  logic [15:0]        pe_wrData_o,
    output  logic               pe_wrEn_o,
    // to edge mem controller
    output logic [13:0]         pe_edge_reqAddr_o,
    output logic                pe_edge_reqValid_o
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
    logic [15:0] num_of_vertices_float16;
    logic [7:0]  num_of_vertices_int8;
    logic ruw_complete_n;

    // initialization
    logic init_value_ready, init_value_denom_ready;
    logic [15:0] init_value, init_value_denom;
    logic init_value_ready_n, init_value_denom_ready_n;
    logic [15:0] init_value_n, init_value_denom_n;

    // FPU
    logic [15:0] fpu_opA, fpu_opB, fpu_result;
    logic [1:0] fpu_op, fpu_status_i, fpu_status_o;
    logic fpu_empty, fpu_clear;

    // current event info
    logic [15:0] curr_delta, curr_delta_n;
    logic [7:0]  curr_idx, curr_idx_n;

    // adjacency list extraction status
    logic [7:0] adj_list_start, adj_list_end;
    logic adj_list_start_ready, adj_list_end_ready;
    logic [7:0] adj_list_start_n, adj_list_end_n;
    logic adj_list_start_ready_n, adj_list_end_ready_n;

    // mem req status
    logic [1:0] vc_req_status, ec_req_status;
    logic [1:0] vc_req_status_n, ec_req_status_n;

    // propagate evgen
    logic [7:0] curr_evgen_idx, curr_col_idx_word_tag;
    logic [15:0] curr_prodelta_numerator, curr_prodelta_denom, curr_prodelta;
    logic [63:0] curr_col_idx_word;
    logic curr_prodelta_numerator_ready, curr_prodelta_denom_ready, curr_prodelta_ready, curr_col_idx_word_valid;
    logic [7:0] curr_evgen_idx_n, curr_col_idx_word_tag_n;
    logic [15:0] curr_prodelta_numerator_n, curr_prodelta_denom_n, curr_prodelta_n;
    logic [63:0] curr_col_idx_word_n;
    logic curr_prodelta_numerator_ready_n, curr_prodelta_denom_ready_n, curr_prodelta_ready_n, curr_col_idx_word_valid_n;

    // internal nets for outputs
    logic PEReady_n, pe_vertex_reqValid_n, pe_edge_reqValid_n, pe_wrEn_n;
    logic [1:0]              ProValid_n;
    logic [1:0][15:0]        ProDelta_n;
    logic [1:0][7:0]         ProIdx_n;
    logic [7:0]              pe_vertex_reqAddr_n;
    logic [15:0]             pe_wrData_n;
    logic [13:0]             pe_edge_reqAddr_n;          
    
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
    fpu fpu0 #(`PE_FPU_PIPE_DEPTH) (
        .clk(clk_i),
        .reset(rst_i || fpu_clear),
        .opA(fpu_opA),
        .opB(fpu_opB),
        .op(fpu_op),
        .status_i(fpu_status_i),
        .result(fpu_result),
        .status_o(fpu_status_o),
        .empty(fpu_empty)
    );

    // ----------------------------------------------------------------


// ====================================================================
// Module Instantiations End
// ====================================================================

// ====================================================================
// RTL Logic Start
// ====================================================================

    assign idle_o = (curr_state == S_IDLE);
    assign initializing = (curr_state == S_INIT);
    assign ready = (curr_state == S_IDLE);
    assign fpu_clear = (curr_state == S_IDLE);

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
            ec_req_status                   <= '0;
            vc_req_status                   <= '0;
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
        end
        else
        begin
            ruw_complete                    <= ruw_complete_n;
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
            ec_req_status                   <= ec_req_status_n;
            vc_req_status                   <= vc_req_status_n;
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
        ec_req_status_n                     = ec_req_status;
        vc_req_status_n                     = vc_req_status;
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
        ////////// top-level outputs //////////
        pe_edge_reqValid_n                  = 1'b0;
        pe_vertex_reqValid_n                = 1'b0;
        pe_wrEn_n                           = 1'b0;
        ProValid_n                          = 2'b00;
        ////////// fpu inputs //////////
        fpu_opA                             = '0;
        fpu_opB                             = '0;
        fpu_status_i                        = '0;
        
        // FSM output behavior definition
        case(curr_state)
            //////////////////// INIT ////////////////////
            S_INIT: begin
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
                    curr_evgen_idx = C_PEID;
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

                if (PEValid_i)
                begin
                    // store current event
                    curr_delta_n = PEDelta_i;
                    curr_idx_n = PEIdx_i;
                    // send read vertex value request to vertexmem
                    pe_vertex_reqAddr_n = curr_idx_n;
                    pe_wrEn_n = 1'b0;
                    pe_vertex_reqValid_n = 1'b1;
                    vc_req_status_n = 2'd1;
                    // check if delta over threshold
                    if (curr_delta_n > C_THRESHOLD)
                    begin
                        // request start index from edgemem
                        pe_edge_reqAddr_n = 'x;
                        pe_edge_reqValid_n = 1'b1;
                        ec_req_status_n = 2'd1;
                        // calculate d * delta to prepare for propagate calculation
                        fpu_opA = C_DAMPING_FACTOR;
                        fpu_opB = curr_delta_n;
                        fpu_status_i = 2'd3;
                    end
                    next_state = S_RUW;
                end
                else next_state = S_IDLE;
            end
            //////////////////// RUW ////////////////////
            S_RUW: begin
                
            end
            //////////////////// EVGEN ////////////////////
            S_EVGEN: begin
                
            end
            default:
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
