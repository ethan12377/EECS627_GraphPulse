/////////////////////////////////////////////////////////////////////////
//                                                                     //
//  Modulename  :  bin_func.sv                                         //
//                                                                     //
//  Description :   if bin_selected and readen, read to outputbuffer   // 
//                  otherwise, search and write with cu                //
//                                                                     //
/////////////////////////////////////////////////////////////////////////

module bin_func #(
    parameter   C_ROW_NUM           =   `ROW_NUM            ,
    parameter   C_COL_NUM           =   `COL_NUM            ,
    parameter   C_ROW_IDX_WIDTH     =   `ROW_IDX_WIDTH      ,
    parameter   C_COL_IDX_WIDTH     =   `COL_IDX_WIDTH      ,
    parameter   C_ROW_IDX_LSB       =   `ROW_IDX_LSB        ,
    parameter   C_COL_IDX_LSB       =   `COL_IDX_LSB        ,
    parameter   C_VERTEX_IDX_WIDTH  =   `VERTEX_IDX_WIDTH   ,
    parameter   C_DELTA_WIDTH       =   `DELTA_WIDTH        
)(
    input   logic                                   clk_i           ,   //  Clock
    input   logic                                   rst_i           ,   //  Reset

    // Interface with queue_scheduler
    input   logic                                   binSelected_i     ,
    input   logic                                   readEn_i          ,
    output  logic                                   binValid_o        ,

    // Interface with coalescing_unit
    input   logic                                   newValid_i        ,
    input   logic  [C_VERTEX_IDX_WIDTH-1:0]         newIdx_i          ,    
    input   logic  [C_DELTA_WIDTH-1:0]              newDelta_i        ,

    input   logic  [C_VERTEX_IDX_WIDTH-1:0]         searchIdx_i       ,
    input   logic                                   searchValid_i     ,
    output  logic  [C_DELTA_WIDTH-1:0]              searchValue_o     ,
    output  logic                                   searchValueValid_o,
    //for test
    output  logic   [C_ROW_NUM-1:0]                 rowNotEmpty     ,
    output  logic   [C_COL_NUM-1:0][C_DELTA_WIDTH-1:0]   allrow0  ,


    // Interface with output_buffer
    output  logic  [C_ROW_IDX_WIDTH-1:0]            rowIdx_o          ,
    output  logic  [C_DELTA_WIDTH * C_COL_NUM-1:0]  rowDelta_o        ,
    output  logic                                   rowValid_o        ,
    input   logic                                   rowReady_i      
);

// ====================================================================
// Signal Declarations Start
// ====================================================================
    // extract Idx
    logic   [C_ROW_IDX_WIDTH-1:0]           newRowIdx                       ;
    logic   [C_COL_IDX_WIDTH-1:0]           newColIdx                       ;

    logic   [C_ROW_IDX_WIDTH-1:0]           readRowIdx                      ;
    logic                                   readRowValid                    ;

    // extract Idx
    logic   [C_ROW_IDX_WIDTH-1:0]           searchRowIdx                    ;
    logic   [C_COL_IDX_WIDTH-1:0]           searchColIdx                    ;

    // logic   [C_ROW_NUM-1:0]                 rowNotEmpty                     ;
    logic   [C_ROW_NUM-1:0][C_COL_NUM-1:0][C_DELTA_WIDTH-1:0]   eventArray  ;
    assign allrow0 = eventArray[0];

    genvar rowIter, colIter;

// ====================================================================
// Signal Declarations End
// ====================================================================

// ====================================================================
// Module Instantiations Start
// ====================================================================
// --------------------------------------------------------------------
// Module name  :   prority arbiter
// Description  :   prority arbiter
// --------------------------------------------------------------------
    priority_arbiter #(
        .C_REQ_NUM          (C_ROW_NUM          ),
        .C_REQ_IDX_WIDTH    (C_ROW_IDX_WIDTH    )
    )readrow_priority_arbiter(
        .req_i              (rowNotEmpty        ),
        .grant_o            (readRowIdx         ),
        .valid_o            (readRowValid       )  
    );

// --------------------------------------------------------------------


// ====================================================================
// Module Instantiations End
// ====================================================================

// ====================================================================
// RTL Logic Start
// ====================================================================

// --------------------------------------------------------------------
// Row-wise read operation (to output_buffer)
// --------------------------------------------------------------------
    always_ff @(posedge clk_i) begin 
        if (rst_i) begin
            rowValid_o  <=  `SD 'b0;
            rowIdx_o    <=  `SD 'd0;
            rowDelta_o  <=  `SD 'd0;
        end else begin
            if (binSelected_i && readEn_i && readRowValid && rowReady_i) begin
                rowValid_o  <=  `SD 'b1                     ;
                rowIdx_o    <=  `SD readRowIdx              ;
                rowDelta_o  <=  `SD eventArray[readRowIdx]  ;
            end else begin
                rowValid_o  <=  `SD 'b0       ;
                rowIdx_o    <=  `SD 'd0  ;
                rowDelta_o  <=  `SD 'd0;
            end
        end

        
    end

// --------------------------------------------------------------------
// Event-wise read operation (to CU)
// --------------------------------------------------------------------
    always_comb begin
        searchRowIdx    =   searchIdx_i[C_ROW_IDX_LSB +: C_ROW_IDX_WIDTH];
        searchColIdx    =   searchIdx_i[C_COL_IDX_LSB +: C_COL_IDX_WIDTH];
    end

    // search for cu
    always_ff @(posedge clk_i) begin 
        if (searchValid_i)begin
            searchValue_o       <=  `SD eventArray[searchRowIdx][searchColIdx];
            searchValueValid_o  <=  `SD 'b1;
        end else begin
            searchValue_o       <=  `SD 'd0;
            searchValueValid_o  <=  `SD 'b0;
        end
    end

// --------------------------------------------------------------------
// Event-wise write operation
// --------------------------------------------------------------------
    always_comb begin
        newRowIdx   =   newIdx_i[C_ROW_IDX_LSB +: C_ROW_IDX_WIDTH];
        newColIdx   =   newIdx_i[C_COL_IDX_LSB +: C_COL_IDX_WIDTH];
    end

    generate
        for (rowIter = 0; rowIter < C_ROW_NUM; rowIter++) begin
            for (colIter = 0; colIter < C_COL_NUM; colIter++) begin

                always_ff @(posedge clk_i) begin
                    if (rst_i) begin
                        eventArray[rowIter][colIter]    <=  `SD 'd0;
                    end else begin
                        // Read to output_buffer -> clear every entry of the row
                        if ((readRowIdx == rowIter) && binSelected_i && readEn_i && readRowValid && rowReady_i) begin
                            eventArray[rowIter][colIter]    <=  `SD 'd0;
                        // New event (from CU) is mapped to this element -> store the event value
                        end else if (newValid_i && (newRowIdx == rowIter)
                        && (newColIdx == colIter) ) begin
                            eventArray[rowIter][colIter]    <=  `SD newDelta_i;
                        end
                        else begin
                            eventArray[rowIter][colIter]    <=  eventArray[rowIter][colIter];
                        end
                    end
                end

            end
        end
    endgenerate


// --------------------------------------------------------------------
// Row-wise Not Empty flags operation
// --------------------------------------------------------------------
    generate
        for (rowIter = 0; rowIter < C_ROW_NUM; rowIter++) begin

            always_ff @(posedge clk_i) begin
                if (rst_i) begin
                    rowNotEmpty[rowIter]  <=  `SD 'b0;
                end else begin
                    // Read to output_buffer -> empty
                    if ((readRowIdx == rowIter) && binSelected_i && readEn_i && readRowValid && rowReady_i) begin
                        rowNotEmpty[rowIter]  <=  `SD 'b0;
                    // Any event written in the row -> not empty
                    end else if (newValid_i 
                    && (newIdx_i[C_ROW_IDX_LSB +: C_ROW_IDX_WIDTH] == rowIter)) begin
                        rowNotEmpty[rowIter]  <=  `SD 'b1;
                    end
                end
            end

        end
    endgenerate

// --------------------------------------------------------------------
// Bin valid (not empty)
// --------------------------------------------------------------------
    // always_ff @(posedge clk_i) begin
    //     if (rst_i) begin
    //         binValid_o  <=  'b0;
    //     end else begin
    //         if (rowNotEmpty == 'd0) begin
    //             binValid_o  <=  'b0;
    //         end else begin
    //             binValid_o  <=  'b1;
    //         end
    //     end
    // end

    assign binValid_o = (rowNotEmpty == 'd0) ? 'b0: 'b1;

// ====================================================================
// RTL Logic End
// ====================================================================


endmodule
