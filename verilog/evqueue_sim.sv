/////////////////////////////////////////////////////////////////////////
//                                                                     //
//  Modulename  :  evqueue_sim.sv                                      //
//                                                                     //
//  Description :  Ideal event queue for pe testing purpose            // 
//                                                                     //
/////////////////////////////////////////////////////////////////////////


/// ************** TODO: integrate into pe_tb.sv

module evqueue_sim
(
    input   logic                                                   clk_i           ,   //  Clock
    input   logic                                                   rst_i           ,   //  Reset
    // from PE
    input   logic [`PE_NUM_OF_CORES-1:0]                            PEReady_i,
    input   logic [2*`PE_NUM_OF_CORES-1:0][`DELTA_WIDTH-1:0]        proDelta_i,
    input   logic [2*`PE_NUM_OF_CORES-1:0][`VERTEX_IDX_WIDTH-1:0]   proIdx_i,
    input   logic [2*`PE_NUM_OF_CORES-1:0]                          proValid_i,
    // to PE
    output  logic [`PE_NUM_OF_CORES-1:0][1:0]                       ProReady_o,
    output  logic [`PE_NUM_OF_CORES-1:0][`DELTA_WIDTH-1:0]          PEDelta_o,
    output  logic [`PE_NUM_OF_CORES-1:0][`VERTEX_IDX_WIDTH-1:0]     PEIdx_o,
    output  logic [`PE_NUM_OF_CORES-1:0]                            PEValid_o
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
    // internal storage of events
    logic [255:0]                   valid_queue, valid_queue_n;
    logic [255:0][`DELTA_WIDTH-1:0] delta_queue, delta_queue_n;
    // curr idx
    logic [`VERTEX_IDX_WIDTH-1:0] curr_scan_idx, curr_scan_idx_n;
    logic queue_empty;
    logic waiting_for_pe, waiting_for_pe_n;
    // fpu
    logic [15:0] fpu_opA, fpu_opB, fpu_result;
    logic [1:0] fpu_op;
    // outputs
    logic [`PE_NUM_OF_CORES-1:0][`DELTA_WIDTH-1:0]          PEDelta_n;
    logic [`PE_NUM_OF_CORES-1:0][`VERTEX_IDX_WIDTH-1:0]     PEIdx_n;
    logic [`PE_NUM_OF_CORES-1:0]                            PEValid_n;
// ====================================================================
// Signal Declarations End
// ====================================================================

// ====================================================================
// Module Instantiations Start
// ====================================================================
// --------------------------------------------------------------------
// Module name  :   evqueue_fpadd
// Description  :   1_cycle fp adder unit for instant coalescing
// --------------------------------------------------------------------
    fp_add evqueue_fpadd (
        .opA(fpu_opA),
        .opB(fpu_opB),
        .sum(fpu_result)
    );

// --------------------------------------------------------------------


// ====================================================================
// Module Instantiations End
// ====================================================================

// ====================================================================
// RTL Logic Start
// ====================================================================
    assign queue_empty = ~(|valid_queue);
    // always ready for new events
    generate
        for (genvar i = 0; i < `PE_NUM_OF_CORES; i = i + 1)
        begin
            assign ProReady_o[i] = 2'b11;
        end
    endgenerate

    // behavior
    always_comb
    begin
        // default to holding
        valid_queue_n = valid_queue;
        delta_queue_n = delta_queue;
        waiting_for_pe_n = waiting_for_pe;
        curr_scan_idx_n = curr_scan_idx;
        PEDelta_n = PEDelta_o;
        PEIdx_n = PEIdx_o;
        PEValid_n = PEValid_o;
        // default fpu to doing nothing
        fpu_opA = '0;
        fpu_opB = '0;

        // reactivation
        if (waiting_for_pe_n && (|PEReady_i))
        begin
            waiting_for_pe_n = 1'b0;
            curr_scan_idx_n = '0;
        end
        // insertion
        for (integer i = 0; i < 2*`PE_NUM_OF_CORES; i = i + 1)
        begin
            if (proValid_i[i])
            begin
                valid_queue_n[proIdx_i[i]] = 1'b1;
                // coalesce
                fpu_opA = proDelta_i[i];
                fpu_opB = delta_queue[proIdx_i[i]];
                delta_queue_n[proIdx_i[i]] = fpu_result;
            end
        end
        // removal
        for (integer i = 0; i < `PE_NUM_OF_CORES; i = i + 1)
        begin
            if (PEReady_i[i])
            begin
                if (~waiting_for_pe_n) // actively scanning. output new event to pe if found
                begin
                    // default to invalid
                    PEDelta_n[i] = 'x;
                    PEIdx_n[i] = 'x;
                    PEValid_n[i] = 1'b0;
                    // scan for next available event until the end of queue
                    for (integer curr_index = 0; curr_index < 256; curr_index = curr_index + 1)
                    begin
                        if (curr_index > curr_scan_idx_n && ~PEValid_n[i])
                        begin
                            curr_scan_idx_n = curr_index;
                            if (valid_queue_n[curr_index])
                            begin
                                // output valid event to PE
                                PEDelta_n[i] = delta_queue[curr_index];
                                PEIdx_n[i] = curr_index;
                                PEValid_n[i] = 1'b1;
                                // remove event from queue
                                delta_queue_n[curr_index] = '0;
                                valid_queue_n[curr_index] = 1'b0;
                                curr_scan_idx_n = curr_index + 1;
                            end
                        end
                    end
                    if (curr_scan_idx_n >= 255) waiting_for_pe_n = 1'b1;
                end
                else // not actively scanning. disable all outputs
                begin
                    PEDelta_n[i] = 'x;
                    PEIdx_n[i] = 'x;
                    PEValid_n[i] = 1'b0;
                end
            end
        end
    end


    // update queue
    always_ff @(posedge clk_i)
    begin
        if (rst_i)
        begin
            // internal queue
            valid_queue     <= '0;
            delta_queue     <= 'x;
            // status regs
            waiting_for_pe  <= 1'b1;
            curr_scan_idx   <= 0;
            // outputs
            PEDelta_o       <= 'x;
            PEIdx_o         <= 'x;
            PEValid_o       <= '0;
        end
        else
        begin
            // internal queue
            valid_queue     <= valid_queue_n;
            delta_queue     <= delta_queue_n;
            // status regs
            waiting_for_pe  <= waiting_for_pe_n;
            curr_scan_idx   <= curr_scan_idx_n;
            // outputs
            PEDelta_o       <= PEDelta_n;
            PEIdx_o         <= PEIdx_n;
            PEValid_o       <= PEValid_n;
        end
    end
// --------------------------------------------------------------------
// Logic Divider
// --------------------------------------------------------------------

// ====================================================================
// RTL Logic End
// ====================================================================


endmodule
