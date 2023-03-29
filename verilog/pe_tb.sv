/////////////////////////////////////////////////////////////////////////
//                                                                     //
//  Modulename  :  pe_tb.sv                                            //
//                                                                     //
//  Description :  unit testbench for pe module                        // 
//                                                                     //
/////////////////////////////////////////////////////////////////////////
`define SYN

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
    logic                                                         clk_i           ;   //  Clock
    logic                                                         rst_i           ;   //  Reset
    // number of vertices as int 8 and float16 values, sampled on the negative edge of reset
    logic [15:0]                                                  num_of_vertices_float16;
    assign num_of_vertices_float16 = 16'h4900;
    logic [7:0]                                                   num_of_vertices_int8;
    assign num_of_vertices_int8 = 8'd10;
    // from crossbar1
    logic [`PE_NUM_OF_CORES-1:0][`DELTA_WIDTH-1:0]                PEDelta;
    
    logic [`PE_NUM_OF_CORES-1:0][`VERTEX_IDX_WIDTH-1:0]           PEIdx;
    logic [`PE_NUM_OF_CORES-1:0]                                  PEValid;
    // from crossbar2
    logic [`PE_NUM_OF_CORES-1:0][1:0]                             ProReady;

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
            assign pe2vm_wrData_1d[64*(i+1)-1 : 64*i] = {48'd0, pe_wrData[i]};
        end
    endgenerate
    logic [`PE_NUM_OF_CORES-1:0] vm2pe_grant_onehot, em2pe_grant_onehot;

// --------------------------------------------------------------------
// MEM
// --------------------------------------------------------------------
    logic [`XLEN-1:0] mc2vm_addr, mc2em_addr;   // address for current command
    logic [63:0] mc2vm_data, mc2em_data;
    BUS_COMMAND mc2vm_command, mc2em_command;

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
            pe dut (
                ////////// INPUTS //////////
                .clk_i                      (clk_i),
                .rst_i                      (rst_i),
                // PE ID
                .pe_id_i                    (i),
                // num of vertices
                .num_of_vertices_float16_i  (num_of_vertices_float16),
                .num_of_vertices_int8_i     (num_of_vertices_int8),
                // from crossbar1
                .PEDelta_i                  (PEDelta[i]),
                .PEIdx_i                    (PEIdx[i]),
                .PEValid_i                  (PEValid[i]),
                // from crossbar 2
                .ProReady_i                 (ProReady[i]),
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
                .initialFinish_o            (initialFinish[i]),
                // to crossbar 1
                .PEReady_o                  (PEReady[i]),
                // to crossbar2
                .ProDelta0_o                (ProDelta[2*i]),
                .ProIdx0_o                  (ProIdx[2*i]),
                .ProValid0_o                (ProValid[2*i]),
                .ProDelta1_o                (ProDelta[2*i+1]),
                .ProIdx1_o                  (ProIdx[2*i+1]),
                .ProValid1_o                (ProValid[2*i+1]),
                // to vertex mem controller
                .pe_vertex_reqAddr_o        (pe_vertex_reqAddr[i]),
                .pe_vertex_reqValid_o       (pe_vertex_reqValid[i]),
                .pe_wrData_o                (pe_wrData[i]),
                .pe_wrEn_o                  (pe_wrEn[i]),
                // to edge mem controller
                .pe_edge_reqAddr_o          (pe_edge_reqAddr[i]),
                .pe_edge_reqValid_o         (pe_edge_reqValid[i])
            );
            `ifdef SYN
                initial $sdf_annotate("../syn/pe.syn.sdf", dut);
                initial $sdf_annotate("../syn/fpu.syn.sdf", dut.pe_fpu);
            `endif
        end
    endgenerate

// --------------------------------------------------------------------

// --------------------------------------------------------------------
// Module name  :   evqueue
// Description  :   ideal evqueue for simulation
// --------------------------------------------------------------------
    evqueue_sim evqueue (
        .clk_i                  (clk_i),
        .rst_i                  (rst_i),
        .PEReady_i              (PEReady),
        .proDelta_i             (ProDelta),
        .proIdx_i               (ProIdx),
        .proValid_i             (ProValid),
        .ProReady_o             (ProReady),
        .PEDelta_o              (PEDelta),
        .PEIdx_o                (PEIdx),
        .PEValid_o              (PEValid)
    );

// --------------------------------------------------------------------

// --------------------------------------------------------------------
// Module name  :   mc_vm
// Description  :   vertexmem controller
// --------------------------------------------------------------------
    mc mc_vm (
        .clk_i                  (clk_i),
        .rst_i                  (rst_i),
        .pe2mem_reqAddr_i       (pe2vm_reqAddr_1d),
        .pe2mem_wrData_i        (pe2vm_wrData_1d),
        .pe2mem_reqValid_i      (pe_vertex_reqValid),
        .pe2mem_wrEn_i          (pe_wrEn),
        .mc2mem_addr_o          (mc2vm_addr),
        .mc2mem_data_o          (mc2vm_data),
        .mc2mem_command_o       (mc2vm_command),
        .mc2pe_grant_onehot_o   (vm2pe_grant_onehot)
    );

// --------------------------------------------------------------------

// --------------------------------------------------------------------
// Module name  :   mc_em
// Description  :   edgemem controller
// --------------------------------------------------------------------
    mc mc_em (
        .clk_i                  (clk_i),
        .rst_i                  (rst_i),
        .pe2mem_reqAddr_i       (pe2em_reqAddr_1d),
        .pe2mem_wrData_i        ('x), // read only
        .pe2mem_reqValid_i      (pe_edge_reqValid),
        .pe2mem_wrEn_i          ('0), // read only
        .mc2mem_addr_o          (mc2em_addr),
        .mc2mem_data_o          (mc2em_data),
        .mc2mem_command_o       (mc2em_command),
        .mc2pe_grant_onehot_o   (em2pe_grant_onehot)
    );

    `ifdef SYN
        initial $sdf_annotate("../syn/mc.syn.sdf", mc_vm);
        initial $sdf_annotate("../syn/mc.syn.sdf", mc_em);
    `endif

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
    always
    begin
        #(`VERILOG_CLOCK_PERIOD/2);
        clk_i   =   ~clk_i;
    end
// --------------------------------------------------------------------
// Sim
// --------------------------------------------------------------------
    integer cycle_num, timeout_cycle_num;
    initial begin
        cycle_num = 0;
        timeout_cycle_num = 30000;
        // clock generation
        clk_i = 1'b0;
        // initialize memory content
        $readmemb("edge_cache.mem", edgemem.unified_memory);
        rst_i = 1'b1; repeat(5) @(posedge clk_i);
        // rst_i = 1'b0; repeat(10000) @(posedge clk_i);
        rst_i = 1'b0; @(posedge clk_i);
        while (~evqueue.queue_empty || ~(|idle))
        begin
            if (cycle_num >= timeout_cycle_num) break;
            cycle_num = cycle_num + 1;
            @(posedge clk_i);
        end
        if (cycle_num >= timeout_cycle_num)
        begin
            $display("@@@ TIMEOUT AT CYCLE %d @@@", cycle_num);
        end
        else
        begin
            $display("@@@ CONVERGENCE REACHED AT %d @@@", cycle_num);
        end
        for (integer i = 0; i < 10; i = i + 1)
        begin
            $display("vertex mem [%d] = %h", i, vertexmem.unified_memory[i][15:0]);
        end
        $finish;
    end

// ====================================================================
// RTL Logic End
// ====================================================================


endmodule
