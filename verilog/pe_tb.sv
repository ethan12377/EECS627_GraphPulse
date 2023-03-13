/////////////////////////////////////////////////////////////////////////
//                                                                     //
//  Modulename  :  pe_tb.sv                                            //
//                                                                     //
//  Description :  unit testbench for pe module                        // 
//                                                                     //
/////////////////////////////////////////////////////////////////////////

`define CACHE_MODE

module pe_tb ();

// ====================================================================
// Local Parameters Declarations Start
// ====================================================================

// ====================================================================
// Local Parameters Declarations End
// ====================================================================

// ====================================================================
// Signal Declarations Start
// ====================================================================
// --------------------------------------------------------------------
// PE
// --------------------------------------------------------------------
///////////// INPUTS /////////////////
logic                                   clk_i           ;   //  Clock
logic                                   rst_i           ;   //  Reset
// number of vertices as int 8 and float16 values, sampled on the negative edge of reset
logic [15:0]                            num_of_vertices_float16;
logic [7:0]                             num_of_vertices_int8;
// from crossbar1
logic [`PE_NUM_OF_CORES-1:0][`DELTA_WIDTH-1:0]                PEDelta;
logic [`PE_NUM_OF_CORES-1:0][`VERTEX_IDX_WIDTH-1:0]           PEIdx;
logic [`PE_NUM_OF_CORES-1:0]                                  PEValid;
// from crossbar2
logic [`PE_NUM_OF_CORES-1:0][1:0]                             ProReady;
// from mem and mem controllers
logic                                   vertexmem_ready;
logic                                   edgemem_ready;
logic [63:0]                            vertexmem_data;
logic [63:0]                            edgemem_data;

///////////// OUTPUTS /////////////////
// idle status
logic [`PE_NUM_OF_CORES-1:0]                                  idle;
// to scheduler
logic [`PE_NUM_OF_CORES-1:0]                                  initialFinish;
// to crossbar 1
logic [`PE_NUM_OF_CORES-1:0]                                  PEReady;
// to crossbar 2
logic [2*`PE_NUM_OF_CORES-1:0][`DELTA_WIDTH-1:0]              ProDelta;
logic [2*`PE_NUM_OF_CORES-1:0][`VERTEX_IDX_WIDTH-1:0]         ProIdx;
logic [2*`PE_NUM_OF_CORES-1:0]                                ProValid;
// to vertex mem controller
logic [`PE_NUM_OF_CORES-1:0][`XLEN-1:0]                       pe_vertex_reqAddr;
logic [`PE_NUM_OF_CORES-1:0]                                  pe_vertex_reqValid;
logic [`PE_NUM_OF_CORES-1:0][`DELTA_WIDTH-1:0]                pe_wrData;
logic [`PE_NUM_OF_CORES-1:0]                                  pe_wrEn;
// to edge mem controller
logic [`PE_NUM_OF_CORES-1:0][`XLEN-1:0]                       pe_edge_reqAddr;
logic [`PE_NUM_OF_CORES-1:0]                                  pe_edge_reqValid;

// --------------------------------------------------------------------
// MC
// --------------------------------------------------------------------
// flattened 2d arrays for MC
logic [`PE_NUM_OF_CORES*`XLEN-1 : 0] pe2vm_reqAddr_1d, pe2em_reqAddr_1d;
logic [`PE_NUM_OF_CORES*64-1 : 0]    pe2vm_wrData_1d;
generate
    for (genvar i = 0; i < `PE_NUM_OF_CORES; i = i + 1)
    begin
        assign pe2vm_reqAddr_1d[`XLEN*(i+1)-1 : `XLEN*i] = pe_vertex_reqAddr[i];
        assign pe2em_reqAddr_1d[`XLEN*(i+1)-1 : `XLEN*i] = pe_edge_reqAddr[i];
        assign pe2vm_wrData[64*(i+1)-1 : 64*i] = {48'd0, pe_wrData[i]};
    end
endgenerate

// --------------------------------------------------------------------
// MEM
// --------------------------------------------------------------------
logic [`XLEN-1:0] mc2vm_addr, mc2em_addr;   // address for current command
logic [63:0] mc2vm_data, mc2em_data;
logic [1:0] mc2vm_command, mc2em_command;

logic  [3:0] vm_response, em_response; // 0 = can't accept, other=tag of transaction
logic [63:0] vm_rdData, em_rdData;         // data resulting from a load
logic  [3:0] vm_tag, em_tag;           // 0 = no value, other=tag of transaction
// ====================================================================
// Signal Declarations End
// ====================================================================

// ====================================================================
// Module Instantiations Start
// ====================================================================
// --------------------------------------------------------------------
// Module name  :   dut
// Description  :   processing element
// --------------------------------------------------------------------
generate
    for (genvar i = 0; i < `PE_NUM_OF_CORES; i = i + 1)
    begin
        pe dut #(parameter C_PEID=i) (
            .clk_i(clk_i),
            .rst_i(rst_i),
            .num_of_vertices_float16_i(16'h4900), // 10 for tb 
            .num_of_vertices_int8_i(8'd10), // 10 for tb
            .PEDelta_i(PEDelta[i]),
            .PEIdx_i(PEIdx[i]),
            .PEValid_i(PEValid[i]),
            .ProReady_i(ProReady[i]),
            // TODO: updated mem protocols

            .idle_o(idle[i]),
            .initialFinish_o(initialFinish[i]),
            .PEReady_o(PEReady[i]),
            .ProDelta0_o(ProDelta[2*i]),
            .ProIdx0_o(ProIdx[2*i]),
            .ProValid0_o(ProIdx[2*i]),
            .ProDelta1_o(ProDelta[2*i+1]),
            .ProIdx1_o(ProIdx[2*i+1]),
            .ProValid1_o(ProIdx[2*i+1]),
            .pe_vertex_reqAddr_o(pe_vertex_reqAddr[i]),
            .pe_vertex_reqValid_o(pe_vertex_reqValid[i]),
            .pe_wrData_o(pe_wrData[i]),
            .pe_wrEn_o(pe_wrEn[i]),
            .pe_edge_reqAddr_o(pe_edge_reqAddr[i]),
            .pe_edge_reqValid_o(pe_edge_reqValid[i])
        );
    end
endgenerate

// --------------------------------------------------------------------


// --------------------------------------------------------------------
// Module name  :   mc_vm
// Description  :   vertexmem controller
// --------------------------------------------------------------------
mc mc_vm (
    .clk_i              (clk_i),
    .rst_i              (rst_i),
    .pe2mem_reqAddr_i   (pe2vm_reqAddr_1d),
    .pe2mem_wrData_i    (pe2vm_wrData_1d),
    .pe2mem_reqValid_i  (pe_vertex_reqValid),
    .pe2mem_wrEn_i      (pe_wrEn),
    .mc2mem_addr_o      (mc2vm_addr),
    .mc2mem_data_o      (mc2vm_data),
    .mc2mem_command_o   (mc2vm_command)
);

// --------------------------------------------------------------------

// --------------------------------------------------------------------
// Module name  :   mc_em
// Description  :   edgemem controller
// --------------------------------------------------------------------
mc mc_em (
    .clk_i              (clk_i),
    .rst_i              (rst_i),
    .pe2mem_reqAddr_i   (pe2em_reqAddr_1d),
    .pe2mem_wrData_i    ('x), // read only
    .pe2mem_reqValid_i  (pe_edge_reqValid),
    .pe2mem_wrEn_i      ('0), // read only
    .mc2mem_addr_o      (mc2em_addr),
    .mc2mem_data_o      (mc2em_data),
    .mc2mem_command_o   (mc2em_command)
);

// --------------------------------------------------------------------

// --------------------------------------------------------------------
// Module name  :   vertexmem
// Description  :   vertex mem
// --------------------------------------------------------------------
mem vertexmem (
    .clk                (clk_i),
    .proc2mem_addr      (mc2vm_addr),
    .proc2mem_data      (mc2vm_data),
    .proc2mem_command   (mc2vm_command),
    .mem2proc_response  (vm_response),
    .mem2proc_data      (vm_rdData),
    .mem2proc_tag       (vm_tag)
);

// --------------------------------------------------------------------

// --------------------------------------------------------------------
// Module name  :   edgemem
// Description  :   edge mem
// --------------------------------------------------------------------
mem edgemem (
    .clk                (clk_i),
    .proc2mem_addr      (mc2em_addr),
    .proc2mem_data      (mc2em_data),
    .proc2mem_command   (mc2em_command),
    .mem2proc_response  (em_response),
    .mem2proc_data      (em_rdData),
    .mem2proc_tag       (em_tag)
);

// --------------------------------------------------------------------


// ====================================================================
// Module Instantiations End
// ====================================================================

// ====================================================================
// RTL Logic Start
// ====================================================================
// --------------------------------------------------------------------
// Clock generation
// --------------------------------------------------------------------
    initial begin
        clk_i   =   'b0 ;
        forever begin
            #(`VERILOG_CLOCK_PERIOD/2);
            clk_i   =   ~clk_i;
        end
    end
// --------------------------------------------------------------------
// Logic Divider
// --------------------------------------------------------------------

// ====================================================================
// RTL Logic End
// ====================================================================


endmodule
