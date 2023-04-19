/////////////////////////////////////////////////////////////////////////
//                                                                     //
//  Modulename  :  mc_em.sv                                            //
//                                                                     //
//  Description :  edge memory controller                              // 
//                                                                     //
/////////////////////////////////////////////////////////////////////////

module mc_em (
    input   logic                                       clk_i           ,   //  Clock
    input   logic                                       rst_i           ,   //  Reset
    ////////// INPUTS //////////
    input   logic [`PE_NUM_OF_CORES*14-1 : 0]           pe2mem_reqAddr_i,
    // input   logic [`PE_NUM_OF_CORES*64-1 : 0]           pe2mem_wrData_i,
    input   logic [`PE_NUM_OF_CORES-1:0]                pe2mem_reqValid_i,
    // input   logic [`PE_NUM_OF_CORES-1:0]                pe2mem_wrEn_i,
    ////////// OUTPUTS //////////
    output  logic [14-1:0]                           mc2mem_addr_o,
    // output  logic [63:0]                                mc2mem_data_o,
    output  BUS_COMMAND                                 mc2mem_command_o,
    output  logic [`PE_NUM_OF_CORES-1:0]                mc2pe_grant_onehot_o
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
    // internal 2d arrays for inputs
    logic [`PE_NUM_OF_CORES-1:0][14-1:0]  pe2mem_reqAddr;
    // logic [`PE_NUM_OF_CORES-1:0][63:0]       pe2mem_wrData;
    // rr arbiter
    logic [`PE_NUM_OF_CORES-1:0]    rra_grant_onehot;
    logic                           rra_valid;
    // outputs
    logic [14-1:0]   mc2mem_addr_n;
    logic [63:0]        mc2mem_data_n;
    logic [1:0]         mc2mem_command_n; 
// ====================================================================
// Signal Declarations End
// ====================================================================

// ====================================================================
// Module Instantiations Start
// ====================================================================
// --------------------------------------------------------------------
// Module name  :   rr_arbiter0
// Description  :   round robin arbiter
// --------------------------------------------------------------------
    rr_arbiter #(
        .C_REQ_NUM          (`PE_NUM_OF_CORES)
    ) mc_rr_arbiter (
        .clk_i(clk_i),
        .rst_i(rst_i),
        .en_i(1'b1),
        .ack_i(|pe2mem_reqValid_i), // should rotate as long as there are valid requests
        .req_i(pe2mem_reqValid_i),
        .grant_o(), // do not need this signal
        .grant_onehot_o(rra_grant_onehot),
        .valid_o(rra_valid),
        .mask_o() // do not need this signal
    );

// --------------------------------------------------------------------

// ====================================================================
// Module Instantiations End
// ====================================================================

// ====================================================================
// RTL Logic Start
// ====================================================================

    assign mc2pe_grant_onehot_o = rra_grant_onehot;
    // assign inputs to internal arrays
    generate
        for (genvar i = 0; i < `PE_NUM_OF_CORES; i = i + 1)
        begin
            assign pe2mem_reqAddr[i] = pe2mem_reqAddr_i[14*(i+1)-1 : 14*i];
            // assign pe2mem_wrData[i] = pe2mem_wrData_i[64*(i+1)-1 : 64*i];
        end
    endgenerate
    // --------------------------------------------------------------------
    // Output logic
    // --------------------------------------------------------------------
    always_comb
    begin
        // default to invalid outputs
        mc2mem_addr_o = 'd0;
        mc2mem_command_o = BUS_NONE;
        // mc2mem_data_o = 'x;
        // check current grant
        if (rra_valid)
        begin
            for (integer i = 0; i < `PE_NUM_OF_CORES; i = i + 1)
            begin
                if (rra_grant_onehot[i])
                begin
                    mc2mem_addr_o = pe2mem_reqAddr[i];
                    // mc2mem_command_o = pe2mem_wrEn_i[i] ? BUS_STORE : BUS_LOAD;
                    mc2mem_command_o = BUS_LOAD;
                    // mc2mem_data_o = pe2mem_wrData[i];
                end
            end
        end
    end


// ====================================================================
// RTL Logic End
// ====================================================================


endmodule
