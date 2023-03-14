/////////////////////////////////////////////////////////////////////////
//                                                                     //
//                                                                     //
//   Modulename :  testbench.v                                         //
//                                                                     //
//  Description :  Testbench module for the GraphPulse processor;      //
//                                                                     //
//                                                                     //
/////////////////////////////////////////////////////////////////////////

`timescale 1ns/100ps

module testbench;

    logic           clock;
    logic           reset;
    logic [15:0]    num_vertex;
    logic           converge;
    logic [31:0]    clock_count;
    int             cache_fileno;
    
    logic [1:0]  edgemem_command;
    logic [`XLEN-1:0] edgemem_addr;
    logic [63:0] edgemem_st_data;
    logic  [3:0] edgemem_response;
    logic [63:0] edgemem_ld_data;
    logic  [3:0] edgemem_tag;
    logic [1:0]  vertexmem_command;
    logic [`XLEN-1:0] vertexmem_addr;
    logic [63:0] vertexmem_st_data;
    logic  [3:0] vertexmem_response;
    logic [63:0] vertexmem_ld_data;
    logic  [3:0] vertexmem_tag;

    GraphPulse gp(
        // Inputs
        .clock              (clock),
        .reset              (reset),
        .num_vertex         (num_vertex),
        .edgemem_response   (edgemem_response),
        .edgemem_ld_data    (edgemem_ld_data),
        .edgemem_tag        (edgemem_tag),
        .vertexmem_response (vertexmem_response),
        .vertexmem_ld_data  (vertexmem_ld_data),
        .vertexmem_tag      (vertexmem_tag),

        // Outputs
        .converge           (converge),
        .edgemem_command    (edgemem_command),
        .edgemem_addr       (edgemem_addr),
        .edgemem_st_data    (edgemem_st_data),
        .edgemem_size       (edgemem_size)
        .vertexmem_command  (vertexmem_command),
        .vertexmem_addr     (vertexmem_addr),
        .vertexmem_st_data  (vertexmem_st_data),
        .vertexmem_size     (vertexmem_size)
    );

    mem edgemem (
        // Inputs
        .clk               (clock),
        .proc2mem_command  (edgemem_command),
        .proc2mem_addr     (edgemem_addr),
        .proc2mem_data     (edgemem_st_data),

        // Outputs
        .mem2proc_response (edgemem_response),
        .mem2proc_data     (edgemem_ld_data),
        .mem2proc_tag      (edgemem_tag)
    );
    
    mem vertexmem (
        // Inputs
        .clk               (clock),
        .proc2mem_command  (vertexmem_command),
        .proc2mem_addr     (vertexmem_addr),
        .proc2mem_data     (vertexmem_st_data),

        // Outputs
        .mem2proc_response (vertexmem_response),
        .mem2proc_data     (vertexmem_ld_data),
        .mem2proc_tag      (vertexmem_tag)
    );
    
    // Generate System Clock
	always begin
		#(`VERILOG_CLOCK_PERIOD/2.0);
		clock = ~clock;
	end

    initial begin
		// $dumpvars;
	
		clock = 1'b0;
		reset = 1'b0;
		
		// Pulse the reset signal
		$display("@@\n@@\n@@  %t  Asserting System reset......", $realtime);
		reset = 1'b1;
		@(posedge clock);
		@(posedge clock);

		$readmemh("edge_cache.mem", edgemem.unified_memory);
		
		@(posedge clock);
		@(posedge clock);
		`SD;
		// This reset is at an odd time to avoid the pos & neg clock edges
		
		reset = 1'b0;
		$display("@@  %t  Deasserting System reset......\n@@\n@@", $realtime);
		
		cache_fileno = $fopen("cache.out");
	end

    // Count the number of posedges till simulation ends
	always @(posedge clock) begin
		if(reset) begin
			clock_count <= `SD 0;
		end else begin
			clock_count <= `SD (clock_count + 1);
		end
		if (clock_count > 3000000) begin
			$display("Time out @ %d", clock_count);
			$finish;
		end
	end 

    always @(negedge clock) begin
        if(reset) begin
			$display("@@\n@@  %t : System STILL at reset, can't show anything\n@@",
			         $realtime);
        end else begin
			`SD;
			`SD;
			
            $fdisplay(cache_fileno, ""); // TODO
            
            if (converge) begin
                $display("@@@\n@@ Converge");
                    $fclose(cache_fileno);
                    #10 $finish;
            end

		end  // if(reset)   
	end 

endmodule  // module testbench
