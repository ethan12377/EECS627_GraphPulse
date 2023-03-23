/////////////////////////////////////////////////////////////////////////
//                                                                     //
//  Modulename  :  OB_bubble_squeezer.sv                               //
//                                                                     //
//  Description :  Squeeze out the bubbles (invalid events) from a row //
//                 of events                                           // 
//                                                                     //
/////////////////////////////////////////////////////////////////////////

module OB_bubble_squeezer #(
    parameter   C_COL_IDX_WIDTH     =   `COL_IDX_WIDTH      ,
    parameter   C_ROW_IDX_WIDTH     =   `ROW_IDX_WIDTH      ,
    parameter   C_ROW_IDX_LSB       =   `ROW_IDX_LSB        ,
    parameter   C_BIN_IDX_WIDTH     =   `BIN_IDX_WIDTH      ,
    parameter   C_BIN_IDX_LSB       =   `BIN_IDX_LSB        ,
    parameter   C_VERTEX_IDX_WIDTH  =   `VERTEX_IDX_WIDTH   ,
    parameter   C_DELTA_WIDTH       =   `DELTA_WIDTH        ,
    parameter   C_EVENT_WIDTH       =   `EVENT_WIDTH        ,
    parameter   C_INPUT_NUM         =   `COL_NUM            ,
    parameter   C_OUTPUT_NUM        =   `OB_FIFO_INPUT_NUM  
) (
    input   logic                                               clk_i           ,   //  Clock
    input   logic                                               rst_i           ,   //  Reset

    input   logic   [C_ROW_IDX_WIDTH-1:0]                       rowIdx_i        ,
    input   logic   [C_BIN_IDX_WIDTH-1:0]                       binIdx_i        ,
    input   logic   [C_INPUT_NUM-1:0][C_DELTA_WIDTH-1:0]        rowDelta_i      ,
    input   logic                                               rowValid_i      ,
    output  logic                                               rowReady_o      ,
    
    output  logic   [C_OUTPUT_NUM-1:0]                          fifo_valid_o    ,
    output  logic   [C_OUTPUT_NUM-1:0][C_EVENT_WIDTH-1:0]       fifo_data_o     ,
    input   logic                                               fifo_ready_i    
);

// ====================================================================
// Local Parameters Declarations Start
// ====================================================================
    localparam  C_FIFO_CNT_MAX      =   C_INPUT_NUM / C_OUTPUT_NUM; //  Must be integer
    localparam  C_FIFO_CNT_WIDTH    =   $clog2(C_FIFO_CNT_MAX);  
// ====================================================================
// Local Parameters Declarations End
// ====================================================================

// ====================================================================
// Signal Declarations Start
// ====================================================================
    logic   [C_INPUT_NUM-1:0][C_EVENT_WIDTH-1:0]        row_buf_data        ;   //  Bubble free
    logic   [C_INPUT_NUM-1:0][C_EVENT_WIDTH-1:0]        row_buf_data_n      ;   //  Bubble free
    logic   [C_INPUT_NUM-1:0]                           row_buf_valid       ;
    logic   [C_INPUT_NUM-1:0]                           row_buf_valid_n     ;
    logic   [C_INPUT_NUM-1:0][C_COL_IDX_WIDTH-1:0]      offset              ;
    logic   [C_INPUT_NUM-1:0]                           event_invalid       ;
    logic   [C_INPUT_NUM-1:0][C_VERTEX_IDX_WIDTH-1:0]   event_idx           ;
    logic   [C_FIFO_CNT_WIDTH-1:0]                      fifo_cnt            ;
// ====================================================================
// Signal Declarations End
// ====================================================================

// ====================================================================
// RTL Logic Start
// ====================================================================

// --------------------------------------------------------------------
// Identify invalid events and calculate offset
// --------------------------------------------------------------------
    genvar i;

    generate
        for (i = 0; i < C_INPUT_NUM; i++) begin
            always_comb begin
                if (rowDelta_i[i]) begin
                    event_invalid[i]  =   1'b0;
                end else begin
                    event_invalid[i]  =   1'b1;
                end
            end

            always_comb begin
                offset[i]   =   'd0;
                for (int j = 0; j < i; j++) begin
                    if (event_invalid[j]) begin
                        offset[i] = offset[i] + 'd1;
                    end
                end
            end
        end
    endgenerate

// --------------------------------------------------------------------
// Calculate event index
// --------------------------------------------------------------------
    generate
        for (i = 0; i < C_INPUT_NUM; i++) begin
            always_comb begin
                event_idx[i]    =   i + (binIdx_i << C_BIN_IDX_LSB) + (rowIdx_i << C_ROW_IDX_LSB);
            end
        end
    endgenerate

// --------------------------------------------------------------------
// Squeeze out the invalid events and store to row_buf_data
// --------------------------------------------------------------------
    generate
        for (i = 0; i < C_INPUT_NUM; i++) begin
            always_comb begin
                row_buf_data_n[i]   =   row_buf_data[i];
                row_buf_valid_n[i]  =   row_buf_valid[i];
                if (rowValid_i && rowReady_o) begin
                    row_buf_data_n[i]   =   'd0;
                    row_buf_valid_n[i]  =   'b0;
                    for (int j = 0; j < C_INPUT_NUM; j++) begin
                        if (j - offset[j] == i && rowDelta_i[j] != 'h0) begin
                            row_buf_data_n[i]    =   {event_idx[j], rowDelta_i[j]};
                            row_buf_valid_n[i]  =   1'b1;
                        end
                    end
                end else if (row_buf_valid && fifo_ready_i && (fifo_cnt == C_FIFO_CNT_MAX - 1)) begin
                    row_buf_data_n[i]   =   'd0;
                    row_buf_valid_n[i]  =   1'b0;
                end
            end
        end
    endgenerate

    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            row_buf_data    <=  `SD 'd0;
            row_buf_valid   <=  `SD 'b0;
        end else begin
            row_buf_data    <=  `SD row_buf_data_n;
            row_buf_valid   <=  `SD row_buf_valid_n;
        end
    end

// --------------------------------------------------------------------
// Assert rowReady_o when row_buf is empty
// --------------------------------------------------------------------
    always_comb begin
        rowReady_o = ~(|row_buf_valid);
    end

// --------------------------------------------------------------------
// FIFO push-in counter
// --------------------------------------------------------------------
    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            fifo_cnt    <=  `SD 'd0;
        end else begin
            if (row_buf_valid && fifo_ready_i) begin
                if (fifo_cnt < C_FIFO_CNT_MAX - 1) begin
                    fifo_cnt    <=  `SD fifo_cnt + 'd1;
                end else begin
                    fifo_cnt    <=  `SD 'd0;
                end
            end
        end
    end

// --------------------------------------------------------------------
// Output to OB FIFO
// --------------------------------------------------------------------
    always_comb begin
        fifo_data_o     =   row_buf_data[fifo_cnt * C_OUTPUT_NUM +: C_OUTPUT_NUM];
        fifo_valid_o    =   row_buf_valid[fifo_cnt * C_OUTPUT_NUM +: C_OUTPUT_NUM];
    end

// ====================================================================
// RTL Logic End
// ====================================================================


endmodule
