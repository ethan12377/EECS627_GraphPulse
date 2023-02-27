/////////////////////////////////////////////////////////////////////////
//                                                                     //
//  Modulename  :  rr_arbiter.sv                                       //
//                                                                     //
//  Description :  Round-robin Arbiter                                 // 
//                                                                     //
/////////////////////////////////////////////////////////////////////////

module rr_arbiter #(
    parameter   C_REQ_NUM       =   8   ,
    parameter   C_REQ_IDX_WIDTH =   $clog2(C_REQ_NUM)
) (
    input   logic                           clk_i           ,   //  Clock
    input   logic                           rst_i           ,   //  Reset
    input   logic                           en_i            ,
    input   logic                           ack_i           ,
    input   logic   [C_REQ_NUM-1:0]         req_i           ,
    output  logic   [C_REQ_IDX_WIDTH-1:0]   grant_o         ,
    output  logic   [C_REQ_NUM-1:0]         grant_onehot_o  ,
    output  logic                           valid_o         
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
    logic   [C_REQ_NUM-1:0]         mask            ;
    logic   [C_REQ_NUM-1:0]         next_mask       ;
    logic   [C_REQ_NUM-1:0]         req_masked      ;
    logic   [C_REQ_IDX_WIDTH-1:0]   grant_masked    ;
    logic                           valid_masked    ;
    logic   [C_REQ_NUM-1:0]         req_unmasked    ;
    logic   [C_REQ_IDX_WIDTH-1:0]   grant_unmasked  ;
    logic                           valid_unmasked  ;
// ====================================================================
// Signal Declarations End
// ====================================================================

// ====================================================================
// Module Instantiations Start
// ====================================================================
// --------------------------------------------------------------------
// Module name  :   priority_arbiter
// Description  :   Priority Arbiter (LSB is prioritized)
// --------------------------------------------------------------------
priority_arbiter #(
    .C_REQ_NUM          (C_REQ_NUM          ),
    .C_REQ_IDX_WIDTH    (C_REQ_IDX_WIDTH    ),
) priority_arbiter_inst (
    .req_i              (req_i              ),
    .grant_o            (grant_unmasked     ),
    .valid_o            (valid_unmasked     )
);

priority_arbiter #(
    .C_REQ_NUM          (C_REQ_NUM          ),
    .C_REQ_IDX_WIDTH    (C_REQ_IDX_WIDTH    ),
) priority_arbiter_inst (
    .req_i              (req_masked         ),
    .grant_o            (grant_masked       ),
    .valid_o            (valid_masked       )
);

// --------------------------------------------------------------------

// ====================================================================
// Module Instantiations End
// ====================================================================

// ====================================================================
// RTL Logic Start
// ====================================================================

// --------------------------------------------------------------------
// Mask
// --------------------------------------------------------------------
    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            mask    <=  `SD {C_REQ_NUM{1'b1}};
        end else begin
            mask    <=  `SD next_mask;
        end
    end

    always_comb begin
        next_mask   =   mask    ;
        if (ack_i) begin
            for (int i = 0; i < C_REQ_NUM; i++) begin
                if (i <= grant_o) begin
                    next_mask[i]    =   1'b0;
                end else begin
                    next_mask[i]    =   1'b1;
                end
            end
        end
    end

    always_comb begin
        req_unmasked    =   en_i ? req_i : 'b0;
        req_masked      =   en_i ? (req_i & mask) : 'b0;
    end

// --------------------------------------------------------------------
// Grant
// --------------------------------------------------------------------
    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            grant_o         <=  `SD 'b0;
            valid_o         <=  `SD 'b0;
        end else begin
            if (valid_masked) begin
                grant_o <=  `SD grant_masked;
                valid_o <=  `SD valid_masked;
            end else begin
                grant_o <=  `SD grant_unmasked;
                valid_o <=  `SD valid_unmasked;
            end
        end
    end

    always_comb begin
        grant_onehot_o  =   'b0;
        if (valid_o) begin
            grant_onehot_o[grant_o] =   1'b1;
        end
    end

// ====================================================================
// RTL Logic End
// ====================================================================


endmodule