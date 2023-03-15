/////////////////////////////////////////////////////////////////////////
//                                                                     //
//  Modulename  :  event_queues.sv                                     //
//                                                                     //
//  Description :  event_queues                                        // 
//                                                                     //
/////////////////////////////////////////////////////////////////////////

module event_queues #(
    parameter   C_BIN_NUM           =   `BIN_NUM     ,
    parameter   C_ROW_NUM           =   `ROW_NUM            ,
    parameter   C_COL_NUM           =   `COL_NUM            ,
    parameter   C_VERTEX_IDX_WIDTH  =   `VERTEX_IDX_WIDTH   ,
    parameter   C_BIN_IDX_WIDTH     =   `BIN_IDX_WIDTH      ,
    parameter   C_ROW_IDX_WIDTH     =   `ROW_IDX_WIDTH      ,
    parameter   C_COL_IDX_WIDTH     =   `COL_IDX_WIDTH      ,
    parameter   C_DELTA_WIDTH       =   `DELTA_WIDTH        
) (
    input   logic                                           clk_i           ,   //  Clock
    input   logic                                           rst_i           ,   //  Reset
    input   logic                                           initialFinish_i ,

    // Interface with corssbar
    input   logic   [C_BIN_NUM-1:0][C_DELTA_WIDTH-1:0]      CUDelta_i       ,
    input   logic   [C_BIN_NUM-1:0][C_VERTEX_IDX_WIDTH-1:0] CUIdx_i         ,
    input   logic   [C_BIN_NUM-1:0]                         CUValid_i       ,
    output  logic   [C_BIN_NUM-1:0]                         CUReady_o       ,

    // Interface with queue_scheduler
    output  logic   [C_BIN_NUM-1:0]                         CUClean_o       ,
    output  logic   [C_BIN_NUM-1:0]                         binValid_o      ,
    input   logic   [C_BIN_NUM-1:0]                         binSelected_i   ,   
    input   logic                                           readEn_i        , 

    // Interface with output_buffer
    output  logic   [C_ROW_IDX_WIDTH-1:0]                   rowIdx_o        ,
    output  logic   [C_BIN_IDX_WIDTH-1:0]                   binIdx_o        ,
    output  logic   [C_COL_NUM-1:0][C_DELTA_WIDTH-1:0]      rowDelta_o      ,
    output  logic                                           rowValid_o      ,
    input   logic                                           rowReady_i      ,

    // test
    output logic  [C_BIN_NUM-1:0][C_VERTEX_IDX_WIDTH-1:0]         searchIdx         ,
    output logic  [C_BIN_NUM-1:0]                                 searchValid       ,
    // test end

    // Queue empty flag for convergence check
    output  logic                                           queueEmpty_o     
);

// ====================================================================
// Local Parameters Declarations Start
// ====================================================================

// ====================================================================
// Local Parameters Declarations End
// ====================================================================

// ====================================================================
// Signal Declarations Start
// ====================================================================
logic                                   newValid         [C_BIN_NUM-1:0] ;
logic  [C_VERTEX_IDX_WIDTH-1:0]         newIdx           [C_BIN_NUM-1:0] ;
logic  [C_DELTA_WIDTH-1:0]              newDelta         [C_BIN_NUM-1:0] ;

// logic  [C_VERTEX_IDX_WIDTH-1:0]         searchIdx        [C_BIN_NUM-1:0] ;
// logic                                   searchValid      [C_BIN_NUM-1:0] ;
logic  [C_DELTA_WIDTH-1:0]              searchValue      [C_BIN_NUM-1:0] ;
logic                                   searchValueValid [C_BIN_NUM-1:0] ;

logic  [C_ROW_IDX_WIDTH-1:0]            rowIdx           [C_BIN_NUM-1:0] ;
logic  [C_DELTA_WIDTH * C_COL_NUM-1:0]  rowDelta         [C_BIN_NUM-1:0] ;
logic                                   rowValid         [C_BIN_NUM-1:0] ;
logic                                   rowReady         [C_BIN_NUM-1:0] ;
// test
logic   [C_ROW_NUM-1:0]                 rowNotEmpty      [C_BIN_NUM-1:0] ;
logic   [C_COL_NUM-1:0][C_DELTA_WIDTH-1:0]   allrow0     [C_BIN_NUM-1:0] ;
logic   [2:0]                     data_count    [C_BIN_NUM-1:0] ;
logic                            r_en        [C_BIN_NUM-1:0]      ;
logic   [C_VERTEX_IDX_WIDTH-1:0]            arrayheadIdx       [C_BIN_NUM-1:0]      ;

// test end


genvar binIter;

// ====================================================================
// Signal Declarations End
// ====================================================================

// ====================================================================
// Module Instantiations Start
// ====================================================================
// --------------------------------------------------------------------
// Module name  :   bin_func
// Description  :   A bin in the event queues
// --------------------------------------------------------------------
generate
    for (binIter = 0; binIter < C_BIN_NUM; binIter++) begin
        bin_func event_bin_inst (
            .clk_i             (clk_i                       ),   //  Clock
            .rst_i             (rst_i                       ),   //  Reset
            .binSelected_i     (binSelected_i   [binIter]   ),
            .readEn_i          (readEn_i                    ),
            .binValid_o        (binValid_o      [binIter]   ),
            .newValid_i        (newValid        [binIter]   ),
            .newIdx_i          (newIdx          [binIter]   ),    
            .newDelta_i        (newDelta        [binIter]   ),
            .searchIdx_i       (searchIdx       [binIter]   ),
            .searchValid_i     (searchValid     [binIter]   ),
            .searchValue_o     (searchValue     [binIter]   ),
            .searchValueValid_o(searchValueValid[binIter]   ),
            // test
            .rowNotEmpty       (rowNotEmpty     [binIter]   ),
            .allrow0           (allrow0         [binIter]   ),
            // test end
            .rowIdx_o          (rowIdx          [binIter]   ),
            .rowDelta_o        (rowDelta        [binIter]   ),
            .rowValid_o        (rowValid        [binIter]   ),
            .rowReady_i        (rowReady        [binIter]   )
        );
    end
endgenerate
// --------------------------------------------------------------------

// --------------------------------------------------------------------
// Module name  :   coalescing_unit
// Description  :   A bin in the event queues
// --------------------------------------------------------------------
generate
    for (binIter = 0; binIter < C_BIN_NUM; binIter++) begin
        coalescing_unit coalescing_unit_inst (
            .clk_i             (clk_i                     ),   //  Clock
            .rst_i             (rst_i                     ),   //  Reset
            .initialFinish_i   (initialFinish_i           ),
            .binSelected_i     (binSelected_i   [binIter] ),
            .CUDelta_i         (CUDelta_i       [binIter] ),
            .CUIdx_i           (CUIdx_i         [binIter] ),
            .CUValid_i         (CUValid_i       [binIter] ),
            .CUReady_o         (CUReady_o       [binIter] ),
            .newValid_o        (newValid        [binIter] ),
            .newIdx_o          (newIdx          [binIter] ),    
            .newDelta_o        (newDelta        [binIter] ),
            .searchIdx_o       (searchIdx       [binIter] ),
            .searchValid_o     (searchValid     [binIter] ),
            .searchValue_i     (searchValue     [binIter] ),
            .searchValueValid_i(searchValueValid[binIter] ),

            // test
            .data_count(data_count[binIter]),
            .r_en(r_en[binIter]),
            .arrayheadIdx(arrayheadIdx[binIter]),
            // test end
            .CUClean_o         (CUClean_o       [binIter] )
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
// Empty flag
// --------------------------------------------------------------------
    always_ff @(posedge clk_i) begin
        if (binValid_o == 'b0) begin
            queueEmpty_o <=  `SD 'b1;
        end else begin
            queueEmpty_o <=  `SD 'b0;
        end
    end

// --------------------------------------------------------------------
// Output MUX
// --------------------------------------------------------------------
    always_comb begin
        binIdx_o    =   'd0;
        rowIdx_o    =   'd0;
        rowDelta_o  =   'd0;
        rowValid_o  =   'b0;
        for (int i = 0; i < C_BIN_NUM; i++) begin
            if (binSelected_i[i] & rowValid[i]) begin
                binIdx_o    =   i;
                rowIdx_o    =   rowIdx[i];
                rowDelta_o  =   rowDelta[i];
                rowValid_o  =   rowValid[i];
            end
        end
    end

    generate
        for (binIter = 0; binIter < C_BIN_NUM; binIter++) begin
            always_comb begin
                rowReady[binIter]   =   'b0;
                if (binSelected_i[binIter]) begin
                    rowReady[binIter]   =   rowReady_i;
                end
            end
        end
    endgenerate

// ====================================================================
// RTL Logic End
// ====================================================================


endmodule
