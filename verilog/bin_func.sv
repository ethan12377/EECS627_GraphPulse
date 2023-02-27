/////////////////////////////////////////////////////////////////////////
//                                                                     //
//  Modulename  :  bin_func.sv                                         //
//                                                                     //
//  Description :   if bin_selected and readen, read to outputbuffer   // 
//                  otherwise, search and write with cu                //
//                                                                     //
/////////////////////////////////////////////////////////////////////////

module bin_func #(
    parameter   C_BIN_NUM           =   `BIN_NUM                      ,
    parameter   C_ROW_NUM           =   `ROW_NUM                      ,
    parameter   C_COL_NUM           =   `COL_NUM                      ,
    parameter   C_BIN_IDX_WIDTH     =   `BIN_IDX_WIDTH                ,
    parameter   C_ROW_IDX_WIDTH     =   `ROW_IDX_WIDTH                ,
    parameter   C_COL_IDX_WIDTH     =   `COL_IDX_WIDTH                ,
    parameter   C_BIN_ROW_IDX_WIDTH =   `BIN_IDX_WIDTH + `ROW_IDX_WIDTH,
    parameter   C_FULL_IDX_WIDTH    =   C_BIN_ROW_IDX_WIDTH + `COL_IDX_WIDTH,

    parameter   C_DELTA_WIDTH       =   `DELTA_WIDTH       ,
    pparameter  C_REQ_IDX_WIDTH     =   $clog2(C_REQ_NUM)
)(
    input   logic                             clk_i         ,   //  Clock
    input   logic                             rst_i         ,   //  Reset
    
    //from queue scheduler
    input   logic                                  cuclean       ,
    input   logic                                  rowready      ,
    input   logic  [C_BIN_IDX_WIDTH-1:0]           reading_bin   ,
    

    //from coalescing unit
    input   logic  [C_FULL_IDX_WIDTH-1:0]          newIdx        ,
    input   logic                                  newValid      ,
    input   logic  [C_DELTA_WIDTH-1:0]             newDelta      ,

    output  logic  [C_FULL_IDX_WIDTH-1:0]          searchIdx     ,
    output  logic                                  searchValid   ,
    

    // to output buffer
    output  logic  [C_DELTA_WIDTH * C_COL_NUM-1:0] rowDelta      ,
    output  logic                                  rowValid      ,
    output  logic  [C_BIN_ROW_IDX_WIDTH-1:0]       binrowIdx     ,

    //to coalecing unit
    output  logic  [C_DELTA_WIDTH-1:0]             searchValue   ,
    output  logic                                  searchValueValid,


    //inout: bin
    input   logic  [C_BIN_IDX_WIDTH-1:0]          processing_bin,   // this bin
    inout   logic  [C_DELTA_WIDTH-1:0]            bin[C_ROW_NUM-1:0][C_COL_NUM-1:0],
    inout   logic  [C_ROW_NUM-1:0]                rowValidMatrix

);

// ====================================================================
// Local Parameters Declarations Start
// ====================================================================
    parameter   C_REQ_NUM       =   8                 ;
    parameter   C_REQ_IDX_WIDTH =   $clog2(C_REQ_NUM) ;
// ====================================================================
// Local Parameters Declarations End
// ====================================================================

// ====================================================================
// Signal Declarations Start
// ====================================================================
    // to output buffer
    logic  [C_DELTA_WIDTH * C_COL_NUM-1:0] next_rowDelta ;
    logic                                  next_rowValid ;
    logic  [C_BIN_ROW_IDX_WIDTH-1:0]       next_binrowIdx;

    // extract Idx
    logic [C_BIN_IDX_WIDTH-1:0]            newBIN;
    logic [C_ROW_IDX_WIDTH-1:0]            newROW;
    logic [C_COL_IDX_WIDTH-1:0]            newCOL;

    // extract Idx
    logic [C_BIN_IDX_WIDTH-1:0]            searchBIN;
    logic [C_ROW_IDX_WIDTH-1:0]            searchROW;
    logic [C_COL_IDX_WIDTH-1:0]            searchCOL;
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
    .C_REQ_NUM       = C_REQ_NUM      ,
    .C_REQ_IDX_WIDTH = C_REQ_IDX_WIDTH         
    )readrow_priority_arbiter(
    .req_i         (rowValidMatrix)   ,
    .grant_o       (readrowIdx    )   ,
    .valid_o       (readrowValid  )  
);

// --------------------------------------------------------------------


// ====================================================================
// Module Instantiations End
// ====================================================================

// ====================================================================
// RTL Logic Start
// ====================================================================

// --------------------------------------------------------------------
// When the bin is selected
// Read row to output_buffer
// --------------------------------------------------------------------
    // select reading row
    always_comb begin
        if ((processing_bin == reading_bin) & cuclean & rowReady & readrowValid) begin
            next_binrowIdx = {reading_bin, readrowIdx};
            next_rowValid  = 1'b1;
            next_rowDelta  = bin[readrowIdx]
        end else begin
            next_binrowIdx =  'b0;
            next_rowValid  = 1'b0;
            next_rowDelta  =  'b0;
        end
    end

    // update reading row
    always_ff @( posedge clk ) begin 
         if (rst_i) begin
            binrowIdx <=  'b0;
            rowValid  <= 1'b0;
            rowDelta  <=  'b0;
         end
         else begin
            binrowIdx <= next_binrowIdx;
            rowValid  <= next_rowValid ;
            rowDelta  <= next_rowDelta ;
         end        
    end


    // update bin, dead lock???
    always_ff @( posedge clk ) begin 
         if (rst_i) begin
            bin             <= bin           ;
            rowValidMatrix  <= rowValidMatrix;
         end
         else begin
            if (next_rowValid) begin
                bin[readrowIdx]             <=  'b0;
                rowValidMatrix[readrowIdx]  <= 1'b0;
            end else begin
                bin             <= bin           ;
                rowValidMatrix  <= rowValidMatrix;
            end
         end        
    end
    

// --------------------------------------------------------------------
// When the bin is not selected
// search and write with cu
// --------------------------------------------------------------------


// extract newIdx
always_comb begin
    newBIN = newIdx[C_FULL_IDX_WIDTH-1:C_ROW_IDX_WIDTH+C_COL_IDX_WIDTH];
    newROW = newIdx[C_ROW_IDX_WIDTH+C_COL_IDX_WIDTH-1:C_COL_IDX_WIDTH];
    newCOL = newIdx[C_COL_IDX_WIDTH-1:0];  
end

// write from cu
always_ff @( posedge clk ) begin 
         if (rst_i) begin
            bin             <= bin           ;
            rowValidMatrix  <= rowValidMatrix;
         end
         else begin
            if (processing_bin != reading_bin) & (newValid) & (processing_bin == newBIN)begin
                bin[newROW][newCOL]    <= newDelta;
                rowValidMatrix[newROW] <= 1'b1;
            end
            else begin
            bin             <= bin           ;
            rowValidMatrix  <= rowValidMatrix;
            end
        end
end

// extract searchIdx
always_comb begin
    newBIN = searchIdx[C_FULL_IDX_WIDTH-1:C_ROW_IDX_WIDTH+C_COL_IDX_WIDTH];
    newROW = searchIdx[C_ROW_IDX_WIDTH+C_COL_IDX_WIDTH-1:C_COL_IDX_WIDTH];
    newCOL = searchIdx[C_COL_IDX_WIDTH-1:0];  
end
// search for cu
always_ff @( posedge clk ) begin 
         if (rst_i) begin
            searchValue      <=  'b0;
            searchValueValid <= 1'b0;
         end
         else begin
            if (processing_bin != reading_bin) & (searchValid) & (processing_bin == searchBIN)begin
                searchValue      <= bin[newROW][newCOL];
                searchValueValid <= 1'b1;
            end
            else begin
                searchValue      <=  'b0;
                searchValueValid <= 1'b0;
            end
        end
end


// ====================================================================
// RTL Logic End
// ====================================================================


endmodule
