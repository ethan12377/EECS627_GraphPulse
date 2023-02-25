/////////////////////////////////////////////////////////////////////////
//                                                                     //
//  Modulename  :  Xbar_SchedToPE_tb.sv                                //
//                                                                     //
//  Description :  Xbar_SchedToPE_tb                                   // 
//                                                                     //
/////////////////////////////////////////////////////////////////////////

module Xbar_SchedToPE_tb;

// ====================================================================
// Local Parameters Declarations Start
// ====================================================================

// ====================================================================
// Local Parameters Declarations End
// ====================================================================

// ====================================================================
// Signal Declarations Start
// ====================================================================
    logic                                           clk_i       ;
    logic                                           rst_i       ;
    logic   [`PE_NUM-1:0][`DELTA_WIDTH-1:0]         IssDelta_i  ;
    logic   [`PE_NUM-1:0][`VERTEX_IDX_WIDTH-1:0]    IssIdx_i    ;
    logic   [`PE_NUM-1:0]                           IssValid_i  ;
    logic   [`PE_NUM-1:0]                           IssReady_o  ;
    logic   [`PE_NUM-1:0][`DELTA_WIDTH-1:0]         PEDelta_o   ;
    logic   [`PE_NUM-1:0][`VERTEX_IDX_WIDTH-1:0]    PEIdx_o     ;
    logic   [`PE_NUM-1:0]                           PEValid_o   ;
    logic   [`PE_NUM-1:0]                           PEReady_i   ;

    int fd;
    string line;
// ====================================================================
// Signal Declarations End
// ====================================================================

// ====================================================================
// Module Instantiations Start
// ====================================================================
// --------------------------------------------------------------------
// Module name  :   Xbar_SchedToPE
// Description  :   Crossbar
// --------------------------------------------------------------------
    Xbar_SchedToPE Xbar_SchedToPE_inst(
        .clk_i      (clk_i      ),   //  Clock
        .rst_i      (rst_i      ),   //  Reset
        .IssDelta_i (IssDelta_i ),
        .IssIdx_i   (IssIdx_i   ),
        .IssValid_i (IssValid_i ),
        .IssReady_o (IssReady_o ),
        .PEDelta_o  (PEDelta_o  ),
        .PEIdx_o    (PEIdx_o    ),
        .PEValid_o  (PEValid_o  ),
        .PEReady_i  (PEReady_i  )
    );
// --------------------------------------------------------------------

// ====================================================================
// Module Instantiations End
// ====================================================================

// ====================================================================
// RTL Logic Start
// ====================================================================

// --------------------------------------------------------------------
// Clock generation
// --------------------------------------------------------------------
    initial begin
        clk_i   =   'b0 ;
        forever begin
            #(`VERILOG_CLOCK_PERIOD/2);
            clk_i   =   ~clk_i;
        end
    end

// --------------------------------------------------------------------
// Read ground truth from file
// --------------------------------------------------------------------
    initial begin
        fd  =   $open("../Xbar_SchedToPE_ground_truth.txt", "r");
        if (fd == 0) begin
            $$display("File not opened!!!");
            $finish;
        end

        while (!$feof(fd)) begin
            $fgets(fd, line);
            $display(line);
        end

    end

// ====================================================================
// RTL Logic End
// ====================================================================


endmodule
