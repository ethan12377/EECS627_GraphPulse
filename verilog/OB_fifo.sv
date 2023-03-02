/////////////////////////////////////////////////////////////////////////
//                                                                     //
//  Modulename  :  OB_fifo.sv                                          //
//                                                                     //
//  Description :  FIFO inside output buffer, which support multiple   //
//                 push-ins(grouped) and multiple push-outs(ungrouped) //
//                                                                     //
/////////////////////////////////////////////////////////////////////////

module OB_fifo #(
    parameter   C_DEPTH         =   `OB_DEPTH           ,
    parameter   C_WIDTH         =   `EVENT_WIDTH        ,
    parameter   C_INPUT_NUM     =   `OB_FIFO_INPUT_NUM  ,
    parameter   C_OUTPUT_NUM    =   `PE_NUM             ,
    parameter   C_IDX_WIDTH     =   $clog2(C_DEPTH)     ,
    parameter   C_NUM_WIDTH     =   $clog2(C_DEPTH+1)   
) (
    input   logic                                   clk_i           ,   // Clock
    input   logic                                   rst_i           ,   // Reset
    // Push-In
    input   logic   [C_INPUT_NUM-1:0]               s_valid_i       ,   // Push-in Valid
    output  logic                                   s_ready_o       ,   // Push-in Ready, asserted when number of empty entries > C_INPUT_NUM
    input   logic   [C_INPUT_NUM-1:0][C_WIDTH-1:0]  s_data_i        ,   // Push-in Data
    // Pop-Out
    output  logic   [C_OUTPUT_NUM-1:0]              m_valid_o       ,   // Pop-out Valid
    input   logic   [C_OUTPUT_NUM-1:0]              m_ready_i       ,   // Pop-out Ready
    output  logic   [C_OUTPUT_NUM-1:0][C_WIDTH-1:0] m_data_o            // Pop-out Data
);

// ====================================================================
// Signal Declarations Start
// ====================================================================
    logic   [C_IDX_WIDTH-1:0]                   head            ;
    logic   [C_IDX_WIDTH-1:0]                   tail            ;
    logic                                       head_rollover   ;
    logic                                       tail_rollover   ;

    logic   [C_IDX_WIDTH-1:0]                   next_head       ;
    logic   [C_IDX_WIDTH-1:0]                   next_tail       ;
    logic   [C_NUM_WIDTH-1:0]                   push_in_num     ;
    logic   [C_NUM_WIDTH-1:0]                   pop_out_num     ;

    logic   [C_DEPTH-1:0][C_WIDTH-1:0]          array           ;
    logic   [C_DEPTH-1:0]                       valid           ;

    logic   [C_NUM_WIDTH-1:0]                   data_num        ;
    logic   [C_NUM_WIDTH-1:0]                   empty_num       ;

    logic   [C_INPUT_NUM-1:0]                   push_in_en      ;
    logic   [C_DEPTH-1:0]                       push_in_sel     ;
    logic   [C_DEPTH-1:0][C_WIDTH-1:0]          push_in_switch  ;
    logic   [C_OUTPUT_NUM-1:0]                  pop_out_en      ;
    logic   [C_DEPTH-1:0]                       pop_out_sel     ;

    logic   [C_INPUT_NUM-1:0][C_IDX_WIDTH-1:0]  push_in_idx     ;
    logic   [C_OUTPUT_NUM-1:0][C_IDX_WIDTH-1:0] pop_out_idx     ;
// ====================================================================
// Signal Declarations End
// ====================================================================

// ====================================================================
// RTL Logic Start
// ====================================================================

// --------------------------------------------------------------------
// Push-in & Pop-out handshake
// --------------------------------------------------------------------
    assign  push_in_en  =   s_valid_i & {C_INPUT_NUM{s_ready_o}};
    assign  pop_out_en  =   m_valid_o & m_ready_i;

// --------------------------------------------------------------------
// Calculate the number of input and output 
// --------------------------------------------------------------------
    always_comb begin
        push_in_num =   0;
        for (int unsigned in_idx = 0; in_idx < C_INPUT_NUM; in_idx++) begin
            if (push_in_en[in_idx]) begin
                push_in_num =   push_in_num + 'd1;
            end
        end
    end

    always_comb begin
        pop_out_num =   0;
        for (int unsigned out_idx = 0; out_idx < C_OUTPUT_NUM; out_idx++) begin
            if (pop_out_en[out_idx]) begin
                pop_out_num =   pop_out_num + 'd1;
            end
        end
    end

// --------------------------------------------------------------------
// Pointer movement
// --------------------------------------------------------------------
    // Pointer sequential
    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            head    <=  `SD 'd0;
            tail    <=  `SD 'd0;
        end else begin
            head    <=  `SD next_head;
            tail    <=  `SD next_tail;
        end
    end

    // Next state of pointers
    always_comb begin
        if (head + pop_out_num >= C_DEPTH) begin
            next_head   =   head + pop_out_num - C_DEPTH;
        end else begin
            next_head   =   head + pop_out_num;
        end
        
        if (tail + push_in_num >= C_DEPTH) begin
            next_tail   =   tail + push_in_num - C_DEPTH;
        end else begin
            next_tail   =   tail + push_in_num;
        end
    end

    // Pointer rollover states
    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            head_rollover   <=  `SD 1'b0;
            tail_rollover   <=  `SD 1'b0;
        end else begin
            if (head + pop_out_num >= C_DEPTH) begin
                head_rollover   <=  `SD ~head_rollover;
            end
            if (tail + push_in_num >= C_DEPTH) begin
                tail_rollover   <=  `SD ~tail_rollover;
            end
        end
    end

// --------------------------------------------------------------------
// Number of Empty entries and Data entries
// --------------------------------------------------------------------
    always_comb begin
        if (head_rollover == tail_rollover) begin
            empty_num   =   C_DEPTH - (tail - head);
            data_num    =   tail - head;
        end else begin
            empty_num   =   head - tail;
            data_num    =   C_DEPTH - (head - tail);
        end
    end

// --------------------------------------------------------------------
// Push-in Entry
// --------------------------------------------------------------------
    // Push-in Ready
    always_comb begin
        if (empty_num >= C_INPUT_NUM) begin
            s_ready_o   =   1'b1;
        end else begin
            s_ready_o   =   1'b0;
        end
    end

    always_comb begin
        push_in_switch  =   0;
        for (int unsigned in_idx = 0; in_idx < C_INPUT_NUM; in_idx++) begin
            // Push-in Data
            //  Derive the entry indexes to be pushed-in
            if (in_idx + tail >= C_DEPTH) begin
                push_in_idx[in_idx] =   in_idx + tail - C_DEPTH;
            end else begin
                push_in_idx[in_idx] =   in_idx + tail;
            end
            //  Route the input to update the entry contents
            push_in_switch[push_in_idx[in_idx]] =   s_data_i[in_idx];
        end

        // Select the entries to push-in
        push_in_sel =   (push_in_en << tail) | (push_in_en >> (C_DEPTH - tail));
    end

// --------------------------------------------------------------------
// Pop-out Entry
// --------------------------------------------------------------------
    always_comb begin
        for (int unsigned out_idx = 0; out_idx < C_OUTPUT_NUM; out_idx++) begin
            // Pop-out Data
            //  Derive the entry indexes to be popped-out
            if (out_idx + head >= C_DEPTH) begin
                pop_out_idx[out_idx] =   out_idx + head - C_DEPTH;
            end else begin
                pop_out_idx[out_idx] =   out_idx + head;
            end
            //  Route the entry content to the output
            m_data_o[out_idx]   =   array[pop_out_idx[out_idx]];

            // Pop-out Valid
            // If the pop-out channel is within head and tail pointers
            if (out_idx < data_num) begin
                m_valid_o[out_idx]      =   1'b1;
            end else begin
                m_valid_o[out_idx]      =   1'b0;
            end
        end
        pop_out_sel =   (pop_out_en << head) | (pop_out_en >> (C_DEPTH - head));
    end

// --------------------------------------------------------------------
// Array Entry
// --------------------------------------------------------------------
    always_ff @(posedge clk_i) begin
        for (int unsigned entry_idx = 0; entry_idx < C_DEPTH; entry_idx++) begin
            // Reset
            if (rst_i) begin
                array[entry_idx]   <=  `SD 'b0;
            // Push-in the entry (including Pop-up at the same time)
            end else if (push_in_sel[entry_idx]) begin
                array[entry_idx]    <=  `SD push_in_switch[entry_idx];
            // Only Pop-out the entry -> Clear it
            end else if (pop_out_sel[entry_idx]) begin
                array[entry_idx]    <=  `SD 'b0;
            // Otherwise -> Latch
            end else begin
                array[entry_idx]    <=  `SD array[entry_idx];
            end
        end
    end

// ====================================================================
// RTL Logic End
// ====================================================================


endmodule