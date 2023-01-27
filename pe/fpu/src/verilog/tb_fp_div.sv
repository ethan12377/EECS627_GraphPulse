// tb_fp_add tests that the fpu can accurately compute the sum of 2 operands
module tb_fp_div();
    logic clk, reset, start;
    logic [15:0] opA, opB, quotient;
    logic underflow, overflow, inexact, valid;
	
    parameter ClockDelay = 10000;
	initial begin // Set up the clock
		clk <= 0;
		forever #(ClockDelay/2) clk <= ~clk;
	end

    fp_div dut(.clk, .reset, .start, .opA, .opB, .quotient, 
        .underflow, .overflow, .inexact, .valid);

    integer f;
    initial begin
        f = $fopen("fp_output.txt", "w");
        repeat(3) @(posedge clk);
        while(1) begin
            if (valid & dut.mValid) begin
                $fwrite(f, "%b\t %b %b %b\n", 
                    quotient, underflow, overflow, inexact); 
            end
            @(posedge clk);
        end
    end

    initial begin
        $vcdpluson;
        reset <= 1'b1; @(posedge clk);
        reset <= 1'b0;
        // simple example
        // 20 / 4 = 5
        opA <= 16'b0_10000011_0100000;
        opB <= 16'b0_10000001_0000000;
        start <= 1'b1; @(posedge clk);
        start <= 1'b0; repeat(16) @(posedge clk);
        // 1 negative operand
        // -20 / 4 = -5
        opA <= 16'b1_10000011_0100000;
        opB <= 16'b0_10000001_0000000;
        start <= 1'b1; @(posedge clk);
        start <= 1'b0; repeat(16) @(posedge clk);
        // 20 / -4 = -5
        opA <= 16'b0_10000011_0100000;
        opB <= 16'b1_10000001_0000000;
        start <= 1'b1; @(posedge clk);
        start <= 1'b0; repeat(16) @(posedge clk);
        // 2 negative operands
        // -20 / -4 = 5
        opA <= 16'b1_10000011_0100000;
        opB <= 16'b1_10000001_0000000;
        start <= 1'b1; @(posedge clk);
        start <= 1'b0; repeat(16) @(posedge clk);
        // normalize & inexact
        // 32 / -1.0625 = -30.12
        opA <= 16'b0_10000100_0000000;
        opB <= 16'b1_01111111_0001000;
        start <= 1'b1; @(posedge clk);
        start <= 1'b0; repeat(16) @(posedge clk);
        // underflow (exponents too small)
        // 1.7e38 * 1.7e38 =  
        opA <= 16'b0_00000000_0000000;
        opB <= 16'b0_01111111_0001000;
        start <= 1'b1; @(posedge clk);
        start <= 1'b0; repeat(16) @(posedge clk);
        // underflow (exponent normalizes to 0)
        // 1.06e38 * 2.07e-38= 2.1836??
        opA <= 16'b0_00000001_0000000;
        opB <= 16'b0_01111111_0001000;
        start <= 1'b1; @(posedge clk);
        start <= 1'b0; repeat(16) @(posedge clk);
        @(posedge clk);
        $finish;
        $fclose(f);
    end
endmodule
