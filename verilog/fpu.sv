// fp_add takes 2 16-bit operands and performs addition, subtraction,
// multiplication, or division based on the op input. It outputs a 16-bit
// result. Flags include overflow, underflow, inexact, and flags used for
// the compare instruction in the cpu.

module fpu #(parameter PIPELINE_DEPTH=3) (
	input logic clk, reset,
	input logic [15:0] opA, opB,
	input logic [1:0] op,
	input logic [1:0] status_i,
	output logic [15:0] result,
	output logic [1:0] status_o,
	output logic empty_o
);

	logic [15:0] newOpB;
	logic [15:0] sum, product, quotient;
	logic cout;
	
	// pipelining
	logic [PIPELINE_DEPTH:0][17:0] pipeline_regs;
	always_ff @(posedge clk)
	begin
		if (reset) pipeline_regs[PIPELINE_DEPTH:1] <= '0;
		else
		begin
			for (integer i = 0; i < PIPELINE_DEPTH; i = i + 1)
				pipeline_regs[i+1] <= pipeline_regs[i];
		end
	end

	// internal nets and assigning I/O
	logic [15:0] result_internal;

	assign pipeline_regs[0][15:0] = result_internal;
	assign pipeline_regs[0][17:16] = status_i;
	assign result = pipeline_regs[PIPELINE_DEPTH][15:0];
	assign status_o = pipeline_regs[PIPELINE_DEPTH][17:16];
	always_comb
	begin
		empty_o = 1
		for (integer i = 1; i < PIPELINE_DEPTH; i = i + 1)
			if (pipeline_regs[i][17:16] != 2'b00)
				empty_o = 0;
	end

	assign newOpB = (op == 2'd0) ? opB : {~opB[15], opB[14:0]};
	
	fp_add add_sub(.opA, .opB(newOpB), .sum);

	fp_mul multiply(.opA, .opB, .product);

	fp_div divide(.opA, .opB, .quotient);

	always_comb begin
		case(op)
			2'b00: result_internal = sum;      // add
			2'b01: result_internal = sum;      // sub
			2'b10: result_internal = product;  // mult
			2'b11: result_internal = quotient; // div
            default: result_internal = 'X;
		endcase
	end

endmodule
