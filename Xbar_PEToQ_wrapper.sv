/////////////////////////////////////////////////////////////////////////
//                                                                     //
//  Modulename  :  Xbar_PEToQ_wrapper.sv                                       //
//                                                                     //
//  Description :  Crossbar from PEs to Event Queues                   // 
//                                                                     //
/////////////////////////////////////////////////////////////////////////

module Xbar_PEToQ_wrapper #(
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

    input   logic   [C_GEN_NUM*C_DELTA_WIDTH-1:0]               proDelta_i  ,
    input   logic   [C_GEN_NUM*C_VERTEX_IDX_WIDTH-1:0]          proIdx_i    ,
    input   logic   [C_GEN_NUM-1:0]                             proValid_i  ,
    output  logic   [C_GEN_NUM-1:0]                             proReady_o  ,

    output  logic   [C_BIN_NUM*C_DELTA_WIDTH-1:0]               CUDelta_o   ,
    output  logic   [C_BIN_NUM*C_VERTEX_IDX_WIDTH-1:0]          CUIdx_o     ,
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
    logic   [C_GEN_NUM-1:0][C_DELTA_WIDTH-1:0]          int_proDelta_i  ;
    logic   [C_GEN_NUM-1:0][C_VERTEX_IDX_WIDTH-1:0]     int_proIdx_i    ;
    logic   [C_BIN_NUM-1:0][C_DELTA_WIDTH-1:0]          int_CUDelta_o   ;
    logic   [C_BIN_NUM-1:0][C_VERTEX_IDX_WIDTH-1:0]     int_CUIdx_o     ;

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
    Xbar_PEToQ Xbar_PEToQ_inst(
        .clk_i      (clk_i          ),   //  Clock
        .rst_i      (rst_i          ),   //  Reset
        .proDelta_i (int_proDelta_i ),
        .proIdx_i   (int_proIdx_i   ),
        .proValid_i (proValid_i     ),
        .proReady_o (proReady_o     ),
        .CUDelta_o  (int_CUDelta_o  ),
        .CUIdx_o    (int_CUIdx_o    ),
        .CUValid_o  (CUValid_o      ),
        .CUReady_i  (CUReady_i      )
    );
// --------------------------------------------------------------------


// ====================================================================
// Module Instantiations End
// ====================================================================

// ====================================================================
// RTL Logic Start
// ====================================================================

// --------------------------------------------------------------------
// Convert 2D to 1D
// --------------------------------------------------------------------

genvar i, j;

generate

    for (i = 0; i < C_GEN_NUM; i++) begin
        for (j = 0; j < C_DELTA_WIDTH; j++) begin
            assign  int_proDelta_i[i][j] = proDelta_i[i*C_DELTA_WIDTH+j];
        end
    end

    for (i = 0; i < C_GEN_NUM; i++) begin
        for (j = 0; j < C_VERTEX_IDX_WIDTH; j++) begin
            assign  int_proIdx_i[i][j] = proIdx_i[i*C_VERTEX_IDX_WIDTH+j];
        end
    end

    for (i = 0; i < C_BIN_NUM; i++) begin
        for (j = 0; j < C_DELTA_WIDTH; j++) begin
            assign  CUDelta_o[i*C_DELTA_WIDTH+j] = int_CUDelta_o[i][j];
        end
    end

    for (i = 0; i < C_BIN_NUM; i++) begin
        for (j = 0; j < C_VERTEX_IDX_WIDTH; j++) begin
            assign  CUIdx_o[i*C_VERTEX_IDX_WIDTH+j] = int_CUIdx_o[i][j];
        end
    end

endgenerate

// ====================================================================
// RTL Logic End
// ====================================================================


endmodule
