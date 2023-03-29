/////////////////////////////////////////////////////////////////////////
//                                                                     //
//  Modulename  :  output_buffer.sv                                    //
//                                                                     //
//  Description :  Buffer for a rows drained from Event Queues by      //
//                 Scheduler                                           // 
//                                                                     //
/////////////////////////////////////////////////////////////////////////

module output_buffer #(
    parameter   C_ROW_IDX_WIDTH     =   `ROW_IDX_WIDTH      ,
    parameter   C_BIN_IDX_WIDTH     =   `BIN_IDX_WIDTH      ,
    parameter   C_VERTEX_IDX_WIDTH  =   `VERTEX_IDX_WIDTH   ,
    parameter   C_DELTA_WIDTH       =   `DELTA_WIDTH        ,
    parameter   C_EVENT_WIDTH       =   `EVENT_WIDTH        ,
    parameter   C_INPUT_NUM         =   `COL_NUM            ,
    parameter   C_OUTPUT_NUM        =   `PE_NUM             ,
    parameter   C_FIFO_INPUT_NUM    =   `OB_FIFO_INPUT_NUM  
) (
    input   logic                                               clk_i           ,   //  Clock
    input   logic                                               rst_i           ,   //  Reset
    
    input   logic   [C_ROW_IDX_WIDTH-1:0]                       rowIdx_i        ,
    input   logic   [C_BIN_IDX_WIDTH-2:0]                       binIdx_i        ,
    input   logic   [C_INPUT_NUM-1:0][C_DELTA_WIDTH-1:0]        rowDelta_i      ,
    input   logic                                               rowValid_i      ,
    output  logic                                               rowReady_o      ,

    output  logic   [C_OUTPUT_NUM-1:0][C_DELTA_WIDTH-1:0]       IssDelta_o      ,
    output  logic   [C_OUTPUT_NUM-1:0][C_VERTEX_IDX_WIDTH-1:0]  IssIdx_o        ,
    output  logic   [C_OUTPUT_NUM-1:0]                          IssValid_o      ,
    input   logic   [C_OUTPUT_NUM-1:0]                          IssReady_i  
);

// ====================================================================
// Signal Declarations Start
// ====================================================================
    logic   [C_FIFO_INPUT_NUM-1:0][C_EVENT_WIDTH-1:0]   fifo_data       ;
    logic   [C_FIFO_INPUT_NUM-1:0]                      fifo_valid      ;
    logic                                               fifo_ready      ;
    logic   [C_OUTPUT_NUM-1:0][C_EVENT_WIDTH-1:0]       IssData         ;
// ====================================================================
// Signal Declarations End
// ====================================================================

// ====================================================================
// Module Instantiations Start
// ====================================================================
// --------------------------------------------------------------------
// Module name  :   OB_bubble_squeezer
// Description  :   Squeeze out the bubbles (invalid events) from a row
//                  of events                                          
// --------------------------------------------------------------------
OB_bubble_squeezer OB_bubble_squeezer_inst(
    .clk_i          (clk_i      ),   //  Clock
    .rst_i          (rst_i      ),   //  Reset
    .rowIdx_i       (rowIdx_i   ),
    .binIdx_i       (binIdx_i   ),
    .rowDelta_i     (rowDelta_i ),
    .rowValid_i     (rowValid_i ),
    .rowReady_o     (rowReady_o ),
    .fifo_valid_o   (fifo_valid ),
    .fifo_data_o    (fifo_data  ),
    .fifo_ready_i   (fifo_ready )
);

// --------------------------------------------------------------------

// --------------------------------------------------------------------
// Module name  :   OB_fifo
// Description  :   FIFO inside output buffer, which support multiple  
//                  push-ins(grouped) and multiple push-outs(ungrouped)
// --------------------------------------------------------------------
OB_fifo OB_fifo_inst (
    .clk_i      (clk_i          ),   // Clock
    .rst_i      (rst_i          ),   // Reset
    .s_valid_i  (fifo_valid     ),   // Push-in Valid
    .s_ready_o  (fifo_ready     ),   // Push-in Ready, asserted when number of empty entries > C_INPUT_NUM
    .s_data_i   (fifo_data      ),   // Push-in Data
    .m_valid_o  (IssValid_o     ),   // Pop-out Valid
    .m_ready_i  (IssReady_i     ),   // Pop-out Ready
    .m_data_o   (IssData        )    // Pop-out Data
);

// --------------------------------------------------------------------

// ====================================================================
// Module Instantiations End
// ====================================================================

// ====================================================================
// RTL Logic Start
// ====================================================================

// --------------------------------------------------------------------
// Split the Index and Delta of the events
// --------------------------------------------------------------------

genvar i;
generate
    for (i = 0; i < C_OUTPUT_NUM; i++) begin
        always_comb begin
            IssDelta_o[i]   =   IssData[i][C_DELTA_WIDTH-1:0]               ;
            IssIdx_o  [i]   =   IssData[i][C_EVENT_WIDTH-1:C_DELTA_WIDTH]   ;
        end
    end
endgenerate

// ====================================================================
// RTL Logic End
// ====================================================================


endmodule
