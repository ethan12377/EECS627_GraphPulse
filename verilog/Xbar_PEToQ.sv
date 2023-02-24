/////////////////////////////////////////////////////////////////////////
//                                                                     //
//  Modulename  :  Xbar_PEToQ.sv                                       //
//                                                                     //
//  Description :  Crossbar from PEs to Event Queues                   // 
//                                                                     //
/////////////////////////////////////////////////////////////////////////

module Xbar_PEToQ #(
    parameter   C_GEN_NUM           =   `GEN_NUM            ,
    parameter   C_BIN_NUM           =   `BIN_NUM            ,
    parameter   C_STAGES_NUM        =   `XBAR_1_STAGES_NUM  ,
    parameter   C_DELTA_WIDTH       =   `DELTA_WIDTH        ,
    parameter   C_VERTEX_IDX_WIDTH  =   `VERTEX_IDX_WIDTH   ,
    parameter   C_PE_IDX_WIDTH      =   `PE_IDX_WIDTH       ,
    parameter   C_BIN_IDX_WIDTH     =   `BIN_IDX_WIDTH      ,
    parameter   C_BIN_IDX_LSB       =   `BIN_IDX_LSB        
) (
    input   logic                                               clk_i       ,   //  Clock
    input   logic                                               rst_i       ,   //  Reset

    input   logic   [C_GEN_NUM-1:0][C_DELTA_WIDTH-1:0]          proDelta_i  ,
    input   logic   [C_GEN_NUM-1:0][C_VERTEX_IDX_WIDTH-1:0]     proIdx_i    ,
    input   logic   [C_GEN_NUM-1:0]                             proValid_i  ,
    output  logic   [C_GEN_NUM-1:0]                             proReady_o  ,

    output  logic   [C_BIN_NUM-1:0][C_DELTA_WIDTH-1:0]          CUDelta_o   ,
    output  logic   [C_BIN_NUM-1:0][C_VERTEX_IDX_WIDTH-1:0]     CUIdx_o     ,
    output  logic   [C_BIN_NUM-1:0]                             CUValid_o   ,
    input   logic   [C_BIN_NUM-1:0]                             CUReady_i   
);

// ====================================================================
// Local Parameters Declarations Start
// ====================================================================
    localparam  C_GEN_IDX_WIDTH     =   $clog2(C_GEN_NUM)   ;
// ====================================================================
// Local Parameters Declarations End
// ====================================================================

// ====================================================================
// Signal Declarations Start
// ====================================================================
    logic   [C_GEN_NUM-1:0][C_BIN_IDX_WIDTH-1:0]    bin_idx         ;
    logic   [C_BIN_NUM-1:0][C_GEN_NUM-1:0]          request         ;
    logic   [C_BIN_NUM-1:0][C_GEN_NUM-1:0]          grant_onehot    ;
    logic   [C_BIN_NUM-1:0][C_GEN_IDX_WIDTH-1:0]    grant           ;
    logic   [C_BIN_NUM-1:0]                         valid           ;
    logic   [C_BIN_NUM-1:0]                         bin_lock        ;
    logic   [C_BIN_NUM-1:0]                         arb_en          ;
    logic   [C_BIN_NUM-1:0][C_DELTA_WIDTH-1:0]      CUDelta_pipe   [C_STAGES_NUM-1:0];
    logic   [C_BIN_NUM-1:0][C_VERTEX_IDX_WIDTH-1:0] CUIdx_pipe     [C_STAGES_NUM-1:0];
    logic   [C_BIN_NUM-1:0]                         CUValid_pipe   [C_STAGES_NUM-1:0];
    logic   [C_BIN_NUM-1:0][C_DELTA_WIDTH-1:0]      CUDelta_n       ;
    logic   [C_BIN_NUM-1:0][C_VERTEX_IDX_WIDTH-1:0] CUIdx_n         ;
    logic   [C_BIN_NUM-1:0]                         CUValid_n       ;

    genvar i;
// ====================================================================
// Signal Declarations End
// ====================================================================

// ====================================================================
// Module Instantiations Start
// ====================================================================
// --------------------------------------------------------------------
// Module name  :   rr_arbiter
// Description  :   Round-Robin Arbiter
// --------------------------------------------------------------------
generate
    for (i = 0; i < C_BIN_NUM; i++) begin
        rr_arbiter #(
            .C_REQ_NUM          (C_GEN_NUM                      ),
            .C_REQ_IDX_WIDTH    (C_GEN_IDX_WIDTH                )
        ) rr_arbiter_inst(
            .clk_i              (clk_i                          ),   //  Clock
            .rst_i              (rst_i                          ),   //  Reset
            .en_i               (arb_en[i]                      ),
            .ack_i              (CUValid_o[i] && CUReady_i[i]   ),
            .req_i              (request[i]                     ),
            .grant_o            (grant[i]                       ),
            .grant_onehot_o     (grant_onehot[i]                ),
            .valid_o            (valid[i]                       )
        );
    end
endgenerate

// --------------------------------------------------------------------


// ====================================================================
// Module Instantiations End
// ====================================================================

// ====================================================================
// RTL Logic Start
// ====================================================================

// --------------------------------------------------------------------
// Determine bin index
// --------------------------------------------------------------------
    generate
        for (i = 0; i < C_GEN_NUM; i++) begin
            always_comb begin
                bin_idx[i]  =   proIdx_i[C_BIN_IDX_LSB +: C_BIN_IDX_WIDTH];
            end
        end
    endgenerate

// --------------------------------------------------------------------
// Requests to each arbiter
// --------------------------------------------------------------------
    generate
        for (i = 0; i < C_BIN_NUM; i++) begin
            always_comb begin
                request[i] =   'b0
                for (int j = 0; j < C_GEN_NUM; j++) begin
                    if (bin_idx[j] == i) begin
                        request[i][j]   =   1'b1;
                    end
                end
            end
        end
    endgenerate

// --------------------------------------------------------------------
// Ready signals to PEs
// --------------------------------------------------------------------
    generate
        for (i = 0; i < C_GEN_NUM; i++) begin
            always_ff @(posedge clk_i) begin
                if ((grant[bin_idx[i]] == i) && valid[bin_idx[i]]
                && CUReady_i[bin_idx[i]]) begin
                    proReady_o[i]   <=  `SD 'b1;
                end else begin
                    proReady_o[i]   <=  `SD 'b0;
                end
            end
        end
    endgenerate

// --------------------------------------------------------------------
// Lock a bin after a valid arbitration, before the bin take the data away
// --------------------------------------------------------------------
    generate
        for (i = 0; i < C_BIN_NUM; i++) begin
            always_ff @(posedge clk_i) begin
                if (rst_i) begin
                    bin_lock[i] <=  `SD 'b0;
                end else begin
                    if (CUValid_o[i] && CUReady_i[i]) begin
                        bin_lock[i] <=  `SD 'b0;
                    end else if (valid[i] && CUReady_i[i]) begin
                        bin_lock[i] <=  `SD 'b1;
                    end
                end
            end
        end
    endgenerate

// --------------------------------------------------------------------
// Arbitration enable
// disable when:
//      bin is locked (bin_lock[i] == 1)
//      OR bin is ready (CUReady_i[i] == 1)
// --------------------------------------------------------------------
    always_comb begin
        arb_en  =   ~(bin_lock | (~CUReady_i));
    end

// --------------------------------------------------------------------
// Route event
// --------------------------------------------------------------------
    generate
        for (i = 0; i < C_BIN_NUM; i++) begin
            always_comb begin
                if (proReady_o[grant[i]]) begin
                    CUDelta_n[i]    =   proDelta_i[grant[i]];
                    CUIdx_n[i]      =   CUIdx_n[grant[i]];
                    CUValid_n[i]    =   'b1;
                end else begin
                    CUDelta_n[i]    =   'd0;
                    CUIdx_n[i]      =   'd0;
                    CUValid_n[i]    =   'b0;
                end
            end
        end
    endgenerate

// --------------------------------------------------------------------
// Pipelining
// --------------------------------------------------------------------

// ====================================================================
// RTL Logic End
// ====================================================================


endmodule
