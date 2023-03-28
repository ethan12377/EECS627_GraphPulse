/////////////////////////////////////////////////////////////////////////
//                                                                     //
//  Modulename  :  queue_scheduler.sv                                  //
//                                                                     //
//  Description :  queue_scheduler                                     // 
//                                                                     //
/////////////////////////////////////////////////////////////////////////

module queue_scheduler #(
    parameter   C_BIN_NUM           =   `BIN_NUM           ,

    parameter   C_BIN_IDX_WIDTH     =   `BIN_IDX_WIDTH     
) (
    input   logic                         clk_i             ,   //  Clock
    input   logic                         rst_i             ,   //  Reset
    input   logic  [`PE_NUM_OF_CORES-1:0] initialFinish_i   ,   
    input   logic  [C_BIN_NUM-1:0]        CUClean_i         ,
    input   logic  [C_BIN_NUM-1:0]        binValid_i        ,
    output  logic  [C_BIN_NUM-1:0]        binSelected_o     ,
    input   logic  [`PE_NUM_OF_CORES-1:0] PEready_i          ,   
    output  logic                         readEn_o          
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
    // Declare state and next state variables
    QS_STATE                    qs_state            ;
    QS_STATE                    next_qs_state       ;
    
    // Declare bin reading variables
    logic [C_BIN_IDX_WIDTH-1:0] reading_bin         ;
    logic [C_BIN_IDX_WIDTH-1:0] grant               ;
    logic                       grant_valid         ;
    logic                       grant_ack           ;
    
    // Declare internal variables
    logic [C_BIN_NUM-1:0]       grant_onehot        ;
    logic                       next_readen         ;
    logic                       next_queue_empty    ;
 
    // Delay peidle for peready
    logic                       PEidle              ;
    logic                       PEReady             ;
    logic [3:0]                 delaycount          ;

    // past readbing bin buffer
    // bin_buf[i] = {valid, bin_idx}
    logic [C_BIN_NUM-1:0][C_BIN_IDX_WIDTH:0]   bin_buf;
    logic [C_BIN_NUM-1:0]       bin_reselect_b        ;
    logic                       bin_reselect          ;
    logic                       RoundFinish           ;

    // preselect bin at Binselection stage and output binselecion at Wait stage
    logic [C_BIN_NUM-1:0]       prebinSelected        ;

    //logic bin

    logic initialFinish;
    assign initialFinish = &initialFinish_i;


// ====================================================================
// Signal Declarations End
// ====================================================================

// ====================================================================
// Module Instantiations Start
// ====================================================================
// --------------------------------------------------------------------
// Module name  :   rr_arbiter
// Description  :   round robin arbiter
// --------------------------------------------------------------------
    rr_arbiter #(
        .C_REQ_NUM          (C_BIN_NUM              ),
        .C_REQ_IDX_WIDTH    (C_BIN_IDX_WIDTH        )
    ) qs_rr_arbiter (
        .clk_i              (clk_i                  ),   //  Clock
        .rst_i              (rst_i                  ),   //  Reset
        .en_i               (1'b1                   ),
        .ack_i              (grant_ack              ),  
        .req_i              (binValid_i             ),
        .grant_o            (grant                  ),
        .grant_onehot_o     (grant_onehot           ),
        .valid_o            (grant_valid            ),
        .mask_o             ()
    );

// --------------------------------------------------------------------


// ====================================================================
// Module Instantiations End
// ====================================================================

// ====================================================================
// RTL Logic Start
// ====================================================================

// --------------------------------------------------------------------
// FSM
// --------------------------------------------------------------------
    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            qs_state    <=  `SD Init;
        end else begin
            qs_state    <=  `SD next_qs_state;
        end
    end

    always_comb begin

        next_qs_state = qs_state;

        case(qs_state)
            
            // Initial state
            Init: next_qs_state = initialFinish ? CUComm : Init;
            
            // read and write from CU
            CUComm: begin
                if (binValid_i != 8'd0) begin
                    next_qs_state    = BinSelect;
                end 
            end
            
            // Bin selection state
            BinSelect: begin
                if (bin_reselect) begin
                    next_qs_state = DetectRound;
                end
                else begin
                    next_qs_state = WaitRead;
                end
            end

            // RoundFinish state
            DetectRound: begin
                if (PEReady) begin
                    next_qs_state    = WaitRead;
                end 
            end
            
            // WaitRead state
            WaitRead: begin
                if (CUClean_i[reading_bin]) begin
                    next_qs_state = Read;
                end
            end
            
            // Read state
            Read: begin
                if (binValid_i[reading_bin] == 1'b0) begin
                    next_qs_state = CUComm;
                end
            end
            
            // Default state
            default: next_qs_state = Init;
        endcase
    end


// --------------------------------------------------------------------
// PEReady : 10-cycle delay of PEidle
// --------------------------------------------------------------------
    assign PEidle   =   &PEready_i;

    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            delaycount <=  `SD 'd0;
            PEReady    <=  `SD 'd0;
        end
        else if (PEidle) begin
            // in python, we have 10.
            // in verilog, we have 8.
            if (delaycount == 'd8) begin
                PEReady    <=  `SD 'd1;
                delaycount <=  `SD 'd0;
            end
            else begin
                PEReady    <=  `SD 'd0;
                delaycount <=  `SD 'd1 + delaycount;
            end
        end else begin
            PEReady    <=  `SD 'd0;
            delaycount <=  `SD 'd0;
        end
    end


// --------------------------------------------------------------------
// Read enable
// --------------------------------------------------------------------
    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            readEn_o      <=  `SD 'b0;
        end else begin
            if (qs_state == WaitRead && CUClean_i[reading_bin]) begin
                readEn_o  <=  `SD 'b1;
            end else if (qs_state == Read && ~binValid_i[reading_bin]) begin
                readEn_o  <=  `SD 'b0;
            end
            else begin
                readEn_o  <=  `SD readEn_o;
            end
        end
    end



// --------------------------------------------------------------------
// Control the bins
// --------------------------------------------------------------------
    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            reading_bin     <=  `SD 'd0;
            prebinSelected  <=  `SD 'd0;
        end else if (qs_state == CUComm && grant_valid) begin
            reading_bin     <=  `SD grant;
            prebinSelected  <=  `SD grant_onehot;
        end else if (qs_state == CUComm && binValid_i[reading_bin] == 1'b0) begin
            reading_bin     <=  `SD 'd0;
            prebinSelected  <=  `SD 'd0;
        end else begin 
            reading_bin     <=  `SD  reading_bin;
            prebinSelected  <=  `SD  prebinSelected;
        end
        
    end

    always_ff@(posedge clk_i) begin
        if (rst_i) begin
            binSelected_o <=  `SD 'd0;
        end else if (qs_state == WaitRead) begin
            binSelected_o <=  `SD prebinSelected;
        end else begin
            binSelected_o <=  `SD binSelected_o;
        end
    end

// --------------------------------------------------------------------
// fill in bin_buf and detect roundfinish
// --------------------------------------------------------------------
    always_comb begin
    for (int i  = 0; i < C_BIN_NUM; i++) begin
        bin_reselect_b[i] = (reading_bin == bin_buf[i][C_BIN_IDX_WIDTH-1:0]) && (bin_buf[i][C_BIN_IDX_WIDTH]);
    end
    end

    assign bin_reselect = |bin_reselect_b;

    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            bin_buf      <= `SD  'd0;
        end
        else if (qs_state == BinSelect) begin
            bin_buf[0]               <= `SD  {1'b1, reading_bin};
            if (bin_reselect) begin
                bin_buf[C_BIN_NUM-1:1]   <= `SD  'd0;
            end else begin
                bin_buf[C_BIN_NUM-1:1]   <= `SD  bin_buf[C_BIN_NUM-2:0];
            end
        end else begin
                bin_buf      <= `SD  bin_buf      ;
        end
    end





// --------------------------------------------------------------------
// Acknowledge the grant and shift priority
// --------------------------------------------------------------------
    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            grant_ack   <=  'b0;
        end
        else if (qs_state == BinSelect) begin
            grant_ack   <=  'b1;
        end else begin
            grant_ack   <=  'b0;
        end
    end

// ====================================================================
// RTL Logic End
// ====================================================================


endmodule


