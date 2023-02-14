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
    logic [15:0]    numVert;
    logic           converge;
    logic [31:0]    clock_count;
	int             cache_fileno;

    GraphPulse gp(
        // Inputs
        .clock          (clock),
        .reset          (reset),
        .numVert        (numVert),

        // Outputs
        // snoop cache ports?
        .converge       (converge)
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

		// $readmemh(, ); // need off-chip memory? or model cache here?
		
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
			
			// display cahce port signal?

		end  // if(reset)   
	end 

endmodule  // module testbench