// tb_fp_add tests that the fpu can accurately compute the sum of 2 operands
module tb_fp_add();
    logic clk, reset;
    logic [15:0] opA, opB, sum;
    logic underflow, overflow, inexact;

	parameter ClockDelay = 10000;
	initial begin // Set up the clock
		clk <= 0;
		forever #(ClockDelay/2) clk <= ~clk;
	end

    fp_add dut(.clk, .reset, .opA, .opB, .sum, 
        .underflow, .overflow, .inexact);

    integer f;    
    initial begin
        f = $fopen("fp_output.txt", "w");
        repeat(3) @(posedge clk);
        while(1) begin
            $fwrite(f, "%b\n", dut.sum); @(posedge clk);
        end
    end

    initial begin
        $vcdpluson;
        reset <= 1; @(posedge clk);
        reset <= 0;
        // simple example
        // 100 + 0.5 <= 100.5
        opA <= 16'b0_10000101_1001000;
        opB <= 16'b0_01111110_0000000;
        @(posedge clk);
        // test 1 negative operand, positive result
        // 100 - 0.5 <= 99.5
        opA <= 16'b0_10000101_1001000;
        opB <= 16'b1_01111110_0000000;
        @(posedge clk);
        // test 1 negative operand, negative result
        // -100 + 0.5 <= -99.5
        opA <= 16'b1_10000101_1001000;
        opB <= 16'b0_01111110_0000000;
        @(posedge clk);
        // test 2 negative operands
        // -100 - 0.5 <= -100.5
        opA <= 16'b1_10000101_1001000;
        opB <= 16'b1_01111110_0000000;
        @(posedge clk);
        // test normalize
        // 127.5 + 0.5 <= 128 
        opA <= 16'b0_10000101_1111111;
        opB <= 16'b0_01111110_1000000;
        @(posedge clk);
        // test overflow
        // result <= 0_11111111_0000000
        opA <= 16'b0_11111110_1111110;
        opB <= 16'b0_11111101_0000010;
        @(posedge clk);
        // test underflow // TODO: once subtract is implemented
        // opA <= 16'b0_00000001_1111110;
        // opB <= 16'b1_10000101_0000010;
        // @(posedge clk);
        // test inexact flag
        // 100 + .52734375 <= 100.52734375
        opA <= 16'b0_10000101_1001000;
        opB <= 16'b0_01111110_0000111;
        @(posedge clk);
        @(posedge clk);
        $finish;
        $fclose(f);
    end
endmodule
