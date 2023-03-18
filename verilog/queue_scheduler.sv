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
            qs_state    <=  `SD I;
        end else begin
            qs_state    <=  `SD next_qs_state;
        end
    end

    always_comb begin

        next_qs_state = qs_state;

        case(qs_state)
            
            // Initial state
            I: next_qs_state = initialFinish ? C : I;
            
            // read and write from CU
            C: begin
                if (binValid_i != 8'd0) begin
                    next_qs_state    = B;
                end 
            end
            
            // Bin selection state
            B: next_qs_state = W;
            
            // Wait state
            W: begin
                if (CUClean_i[reading_bin]) begin
                    next_qs_state = R;
                end
            end
            
            // Read state
            R: begin
                if (binValid_i[reading_bin] == 1'b0) begin
                    next_qs_state = C;
                end
            end
            
            // Default state
            default: next_qs_state = I;
        endcase
    end

// --------------------------------------------------------------------
// Read enable
// --------------------------------------------------------------------
    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            readEn_o      <=  `SD 'b0;
        end else begin
            if (qs_state == W && CUClean_i[reading_bin]) begin
                readEn_o  <=  `SD 'b1;
            end else if (qs_state == R && ~binValid_i[reading_bin]) begin
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
            binSelected_o   <=  `SD 'b0;
        end else if (qs_state == C && grant_valid) begin
            reading_bin     <=  `SD grant;
            binSelected_o   <=  `SD grant_onehot;
        end else begin 
            reading_bin     <=  `SD  reading_bin;
            binSelected_o   <=  `SD  binSelected_o;
        end
        // else if (qs_state == R && binValid_i[reading_bin] == 1'b0) begin
        //     reading_bin     <=  `SD 'd0;
        //     binSelected_o   <=  `SD 'b0;
        // end
    end

// --------------------------------------------------------------------
// Acknowledge the grant and shift priority
// --------------------------------------------------------------------
    always_ff @(posedge clk_i) begin
        if (qs_state == B) begin
            grant_ack   <=  'b1;
        end else begin
            grant_ack   <=  'b0;
        end
    end

// ====================================================================
// RTL Logic End
// ====================================================================


endmodule


