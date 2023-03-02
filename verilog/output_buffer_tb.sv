/////////////////////////////////////////////////////////////////////////
//                                                                     //
//  Modulename  :  output_buffer_tb.sv                                //
//                                                                     //
//  Description :  output_buffer_tb                                   // 
//                                                                     //
/////////////////////////////////////////////////////////////////////////

module output_buffer_tb;

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
    logic   [`ROW_IDX_WIDTH-1:0]                    rowIdx_i    ;
    logic   [`BIN_IDX_WIDTH-1:0]                    binIdx_i    ;
    logic   [`COL_NUM-1:0][`DELTA_WIDTH-1:0]        rowDelta_i  ;
    logic                                           rowValid_i  ;
    logic                                           rowReady_o  ;
    logic   [`PE_NUM-1:0][`DELTA_WIDTH-1:0]         IssDelta_o  ;
    logic   [`PE_NUM-1:0][`VERTEX_IDX_WIDTH-1:0]    IssIdx_o    ;
    logic   [`PE_NUM-1:0]                           IssValid_o  ;
    logic   [`PE_NUM-1:0]                           IssReady_i  ;

    logic                                           rowValid_i_ram  [C_CYCLE_NUM-1:0];
    logic                                           rowReady_o_ram  [C_CYCLE_NUM-1:0];
    logic   [`BIN_IDX_WIDTH-1:0]                    binIdx_i_ram    [C_CYCLE_NUM-1:0];
    logic   [`ROW_IDX_WIDTH-1:0]                    rowIdx_i_ram    [C_CYCLE_NUM-1:0];
    logic   [`COL_NUM-1:0][`DELTA_WIDTH-1:0]        rowDelta_i_ram  [C_CYCLE_NUM-1:0];
    logic   [`PE_NUM-1:0][`DELTA_WIDTH-1:0]         IssDelta_o_ram  [C_CYCLE_NUM-1:0];
    logic   [`PE_NUM-1:0][`VERTEX_IDX_WIDTH-1:0]    IssIdx_o_ram    [C_CYCLE_NUM-1:0];
    logic   [`PE_NUM-1:0]                           IssValid_o_ram  [C_CYCLE_NUM-1:0];
    logic   [`PE_NUM-1:0]                           IssReady_i_ram  [C_CYCLE_NUM-1:0];

// ====================================================================
// Signal Declarations End
// ====================================================================

// ====================================================================
// Module Instantiations Start
// ====================================================================
// --------------------------------------------------------------------
// Module name  :   output_buffer
// Description  :   
// --------------------------------------------------------------------
output_buffer output_buffer_inst (
    .clk_i      (clk_i      ),   //  Clock
    .rst_i      (rst_i      ),   //  Reset
    .rowIdx_i   (rowIdx_i   ),
    .binIdx_i   (binIdx_i   ),
    .rowDelta_i (rowDelta_i ),
    .rowValid_i (rowValid_i ),
    .rowReady_o (rowReady_o ),
    .IssDelta_o (IssDelta_o ),
    .IssIdx_o   (IssIdx_o   ),
    .IssValid_o (IssValid_o ),
    .IssReady_i (IssReady_i )
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

        fd  =   $fopen("../output_buffer_ground_truth.txt", "r");
        if (fd == 0) begin
            $display("Input File not opened!!!");
            $finish;
        end
        $fgets(line, fd);
        while (!$feof(fd)) begin
            $fscanf(fd, "%h ", value);
            // $display(value);
            case (value_idx)
                0 : rowValid_i_ram[cycle_idx]       =   value;
                1 : rowReady_o_ram[cycle_idx]       =   value;
                2 : binIdx_i_ram  [cycle_idx]       =   value;
                3 : rowIdx_i_ram  [cycle_idx]       =   value;
                4 : rowDelta_i_ram[cycle_idx][0]    =   value;
                5 : rowDelta_i_ram[cycle_idx][1]    =   value;
                6 : rowDelta_i_ram[cycle_idx][2]    =   value;
                7 : rowDelta_i_ram[cycle_idx][3]    =   value;
                8 : rowDelta_i_ram[cycle_idx][4]    =   value;
                9 : rowDelta_i_ram[cycle_idx][5]    =   value;
                10: rowDelta_i_ram[cycle_idx][6]    =   value;
                11: rowDelta_i_ram[cycle_idx][7]    =   value;
                12: IssDelta_o_ram[cycle_idx][0]    =   value;
                13: IssIdx_o_ram  [cycle_idx][0]    =   value;
                14: IssValid_o_ram[cycle_idx][0]    =   value;
                15: IssReady_i_ram[cycle_idx][0]    =   value;
                16: IssDelta_o_ram[cycle_idx][1]    =   value;
                17: IssIdx_o_ram  [cycle_idx][1]    =   value;
                18: IssValid_o_ram[cycle_idx][1]    =   value;
                19: IssReady_i_ram[cycle_idx][1]    =   value;
                20: IssDelta_o_ram[cycle_idx][2]    =   value;
                21: IssIdx_o_ram  [cycle_idx][2]    =   value;
                22: IssValid_o_ram[cycle_idx][2]    =   value;
                23: IssReady_i_ram[cycle_idx][2]    =   value;
                24: IssDelta_o_ram[cycle_idx][3]    =   value;
                25: IssIdx_o_ram  [cycle_idx][3]    =   value;
                26: IssValid_o_ram[cycle_idx][3]    =   value;
                27: IssReady_i_ram[cycle_idx][3]    =   value;
                default: ;
            endcase
            if (value_idx == 27) begin
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
        fd_w    =   $fopen("../output_buffer_attempt.txt", "w");
        if (fd_w == 0) begin
            $display("Output File not opened!!!");
            $finish;
        end
        $fdisplay(fd_w, "rowValid rowReady binIdx rowIdx rowDelta[0] rowDelta[1] rowDelta[2] rowDelta[3] rowDelta[4] rowDelta[5] rowDelta[6] rowDelta[7] IssDelta[0] IssIdx[0] IssValid[0] IssReady[0] IssDelta[1] IssIdx[1] IssValid[1] IssReady[1] IssDelta[2] IssIdx[2] IssValid[2] IssReady[2] IssDelta[3] IssIdx[3] IssValid[3] IssReady[3] ");
        rst_i   =   0;
        #(`VERILOG_CLOCK_PERIOD);
        rst_i   =   1;
        #(`VERILOG_CLOCK_PERIOD);
        rst_i   =   0;
        for (int i = 0; i < C_CYCLE_NUM; i++) begin
            $display("Cycle[%0d]", i);
            @(posedge clk_i);
            `SD;
            rowIdx_i    =   rowIdx_i_ram[i];
            binIdx_i    =   binIdx_i_ram[i];
            rowDelta_i  =   rowDelta_i_ram[i];
            rowValid_i  =   rowValid_i_ram[i];
            IssReady_i  =   IssReady_i_ram[i];

            @(negedge clk_i);
            $fdisplay(fd_w, "%h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h ",
            rowValid_i, rowReady_o, binIdx_i, rowIdx_i, 
            rowDelta_i[0], rowDelta_i[1], rowDelta_i[2], rowDelta_i[3], 
            rowDelta_i[4], rowDelta_i[5], rowDelta_i[6], rowDelta_i[7], 
            IssDelta_o[0], IssIdx_o[0], IssValid_o[0], IssReady_i[0],
            IssDelta_o[1], IssIdx_o[1], IssValid_o[1], IssReady_i[1],
            IssDelta_o[2], IssIdx_o[2], IssValid_o[2], IssReady_i[2],
            IssDelta_o[3], IssIdx_o[3], IssValid_o[3], IssReady_i[3],
            );

            $display("offset - [0]:%h [1]:%h [2]:%h [3]:%h [4]:%h [5]:%h [6]:%h [7]:%h",
            output_buffer_inst.OB_bubble_squeezer_inst.offset[0], output_buffer_inst.OB_bubble_squeezer_inst.offset[1], output_buffer_inst.OB_bubble_squeezer_inst.offset[2], output_buffer_inst.OB_bubble_squeezer_inst.offset[3], 
            output_buffer_inst.OB_bubble_squeezer_inst.offset[4], output_buffer_inst.OB_bubble_squeezer_inst.offset[5], output_buffer_inst.OB_bubble_squeezer_inst.offset[6], output_buffer_inst.OB_bubble_squeezer_inst.offset[7]
            );
            $display("row - [0]:%h [1]:%h [2]:%h [3]:%h [4]:%h [5]:%h [6]:%h [7]:%h",
            rowDelta_i[0], rowDelta_i[1], rowDelta_i[2], rowDelta_i[3], 
            rowDelta_i[4], rowDelta_i[5], rowDelta_i[6], rowDelta_i[7]
            );
            $display("buf - [0]:(%h, %h, %h) [1]:(%h, %h, %h) [2]:(%h, %h, %h) [3]:(%h, %h, %h)",
            output_buffer_inst.OB_bubble_squeezer_inst.row_buf_data[0][23:16], output_buffer_inst.OB_bubble_squeezer_inst.row_buf_data[0][15:0], output_buffer_inst.OB_bubble_squeezer_inst.row_buf_valid[0],
            output_buffer_inst.OB_bubble_squeezer_inst.row_buf_data[1][23:16], output_buffer_inst.OB_bubble_squeezer_inst.row_buf_data[1][15:0], output_buffer_inst.OB_bubble_squeezer_inst.row_buf_valid[1],
            output_buffer_inst.OB_bubble_squeezer_inst.row_buf_data[2][23:16], output_buffer_inst.OB_bubble_squeezer_inst.row_buf_data[2][15:0], output_buffer_inst.OB_bubble_squeezer_inst.row_buf_valid[2],
            output_buffer_inst.OB_bubble_squeezer_inst.row_buf_data[3][23:16], output_buffer_inst.OB_bubble_squeezer_inst.row_buf_data[3][15:0], output_buffer_inst.OB_bubble_squeezer_inst.row_buf_valid[3]
            );
            $display("buf - [4]:(%h, %h, %h) [5]:(%h, %h, %h) [6]:(%h, %h, %h) [7]:(%h, %h, %h)",
            output_buffer_inst.OB_bubble_squeezer_inst.row_buf_data[4][23:16], output_buffer_inst.OB_bubble_squeezer_inst.row_buf_data[4][15:0], output_buffer_inst.OB_bubble_squeezer_inst.row_buf_valid[4],
            output_buffer_inst.OB_bubble_squeezer_inst.row_buf_data[5][23:16], output_buffer_inst.OB_bubble_squeezer_inst.row_buf_data[5][15:0], output_buffer_inst.OB_bubble_squeezer_inst.row_buf_valid[5],
            output_buffer_inst.OB_bubble_squeezer_inst.row_buf_data[6][23:16], output_buffer_inst.OB_bubble_squeezer_inst.row_buf_data[6][15:0], output_buffer_inst.OB_bubble_squeezer_inst.row_buf_valid[6],
            output_buffer_inst.OB_bubble_squeezer_inst.row_buf_data[7][23:16], output_buffer_inst.OB_bubble_squeezer_inst.row_buf_data[7][15:0], output_buffer_inst.OB_bubble_squeezer_inst.row_buf_valid[7],
            );
            $display("fifo - ready: %0b empty_num: %0d data_num: %0d [0]:(%h, %h, %h) [1]:(%h, %h, %h) [2]:(%h, %h, %h) [3]:(%h, %h, %h)",
            output_buffer_inst.fifo_ready, output_buffer_inst.OB_fifo_inst.empty_num, output_buffer_inst.OB_fifo_inst.data_num,
            output_buffer_inst.fifo_data[0][23:16], output_buffer_inst.fifo_data[0][15:0], output_buffer_inst.fifo_valid[0],
            output_buffer_inst.fifo_data[1][23:16], output_buffer_inst.fifo_data[1][15:0], output_buffer_inst.fifo_valid[1],
            output_buffer_inst.fifo_data[2][23:16], output_buffer_inst.fifo_data[2][15:0], output_buffer_inst.fifo_valid[2],
            output_buffer_inst.fifo_data[3][23:16], output_buffer_inst.fifo_data[3][15:0], output_buffer_inst.fifo_valid[3]
            );

        end
        $fclose(fd_w);
        $finish;
    end


// ====================================================================
// RTL Logic End
// ====================================================================


endmodule
