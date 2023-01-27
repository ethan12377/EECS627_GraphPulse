
// tb_fp_add tests that the fpu can accurately add, subtract, multiply, and
// divide 2 operands
module tb_fpu();
    logic clk, reset;
    logic [15:0] opA, opB;
    logic [1:0] op;
    logic [15:0] result;
    logic overflow, underflow, inexact, valid;

	parameter ClockDelay = 10000;
	initial begin 
		clk <= 0;
		forever #(ClockDelay/2) clk <= ~clk;
	end

    fpu dut(.clk, .reset, .opA, .opB, .op, .result, 
        .underflow, .overflow, .inexact, .valid);

    integer f;    
    initial begin
        f = $fopen("fp_output.txt", "w");
        repeat(3) @(posedge clk);
        while(1) begin
            $fwrite(f, "%t %b\t %b %b %b\n", 
                $time, dut.result, dut.underflow, dut.overflow, dut.inexact);
            @(posedge clk);
        end
    end


    initial begin
        $vcdpluson;
        reset <= 1; @(posedge clk);
        reset <= 0;
        ///////////////////////////////////////////////////////////
        // Test add
        // --------------------------------------------------------
        op <= 2'd0;
        // 100 + 0.5 = 100.5
        opA <= 16'b0_10000101_1001000;
        opB <= 16'b0_01111110_0000000;
        @(posedge clk);
        // 100 - 0.5 = 99.5
        opA <= 16'b0_10000101_1001000;
        opB <= 16'b1_01111110_0000000;
        @(posedge clk);
        // -100 + 0.5 = -99.5
        opA <= 16'b1_10000101_1001000;
        opB <= 16'b0_01111110_0000000;
        @(posedge clk);
        // -0.5 + 100 = 99.5
        opA <= 16'b1_01111110_0000000;
        opB <= 16'b0_10000101_1001000;
        @(posedge clk);
        // 0.5 - 100 = -99.5
        opA <= 16'b0_01111110_0000000;
        opB <= 16'b1_10000101_1001000;
        @(posedge clk);
        // -100 - 0.5 = -100.5
        opA <= 16'b1_10000101_1001000;
        opB <= 16'b1_01111110_0000000;
        @(posedge clk);
        // 127.5 + 0.5 = 128, normalize 
        opA <= 16'b0_10000101_1111111;
        opB <= 16'b0_01111110_1000000;
        @(posedge clk);
        // result = 0_11111111_0000000, overflow = 1
        opA <= 16'b0_11111110_1111110; // c
        opB <= 16'b0_11111101_0000010; // d
        @(posedge clk);
        // 100 + .52734375 = 100.52734375, inexact = 1
        opA <= 16'b0_10000101_1001000;
        opB <= 16'b0_01111110_0000111;
        @(posedge clk);
        ///////////////////////////////////////////////////////////
        // Test subtract
        // --------------------------------------------------------
        op <= 2'd1;
        // 100 - 0.5 = 99.5
        opA <= 16'b0_10000101_1001000;
        opB <= 16'b0_01111110_0000000;
        @(posedge clk);
        // 100 - -0.5 = 100.5
        opA <= 16'b0_10000101_1001000;
        opB <= 16'b1_01111110_0000000;
        @(posedge clk);
        // -100 - 0.5 = -100.5
        opA <= 16'b1_10000101_1001000;
        opB <= 16'b0_01111110_0000000;
        @(posedge clk);
        // -0.5 - 100 = -100.5
        opA <= 16'b1_01111110_0000000;
        opB <= 16'b0_10000101_1001000;
        @(posedge clk);
        // -0.5 - 0.390625 
        opA <= 16'b1_01111110_0000000;
        opB <= 16'b0_01111101_1001000;
        @(posedge clk);
        // 0.5 - -100 = 100.5
        opA <= 16'b0_01111110_0000000;
        opB <= 16'b1_10000101_1001000;
        @(posedge clk);
        // -100 - -0.5 = -99.5
        opA <= 16'b1_10000101_1001000;
        opB <= 16'b1_01111110_0000000;
        @(posedge clk);
        // 66 - 64.5 = 1.5, normalize 
        opA <= 16'b0_10000101_0000100;
        opB <= 16'b0_10000101_0000001;
        @(posedge clk);
        // result = 0_11111111_0000000, overflow = 1
        opA <= 16'b0_11111110_1111110; // a
        opB <= 16'b1_11111101_0000010; // b
        @(posedge clk);
        // 100 - .52734375 = 99...., inexact = 1
        opA <= 16'b0_10000101_1001000;
        opB <= 16'b0_01111110_0000111;
        @(posedge clk);
        ///////////////////////////////////////////////////////////
        // Test multiply
        // --------------------------------------------------------
        op <= 2'd2;
        // simple example
        // 5 * 4 = 20
        opA <= 16'b0_10000001_0100000;
        opB <= 16'b0_10000001_0000000;
        @(posedge clk);
        // 1 negative operand
        // -5 * 4 = -20
        opA <= 16'b1_10000001_0100000;
        opB <= 16'b0_10000001_0000000;
        @(posedge clk);
        // 5 * -4 = -20
        opA <= 16'b0_10000001_0100000;
        opB <= 16'b1_10000001_0000000;
        @(posedge clk);
        // 2 negative operands
        // -5 * -4 = 20
        opA <= 16'b1_10000001_0100000;
        opB <= 16'b1_10000001_0000000;
        @(posedge clk);
        // normalize
        // 40 * -1.2e-20
        opA <= 16'b0_10000100_0100000;
        opB <= 16'b1_00111100_1100000;
        @(posedge clk);
        // overflow (exponents too big)
        // 1.7e38 * 1.7e38 =  
        opA <= 16'b0_11111110_0000000; // e
        opB <= 16'b0_11111110_0000000;
        @(posedge clk);
        // overflow (exponent normalizes to 255)
        // 1.33e37 * 3.5 = 4.66e37
        opA <= 16'b0_11111101_0100000;
        opB <= 16'b0_10000000_1100000;
        @(posedge clk);
        // inexact
        // 40 * 6.8292e-21 = 
        opA <= 16'b0_10000100_0100000;
        opB <= 16'b0_00111100_0000001;
        @(posedge clk);
        ///////////////////////////////////////////////////////////
        // Test divide
        // --------------------------------------------------------
        op <= 2'd3;
        // simple example
        // 20 / 4 = 5
        opA <= 16'b0_10000011_0100000;
        opB <= 16'b0_10000001_0000000;
        @(posedge clk);
        // 1 negative operand
        // -20 / 4 = -5
        opA <= 16'b1_10000011_0100000;
        opB <= 16'b0_10000001_0000000;
        @(posedge clk);
        // 20 / -4 = -5
        opA <= 16'b0_10000011_0100000;
        opB <= 16'b1_10000001_0000000;
        @(posedge clk);
        // 2 negative operands
        // -20 / -4 = 5
        opA <= 16'b1_10000011_0100000;
        opB <= 16'b1_10000001_0000000;
        @(posedge clk);
        // normalize & inexact
        // 32 / -1.0625 = -30.12
        opA <= 16'b0_10000100_0000000;
        opB <= 16'b1_01111111_0001000;
        @(posedge clk);
        // underflow (normalizedE = 0)
        // 1.18e-38 / 1.0625 = 1.11e-38 result also too small
        opA <= 16'b0_00000001_0000000;
        opB <= 16'b0_01111111_0001000;
        @(posedge clk);
        // underflow (diffE < -127)
        // .0078125 / 8.51e37 = 9.18e-41 result also too small
        opA <= 16'b0_01111000_0000000;
        opB <= 16'b0_11111101_0000000;
        @(posedge clk);
        // underflow (diffE = -127)
        // 1.17e-38/ 2.125 = 5.5e-39
        opA <= 16'b0_00000001_0000000;
        opB <= 16'b0_10000000_0001000;
        @(posedge clk);
        // overflow 
        // 1.06e38 / 0.25 = 4.24e38 
        opA <= 16'b0_11111101_0011111; // 1.06e38
        opB <= 16'b0_01111101_0000000; // 0.25
        @(posedge clk);
        @(posedge clk);
        $finish;
        $fclose(f);
    end
endmodule
