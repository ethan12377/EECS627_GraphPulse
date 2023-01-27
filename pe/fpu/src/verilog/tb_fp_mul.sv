// tb_fp_add tests that the fpu can accurately compute the sum of 2 operands
module tb_fp_mul();
    logic clk, reset;
    logic [15:0] opA, opB, product;
    logic underflow, overflow, inexact;
	
    parameter ClockDelay = 10000;
	initial begin // Set up the clock
		clk <= 0;
		forever #(ClockDelay/2) clk <= ~clk;
	end

    fp_mul dut(.clk, .reset, .opA, .opB, .product, 
        .underflow, .overflow, .inexact);

    integer f;
    initial begin
        f = $fopen("fp_output.txt", "w");
        repeat(3) @(posedge clk);
        while(1) begin
            $fwrite(f, "%b\t %b %b %b\n", 
                product, underflow, overflow, inexact); 
            @(posedge clk);
        end
    end

    initial begin
        $vcdpluson;
        reset <= 1'b1; @(posedge clk);
        reset <= 1'b0;
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
        // 1.25 * -5.08 = 2.1875
        opA <= 16'b0_10000100_0100000;
        opB <= 16'b1_00111100_1100000;
        @(posedge clk);
        // overflow (exponents too big)
        // 1.7e38 * 1.7e38 =  
        opA <= 16'b0_11111110_0000000;
        opB <= 16'b0_11111110_0000000;
        @(posedge clk);
        // overflow (exponent normalizes to 255)
        // 1.06e38 * 2.07e-38= 2.1836??
        opA <= 16'b0_11111101_0100000;
        opB <= 16'b0_10000000_1100000;
        @(posedge clk);
        // inexact
        // 1.25 * 6.8292e-21 = 
        opA <= 16'b0_10000100_0100000;
        opB <= 16'b0_00111100_0000001;
        @(posedge clk);
        @(posedge clk);
        $finish;
        $fclose(f);
    end
endmodule
