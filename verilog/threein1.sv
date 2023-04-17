/////////////////////////////////////////////////////////////////////////
//                                                                     //
//  Modulename  :  threein1.sv                                         //
//                                                                     //
//  Description :  Crossbar from Scheds to PE with output_buffer       // 
//                 and queue_scheduler                                 //
/////////////////////////////////////////////////////////////////////////

module threein1 #(
    parameter   C_ROW_IDX_WIDTH     =   `ROW_IDX_WIDTH      ,
    parameter   C_BIN_IDX_WIDTH     =   `BIN_IDX_WIDTH      ,
    parameter   C_VERTEX_IDX_WIDTH  =   `VERTEX_IDX_WIDTH   ,
    parameter   C_DELTA_WIDTH       =   `DELTA_WIDTH        ,
    parameter   C_EVENT_WIDTH       =   `EVENT_WIDTH        ,
    parameter   C_INPUT_NUM         =   `COL_NUM            ,
    parameter   C_OUTPUT_NUM        =   `PE_NUM             ,
    parameter   C_FIFO_INPUT_NUM    =   `OB_FIFO_INPUT_NUM  ,
    // parameter   C_INPUT_NUM         =   `PE_NUM             ,
    // parameter   C_OUTPUT_NUM        =   `PE_NUM             ,
    parameter   C_STAGES_NUM        =   `XBAR_0_STAGES_NUM  ,
    // parameter   C_DELTA_WIDTH       =   `DELTA_WIDTH        ,
    // parameter   C_VERTEX_IDX_WIDTH  =   `VERTEX_IDX_WIDTH   ,
    parameter   C_PE_IDX_WIDTH      =   `PE_IDX_WIDTH       ,
    parameter   C_BIN_NUM           =   `BIN_NUM            
) (
    input   logic                                               clk_i       ,   //  Clock
    input   logic                                               rst_i       ,   //  Reset
    
    // input   logic   [C_INPUT_NUM*C_DELTA_WIDTH-1:0]             IssDelta_i  ,
    // input   logic   [C_INPUT_NUM*C_VERTEX_IDX_WIDTH-1:0]        IssIdx_i    ,
    input   logic   [C_ROW_IDX_WIDTH-1:0]                       rowIdx_up_i    ,
    input   logic   [C_BIN_IDX_WIDTH-2:0]                       binIdx_up_i    ,
    input   logic   [C_INPUT_NUM*C_DELTA_WIDTH-1:0]             rowDelta_up_i  ,
    input   logic                                               rowValid_up_i  ,
    input   logic   [C_ROW_IDX_WIDTH-1:0]                       rowIdx_down_i    ,
    input   logic   [C_BIN_IDX_WIDTH-2:0]                       binIdx_down_i    ,
    input   logic   [C_INPUT_NUM*C_DELTA_WIDTH-1:0]             rowDelta_down_i  ,
    input   logic                                               rowValid_down_i  ,
    output  logic                                               rowReady_o  ,

    output  logic   [C_OUTPUT_NUM*C_DELTA_WIDTH-1:0]            PEDelta_o   ,
    output  logic   [C_OUTPUT_NUM*C_VERTEX_IDX_WIDTH-1:0]       PEIdx_o     ,
    output  logic   [C_OUTPUT_NUM-1:0]                          PEValid_o   ,
    input   logic   [C_OUTPUT_NUM-1:0]                          PEReady_i   ,

    input   logic   [C_OUTPUT_NUM-1:0]                    initialFinish_i   ,   
    input   logic   [C_BIN_NUM-1:0]                       CUClean_i         ,
    input   logic   [C_BIN_NUM-1:0]                       binValid_i        ,
    output  logic   [C_BIN_NUM-1:0]                       binSelected_o     ,
    output  logic                                         readEn_o          ,
    output  logic                                         initialFinish_o
);

// ====================================================================
// Local Parameters Declarations Start
// ====================================================================
    // localparam  C_GEN_IDX_WIDTH     =   $clog2(C_GEN_NUM)   ;
// ====================================================================
// Local Parameters Declarations End
// ====================================================================

// ====================================================================
// Signal Declarations Start
// ====================================================================
    logic   [C_ROW_IDX_WIDTH-1:0]                          rowIdx_i        ;
    logic   [C_BIN_IDX_WIDTH-2:0]                          binIdx_i        ;
    logic   [C_INPUT_NUM*C_DELTA_WIDTH-1:0]                rowDelta_i      ;
    logic                                                  rowValid_i      ;

    logic                                                  upQ_selected  ;

    logic   [C_INPUT_NUM-1:0][C_DELTA_WIDTH-1:0]           int_rowDelta_i  ;
    // logic   [C_GEN_NUM-1:0][C_VERTEX_IDX_WIDTH-1:0]     int_proIdx_i    ;
    logic   [C_OUTPUT_NUM-1:0][C_DELTA_WIDTH-1:0]          int_PEDelta_o   ;
    logic   [C_OUTPUT_NUM-1:0][C_VERTEX_IDX_WIDTH-1:0]     int_PEIdx_o     ;

    logic   [C_OUTPUT_NUM-1:0][C_DELTA_WIDTH-1:0]          IssDelta_i      ;
    logic   [C_OUTPUT_NUM-1:0][C_VERTEX_IDX_WIDTH-1:0]     IssIdx_i        ;
    logic   [C_OUTPUT_NUM-1:0]                             IssValid_i      ;
    logic   [C_OUTPUT_NUM-1:0]                             IssReady_o      ;
    logic   [C_OUTPUT_NUM-1:0][C_DELTA_WIDTH-1:0]          IssDelta_o      ;
    logic   [C_OUTPUT_NUM-1:0][C_VERTEX_IDX_WIDTH-1:0]     IssIdx_o        ;
    logic   [C_OUTPUT_NUM-1:0]                             IssValid_o      ;
    logic   [C_OUTPUT_NUM-1:0]                             IssReady_i      ;

// ====================================================================
// Signal Declarations End
// ====================================================================

// ====================================================================
// Module Instantiations Start
// ====================================================================
// --------------------------------------------------------------------
// Module name  :   Xbar_SchedToPE
// Description  :   Round-Robin Arbiter
// --------------------------------------------------------------------
    Xbar_SchedToPE Xbar_SchedToPE_inst(
        .clk_i      (clk_i          ),   //  Clock
        .rst_i      (rst_i          ),   //  Reset
        .IssDelta_i (IssDelta_i     ),
        .IssIdx_i   (IssIdx_i       ),
        .IssValid_i (IssValid_i     ),
        .IssReady_o (IssReady_o     ),
        .PEDelta_o  (int_PEDelta_o  ),
        .PEIdx_o    (int_PEIdx_o    ),
        .PEValid_o  (PEValid_o      ),
        .PEReady_i  (PEReady_i      )
    );
// --------------------------------------------------------------------

// --------------------------------------------------------------------
// Module name  :   output_buffer
// Description  :   Buffer for a rows drained from Event Queues by
//                  Scheduler                                          
// --------------------------------------------------------------------
    output_buffer output_buffer_inst(
        .clk_i      (clk_i          ),   //  Clock
        .rst_i      (rst_i          ),   //  Reset
        .rowIdx_i   (rowIdx_i       ),
        .binIdx_i   (binIdx_i       ),
        .rowDelta_i (int_rowDelta_i ),
        .rowValid_i (rowValid_i     ),
        .rowReady_o (rowReady_o     ),
        .IssDelta_o (IssDelta_o     ),
        .IssIdx_o   (IssIdx_o       ),
        .IssValid_o (IssValid_o     ),
        .IssReady_i (IssReady_i     ) 
);

// --------------------------------------------------------------------

// --------------------------------------------------------------------
// Module name  :   queue_scheduler
// Description  :   queue_scheduler                                          
// --------------------------------------------------------------------
    queue_scheduler queue_scheduler_inst(
        .clk_i            (clk_i          ),   //  Clock
        .rst_i            (rst_i          ),   //  Reset
        .initialFinish_i  (initialFinish_o),   
        .CUClean_i        (CUClean_i      ),
        .binValid_i       (binValid_i     ),
        .binSelected_o    (binSelected_o  ),   
        .PEready_i        (PEReady_i      ), 
        .readEn_o         (readEn_o       ) 
);

// --------------------------------------------------------------------

// ====================================================================
// Module Instantiations End
// ====================================================================

// ====================================================================
// RTL Logic Start
// ====================================================================

assign IssDelta_i     = IssDelta_o ;
assign IssIdx_i       = IssIdx_o   ;
assign IssValid_i     = IssValid_o     ;
assign IssReady_i     = IssReady_o     ;

assign initialFinish_o  = &initialFinish_i;

assign upQ_selected = |binSelected_o[C_BIN_NUM-1:C_BIN_NUM/2];
assign rowIdx_i = upQ_selected ? rowIdx_up_i : rowIdx_down_i;
assign binIdx_i = upQ_selected ? binIdx_up_i : binIdx_down_i;
assign rowDelta_i = upQ_selected ? rowDelta_up_i : rowDelta_down_i;
assign rowValid_i = upQ_selected ? rowValid_up_i : rowValid_down_i;

// --------------------------------------------------------------------
// Convert 2D to 1D
// --------------------------------------------------------------------

genvar i, j;

generate

    for (i = 0; i < C_INPUT_NUM; i++) begin
        for (j = 0; j < C_DELTA_WIDTH; j++) begin
            assign  int_rowDelta_i[i][j] = rowDelta_i[i*C_DELTA_WIDTH+j];
        end
    end

    // for (i = 0; i < C_GEN_NUM; i++) begin
    //     for (j = 0; j < C_VERTEX_IDX_WIDTH; j++) begin
    //         assign  int_proIdx_i[i][j] = proIdx_i[i*C_VERTEX_IDX_WIDTH+j];
    //     end
    // end

    for (i = 0; i < C_OUTPUT_NUM; i++) begin
        for (j = 0; j < C_DELTA_WIDTH; j++) begin
            assign  PEDelta_o[i*C_DELTA_WIDTH+j] = int_PEDelta_o[i][j];
        end
    end

    for (i = 0; i < C_OUTPUT_NUM; i++) begin
        for (j = 0; j < C_VERTEX_IDX_WIDTH; j++) begin
            assign  PEIdx_o[i*C_VERTEX_IDX_WIDTH+j] = int_PEIdx_o[i][j];
        end
    end

endgenerate

// ====================================================================
// RTL Logic End
// ====================================================================


endmodule