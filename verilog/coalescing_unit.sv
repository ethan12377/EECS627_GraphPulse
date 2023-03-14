/////////////////////////////////////////////////////////////////////////
//                                                                     //
//  Modulename  :  template.sv                                         //
//                                                                     //
//  Description :  template                                            // 
//                                                                     //
/////////////////////////////////////////////////////////////////////////

module coalescing_unit #(
    parameter   C_DELTA_WIDTH       =   `DELTA_WIDTH        ,
    parameter   C_VERTEX_IDX_WIDTH  =   `VERTEX_IDX_WIDTH   ,
    parameter   C_CU_FIFO_DEPTH     =   `CU_FIFO_DEPTH      ,
    parameter   C_WIDTH             =   `EVENT_WIDTH        ,
    parameter   C_IDX_WIDTH         =   $clog2(C_CU_FIFO_DEPTH)


) (
    input   logic               clk_i           ,   //  Clock
    input   logic               rst_i           ,   //  Reset
    
    input   logic                           initialFinish_i,
    input   logic                           binSelected_i  ,
    
    // Interface with corssbar
    input  logic   [C_DELTA_WIDTH-1:0]      CUDelta_i      ,
    input  logic   [C_VERTEX_IDX_WIDTH-1:0] CUIdx_i        ,
    input  logic                            CUValid_i      ,
    output logic                            CUReady_o      ,

    // Interface with queue
    output logic                            newValid_o     ,
    output logic   [C_VERTEX_IDX_WIDTH-1:0] newIdx_o       ,    
    output logic   [C_DELTA_WIDTH-1:0]      newDelta_o     ,

    output logic   [C_VERTEX_IDX_WIDTH-1:0] searchIdx_o    ,
    output logic                            searchValid_o  ,
    input  logic   [C_DELTA_WIDTH-1:0]      searchValue_i  ,
    input  logic                            searchValueValid_i  ,

    output  logic                            CUClean_o      

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
    logic                            CU_fifo_empty    ;
    logic   [C_WIDTH-1:0]            fifo_o           ;
    logic                            fifo_valid_o     ;
    logic   [C_DELTA_WIDTH-1:0]      sum              ;


    // register
    logic                            Valid_o_reg0     ;
    logic   [C_VERTEX_IDX_WIDTH-1:0] Idx_o_reg0       ;
    logic   [C_DELTA_WIDTH-1:0]      Delta_o_reg0     ;

    logic                            Valid_o_reg1     ;
    logic   [C_VERTEX_IDX_WIDTH-1:0] Idx_o_reg1       ;
    logic   [C_DELTA_WIDTH-1:0]      Delta_o_reg1     ;

    logic                            Valid_o_reg2     ;
    logic   [C_VERTEX_IDX_WIDTH-1:0] Idx_o_reg2       ;
    logic   [C_DELTA_WIDTH-1:0]      Delta_o_reg2     ;

// ====================================================================
// Signal Declarations End
// ====================================================================

// ====================================================================
// Module Instantiations Start
// ====================================================================
// --------------------------------------------------------------------
// Module name  :   CU_fifo
// Description  :   basic fifo for coalescing unit
// --------------------------------------------------------------------
CU_fifo CU_fifo_inst (
    .clk_i        (clk_i                               ),   //  Clock
    .rst_i        (rst_i                               ),   //  Reset   
    .wr_en_i      (CUValid_i & (initialFinish_i)       ),   //  fifo after initial
    .wdata_i      ({CUIdx_i, CUDelta_i}                ),
    .ready_o      (CUReady_o                           ),   
    .rdata_o      (fifo_o                              ),
    .rdata_valid_o(fifo_valid_o                        ),
    .rd_en_i      ((~binSelected_i) & (initialFinish_i)),   //  issue new data only when bin not selected
    .empty_o      (CU_fifo_empty                       )     

);

// --------------------------------------------------------------------
// Module name  :   fp_add
// Description  :   adder
// --------------------------------------------------------------------
fp_add fp_add_inst(
    .opA (searchValue_i),
    .opB (Delta_o_reg1),
    .sum (sum)
);
// --------------------------------------------------------------------

// ====================================================================
// Module Instantiations End
// ====================================================================

// ====================================================================
// RTL Logic Start
// ====================================================================

// --------------------------------------------------------------------
// output to Queue
// --------------------------------------------------------------------

    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            newValid_o   <=  ` SD 'b0;
            newIdx_o     <=  ` SD 'b0;
            newDelta_o   <=  ` SD 'b0;
        end
        else if (~initialFinish_i) begin
            newValid_o   <=  ` SD CUValid_i;
            newIdx_o     <=  ` SD CUIdx_i  ;
            newDelta_o   <=  ` SD CUDelta_i;
        end
        else begin
            newValid_o   <=  ` SD Valid_o_reg2;
            newIdx_o     <=  ` SD Idx_o_reg2  ;
            newDelta_o   <=  ` SD Delta_o_reg2;
        end
    end
    
// --------------------------------------------------------------------
// register 0 & search
// --------------------------------------------------------------------

    always_comb begin
        Valid_o_reg0   =  fifo_valid_o                   ;
        Idx_o_reg0     =  fifo_o[C_WIDTH-1:C_DELTA_WIDTH];
        Delta_o_reg0   =  fifo_o[C_DELTA_WIDTH-1:0]      ;
    end

    always_comb begin
        if (fifo_valid_o) begin
            searchIdx_o    =  fifo_o[C_WIDTH-1:C_DELTA_WIDTH];
            searchValid_o  =  fifo_valid_o;
        end
        else begin
            searchIdx_o    =  'd0  ;  
            searchValid_o  =  'd0  ; 
        end
    end 


// --------------------------------------------------------------------
// register 1
// --------------------------------------------------------------------
    always_ff @(posedge clk_i) begin
            Valid_o_reg1   <=  ` SD Valid_o_reg0;
            Idx_o_reg1     <=  ` SD Idx_o_reg0  ;
            Delta_o_reg1   <=  ` SD Delta_o_reg0;
    end
    

// --------------------------------------------------------------------
// register 2
// --------------------------------------------------------------------
    always_ff @(posedge clk_i) begin
        if (searchValueValid_i) begin
            Valid_o_reg2   <=  ` SD Valid_o_reg1;
            Idx_o_reg2     <=  ` SD Idx_o_reg1  ;
            Delta_o_reg2   <=  ` SD sum         ;
        end
        else begin
            Valid_o_reg2   <=  ` SD 'b0;
            Idx_o_reg2     <=  ` SD 'd0;
            Delta_o_reg2   <=  ` SD 'd0;
        end
    end

// --------------------------------------------------------------------
// CUClean_o
// --------------------------------------------------------------------
    always_ff @(posedge clk_i) begin
        if (rst_i)
            CUClean_o <= `SD 'b0;

        else if (~Valid_o_reg2 & ~Valid_o_reg1 & ~Valid_o_reg0 & ~newValid_o & initialFinish_i)
                CUClean_o <= `SD 'b1;
            else
                CUClean_o <= `SD 'b0;
    end

// ====================================================================
// RTL Logic End
// ====================================================================


endmodule
