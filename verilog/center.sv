/////////////////////////////////////////////////////////////////////////
//                                                                     //
//  Modulename  :  center.sv                                           //
//                                                                     //
//  Description :  Crossbars, output_buffer, queue's output mux,       // 
//                 and queue_scheduler                                 //
/////////////////////////////////////////////////////////////////////////

module center #(
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
    parameter   C_BIN_NUM           =   `BIN_NUM            ,
        
    parameter   C_GEN_NUM           =   `GEN_NUM            ,
    parameter   C_BIN_IDX_LSB       =   `BIN_IDX_LSB  
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

    input   logic   [C_GEN_NUM*C_DELTA_WIDTH-1:0]               proDelta_i  ,
    input   logic   [C_GEN_NUM*C_VERTEX_IDX_WIDTH-1:0]          proIdx_i    ,
    input   logic   [C_GEN_NUM-1:0]                             proValid_i  ,
    output  logic   [C_GEN_NUM-1:0]                             proReady_o  ,

    output  logic   [C_BIN_NUM*C_DELTA_WIDTH-1:0]               CUDelta_o   ,
    output  logic   [C_BIN_NUM*C_VERTEX_IDX_WIDTH-1:0]          CUIdx_o     ,
    output  logic   [C_BIN_NUM-1:0]                             CUValid_o   ,
    input   logic   [C_BIN_NUM-1:0]                             CUReady_i   ,

    input   logic   [C_OUTPUT_NUM-1:0]                    initialFinish_i   ,   
    input   logic   [C_BIN_NUM-1:0]                       CUClean_i         ,
    input   logic   [C_BIN_NUM-1:0]                       binValid_i        ,
    output  logic   [C_BIN_NUM-1:0]                       binSelected_o     ,
    output  logic                                         readEn_o          ,
    output  logic                                         initialFinish_o   

    // input   logic [`PE_NUM_OF_CORES*8-1 : 0]        pe2vm_reqAddr_i,
    // input   logic [`PE_NUM_OF_CORES*64-1 : 0]           pe2vm_wrData_i,
    // input   logic [`PE_NUM_OF_CORES-1:0]                pe2vm_reqValid_i,
    // input   logic [`PE_NUM_OF_CORES-1:0]                pe2vm_wrEn_i,
    // output  logic [7:0]                           mc2vm_addr_o,
    // output  logic [63:0]                                mc2vm_data_o,
    // output  BUS_COMMAND                                 mc2vm_command_o,
    // output  logic [`PE_NUM_OF_CORES-1:0]                vm2pe_grant_onehot_o,

    // input   logic [`PE_NUM_OF_CORES*14-1 : 0]        pe2em_reqAddr_i,
    // input   logic [`PE_NUM_OF_CORES-1:0]                pe2em_reqValid_i,
    // output  logic [`XLEN-1:0]                           mc2em_addr_o,
    // output  logic [21:0]                                mc2em_data_o,
    // output  BUS_COMMAND                                 mc2em_command_o,
    // output  logic [`PE_NUM_OF_CORES-1:0]                em2pe_grant_onehot_o

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

    logic   [C_GEN_NUM-1:0][C_DELTA_WIDTH-1:0]             int_proDelta_i  ;
    logic   [C_GEN_NUM-1:0][C_VERTEX_IDX_WIDTH-1:0]        int_proIdx_i    ;
    logic   [C_BIN_NUM-1:0][C_DELTA_WIDTH-1:0]             int_CUDelta_o   ;
    logic   [C_BIN_NUM-1:0][C_VERTEX_IDX_WIDTH-1:0]        int_CUIdx_o     ;

    logic   [C_OUTPUT_NUM-1:0][C_DELTA_WIDTH-1:0]          IssDelta_i      ;
    logic   [C_OUTPUT_NUM-1:0][C_VERTEX_IDX_WIDTH-1:0]     IssIdx_i        ;
    logic   [C_OUTPUT_NUM-1:0]                             IssValid_i      ;
    logic   [C_OUTPUT_NUM-1:0]                             IssReady_o      ;
    logic   [C_OUTPUT_NUM-1:0][C_DELTA_WIDTH-1:0]          IssDelta_o      ;
    logic   [C_OUTPUT_NUM-1:0][C_VERTEX_IDX_WIDTH-1:0]     IssIdx_o        ;
    logic   [C_OUTPUT_NUM-1:0]                             IssValid_o      ;
    logic   [C_OUTPUT_NUM-1:0]                             IssReady_i      ;

    logic [`PE_NUM_OF_CORES-1:0] vm2pe_grant_onehot, em2pe_grant_onehot;

// ====================================================================
// Signal Declarations End
// ====================================================================

// ====================================================================
// Module Instantiations Start
// ====================================================================
// --------------------------------------------------------------------
// Module name  :   Xbar_SchedToPE
// Description  :   Crossbar from Scheduler / Output Buffer to PEs
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
// Module name  :   Xbar_PEToQ
// Description  :   Crossbar from PEs to Event Queues
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

// // --------------------------------------------------------------------
// // Module name  :   mc_vm
// // Description  :   vertexmem controller
// // --------------------------------------------------------------------
//     logic [`PE_NUM_OF_CORES*`XLEN-1 : 0]        pe2vm_reqAddr_padded;
//     generate
//         for (genvar i = 0; i < `PE_NUM_OF_CORES; i = i + 1)
//         begin
//             assign pe2vm_reqAddr_padded[`XLEN*(i+1)-1 : `XLEN*i] = {8'b0, pe2vm_reqAddr_i[8*(i+1)-1 : 8*i]};
//         end
//     endgenerate
//     logic [`XLEN-1:0]   mc2vm_addr_padded;
//     assign mc2vm_addr_o = mc2vm_addr_padded[7:0];
//     mc mc_vm (
//         .clk_i                  (clk_i),
//         .rst_i                  (rst_i),
//         .pe2mem_reqAddr_i       (pe2vm_reqAddr_padded),
//         .pe2mem_wrData_i        (pe2vm_wrData_i),
//         .pe2mem_reqValid_i      (pe2vm_reqValid_i),
//         .pe2mem_wrEn_i          (pe2vm_wrEn_i),
//         .mc2mem_addr_o          (mc2vm_addr_padded),
//         .mc2mem_data_o          (mc2vm_data_o),
//         .mc2mem_command_o       (mc2vm_command_o),
//         .mc2pe_grant_onehot_o   (vm2pe_grant_onehot_o)
//     );
// // --------------------------------------------------------------------

// // --------------------------------------------------------------------
// // Module name  :   mc_em
// // Description  :   edgemem controller
// // --------------------------------------------------------------------
//     logic [`PE_NUM_OF_CORES*`XLEN-1 : 0]        pe2em_reqAddr_padded;
//     generate
//         for (genvar i = 0; i < `PE_NUM_OF_CORES; i = i + 1)
//         begin
//             assign pe2em_reqAddr_padded[`XLEN*(i+1)-1 : `XLEN*i] = {2'b0, pe2em_reqAddr_i[14*(i+1)-1 : 14*i]};
//         end
//     endgenerate
//     logic [63:0]   mc2em_data_padded;
//     assign mc2em_data_o = mc2em_data_padded[21:0];
//     mc mc_em (
//         .clk_i                  (clk_i),
//         .rst_i                  (rst_i),
//         .pe2mem_reqAddr_i       (pe2em_reqAddr_padded),
//         .pe2mem_wrData_i        ('x), // read only
//         .pe2mem_reqValid_i      (pe2em_reqValid_i),
//         .pe2mem_wrEn_i          ('0), // read only
//         .mc2mem_addr_o          (mc2em_addr_o),
//         .mc2mem_data_o          (mc2em_data_padded),
//         .mc2mem_command_o       (mc2em_command_o),
//         .mc2pe_grant_onehot_o   (em2pe_grant_onehot_o)
//     );
// // --------------------------------------------------------------------

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