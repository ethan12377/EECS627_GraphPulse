/////////////////////////////////////////////////////////////////////////
//                                                                     //
//  Modulename  :  qs_cu_tb.sv                                         //
//                                                                     //
//  Description :  qs_cu_tb                                            // 
//                                                                     //
/////////////////////////////////////////////////////////////////////////

module qs_cu_tb;

// ====================================================================
// Local Parameters Declarations Start
// ====================================================================
    localparam  C_CYCLE_NUM =   500;
// ====================================================================
// Local Parameters Declarations End
// ====================================================================

// ====================================================================
// Signal Declarations Start
// ====================================================================
    logic                         clk_i             ;   //  Clock
    logic                         rst_i             ;

    logic  [`PE_NUM_OF_CORES-1:0] initialFinish_i   ;   
    logic  [`BIN_NUM-1:0]         CUClean           ;
    logic  [`BIN_NUM-1:0]         binValid          ;
    logic  [`BIN_NUM-1:0]         binSelected       ; 
    logic  [`PE_NUM_OF_CORES-1:0] PEready_i         ;
    logic                         readEn            ;

    logic   [`BIN_NUM-1:0][`DELTA_WIDTH-1:0]        CUDelta_i       ;
    logic   [`BIN_NUM-1:0][`VERTEX_IDX_WIDTH-1:0]   CUIdx_i         ;
    logic   [`BIN_NUM-1:0]                          CUValid_i       ;
    logic   [`BIN_NUM-1:0]                          CUReady_o       ;
    logic   [`BIN_NUM-1:0]                          CUClean_o       ;
    
    logic   [`ROW_IDX_WIDTH-1:0]                    rowIdx_o        ;
    logic   [`BIN_IDX_WIDTH-1:0]                    binIdx_o        ;
    logic   [`COL_NUM-1:0][`DELTA_WIDTH-1:0]        rowDelta_o      ;
    logic                                           rowValid_o      ;
    logic                                           rowReady_i      ;
    // // test
    // logic  [`BIN_NUM-1:0][`VERTEX_IDX_WIDTH-1:0]    searchIdx       ;
    // logic  [`BIN_NUM-1:0]                           searchValid     ;
    // // test end

    //???
    logic                                           queueEmpty_o    ;

    logic                                           initialFinish_i_ram     [C_CYCLE_NUM-1:0];
    logic   [`BIN_NUM-1:0][`DELTA_WIDTH-1:0]        CUDelta_i_ram           [C_CYCLE_NUM-1:0];
    logic   [`BIN_NUM-1:0][`VERTEX_IDX_WIDTH-1:0]   CUIdx_i_ram             [C_CYCLE_NUM-1:0];
    logic   [`BIN_NUM-1:0]                          CUValid_i_ram           [C_CYCLE_NUM-1:0];
    logic                                           rowReady_i_ram          [C_CYCLE_NUM-1:0]; 
    logic                                           rowValid_o_ram          [C_CYCLE_NUM-1:0]; 
    logic   [`BIN_IDX_WIDTH-1:0]                    binIdx_o_ram            [C_CYCLE_NUM-1:0]; 
    logic   [`ROW_IDX_WIDTH-1:0]                    rowIdx_o_ram            [C_CYCLE_NUM-1:0]; 
    logic   [`COL_NUM-1:0][`DELTA_WIDTH-1:0]        rowDelta_o_ram          [C_CYCLE_NUM-1:0];
    logic   [`BIN_NUM-1:0]                          CUReady_o_ram           [C_CYCLE_NUM-1:0];
    logic   [`PE_NUM_OF_CORES-1:0]                  PEready_i_ram           [C_CYCLE_NUM-1:0];
    // logic   [`BIN_NUM-1:0]                          CUClean_o_ram           [C_CYCLE_NUM-1:0];
    // logic   [`BIN_NUM-1:0][`VERTEX_IDX_WIDTH-1:0]   searchidx_i_ram         [C_CYCLE_NUM-1:0];
    // logic   [`BIN_NUM-1:0]                          searchValid_i_ram       [C_CYCLE_NUM-1:0];

// ====================================================================
// Signal Declarations End
// ====================================================================

// ====================================================================
// Module Instantiations Start
// ====================================================================
// --------------------------------------------------------------------
// Module name  :   queue_scheduler
// Description  :   
// --------------------------------------------------------------------
queue_scheduler queue_scheduler_inst(
    .clk_i                  (clk_i),   //  Clock
    .rst_i                  (rst_i),   //  Reset
    .initialFinish_i        (initialFinish_i),   
    .CUClean_i              (CUClean_o),
    .binValid_i             (binValid),
    .binSelected_o          (binSelected),   
    .PEready_i              (PEready_i),
    .readEn_o               (readEn)          
);
// --------------------------------------------------------------------

// --------------------------------------------------------------------
// Module name  :   event_queues
// Description  :   
// --------------------------------------------------------------------
event_queues  event_queues_inst(
    .clk_i                  (clk_i),   //  Clock
    .rst_i                  (rst_i),   //  Reset
    .initialFinish_i        (initialFinish_i),
    .CUDelta_i              (CUDelta_i),
    .CUIdx_i                (CUIdx_i),
    .CUValid_i              (CUValid_i),
    .CUReady_o              (CUReady_o),
    .CUClean_o              (CUClean_o),
    .binValid_o             (binValid),
    .binSelected_i          (binSelected),   
    .readEn_i               (readEn), 
    .rowIdx_o               (rowIdx_o),
    .binIdx_o               (binIdx_o),
    .rowDelta_o             (rowDelta_o),
    .rowValid_o             (rowValid_o),
    .rowReady_i             (rowReady_i),
    // // test
    // .searchIdx        (searchIdx),
    // .searchValid      (searchValid),
    // // test end
    .queueEmpty_o           (queueEmpty_o)     
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

        fd  =   $fopen("../qs_cu_ground_truth.txt", "r");
        if (fd == 0) begin
            $display("Input File not opened!!!");
            $finish;
        end
        $fgets(line, fd);
        while (!$feof(fd)) begin
            $fscanf(fd, "%h ", value);
            case (value_idx)
                0 : initialFinish_i_ram[cycle_idx]       =   value;
                1 : CUDelta_i_ram[cycle_idx][0]          =   value;
                2 : CUIdx_i_ram[cycle_idx][0]            =   value;
                3 : CUValid_i_ram[cycle_idx][0]          =   value;
                4 : CUDelta_i_ram[cycle_idx][1]          =   value;
                5 : CUIdx_i_ram[cycle_idx][1]            =   value;
                6 : CUValid_i_ram[cycle_idx][1]          =   value;
                7 : CUDelta_i_ram[cycle_idx][2]          =   value;
                8 : CUIdx_i_ram[cycle_idx][2]            =   value;
                9 : CUValid_i_ram[cycle_idx][2]          =   value;
                10: CUDelta_i_ram[cycle_idx][3]          =   value;
                11: CUIdx_i_ram[cycle_idx][3]            =   value;
                12: CUValid_i_ram[cycle_idx][3]          =   value;
                13: CUDelta_i_ram[cycle_idx][4]          =   value;
                14: CUIdx_i_ram[cycle_idx][4]            =   value;
                15: CUValid_i_ram[cycle_idx][4]          =   value;
                16: CUDelta_i_ram[cycle_idx][5]          =   value;
                17: CUIdx_i_ram[cycle_idx][5]            =   value;
                18: CUValid_i_ram[cycle_idx][5]          =   value;
                19: CUDelta_i_ram[cycle_idx][6]          =   value;
                20: CUIdx_i_ram[cycle_idx][6]            =   value;
                21: CUValid_i_ram[cycle_idx][6]          =   value;
                22: CUDelta_i_ram[cycle_idx][7]          =   value;
                23: CUIdx_i_ram[cycle_idx][7]            =   value;
                24: CUValid_i_ram[cycle_idx][7]          =   value;
                25: rowReady_i_ram[cycle_idx]            =   value;
                26: rowValid_o_ram[cycle_idx]            =   value;
                27: binIdx_o_ram[cycle_idx]              =   value;
                28: rowIdx_o_ram[cycle_idx]              =   value;
                29: rowDelta_o_ram[cycle_idx][0]         =   value;
                30: rowDelta_o_ram[cycle_idx][1]         =   value;
                31: rowDelta_o_ram[cycle_idx][2]         =   value;
                32: rowDelta_o_ram[cycle_idx][3]         =   value;
                33: rowDelta_o_ram[cycle_idx][4]         =   value;
                34: rowDelta_o_ram[cycle_idx][5]         =   value;
                35: rowDelta_o_ram[cycle_idx][6]         =   value;
                36: rowDelta_o_ram[cycle_idx][7]         =   value;
                37: CUReady_o_ram[cycle_idx][0]          =   value; // // CUClean_o_ram[cycle_idx][0]         =   value;
                38: CUReady_o_ram[cycle_idx][1]          =   value; // // CUClean_o_ram[cycle_idx][1]         =   value;
                39: CUReady_o_ram[cycle_idx][2]          =   value; // // CUClean_o_ram[cycle_idx][2]         =   value;
                40: CUReady_o_ram[cycle_idx][3]          =   value; // // CUClean_o_ram[cycle_idx][3]         =   value;
                41: CUReady_o_ram[cycle_idx][4]          =   value; // // CUClean_o_ram[cycle_idx][4]         =   value;
                42: CUReady_o_ram[cycle_idx][5]          =   value; // // CUClean_o_ram[cycle_idx][5]         =   value;
                43: CUReady_o_ram[cycle_idx][6]          =   value; // // CUClean_o_ram[cycle_idx][6]         =   value;
                44: CUReady_o_ram[cycle_idx][7]          =   value; // // CUClean_o_ram[cycle_idx][7]         =   value;         
                45: PEready_i_ram[cycle_idx][0]          =   value;
                46: PEready_i_ram[cycle_idx][1]          =   value;
                47: PEready_i_ram[cycle_idx][2]          =   value;
                48: PEready_i_ram[cycle_idx][3]          =   value;
                // 45: searchidx_i_ram[cycle_idx][0]          =   value;
                // 46: searchValid_i_ram[cycle_idx][1]          =   value;
                // 47: searchidx_i_ram[cycle_idx][2]          =   value;
                // 48: searchValid_i_ram[cycle_idx][3]          =   value;
                // 49: searchidx_i_ram[cycle_idx][4]          =   value;
                // 50: searchValid_i_ram[cycle_idx][5]          =   value;
                // 51: searchidx_i_ram[cycle_idx][6]          =   value;
                // 52: searchValid_i_ram[cycle_idx][7]          =   value;
                // 53: searchidx_i_ram[cycle_idx][0]          =   value;
                // 54: searchValid_i_ram[cycle_idx][1]          =   value;
                // 55: searchidx_i_ram[cycle_idx][2]          =   value;
                // 56: searchValid_i_ram[cycle_idx][3]          =   value;
                // 57: searchidx_i_ram[cycle_idx][4]          =   value;
                // 58: searchValid_i_ram[cycle_idx][5]          =   value;
                // 59: searchidx_i_ram[cycle_idx][6]          =   value;
                // 60: searchValid_i_ram[cycle_idx][7]          =   value;
                default: ;
            endcase
            if (value_idx == 48) begin
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
        fd_w    =   $fopen("../qs_cu_attempt.txt", "w");
        if (fd_w == 0) begin
            $display("Output File not opened!!!");
            $finish;
        end
        $fdisplay(fd_w, "initialFinish CUDelta[0] CUIdx[0] CUValid[0] CUDelta[1] CUIdx[1] CUValid[1] CUDelta[2] CUIdx[2] CUValid[2] CUDelta[3] CUIdx[3] CUValid[3] CUDelta[4] CUIdx[4] CUValid[4] CUDelta[5] CUIdx[5] CUValid[5] CUDelta[6] CUIdx[6] CUValid[6] CUDelta[7] CUIdx[7] CUValid[7] rowReady rowValid binIdx rowIdx rowDelta[0] rowDelta[1] rowDelta[2] rowDelta[3] rowDelta[4] rowDelta[5] rowDelta[6] rowDelta[7] CUReady[0] CUReady[1] CUReady[2] CUReady[3] CUReady[4] CUReady[5] CUReady[6] CUReady[7] PEReady[0] PEReady[1] PEReady[2] PEReady[3]");
        rst_i   =   0;
        #(`VERILOG_CLOCK_PERIOD);
        rst_i   =   1;
        #(`VERILOG_CLOCK_PERIOD);
        rst_i   =   0;
        for (int i = 0; i < C_CYCLE_NUM; i++) begin
            $display("Cycle[%0d]", i);
            @(posedge clk_i);
            `SD;
            initialFinish_i = {4{initialFinish_i_ram[i]}};
            CUDelta_i       = CUDelta_i_ram[i];
            CUIdx_i         = CUIdx_i_ram[i];
            CUValid_i       = CUValid_i_ram[i];
            rowReady_i      = rowReady_i_ram[i];
            PEready_i       = PEready_i_ram[i];
            
            @(negedge clk_i);
            $fdisplay(fd_w, "%h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h",   //
            initialFinish_i[0], 
            CUDelta_i[0], CUIdx_i[0], CUValid_i[0],
            CUDelta_i[1], CUIdx_i[1], CUValid_i[1],
            CUDelta_i[2], CUIdx_i[2], CUValid_i[2],
            CUDelta_i[3], CUIdx_i[3], CUValid_i[3],
            CUDelta_i[4], CUIdx_i[4], CUValid_i[4],
            CUDelta_i[5], CUIdx_i[5], CUValid_i[5],
            CUDelta_i[6], CUIdx_i[6], CUValid_i[6],
            CUDelta_i[7], CUIdx_i[7], CUValid_i[7],
            rowReady_i, rowValid_o, binIdx_o, rowIdx_o,
            rowDelta_o[0], rowDelta_o[1], rowDelta_o[2], rowDelta_o[3], 
            rowDelta_o[4], rowDelta_o[5], rowDelta_o[6], rowDelta_o[7],
            CUReady_o[0], CUReady_o[1], CUReady_o[2], CUReady_o[3],
            CUReady_o[4], CUReady_o[5], CUReady_o[6], CUReady_o[7],
            PEready_i[0], PEready_i[1], PEready_i[2], PEready_i[3],
            // ,
            // CUClean_o[0], CUClean_o[1], CUClean_o[2], CUClean_o[3],
            // CUClean_o[4], CUClean_o[5], CUClean_o[6], CUClean_o[7],
            // searchIdx[0],searchValid[0],searchIdx[1],searchValid[1],
            // searchIdx[2],searchValid[2],searchIdx[3],searchValid[3],
            // searchIdx[4],searchValid[4],searchIdx[5],searchValid[5],
            // searchIdx[6],searchValid[6],searchIdx[7],searchValid[7]
            );

            // $display("binSelected[0]:(%b) [1]:(%b) [2]:(%b) [3]:(%b) [4]:(%b) [5]:(%b) [6]:(%b) [7]:(%b) ",
            // binSelected[0],binSelected[1],binSelected[2],binSelected[3],
            // binSelected[4],binSelected[5],binSelected[6],binSelected[7]);
            // $display("r_en[7]:(%b)", event_queues_inst.r_en[7]);
            // $display("arrayhead[7]:(%h)", event_queues_inst.arrayheadIdx[7]);

            // $display("readEn:(%b)", readEn);
            // $display("CUClean[1]:(%b)", CUClean[1]);
            $display("qs_state :(%s)", queue_scheduler_inst.qs_state);
            $display("bin_buf[0][3] && (bin_buf[0][2:0]:(%h %h )", queue_scheduler_inst.bin_buf[0][3], queue_scheduler_inst.bin_buf[0][2:0]);
            $display("bin_buf[1][3] && (bin_buf[1][2:0]:(%h %h )", queue_scheduler_inst.bin_buf[1][3], queue_scheduler_inst.bin_buf[1][2:0]);
            $display("bin_buf[2][3] && (bin_buf[2][2:0]:(%h %h )", queue_scheduler_inst.bin_buf[2][3], queue_scheduler_inst.bin_buf[2][2:0]);
            $display("bin_buf[3][3] && (bin_buf[3][2:0]:(%h %h )", queue_scheduler_inst.bin_buf[3][3], queue_scheduler_inst.bin_buf[3][2:0]);
            $display("bin_buf[4][3] && (bin_buf[4][2:0]:(%h %h )", queue_scheduler_inst.bin_buf[4][3], queue_scheduler_inst.bin_buf[4][2:0]);
            $display("bin_buf[5][3] && (bin_buf[5][2:0]:(%h %h )", queue_scheduler_inst.bin_buf[5][3], queue_scheduler_inst.bin_buf[5][2:0]);
            $display("bin_buf[6][3] && (bin_buf[6][2:0]:(%h %h )", queue_scheduler_inst.bin_buf[6][3], queue_scheduler_inst.bin_buf[6][2:0]);
            $display("bin_buf[7][3] && (bin_buf[7][2:0]:(%h %h )", queue_scheduler_inst.bin_buf[7][3], queue_scheduler_inst.bin_buf[7][2:0]);
            // $display("datacount[4]:(%h)", event_queues_inst.data_count[4]);
            // $display("ready_o[4]:(%h)", event_queues_inst.CUReady_o[4]);
            // $display("ready_o[4]:(%h)", CUReady_o[4]);
            // ,CUClean[1],CUClean[2],CUClean[3],CUClean[4],CUClean[5],CUClean[6],CUClean[7]

            // $display("rowNotEmpty[bin1]:(%d,%d,%d,%d)", 
            // event_queues_inst.rowNotEmpty[1][0],
            // event_queues_inst.rowNotEmpty[1][1],
            // event_queues_inst.rowNotEmpty[1][2],
            // event_queues_inst.rowNotEmpty[1][3]); 

            
        end
        $fclose(fd_w);
        $finish;
    end


// ====================================================================
// RTL Logic End
// ====================================================================


endmodule