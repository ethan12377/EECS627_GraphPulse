/////////////////////////////////////////////////////////////////////////
//                                                                     //
//  Modulename  :  queue_scheduler.sv                                  //
//                                                                     //
//  Description :  queue_scheduler                                     // 
//                                                                     //
/////////////////////////////////////////////////////////////////////////

module queue_scheduler #(
    parameter   C_BIN_NUM           =   `BIN_NUM           ,
    parameter   C_BIN_IDX_WIDTH     =   `BIN_IDX_WIDTH     ,
    parameter   C_REQ_IDX_WIDTH     =   $clog2(C_REQ_NUM)
) (
    input   logic                         clk_i           ,   //  Clock
    input   logic                         rst_i           ,   //  Reset
    input   logic  [C_BIN_NUM-1:0]        initialFinish   ,   
    input   logic  [C_BIN_NUM-1:0]        cuclean         ,
    input   logic  [C_BIN_NUM-1:0]        binValid        ,
    output  logic  [C_BIN_NUM-1:0]        binselected     ,   
    output  logic                         readen          ,   
    output  logic                         queue_empty     
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
    QS_STATE qs_state;
    QS_STATE next_qs_state;
    
    // Declare bin reading variables
    logic [C_BIN_IDX_WIDTH-1:0] reading_bin;
    logic [C_BIN_IDX_WIDTH-1:0] next_reading_bin;
    logic                       reading_bin_n_valid;
    
    // Declare internal variables
    logic [C_BIN_NUM-1:0] next_binselected;
    logic                 next_readen;
    logic                 next_queue_empty;

    //logic bin

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
    .C_REQ_NUM      (8              )   ,
    .C_REQ_IDX_WIDTH(C_REQ_IDX_WIDTH)
    ) qs_rr_arbiter (
    .clk_i           (clk_i                 ),   //  Clock
    .rst_i           (rst_i                 ),   //  Reset
    .en_i            (qs_state == 'C'       ),
    .ack_i           (),                           // ???
    .req_i           (binValid              ),
    .grant_o         (next_reading_bin      ),
    .grant_onehot_o  (next_binselected      ),
    .valid_o         (next_reading_bin_valid)
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

    always_comb begin

        case(qs_state)
            
            // Initial state
            'I': next_qs_state = initialFinish ? 'C' : 'I';
            
            // read and write from CU
            'C': begin
                if (binValid != 8'b0) begin
                    next_qs_state    = 'B';
                    next_queue_empty = 1'b1;
                end 
                else begin
                    next_qs_state    = qs_state;
                    next_queue_empty = 1'b0;
                end
            end
            
            // Bin selection state
            'B': next_qs_state = 'W';
            
            // Wait state
            'W': begin
                if (cuclean[reading_bin]) begin
                    next_qs_state = 'R';
                    next_readen   = 1'b1;
                end else begin
                    next_qs_state = qs_state;
                    next_readen   = 1'b0;
                end
            end
            
            // Read state
            'R': begin
                if (binValid[reading_bin_n] == 1'b0) begin
                    next_qs_state = 'C';
                    next_readen   = 1'b0;
                end else begin
                    next_qs_state = qs_state;
                    next_readen   = 1'b1;
                end
            end
            
            // Default state
            default: next_qs_state = 'I';
        endcase
    end


// --------------------------------------------------------------------
// udpate next output
// --------------------------------------------------------------------
        
    always_ff @(posedge clk_i) begin
    if (rst_i) begin
        readen      <=  'b0;
        queue_empty <=  'b0;   
    end
    else begin
        readen      <= next_readen;
        queue_empty <= next_queue_empty;         
    end
    end
        
    // how to assign reading_bin and binselected when next_reading_bin_valid not valid???
    assign reading_bin = next_reading_bin_valid ? next_reading_bin : 'b0;
    assign binselected = next_reading_bin_valid ? next_binselected : 'b0;
// ====================================================================
// RTL Logic End
// ====================================================================


endmodule


