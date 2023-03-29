/////////////////////////////////////////////////////////////////////////
//                                                                     //
//  Modulename  :  EQ_wrapper_half.sv                                  //
//                                                                     //
//  Description :  2D to 1D for event_queues                           // 
//                                                                     //
/////////////////////////////////////////////////////////////////////////

module EQ_wrapper_half #(
    parameter   C_GEN_NUM           =   `GEN_NUM            ,
    parameter   C_BIN_HALF          =   `BIN_NUM / 2        ,
    parameter   C_STAGES_NUM        =   `XBAR_1_STAGES_NUM  ,
    parameter   C_DELTA_WIDTH       =   `DELTA_WIDTH        ,
    parameter   C_VERTEX_IDX_WIDTH  =   `VERTEX_IDX_WIDTH   ,
    parameter   C_PE_IDX_WIDTH      =   `PE_IDX_WIDTH       ,
    parameter   C_BIN_IDX_WIDTH     =   `BIN_IDX_WIDTH      ,
    parameter   C_BIN_IDX_LSB       =   `BIN_IDX_LSB        ,
    parameter   C_COL_NUM           =   `COL_NUM            ,
    parameter   C_ROW_IDX_WIDTH     =   `ROW_IDX_WIDTH      ,
    parameter   C_PE_NUM_OF_CORES   =   `PE_NUM_OF_CORES    
) (
    input   logic                                               clk_i       ,   //  Clock
    input   logic                                               rst_i       ,   //  Reset
    input   logic                                               initialFinish_i,

    // Interface with corssbar
    input   logic   [C_BIN_HALF*C_DELTA_WIDTH-1:0]               CUDelta_i   ,
    input   logic   [C_BIN_HALF*C_VERTEX_IDX_WIDTH-1:0]          CUIdx_i     ,
    input   logic   [C_BIN_HALF-1:0]                             CUValid_i   ,
    output  logic   [C_BIN_HALF-1:0]                             CUReady_o   ,

    // Interface with queue_scheduler
    output  logic   [C_BIN_HALF-1:0]                         CUClean_o       ,
    output  logic   [C_BIN_HALF-1:0]                         binValid_o      ,
    input   logic   [C_BIN_HALF-1:0]                         binSelected_i   ,   
    input   logic                                           readEn_i        , 

    // Interface with output_buffer
    output  logic   [C_ROW_IDX_WIDTH-1:0]                   rowIdx_o        ,
    output  logic   [C_BIN_IDX_WIDTH-2:0]                   binIdx_o        ,
    output  logic   [C_COL_NUM*C_DELTA_WIDTH-1:0]           rowDelta_o      ,
    output  logic                                           rowValid_o      ,
    input   logic                                           rowReady_i

    // Queue empty flag for convergence check
    // output  logic                                           queueEmpty_o   
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
    logic   [C_COL_NUM-1:0][C_DELTA_WIDTH-1:0]          int_rowDelta_o  ;
    logic   [C_BIN_HALF-1:0][C_DELTA_WIDTH-1:0]          int_CUDelta_i   ;
    logic   [C_BIN_HALF-1:0][C_VERTEX_IDX_WIDTH-1:0]     int_CUIdx_i     ;

// ====================================================================
// Signal Declarations End
// ====================================================================

// ====================================================================
// Module Instantiations Start
// ====================================================================
// --------------------------------------------------------------------
// Module name  :   event_queues
// Description  :   event_queues
// --------------------------------------------------------------------
    event_queues_half event_queues_half_inst(
        .clk_i       (clk_i          ),   //  Clock
        .rst_i       (rst_i          ),   //  Reset
        .initialFinish_i (initialFinish_i),
        .CUDelta_i   (int_CUDelta_i  ),   // Interface with corssbar
        .CUIdx_i     (int_CUIdx_i    ),
        .CUValid_i   (CUValid_i      ),
        .CUReady_o   (CUReady_o      ),
        .CUClean_o   (CUClean_o      ),    // Interface with queue_scheduler
        .binValid_o  (binValid_o     ),
        .binSelected_i (binSelected_i),   
        .readEn_i    (readEn_i       ), 
        .rowIdx_o    (rowIdx_o       ),    // Interface with output_buffer
        .binIdx_o    (binIdx_o       ),
        .rowDelta_o  (int_rowDelta_o ),
        .rowValid_o  (rowValid_o     ),
        .rowReady_i  (rowReady_i     )
        // .queueEmpty_o (queueEmpty_o  )    // Queue empty flag for convergence check    
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

    for (i = 0; i < C_COL_NUM; i++) begin
        for (j = 0; j < C_DELTA_WIDTH; j++) begin
            assign  rowDelta_o[i*C_DELTA_WIDTH+j] = int_rowDelta_o[i][j];
        end
    end

    // for (i = 0; i < C_GEN_NUM; i++) begin
    //     for (j = 0; j < C_VERTEX_IDX_WIDTH; j++) begin
    //         assign  int_proIdx_i[i][j] = proIdx_i[i*C_VERTEX_IDX_WIDTH+j];
    //     end
    // end

    for (i = 0; i < C_BIN_HALF; i++) begin
        for (j = 0; j < C_DELTA_WIDTH; j++) begin
            assign  int_CUDelta_i[i][j] = CUDelta_i[i*C_DELTA_WIDTH+j];
        end
    end

    for (i = 0; i < C_BIN_HALF; i++) begin
        for (j = 0; j < C_VERTEX_IDX_WIDTH; j++) begin
            assign  int_CUIdx_i[i][j] = CUIdx_i[i*C_VERTEX_IDX_WIDTH+j];
        end
    end

endgenerate

// ====================================================================
// RTL Logic End
// ====================================================================


endmodule
