// fp_add takes 2 16-bit operands and performs addition, subtraction,
// multiplication, or division based on the op input. It outputs a 16-bit
// result. Flags include overflow, underflow, inexact, and flags used for
// the compare instruction in the cpu.

// TODO: remove flags because they are unnecessary for our purposes
// TODO: add pipeline regs to pipe through fpu status

module fpu #(parameter PIPELINE_DEPTH=3) (
	input logic clk, reset,
	input logic [15:0] opA, opB,
	input logic [1:0] op,
	output logic [15:0] result,
	output logic overflow, underflow, inexact
);

	logic [15:0] newOpB;
	logic [15:0] sum, product, quotient;
	logic aUnderflow, aOverflow, aInexact,
			pUnderflow, pOverflow, pInexact,
			qUnderflow, qOverflow, qInexact;
	logic cout;
	
	// pipelining
	logic [PIPELINE_DEPTH:0][18:0] pipeline_regs;
	always_ff @(posedge clk)
	begin
		if (reset) pipeline_regs[PIPELINE_DEPTH:1] <= '0;
		else
		begin
			for (integer i = 0; i < PIPELINE_DEPTH; i = i + 1)
				pipeline_regs[i+1] <= pipeline_regs[i];
		end
	end

	// internal nets
	logic [15:0] result_internal;
	logic overflow_internal, underflow_internal, inexact_internal;

	assign pipeline_regs[0][15:0] = result_internal;
	assign pipeline_regs[0][16] = overflow_internal;
	assign pipeline_regs[0][17] = underflow_internal;
	assign pipeline_regs[0][18] = inexact_internal;
	assign result = pipeline_regs[PIPELINE_DEPTH][15:0];
	assign overflow = pipeline_regs[PIPELINE_DEPTH][16];
	assign underflow = pipeline_regs[PIPELINE_DEPTH][17];
	assign inexact = pipeline_regs[PIPELINE_DEPTH][18];

	assign newOpB = (op == 2'd0) ? opB : {~opB[15], opB[14:0]};
	fp_add add_sub(.opA, .opB(newOpB), .sum, .underflow(aUnderflow), 
        .overflow(aOverflow), .inexact(aInexact), .cout);

	fp_mul multiply(.opA, .opB, .product, .underflow(pUnderflow), .overflow(pOverflow), 
        .inexact(pInexact));

	fp_div divide(.opA, .opB, .quotient, .underflow(qUnderflow), 
        .overflow(qOverflow), .inexact(qInexact));

	always_comb begin
		case(op)
			2'b00: begin // add
				result_internal = sum;
				overflow_internal = aOverflow;
				underflow_internal = aUnderflow;
				inexact_internal = aInexact;
			end
			2'b01: begin // sub
				result_internal = sum;
				overflow_internal = aOverflow;
				underflow_internal = aUnderflow;
				inexact_internal = aInexact;
			end
			2'b10: begin // mult
				result_internal = product;
				overflow_internal = pOverflow;
				underflow_internal = pUnderflow;
				inexact_internal = pInexact;
			end
			2'b11: begin // div
				result_internal = quotient;
				overflow_internal = qOverflow;
				underflow_internal = qUnderflow;
				inexact_internal = qInexact;
			end
            default: begin
				result_internal = 'X;
				overflow_internal = 'X;
				underflow_internal = 'X;
				inexact_internal = 'X;
            end
		endcase
	end

endmodule
