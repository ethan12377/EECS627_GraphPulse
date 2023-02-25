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
    localparam  C_CYCLE_NUM =   200;
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

    logic   [`PE_NUM-1:0][`DELTA_WIDTH-1:0]         IssDelta_i_ram  [C_CYCLE_NUM-1:0];
    logic   [`PE_NUM-1:0][`VERTEX_IDX_WIDTH-1:0]    IssIdx_i_ram    [C_CYCLE_NUM-1:0];
    logic   [`PE_NUM-1:0]                           IssValid_i_ram  [C_CYCLE_NUM-1:0];
    logic   [`PE_NUM-1:0]                           IssReady_o_ram  [C_CYCLE_NUM-1:0];
    logic   [`PE_NUM-1:0][`DELTA_WIDTH-1:0]         PEDelta_o_ram   [C_CYCLE_NUM-1:0];
    logic   [`PE_NUM-1:0][`VERTEX_IDX_WIDTH-1:0]    PEIdx_o_ram     [C_CYCLE_NUM-1:0];
    logic   [`PE_NUM-1:0]                           PEValid_o_ram   [C_CYCLE_NUM-1:0];
    logic   [`PE_NUM-1:0]                           PEReady_i_ram   [C_CYCLE_NUM-1:0];
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

        int fd;
        int value_idx;
        int cycle_idx;
        string line;
        int value;

        fd  =   $fopen("../Xbar_SchedToPE_ground_truth.txt", "r");
        if (fd == 0) begin
            $display("Input File not opened!!!");
            $finish;
        end
        $fgets(line, fd);
        while (!$feof(fd)) begin
            $fscanf(fd, "%h ", value);
            // $display(value);
            case (value_idx)
                0 : IssDelta_i_ram[cycle_idx][0]    =   value;
                1 : IssIdx_i_ram  [cycle_idx][0]    =   value;
                2 : IssValid_i_ram[cycle_idx][0]    =   value;
                3 : IssReady_o_ram[cycle_idx][0]    =   value;
                4 : IssDelta_i_ram[cycle_idx][1]    =   value;
                5 : IssIdx_i_ram  [cycle_idx][1]    =   value;
                6 : IssValid_i_ram[cycle_idx][1]    =   value;
                7 : IssReady_o_ram[cycle_idx][1]    =   value;
                8 : IssDelta_i_ram[cycle_idx][2]    =   value;
                9 : IssIdx_i_ram  [cycle_idx][2]    =   value;
                10: IssValid_i_ram[cycle_idx][2]    =   value;
                11: IssReady_o_ram[cycle_idx][2]    =   value;
                12: IssDelta_i_ram[cycle_idx][3]    =   value;
                13: IssIdx_i_ram  [cycle_idx][3]    =   value;
                14: IssValid_i_ram[cycle_idx][3]    =   value;
                15: IssReady_o_ram[cycle_idx][3]    =   value;
                16: PEDelta_o_ram [cycle_idx][0]    =   value;
                17: PEIdx_o_ram   [cycle_idx][0]    =   value;
                18: PEValid_o_ram [cycle_idx][0]    =   value;
                19: PEReady_i_ram [cycle_idx][0]    =   value;
                20: PEDelta_o_ram [cycle_idx][1]    =   value;
                21: PEIdx_o_ram   [cycle_idx][1]    =   value;
                22: PEValid_o_ram [cycle_idx][1]    =   value;
                23: PEReady_i_ram [cycle_idx][1]    =   value;
                24: PEDelta_o_ram [cycle_idx][2]    =   value;
                25: PEIdx_o_ram   [cycle_idx][2]    =   value;
                26: PEValid_o_ram [cycle_idx][2]    =   value;
                27: PEReady_i_ram [cycle_idx][2]    =   value;
                28: PEDelta_o_ram [cycle_idx][3]    =   value;
                29: PEIdx_o_ram   [cycle_idx][3]    =   value;
                30: PEValid_o_ram [cycle_idx][3]    =   value;
                31: PEReady_i_ram [cycle_idx][3]    =   value;
                default: ;
            endcase
            if (value_idx == 31) begin
                value_idx = 0;
                cycle_idx++;
            end else begin
                value_idx++;
            end
        end
        $fclose(fd);
    end

// --------------------------------------------------------------------
// Apply stimulus
// --------------------------------------------------------------------
    initial begin
        int fd_w    ;
        fd_w    =   $fopen("../Xbar_SchedToPE_attempt.txt", "w");
        if (fd_w == 0) begin
            $display("Output File not opened!!!");
            $finish;
        end
        $fdisplay(fd_w, "IssDelta[0] IssIdx[0] IssValid[0] IssReady[0] IssDelta[1] IssIdx[1] IssValid[1] IssReady[1] IssDelta[2] IssIdx[2] IssValid[2] IssReady[2] IssDelta[3] IssIdx[3] IssValid[3] IssReady[3] PEDelta[0] PEIdx[0] PEValid[0] PEReady[0] PEDelta[1] PEIdx[1] PEValid[1] PEReady[1] PEDelta[2] PEIdx[2] PEValid[2] PEReady[2] PEDelta[3] PEIdx[3] PEValid[3] PEReady[3] ");
        rst_i   =   0;
        #(`VERILOG_CLOCK_PERIOD);
        rst_i   =   1;
        #(`VERILOG_CLOCK_PERIOD);
        rst_i   =   0;
        for (int i = 0; i < C_CYCLE_NUM; i++) begin
            @(posedge clk_i);
            IssDelta_i  =   IssDelta_i_ram[i];
            IssIdx_i    =   IssIdx_i_ram[i];
            IssValid_i  =   IssValid_i_ram[i];
            PEReady_i   =   PEReady_i_ram[i];

            @(negedge clk_i);
            $fdisplay(fd_w, "%h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h ",
            IssDelta_i[0], IssIdx_i[0], IssValid_i[0], IssReady_o[0],
            IssDelta_i[1], IssIdx_i[1], IssValid_i[1], IssReady_o[1],
            IssDelta_i[2], IssIdx_i[2], IssValid_i[2], IssReady_o[2],
            IssDelta_i[3], IssIdx_i[3], IssValid_i[3], IssReady_o[3],
            PEDelta_o[0] , PEIdx_o[0] , PEValid_o[0] , PEReady_i[0],
            PEDelta_o[1] , PEIdx_o[1] , PEValid_o[1] , PEReady_i[1],
            PEDelta_o[2] , PEIdx_o[2] , PEValid_o[2] , PEReady_i[2],
            PEDelta_o[3] , PEIdx_o[3] , PEValid_o[3] , PEReady_i[3]);
            // if (IssReady_o != IssReady_o_ram[i]) begin
            //     $display("IssReady_o incorrect");
            //     $stop;
            // end
            // if (PEValid_o != PEValid_o_ram[i]) begin
            //     $display("PEValid_o incorrect");
            //     $stop;
            // end
            // if (PEIdx_o != PEIdx_o_ram[i]) begin
            //     $display("PEIdx_o incorrect");
            //     $stop;
            // end
            // if (PEDelta_o != PEDelta_o[i]) begin
            //     $display("PEDelta_o incorrect");
            //     $stop;
            // end
        end
        $fclose(fd_w);
        $finish;
    end


// ====================================================================
// RTL Logic End
// ====================================================================


endmodule
