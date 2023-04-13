/////////////////////////////////////////////////////////////////////////
//                                                                     //
//  Modulename  :  graphpulse.sv                                       //
//                                                                     //
//  Description :  top module                                          // 
//                                                                     //
/////////////////////////////////////////////////////////////////////////

module GraphPulse (
    input           clock,
    input           reset,
    input [15:0]    num_of_vertices_float16,
    input [7:0]     num_of_vertices_int8,
    input  [3:0]    edgemem_response,
    input [63:0]    edgemem_ld_data,
    input  [3:0]    edgemem_tag,
    input  [3:0]    vertexmem_response,
    input [63:0]    vertexmem_ld_data,
    input  [3:0]    vertexmem_tag,

    //output          converge,
    output [1:0]    edgemem_command,
    output [`XLEN-1:0] edgemem_addr,
    output [63:0]   edgemem_st_data,
    output [1:0]    vertexmem_command,
    output [`XLEN-1:0] vertexmem_addr,
    output [63:0]   vertexmem_st_data
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

    ///// PE <---> Sched/Q /////
    logic  [`PE_NUM_OF_CORES-1:0]  initialFinish_pe;
    logic                          initialFinish;

    ///// Q <---> Sched /////
    logic  [`BIN_NUM-1:0]         CUClean           ;
    logic  [`BIN_NUM-1:0]         binValid          ;
    logic  [`BIN_NUM-1:0]         binSelected       ;   
    logic                         readEn            ;

    ///// Q <---> OB /////
    logic   [`ROW_IDX_WIDTH-1:0]                    rowIdx, rowIdx_up, rowIdx_down;
    logic   [`BIN_IDX_WIDTH-2:0]                    binIdx, binIdx_up, binIdx_down;
    logic   [`COL_NUM*`DELTA_WIDTH-1:0]             rowDelta, rowDelta_up, rowDelta_down;
    logic                                           rowValid, rowValid_up, rowValid_down;
    logic                                           rowReady    ;

    ///// Xbar1 <---> PE /////
    logic   [`PE_NUM_OF_CORES*`DELTA_WIDTH-1:0]             PEDelta   ;
    logic   [`PE_NUM_OF_CORES*`VERTEX_IDX_WIDTH-1:0]        PEIdx     ;
    logic   [`PE_NUM_OF_CORES-1:0]                          PEValid   ;
    logic   [`PE_NUM_OF_CORES-1:0]                          PEReady   ;

    ///// PE <---> MC /////
    // to vertex mem controller
    logic [`PE_NUM_OF_CORES-1:0][7:0]                        pe_vertex_reqAddr;
    logic [`PE_NUM_OF_CORES-1:0]                             pe_vertex_reqValid;
    logic [`PE_NUM_OF_CORES-1:0][`DELTA_WIDTH-1:0]           pe_wrData;
    logic [`PE_NUM_OF_CORES-1:0]                             pe_wrEn;
    // to edge mem controller
    logic [`PE_NUM_OF_CORES-1:0][13:0]                       pe_edge_reqAddr;
    logic [`PE_NUM_OF_CORES-1:0]                             pe_edge_reqValid;
    // flattened 2d arrays for MC
    logic [`PE_NUM_OF_CORES*8-1 : 0] pe2vm_reqAddr_1d;
    logic [`PE_NUM_OF_CORES*14-1 : 0] pe2em_reqAddr_1d;
    logic [`PE_NUM_OF_CORES*64-1 : 0]    pe2vm_wrData_1d;
    generate
        for (genvar i = 0; i < `PE_NUM_OF_CORES; i = i + 1)
        begin
            assign pe2vm_reqAddr_1d[8*(i+1)-1 : 8*i] = pe_vertex_reqAddr[i];
            assign pe2em_reqAddr_1d[14*(i+1)-1 : 14*i] = pe_edge_reqAddr[i];
            assign pe2vm_wrData_1d[64*(i+1)-1 : 64*i] = {48'd0, pe_wrData[i]};
        end
    endgenerate
    logic [`PE_NUM_OF_CORES-1:0] vm2pe_grant_onehot, em2pe_grant_onehot;
    
    //// MC <---> mem /////
    logic [7:0] mc2vm_addr;
    logic [`XLEN-1:0] mc2em_addr;   // address for current command
    logic [63:0] mc2vm_data;
    logic [21:0] mc2em_data;
    BUS_COMMAND mc2vm_command, mc2em_command;
    logic  [3:0] vm_response, em_response; // 0 = can't accept, other=tag of transaction
    logic [63:0] vm_rdData, em_rdData;         // data resulting from a load
    logic  [3:0] vm_tag, em_tag;           // 0 = no value, other=tag of transaction
    assign edgemem_command = mc2em_command;
    assign edgemem_addr = mc2em_addr;
    assign edgemem_st_data = {42'b0, mc2em_data};
    assign vertexmem_command = mc2vm_command;
    assign vertexmem_addr = {8'b0, mc2vm_addr};
    assign vertexmem_st_data = mc2vm_data;
    assign em_response = edgemem_response;
    assign em_rdData = edgemem_ld_data;
    assign em_tag = edgemem_tag;
    assign vm_response = vertexmem_response;
    assign vm_rdData = vertexmem_ld_data;
    assign vm_tag = vertexmem_tag;

    ///// PE <---> Xbar2 /////
    logic [`GEN_NUM*`DELTA_WIDTH-1:0]               proDelta;
    logic [`GEN_NUM*`VERTEX_IDX_WIDTH-1:0]          proIdx;
    logic [`GEN_NUM-1:0]                            proValid;
    logic [`GEN_NUM-1:0]                            proReady;

    ///// Xbar2 <---> Q /////
    logic   [`BIN_NUM*`DELTA_WIDTH-1:0]             CUDelta   ;
    logic   [`BIN_NUM*`VERTEX_IDX_WIDTH-1:0]        CUIdx     ;
    logic   [`BIN_NUM-1:0]                          CUValid   ;
    logic   [`BIN_NUM-1:0]                          CUReady   ;

    ///// convergence signal /////
    // logic                           queueEmpty; // from Q
    logic [`PE_NUM_OF_CORES-1:0]    idle; // from PE


// ====================================================================
// Signal Declarations End
// ====================================================================

// ====================================================================
// Module Instantiations Start
// ====================================================================

// --------------------------------------------------------------------
// Module name  :   threein1
// Description  :   Crossbar from Scheds to PE with output_buffer 
//                  and queue_scheduler
// --------------------------------------------------------------------
    center center_inst(
        .clk_i                  (clock),   //  Clock
        .rst_i                  (reset),   //  Reset
        .rowIdx_up_i            (rowIdx_up  ),
        .binIdx_up_i            (binIdx_up  ),
        .rowDelta_up_i          (rowDelta_up),
        .rowValid_up_i          (rowValid_up),
        .rowIdx_down_i          (rowIdx_down),
        .binIdx_down_i          (binIdx_down),
        .rowDelta_down_i        (rowDelta_down),
        .rowValid_down_i        (rowValid_down),
        .rowReady_o             (rowReady   ),
        .PEDelta_o              (PEDelta    ),
        .PEIdx_o                (PEIdx      ),
        .PEValid_o              (PEValid    ),
        .PEReady_i              (PEReady    ),
        .proDelta_i             (proDelta   ),
        .proIdx_i               (proIdx     ),
        .proValid_i             (proValid   ),
        .proReady_o             (proReady   ),
        .CUDelta_o              (CUDelta    ),
        .CUIdx_o                (CUIdx      ),
        .CUValid_o              (CUValid    ),
        .CUReady_i              (CUReady    ),
        .initialFinish_i        (initialFinish_pe),   
        .CUClean_i              (CUClean),
        .binValid_i             (binValid),
        .binSelected_o          (binSelected),    
        .readEn_o               (readEn),
        .initialFinish_o        (initialFinish)

        // .pe2vm_reqAddr_i       (pe2vm_reqAddr_1d),
        // .pe2vm_wrData_i        (pe2vm_wrData_1d),
        // .pe2vm_reqValid_i      (pe_vertex_reqValid),
        // .pe2vm_wrEn_i          (pe_wrEn),
        // .mc2vm_addr_o          (mc2vm_addr),
        // .mc2vm_data_o          (mc2vm_data),
        // .mc2vm_command_o       (mc2vm_command),
        // .vm2pe_grant_onehot_o   (vm2pe_grant_onehot),

        // .pe2em_reqAddr_i       (pe2em_reqAddr_1d),
        // .pe2em_reqValid_i      (pe_edge_reqValid),
        // .mc2em_addr_o          (mc2em_addr),
        // .mc2em_data_o          (mc2em_data),
        // .mc2em_command_o       (mc2em_command),
        // .em2pe_grant_onehot_o   (em2pe_grant_onehot)
    );
// --------------------------------------------------------------------

// --------------------------------------------------------------------

// --------------------------------------------------------------------
// Module name  :   mc_vm
// Description  :   vertexmem controller
// --------------------------------------------------------------------
    logic [`PE_NUM_OF_CORES*`XLEN-1 : 0]        pe2vm_reqAddr_padded;
    generate
        for (genvar i = 0; i < `PE_NUM_OF_CORES; i = i + 1)
        begin
            assign pe2vm_reqAddr_padded[`XLEN*(i+1)-1 : `XLEN*i] = {8'b0, pe2vm_reqAddr_1d[8*(i+1)-1 : 8*i]};
        end
    endgenerate
    logic [`XLEN-1:0]   mc2vm_addr_padded;
    assign mc2vm_addr = mc2vm_addr_padded[7:0];
    mc mc_vm (
        .clk_i                  (clock),
        .rst_i                  (reset),
        .pe2mem_reqAddr_i       (pe2vm_reqAddr_padded),
        .pe2mem_wrData_i        (pe2vm_wrData_1d),
        .pe2mem_reqValid_i      (pe_vertex_reqValid),
        .pe2mem_wrEn_i          (pe_wrEn),
        .mc2mem_addr_o          (mc2vm_addr_padded),
        .mc2mem_data_o          (mc2vm_data),
        .mc2mem_command_o       (mc2vm_command),
        .mc2pe_grant_onehot_o   (vm2pe_grant_onehot)
    );
// --------------------------------------------------------------------

// --------------------------------------------------------------------
// Module name  :   mc_em
// Description  :   edgemem controller
// --------------------------------------------------------------------
    logic [`PE_NUM_OF_CORES*`XLEN-1 : 0]        pe2em_reqAddr_padded;
    generate
        for (genvar i = 0; i < `PE_NUM_OF_CORES; i = i + 1)
        begin
            assign pe2em_reqAddr_padded[`XLEN*(i+1)-1 : `XLEN*i] = {2'b0, pe2em_reqAddr_1d[14*(i+1)-1 : 14*i]};
        end
    endgenerate
    logic [63:0]   mc2em_data_padded;
    assign mc2em_data = mc2em_data_padded[21:0];
    mc mc_em (
        .clk_i                  (clock),
        .rst_i                  (reset),
        .pe2mem_reqAddr_i       (pe2em_reqAddr_padded),
        .pe2mem_wrData_i        ('x), // read only
        .pe2mem_reqValid_i      (pe_edge_reqValid),
        .pe2mem_wrEn_i          ('0), // read only
        .mc2mem_addr_o          (mc2em_addr),
        .mc2mem_data_o          (mc2em_data_padded),
        .mc2mem_command_o       (mc2em_command),
        .mc2pe_grant_onehot_o   (em2pe_grant_onehot)
    );
// --------------------------------------------------------------------

// --------------------------------------------------------------------
// Module name  :   EQ_wrapper_half
// Description  :   2D to 1D for event_queues
// --------------------------------------------------------------------
    EQ_wrapper_half EQ_wrapper_up_inst(
        .clk_i                  (clock),   //  Clock
        .rst_i                  (reset),   //  Reset
        .initialFinish_i        (initialFinish),
        .CUDelta_i              (CUDelta[`BIN_NUM*`DELTA_WIDTH-1:`BIN_NUM*`DELTA_WIDTH/2]),     
        .CUIdx_i                (CUIdx[`BIN_NUM*`VERTEX_IDX_WIDTH-1:`BIN_NUM*`VERTEX_IDX_WIDTH/2]),
        .CUValid_i              (CUValid[`BIN_NUM-1:`BIN_NUM/2]),
        .CUReady_o              (CUReady[`BIN_NUM-1:`BIN_NUM/2]),
        .CUClean_o              (CUClean[`BIN_NUM-1:`BIN_NUM/2]),
        .binValid_o             (binValid[`BIN_NUM-1:`BIN_NUM/2]),
        .binSelected_i          (binSelected[`BIN_NUM-1:`BIN_NUM/2]),
        .readEn_i               (readEn), 
        .rowIdx_o               (rowIdx_up),
        .binIdx_o               (binIdx_up),
        .rowDelta_o             (rowDelta_up),
        .rowValid_o             (rowValid_up),
        .rowReady_i             (rowReady)
        // .queueEmpty_o           (queueEmpty)     
    );
// --------------------------------------------------------------------

// --------------------------------------------------------------------
// Module name  :   EQ_wrapper_half
// Description  :   2D to 1D for event_queues
// --------------------------------------------------------------------
    EQ_wrapper_half EQ_wrapper__down_inst(
        .clk_i                  (clock),   //  Clock
        .rst_i                  (reset),   //  Reset
        .initialFinish_i        (initialFinish),
        .CUDelta_i              (CUDelta[`BIN_NUM*`DELTA_WIDTH/2-1:0]),
        .CUIdx_i                (CUIdx[`BIN_NUM*`VERTEX_IDX_WIDTH/2-1:0]),
        .CUValid_i              (CUValid[`BIN_NUM/2-1:0]),
        .CUReady_o              (CUReady[`BIN_NUM/2-1:0]),
        .CUClean_o              (CUClean[`BIN_NUM/2-1:0]),
        .binValid_o             (binValid[`BIN_NUM/2-1:0]),
        .binSelected_i          (binSelected[`BIN_NUM/2-1:0]),
        .readEn_i               (readEn), 
        .rowIdx_o               (rowIdx_down),
        .binIdx_o               (binIdx_down),
        .rowDelta_o             (rowDelta_down),
        .rowValid_o             (rowValid_down),
        .rowReady_i             (rowReady)
        // .queueEmpty_o           (queueEmpty)     
    );
// --------------------------------------------------------------------

// --------------------------------------------------------------------
// Module name  :   pes
// Description  :   processing elements
// --------------------------------------------------------------------
    generate
        for (genvar i = 0; i < `PE_NUM_OF_CORES; i = i + 1)
        begin
            pe pes (
                ////////// INPUTS //////////
                .clk_i                      (clock),
                .rst_i                      (reset),
                // PE ID
                .pe_id_i                    (i[1:0]),
                // num of vertices
                .num_of_vertices_float16_i  (num_of_vertices_float16),
                .num_of_vertices_int8_i     (num_of_vertices_int8),
                // from crossbar1
                .PEDelta_i                  (PEDelta[i*`DELTA_WIDTH +: `DELTA_WIDTH]),
                .PEIdx_i                    (PEIdx[i*`VERTEX_IDX_WIDTH +: `VERTEX_IDX_WIDTH]),
                .PEValid_i                  (PEValid[i]),
                // from crossbar 2
                .ProReady_i                 (proReady[2*i +: 2]),
                // from mem controller
                .vertexmem_ack_i            (vm2pe_grant_onehot[i]),
                .edgemem_ack_i              (em2pe_grant_onehot[i]),
                // from mem 
                .vertexmem_resp_i           (vm_response),
                .vertexmem_data_i           (vm_rdData),
                .vertexmem_tag_i            (vm_tag),
                .edgemem_resp_i             (em_response),
                .edgemem_data_i             (em_rdData),
                .edgemem_tag_i              (em_tag),
                ////////// OUTPUTS //////////
                .idle_o                     (idle[i]),
                // to scheduler
                .initialFinish_o            (initialFinish_pe[i]),
                // to crossbar 1
                .PEReady_o                  (PEReady[i]),
                // to crossbar2
                .ProDelta0_o                (proDelta[2*i*`DELTA_WIDTH +: `DELTA_WIDTH]),
                .ProIdx0_o                  (proIdx[2*i*`VERTEX_IDX_WIDTH +: `VERTEX_IDX_WIDTH]),
                .ProValid0_o                (proValid[2*i]),
                .ProDelta1_o                (proDelta[(2*i+1)*`DELTA_WIDTH +: `DELTA_WIDTH]),
                .ProIdx1_o                  (proIdx[(2*i+1)*`VERTEX_IDX_WIDTH +: `VERTEX_IDX_WIDTH]),
                .ProValid1_o                (proValid[2*i+1]),
                // to vertex mem controller
                .pe_vertex_reqAddr_o        (pe_vertex_reqAddr[i]),
                .pe_vertex_reqValid_o       (pe_vertex_reqValid[i]),
                .pe_wrData_o                (pe_wrData[i]),
                .pe_wrEn_o                  (pe_wrEn[i]),
                // to edge mem controller
                .pe_edge_reqAddr_o          (pe_edge_reqAddr[i]),
                .pe_edge_reqValid_o         (pe_edge_reqValid[i])
            );
        end
    endgenerate
// --------------------------------------------------------------------



endmodule // GraphPulse
