/////////////////////////////////////////////////////////////////////////
//                                                                     //
//  Modulename  :  CU_fifo.sv                                          //
//                                                                     //
//  Description :  basic fifo in coalescing unit                       // 
//                                                                     //
/////////////////////////////////////////////////////////////////////////

module CU_fifo #(
    parameter   C_WIDTH             =   `EVENT_WIDTH           ,
    parameter   C_VERTEX_IDX_WIDTH             =   `VERTEX_IDX_WIDTH           ,
    parameter   C_DELTA_WIDTH       =   `DELTA_WIDTH           ,
    parameter   C_CU_FIFO_DEPTH     =   `CU_FIFO_DEPTH         ,
    parameter   C_IDX_WIDTH         =   $clog2(C_CU_FIFO_DEPTH)
) (
    input  logic                            clk_i          ,   //  Clock
    input  logic                            rst_i          ,   //  Reset
    

    // test
    output  logic   [C_IDX_WIDTH:0]                     data_count      ,    
    // testend

    output logic [C_VERTEX_IDX_WIDTH-1:0]          arrayheadIdx   ,
    // Push_In
    input  logic                            wr_en_i        ,
    input  logic [C_WIDTH-1:0]              wdata_i        ,
    output logic                            ready_o        ,   // asserted when fifo is not full
    
    // Pop_Out
    output logic [C_WIDTH-1:0]              rdata_o        ,
    output logic                            rdata_valid_o  ,
    input  logic                            rd_en_i        ,
    output logic                            empty_o        

);

// ====================================================================
// Signal Declarations Start
// ====================================================================
    // logic   [C_IDX_WIDTH:0]                     data_count      ;             
    logic   [C_IDX_WIDTH-1:0]                   tail            ;                 
    logic   [C_IDX_WIDTH-1:0]                   head            ; 
    logic   [C_IDX_WIDTH-1:0]                   next_head       ;
    logic   [C_IDX_WIDTH-1:0]                   next_tail       ;
    logic                                       push_in_en      ;
    logic                                       pop_out_en      ;
    // logic                                       full ;

    logic   [C_CU_FIFO_DEPTH-1:0][C_WIDTH-1:0]  FIFO            ;              
// ====================================================================
// Signal Declarations End
// ====================================================================


// ====================================================================
// RTL Logic Start
// ====================================================================

// --------------------------------------------------------------------
// assign arrayhead
// --------------------------------------------------------------------
    assign arrayheadIdx = FIFO[head][C_WIDTH-1:C_DELTA_WIDTH];

// --------------------------------------------------------------------
// Push-in & Pop-out handshake
// --------------------------------------------------------------------
    assign  push_in_en  =   wr_en_i && ready_o;
    assign  pop_out_en  =   rd_en_i && ~empty_o;

// --------------------------------------------------------------------
// Data count
// --------------------------------------------------------------------
always_ff@(posedge clk_i) begin 
    if(rst_i)
        data_count             <= `SD 'd0;
    else begin
        case({push_in_en,pop_out_en})
            2'b00:data_count  <=  `SD  data_count;
            2'b11:data_count  <=  `SD  data_count;
            2'b01:data_count  <=  `SD  data_count - 1;
            2'b10:data_count  <=  `SD  data_count + 1;          
        endcase
    end
end

// --------------------------------------------------------------------
// Flag assign
// --------------------------------------------------------------------
    assign ready_o     =    (data_count==C_CU_FIFO_DEPTH)?1'b0:1'b1;
    assign empty_o     =    (data_count==0)?1'b1:1'b0;


    // always_ff @(posedge clk_i) begin
    //     if (rst_i) begin
    //         ready_o <=   `SD 1'b0;
    //     end
    //     else if (data_count==C_CU_FIFO_DEPTH) begin
    //             ready_o <=   `SD 1'b0;
    //     end else begin
    //         ready_o <=   `SD 1'b1;
    //     end
    // end

    //     always_ff @(posedge clk_i) begin
    //     if (rst_i) begin
    //         ready_o <=   `SD 1'b0;
    //     end
    //     else begin
    //         ready_o <=   `SD ready_o_reg;
    //     end 
    // end

    

// --------------------------------------------------------------------
// Pointer movement
// --------------------------------------------------------------------
    // Pointer sequential
    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            // head    <=  `SD 'd0;
            tail    <=  `SD 'd0;
        end else begin
            // head    <=  `SD next_head;
            tail    <=  `SD next_tail;
        end
    end
    

    // Next state of pointers
    always_comb begin
        next_tail   =   tail;
        if (push_in_en) begin
            if (tail == C_CU_FIFO_DEPTH -1) begin
                next_tail   =   0;
            end else begin
                next_tail   =   tail + 1;
            end        
        end
    end

    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            head    <=  `SD 'd0;
        end else if (pop_out_en) begin
                if (head == C_CU_FIFO_DEPTH -1) begin
                    head   <=  `SD 'd0;
                end else begin
                    head   <=  `SD 'd1+head;
                end
        end else begin
            head   <=  `SD head;
        end
    end


// --------------------------------------------------------------------
// Push-in and Pop-out Entry
// --------------------------------------------------------------------
    // Push-in 
    always_ff@(posedge clk_i) begin
    if(push_in_en)
        FIFO[tail]    <=    `SD wdata_i;
    else
        FIFO[tail]    <=    `SD FIFO[tail];
    end

    // Pop-out 
    always_ff@(posedge clk_i) begin
        if(pop_out_en) begin
            rdata_o       <=    `SD FIFO[head];
            rdata_valid_o <=    `SD 'b1;
        end
        else begin
            rdata_o       <=    `SD 'b0;
            rdata_valid_o <=    `SD 'b0;
        end
    end

// ====================================================================
// RTL Logic End
// ====================================================================


endmodule
