/////////////////////////////////////////////////////////////////////////
//                                                                     //
//  Modulename  :  priority_arbiter.sv                                 //
//                                                                     //
//  Description :  Priority Arbiter (LSB is prioritized)               // 
//                                                                     //
/////////////////////////////////////////////////////////////////////////

module priority_arbiter #(
    parameter   C_REQ_NUM       =   8   ,
    parameter   C_REQ_IDX_WIDTH =   $clog2(C_REQ_NUM)
) (
    input   logic   [C_REQ_NUM-1:0]         req_i           ,
    output  logic   [C_REQ_IDX_WIDTH-1:0]   grant_o         ,
    output  logic                           valid_o         
);

// ====================================================================
// RTL Logic Start
// ====================================================================

    always_comb begin
        grant_o     =   'd0;
        valid_o     =   1'b0;
        for (int unsigned req_idx = C_REQ_NUM; req_idx > 0; req_idx--) begin
            if (req_i[req_idx-1] == 1'b1) begin
                grant_o =   req_idx - 'd1;
                valid_o =   1'b1;
            end
        end
    end

// ====================================================================
// RTL Logic End
// ====================================================================


endmodule
