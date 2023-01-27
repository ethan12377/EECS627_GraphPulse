// fpuStim tests that the fpu can pass randomized tests. 
module fpuStim();
    logic clk, reset;
    logic [15:0] opA, opB;
    logic [1:0] op;
    logic [15:0] result;
    logic overflow, underflow, inexact;
    logic [7:0] address;
    
	parameter ClockDelay = 10e6;
	initial begin 
		clk <= 0;
		forever #(ClockDelay/2) clk <= ~clk;
	end

    fpu dut(.opA, .opB, .op, .result, 
        .underflow, .overflow, .inexact);
	
    opmem ops(.address, .opA, .opB, .op);


	// Handle the read from operation memory.
    always_ff @(posedge clk) begin
        if (reset) begin
            address <= 8'd0;
        end else begin
            address <= address + 1;
        end
    end

    integer f;    
    initial begin
        f = $fopen("fp_output.txt", "w");
        repeat(2) @(posedge clk);
        while(1) begin
            $fwrite(f, "%t %b\t %b %b %b\n", 
                $time, dut.result, dut.underflow, dut.overflow, dut.inexact);
            @(posedge clk);
        end
    end
    
    initial begin
        $vcdpluson;
        $vcdplusmemon;
        reset <= 1; @(posedge clk);
        reset <= 0; @(posedge clk);
        while (opA != 16'b1111111111111111) begin
            @(posedge clk);
        end
//        @(posedge clk);
        $finish;
        $fclose(f);
    end
endmodule
