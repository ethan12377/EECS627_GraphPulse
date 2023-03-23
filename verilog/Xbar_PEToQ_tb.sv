/////////////////////////////////////////////////////////////////////////
//                                                                     //
//  Modulename  :  Xbar_PEToQ_tb.sv                                //
//                                                                     //
//  Description :  Xbar_PEToQ_tb                                   // 
//                                                                     //
/////////////////////////////////////////////////////////////////////////

module Xbar_PEToQ_tb;

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
    logic   [`GEN_NUM-1:0][`DELTA_WIDTH-1:0]        proDelta_i  ;
    logic   [`GEN_NUM-1:0][`VERTEX_IDX_WIDTH-1:0]   proIdx_i    ;
    logic   [`GEN_NUM-1:0]                          proValid_i  ;
    logic   [`GEN_NUM-1:0]                          proReady_o  ;
    logic   [`BIN_NUM-1:0][`DELTA_WIDTH-1:0]        CUDelta_o   ;
    logic   [`BIN_NUM-1:0][`VERTEX_IDX_WIDTH-1:0]   CUIdx_o     ;
    logic   [`BIN_NUM-1:0]                          CUValid_o   ;
    logic   [`BIN_NUM-1:0]                          CUReady_i   ;

    logic   [`GEN_NUM-1:0][`DELTA_WIDTH-1:0]        proDelta_i_ram  [C_CYCLE_NUM-1:0];
    logic   [`GEN_NUM-1:0][`VERTEX_IDX_WIDTH-1:0]   proIdx_i_ram    [C_CYCLE_NUM-1:0];
    logic   [`GEN_NUM-1:0]                          proValid_i_ram  [C_CYCLE_NUM-1:0];
    logic   [`GEN_NUM-1:0]                          proReady_o_ram  [C_CYCLE_NUM-1:0];
    logic   [`BIN_NUM-1:0][`DELTA_WIDTH-1:0]        CUDelta_o_ram   [C_CYCLE_NUM-1:0];
    logic   [`BIN_NUM-1:0][`VERTEX_IDX_WIDTH-1:0]   CUIdx_o_ram     [C_CYCLE_NUM-1:0];
    logic   [`BIN_NUM-1:0]                          CUValid_o_ram   [C_CYCLE_NUM-1:0];
    logic   [`BIN_NUM-1:0]                          CUReady_i_ram   [C_CYCLE_NUM-1:0];
// ====================================================================
// Signal Declarations End
// ====================================================================

// ====================================================================
// Module Instantiations Start
// ====================================================================
// --------------------------------------------------------------------
// Module name  :   Xbar_PEToQ
// Description  :   Crossbar
// --------------------------------------------------------------------
    Xbar_PEToQ Xbar_PEToQ_inst(
        .clk_i      (clk_i      ),   //  Clock
        .rst_i      (rst_i      ),   //  Reset
        .proDelta_i (proDelta_i ),
        .proIdx_i   (proIdx_i   ),
        .proValid_i (proValid_i ),
        .proReady_o (proReady_o ),
        .CUDelta_o  (CUDelta_o  ),
        .CUIdx_o    (CUIdx_o    ),
        .CUValid_o  (CUValid_o  ),
        .CUReady_i  (CUReady_i  )
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

        fd  =   $fopen("../Xbar_PEToQ_ground_truth.txt", "r");
        if (fd == 0) begin
            $display("Input File not opened!!!");
            $finish;
        end
        $fgets(line, fd);
        while (!$feof(fd)) begin
            $fscanf(fd, "%h ", value);
            // $display(value);
            case (value_idx)
                0 : proDelta_i_ram[cycle_idx][0]    =   value;
                1 : proIdx_i_ram  [cycle_idx][0]    =   value;
                2 : proValid_i_ram[cycle_idx][0]    =   value;
                3 : proReady_o_ram[cycle_idx][0]    =   value;
                4 : proDelta_i_ram[cycle_idx][1]    =   value;
                5 : proIdx_i_ram  [cycle_idx][1]    =   value;
                6 : proValid_i_ram[cycle_idx][1]    =   value;
                7 : proReady_o_ram[cycle_idx][1]    =   value;
                8 : proDelta_i_ram[cycle_idx][2]    =   value;
                9 : proIdx_i_ram  [cycle_idx][2]    =   value;
                10: proValid_i_ram[cycle_idx][2]    =   value;
                11: proReady_o_ram[cycle_idx][2]    =   value;
                12: proDelta_i_ram[cycle_idx][3]    =   value;
                13: proIdx_i_ram  [cycle_idx][3]    =   value;
                14: proValid_i_ram[cycle_idx][3]    =   value;
                15: proReady_o_ram[cycle_idx][3]    =   value;
                16: proDelta_i_ram[cycle_idx][4]    =   value;
                17: proIdx_i_ram  [cycle_idx][4]    =   value;
                18: proValid_i_ram[cycle_idx][4]    =   value;
                19: proReady_o_ram[cycle_idx][4]    =   value;
                20: proDelta_i_ram[cycle_idx][5]    =   value;
                21: proIdx_i_ram  [cycle_idx][5]    =   value;
                22: proValid_i_ram[cycle_idx][5]    =   value;
                23: proReady_o_ram[cycle_idx][5]    =   value;
                24: proDelta_i_ram[cycle_idx][6]    =   value;
                25: proIdx_i_ram  [cycle_idx][6]    =   value;
                26: proValid_i_ram[cycle_idx][6]    =   value;
                27: proReady_o_ram[cycle_idx][6]    =   value;
                28: proDelta_i_ram[cycle_idx][7]    =   value;
                29: proIdx_i_ram  [cycle_idx][7]    =   value;
                30: proValid_i_ram[cycle_idx][7]    =   value;
                31: proReady_o_ram[cycle_idx][7]    =   value;
                32: CUDelta_o_ram [cycle_idx][0]    =   value;
                33: CUIdx_o_ram   [cycle_idx][0]    =   value;
                34: CUValid_o_ram [cycle_idx][0]    =   value;
                35: CUReady_i_ram [cycle_idx][0]    =   value;
                36: CUDelta_o_ram [cycle_idx][1]    =   value;
                37: CUIdx_o_ram   [cycle_idx][1]    =   value;
                38: CUValid_o_ram [cycle_idx][1]    =   value;
                39: CUReady_i_ram [cycle_idx][1]    =   value;
                40: CUDelta_o_ram [cycle_idx][2]    =   value;
                41: CUIdx_o_ram   [cycle_idx][2]    =   value;
                42: CUValid_o_ram [cycle_idx][2]    =   value;
                43: CUReady_i_ram [cycle_idx][2]    =   value;
                44: CUDelta_o_ram [cycle_idx][3]    =   value;
                45: CUIdx_o_ram   [cycle_idx][3]    =   value;
                46: CUValid_o_ram [cycle_idx][3]    =   value;
                47: CUReady_i_ram [cycle_idx][3]    =   value;
                48: CUDelta_o_ram [cycle_idx][4]    =   value;
                49: CUIdx_o_ram   [cycle_idx][4]    =   value;
                50: CUValid_o_ram [cycle_idx][4]    =   value;
                51: CUReady_i_ram [cycle_idx][4]    =   value;
                52: CUDelta_o_ram [cycle_idx][5]    =   value;
                53: CUIdx_o_ram   [cycle_idx][5]    =   value;
                54: CUValid_o_ram [cycle_idx][5]    =   value;
                55: CUReady_i_ram [cycle_idx][5]    =   value;
                56: CUDelta_o_ram [cycle_idx][6]    =   value;
                57: CUIdx_o_ram   [cycle_idx][6]    =   value;
                58: CUValid_o_ram [cycle_idx][6]    =   value;
                59: CUReady_i_ram [cycle_idx][6]    =   value;
                60: CUDelta_o_ram [cycle_idx][7]    =   value;
                61: CUIdx_o_ram   [cycle_idx][7]    =   value;
                62: CUValid_o_ram [cycle_idx][7]    =   value;
                63: CUReady_i_ram [cycle_idx][7]    =   value;
                default: ;
            endcase
            if (value_idx == 63) begin
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
        fd_w    =   $fopen("../Xbar_PEToQ_attempt.txt", "w");
        if (fd_w == 0) begin
            $display("Output File not opened!!!");
            $finish;
        end
        $fdisplay(fd_w, "proDelta[0] proIdx[0] proValid[0] proReady[0] proDelta[1] proIdx[1] proValid[1] proReady[1] proDelta[2] proIdx[2] proValid[2] proReady[2] proDelta[3] proIdx[3] proValid[3] proReady[3] proDelta[4] proIdx[4] proValid[4] proReady[4] proDelta[5] proIdx[5] proValid[5] proReady[5] proDelta[6] proIdx[6] proValid[6] proReady[6] proDelta[7] proIdx[7] proValid[7] proReady[7] CUDelta[0] CUIdx[0] CUValid[0] CUReady[0] CUDelta[1] CUIdx[1] CUValid[1] CUReady[1] CUDelta[2] CUIdx[2] CUValid[2] CUReady[2] CUDelta[3] CUIdx[3] CUValid[3] CUReady[3] CUDelta[4] CUIdx[4] CUValid[4] CUReady[4] CUDelta[5] CUIdx[5] CUValid[5] CUReady[5] CUDelta[6] CUIdx[6] CUValid[6] CUReady[6] CUDelta[7] CUIdx[7] CUValid[7] CUReady[7]");
        rst_i   =   0;
        #(`VERILOG_CLOCK_PERIOD);
        rst_i   =   1;
        #(`VERILOG_CLOCK_PERIOD);
        rst_i   =   0;
        for (int i = 0; i < C_CYCLE_NUM; i++) begin
            $display("Cycle[%0d]", i);
            @(posedge clk_i);
            `SD;
            proDelta_i  =   proDelta_i_ram[i];
            proIdx_i    =   proIdx_i_ram[i];
            proValid_i  =   proValid_i_ram[i];
            CUReady_i   =   CUReady_i_ram[i];

            @(negedge clk_i);
            $fdisplay(fd_w, "%h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h ",
            proDelta_i[0], proIdx_i[0], proValid_i[0], proReady_o[0],
            proDelta_i[1], proIdx_i[1], proValid_i[1], proReady_o[1],
            proDelta_i[2], proIdx_i[2], proValid_i[2], proReady_o[2],
            proDelta_i[3], proIdx_i[3], proValid_i[3], proReady_o[3],
            proDelta_i[4], proIdx_i[4], proValid_i[4], proReady_o[4],
            proDelta_i[5], proIdx_i[5], proValid_i[5], proReady_o[5],
            proDelta_i[6], proIdx_i[6], proValid_i[6], proReady_o[6],
            proDelta_i[7], proIdx_i[7], proValid_i[7], proReady_o[7],
            CUDelta_o[0] , CUIdx_o[0] , CUValid_o[0] , CUReady_i[0],
            CUDelta_o[1] , CUIdx_o[1] , CUValid_o[1] , CUReady_i[1],
            CUDelta_o[2] , CUIdx_o[2] , CUValid_o[2] , CUReady_i[2],
            CUDelta_o[3] , CUIdx_o[3] , CUValid_o[3] , CUReady_i[3],
            CUDelta_o[4] , CUIdx_o[4] , CUValid_o[4] , CUReady_i[4],
            CUDelta_o[5] , CUIdx_o[5] , CUValid_o[5] , CUReady_i[5],
            CUDelta_o[6] , CUIdx_o[6] , CUValid_o[6] , CUReady_i[6],
            CUDelta_o[7] , CUIdx_o[7] , CUValid_o[7] , CUReady_i[7]
            );

            for (int j = 0; j < `GEN_NUM; j++) begin
                $display("GEN[%0d] - Delta: %4h\tIdx: %2h\tValid: %0b\tReady: %0b\tBin_Idx: %0d", j, Xbar_PEToQ_inst.proDelta_i[j], Xbar_PEToQ_inst.proIdx_i[j], Xbar_PEToQ_inst.proValid_i[j], Xbar_PEToQ_inst.proReady_o[j], Xbar_PEToQ_inst.bin_idx[j]);
            end
            for (int j = 0; j < `BIN_NUM; j++) begin
                $display("BIN[%0d] - request: %8b\tgrant: %3d\tvalid: %0b\tbin_lock: %0b\tarb_en: %0b\tmask: %8b", j, Xbar_PEToQ_inst.request[j], Xbar_PEToQ_inst.grant[j], Xbar_PEToQ_inst.valid[j], Xbar_PEToQ_inst.bin_lock[j], Xbar_PEToQ_inst.arb_en[j], Xbar_PEToQ_inst.mask[j]);
            end
            for (int j = 0; j < `BIN_NUM; j++) begin
                $display("CU [%0d] - Delta: %4h\tIdx: %2h\tValid: %0b\tReady: %0b", j, Xbar_PEToQ_inst.CUDelta_o[j], Xbar_PEToQ_inst.CUIdx_o[j], Xbar_PEToQ_inst.CUValid_o[j], Xbar_PEToQ_inst.CUReady_i[j]);
            end

        end
        $fclose(fd_w);
        $finish;
    end


// ====================================================================
// RTL Logic End
// ====================================================================


endmodule
