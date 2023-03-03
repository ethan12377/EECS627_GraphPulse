
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

    task display_fpu_status();
        $display("opa = %b \t opb = %b \t op = %b \t result = %b", opA, opB, op, result);
        $display("\n");
    endtask

    // fpu dut(.clk, .reset, .opA, .opB, .op, .result, 
    //     .underflow, .overflow, .inexact, .valid);

    fpu dut(.opA, .opB, .op, .result, .underflow, .overflow, .inexact);

    initial begin
        @(posedge clk);
        ///////////////////////////////////////////////////////////
        // Test add
        // --------------------------------------------------------
        op = 2'd0;
        // 3.0 + 2.0 = 5.0
        opA = 16'b0_10000_1000000000;
        opB = 16'b0_10000_0000000000;
        @(posedge clk);
        display_fpu_status();
        @(posedge clk);
        op = 2'd1;
        // 3.0 - 2.0 = 1.0
        opA = 16'b0_10000_1000000000;
        opB = 16'b0_10000_0000000000;
        @(posedge clk);
        display_fpu_status();
        @(posedge clk);
        op = 2'd2;
        // 3.0 * 2.0 = 6.0
        opA = 16'b0_10000_1000000000;
        opB = 16'b0_10000_0000000000;
        @(posedge clk);
        display_fpu_status();
        @(posedge clk);
        op = 2'd3;
        // 3.0 / 2.0 = 1.5
        opA = 16'b0_10000_1000000000;
        opB = 16'b0_10000_0000000000;
        @(posedge clk);
        display_fpu_status();
        @(posedge clk);
        $finish;
    end
endmodule
