/////////////////////////////////////////////////////////////////////////
//                                                                     //
//  Modulename  :  PE_Freelist.sv                                      //
//                                                                     //
//  Description :  A queue-like Freeslist to track the free PEs.       //
//                 Support 2^N PEs. The number of PEs to be allocated  // 
//                 per cycle must be equal to the number of PEs        // 
//                 in the system.                                      // 
//                                                                     //
/////////////////////////////////////////////////////////////////////////

module PE_Freelist #(
    parameter   C_PE_NUM        =   `PE_NUM             ,   //  Number of PE
    parameter   C_PE_IDX_WIDTH  =   `PE_IDX_WIDTH
) (
    input   logic                                       clk_i           ,   //  Clock
    input   logic                                       rst_i           ,   //  Reset
    input   logic   [C_PE_NUM-1:0]                      IssReady_i      ,
    input   logic   [C_PE_NUM-1:0]                      IssValid_i      ,
    input   logic   [C_PE_NUM-1:0]                      PEReady_i       ,   //  PE ready signal, 0: busy, 1: free
    input   logic   [C_PE_NUM-1:0]                      PEValid_i       ,
    output  logic   [C_PE_NUM-1:0][C_PE_IDX_WIDTH-1:0]  alloc_o         ,
    output  logic   [C_PE_NUM-1:0]                      alloc_valid_o   
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
    logic   [C_PE_NUM-1:0]                          lock            ;
    logic   [C_PE_NUM-1:0]                          pop_en          ;
    logic   [C_PE_NUM-1:0]                          push_en         ;
    logic   [C_PE_IDX_WIDTH:0]                      pop_num         ;
    logic   [C_PE_IDX_WIDTH:0]                      push_num        ;
    logic   [C_PE_NUM-1:0][C_PE_IDX_WIDTH-1:0]      freelist_array  ;
    logic   [C_PE_NUM-1:0][C_PE_IDX_WIDTH-1:0]      push_pe_idx     ;
    logic   [C_PE_IDX_WIDTH:0]                      head            ;
    logic   [C_PE_IDX_WIDTH:0]                      tail            ;
    logic   [C_PE_IDX_WIDTH:0]                      valid_num       ;

// ====================================================================
// Signal Declarations End
// ====================================================================

// ====================================================================
// RTL Logic Start
// ====================================================================

// --------------------------------------------------------------------
// Pop out of and push into freelist
// --------------------------------------------------------------------
    always_comb begin
        // Pop
        pop_en  =   PEReady_i & PEValid_i;
        pop_num =  'd0;
        for (int i = 0; i < C_PE_NUM; i++) begin
            if (pop_en[i]) begin
                pop_num = pop_num + 'd1;
            end
        end

        // Push
        push_en =   (~lock) & PEReady_i;
        push_num =  'd0;
        for (int i = 0; i < C_PE_NUM; i++) begin
            if (push_en[i]) begin
                push_num    =   push_num + 'd1;
            end
        end
    end

// --------------------------------------------------------------------
// Head / Tail pointers
// --------------------------------------------------------------------
    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            head    <=  `SD 'd0;    
            tail    <=  `SD 'd0;
        end else begin
            head    <=  `SD head + pop_num;
            tail    <=  `SD tail + push_num;
        end
    end


    always_comb begin
        if (head[C_PE_IDX_WIDTH] ^ tail[C_PE_IDX_WIDTH]) begin
            valid_num   =   tail[C_PE_IDX_WIDTH-1:0] + C_PE_NUM - head[C_PE_IDX_WIDTH-1:0];
        end else begin
            valid_num   =   tail[C_PE_IDX_WIDTH-1:0] - head[C_PE_IDX_WIDTH-1:0];
        end
    end

// --------------------------------------------------------------------
// Push-in
// --------------------------------------------------------------------
    always_comb begin
        int j = 0;
        for (int i = 0; i < C_PE_NUM; i++) begin
            if (push_en[i] == 1) begin
                push_pe_idx[j]  =   i;
                j++;
            end
        end
    end

    genvar entry_idx;

    generate
        for (entry_idx = 0; entry_idx < C_PE_NUM; entry_idx++) begin

            always_ff @(posedge clk_i) begin
                if (tail[C_PE_IDX_WIDTH-1:0] + push_num >= C_PE_NUM) begin
                    if (entry_idx >= tail[C_PE_IDX_WIDTH-1:0]) begin
                        freelist_array[entry_idx]   <=  `SD push_pe_idx[entry_idx - tail[C_PE_IDX_WIDTH-1:0]];
                    end else if (entry_idx < (tail[C_PE_IDX_WIDTH-1:0] + push_num - C_PE_NUM)) begin
                        freelist_array[entry_idx]   <=  `SD push_pe_idx[entry_idx + C_PE_NUM - tail[C_PE_IDX_WIDTH-1:0]];
                    end
                end else begin
                    if (entry_idx >= tail[C_PE_IDX_WIDTH-1:0] && entry_idx < (tail[C_PE_IDX_WIDTH-1:0] + push_num)) begin
                        freelist_array[entry_idx]   <=  `SD push_pe_idx[entry_idx - tail[C_PE_IDX_WIDTH-1:0]];
                    end
                end
            end
            
        end

    endgenerate

// --------------------------------------------------------------------
// Pop-out
// --------------------------------------------------------------------
    genvar output_idx;
    generate
        for (output_idx = 0; output_idx < C_PE_NUM; output_idx++) begin

            always_comb begin
                if (head[C_PE_IDX_WIDTH-1:0] + output_idx >= C_PE_NUM) begin
                    alloc_o[output_idx] =   freelist_array[head[C_PE_IDX_WIDTH-1:0] + output_idx - C_PE_NUM];
                end else begin
                    alloc_o[output_idx] =   freelist_array[head[C_PE_IDX_WIDTH-1:0] + output_idx];
                end

                if (output_idx < valid_num) begin
                    alloc_valid_o[output_idx]   =   'b1;
                end else begin
                    alloc_valid_o[output_idx]   =   'b0;
                end
            end

        end
    endgenerate

// --------------------------------------------------------------------
// Lock: to prevent errorneously push-in
// --------------------------------------------------------------------
    genvar pe_idx;
    generate
        for (pe_idx = 0; pe_idx < C_PE_NUM; pe_idx++) begin
            always_ff @(posedge clk_i) begin
                if (rst_i) begin
                    lock[pe_idx]    <=  `SD 'b0;
                end else begin
                    if (push_en[pe_idx]) begin
                        lock[pe_idx]    <=  `SD 'b1;
                    end else if (pop_en[pe_idx]) begin
                        lock[pe_idx]    <=  `SD 'b0;
                    end
                end
            end
        end
    endgenerate

// ====================================================================
// RTL Logic End
// ====================================================================


endmodule
