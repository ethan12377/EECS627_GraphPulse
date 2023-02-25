/////////////////////////////////////////////////////////////////////////
//                                                                     //
//  Modulename  :  Xbar_SchedToPE.sv                                   //
//                                                                     //
//  Description :  Crossbar from Scheduler / Output Buffer to PEs      // 
//                                                                     //
/////////////////////////////////////////////////////////////////////////

module Xbar_SchedToPE #(
    parameter   C_INPUT_NUM         =   `PE_NUM             ,
    parameter   C_OUTPUT_NUM        =   `PE_NUM             ,
    parameter   C_STAGES_NUM        =   `XBAR_0_STAGES_NUM  ,
    parameter   C_DELTA_WIDTH       =   `DELTA_WIDTH        ,
    parameter   C_VERTEX_IDX_WIDTH  =   `VERTEX_IDX_WIDTH   ,
    parameter   C_PE_IDX_WIDTH      =   `PE_IDX_WIDTH
) (
    input   logic                                               clk_i       ,   //  Clock
    input   logic                                               rst_i       ,   //  Reset
    
    input   logic   [C_INPUT_NUM-1:0][C_DELTA_WIDTH-1:0]        IssDelta_i  ,
    input   logic   [C_INPUT_NUM-1:0][C_VERTEX_IDX_WIDTH-1:0]   IssIdx_i    ,
    input   logic   [C_INPUT_NUM-1:0]                           IssValid_i  ,
    output  logic   [C_INPUT_NUM-1:0]                           IssReady_o  ,

    output  logic   [C_OUTPUT_NUM-1:0][C_DELTA_WIDTH-1:0]       PEDelta_o   ,
    output  logic   [C_OUTPUT_NUM-1:0][C_VERTEX_IDX_WIDTH-1:0]  PEIdx_o     ,
    output  logic   [C_OUTPUT_NUM-1:0]                          PEValid_o   ,
    input   logic   [C_OUTPUT_NUM-1:0]                          PEReady_i   
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
logic   [C_INPUT_NUM-1:0][C_PE_IDX_WIDTH-1:0]       alloc                           ;
logic   [C_INPUT_NUM-1:0]                           alloc_valid                     ;

logic   [C_OUTPUT_NUM-1:0][C_DELTA_WIDTH-1:0]       PEDelta_pipe   [C_STAGES_NUM-1:0];
logic   [C_OUTPUT_NUM-1:0][C_VERTEX_IDX_WIDTH-1:0]  PEIdx_pipe     [C_STAGES_NUM-1:0];
logic   [C_OUTPUT_NUM-1:0]                          PEValid_pipe   [C_STAGES_NUM-1:0];

logic   [C_OUTPUT_NUM-1:0][C_DELTA_WIDTH-1:0]       PEDelta_n                       ;
logic   [C_OUTPUT_NUM-1:0][C_VERTEX_IDX_WIDTH-1:0]  PEIdx_n                         ;
logic   [C_OUTPUT_NUM-1:0]                          PEValid_n                       ;
// ====================================================================
// Signal Declarations End
// ====================================================================

// ====================================================================
// Module Instantiations Start
// ====================================================================
// --------------------------------------------------------------------
// Module name  :   PE_Freelist
// Description  :   A queue-like Freeslist to track the free PEs.     
//                  Support 2^N PEs. The number of PEs to be allocated
//                  per cycle must be equal to the number of PEs      
//                  in the system.                                    
// --------------------------------------------------------------------
PE_Freelist PE_Freelist_inst(
    .clk_i          (clk_i          ),
    .rst_i          (rst_i          ),
    .IssValid_i     (IssValid_i     ),
    .IssReady_i     (IssReady_o     ),
    .PEReady_i      (PEReady_i      ),
    .PEValid_i      (PEValid_o      ),
    .alloc_o        (alloc          ),
    .alloc_valid_o  (alloc_valid    )
);

// --------------------------------------------------------------------


// ====================================================================
// Module Instantiations End
// ====================================================================

// ====================================================================
// RTL Logic Start
// ====================================================================

// --------------------------------------------------------------------
// IssReady
// --------------------------------------------------------------------
    genvar input_idx;

    generate
        for (input_idx = 0; input_idx < C_INPUT_NUM; input_idx++) begin
            always_ff @(posedge clk_i) begin
                if (rst_i) begin
                    IssReady_o[input_idx]   <=  `SD 'b0;
                end else begin
                    if (IssValid_i[input_idx] && IssReady_o[input_idx]) begin
                        IssReady_o[input_idx]   <=  `SD 'b0;
                    end else if (IssValid_i[input_idx] && alloc_valid[input_idx]) begin
                        IssReady_o[input_idx]   <=  `SD 'b1;
                    end
                end
            end
        end
    endgenerate


// --------------------------------------------------------------------
// Router
// --------------------------------------------------------------------
    genvar output_idx;

    generate
        for (output_idx = 0; output_idx < C_OUTPUT_NUM; output_idx++) begin
            always_comb begin
                if (rst_i) begin
                    PEValid_n[output_idx]   =   'd0;
                end else begin
                    PEDelta_n[output_idx]   =   'd0;
                    PEIdx_n  [output_idx]   =   'd0;
                    PEValid_n[output_idx]   =   'd0;

                    for (int in_idx = 0; in_idx < C_INPUT_NUM; in_idx++) begin
                        if (alloc[in_idx] == output_idx 
                        && IssValid_i[in_idx] && IssReady_o[in_idx]) begin
                            PEDelta_n[output_idx] = IssDelta_i[in_idx];
                            PEIdx_n  [output_idx] = IssIdx_i[in_idx];
                            PEValid_n[output_idx] = 'b1;
                        end
                    end
                end
            end
        end
    endgenerate

// --------------------------------------------------------------------
// Pipeline stages
// --------------------------------------------------------------------
    genvar stage_idx;

    generate
        
        for (stage_idx = 0; stage_idx < C_STAGES_NUM; stage_idx++) begin
            if (stage_idx == 0) begin
                
                always_ff @(posedge clk_i) begin
                    PEDelta_pipe[stage_idx] <=  `SD PEDelta_n   ;
                    PEIdx_pipe  [stage_idx] <=  `SD PEIdx_n     ;
                    PEValid_pipe[stage_idx] <=  `SD PEValid_n   ;
                end

            end else begin

                always_ff @(posedge clk_i) begin
                    PEDelta_pipe[stage_idx] <=  `SD PEDelta_pipe[stage_idx-1];
                    PEIdx_pipe  [stage_idx] <=  `SD PEIdx_pipe  [stage_idx-1];
                    PEValid_pipe[stage_idx] <=  `SD PEValid_pipe[stage_idx-1];
                end

            end
        end
    endgenerate

// --------------------------------------------------------------------
// To PEs
// --------------------------------------------------------------------
    always_comb begin
        PEValid_o   =   PEValid_pipe[C_STAGES_NUM-1];
        PEDelta_o   =   PEDelta_pipe[C_STAGES_NUM-1];
        PEIdx_o     =   PEIdx_pipe  [C_STAGES_NUM-1];
    end


// ====================================================================
// RTL Logic End
// ====================================================================


endmodule
