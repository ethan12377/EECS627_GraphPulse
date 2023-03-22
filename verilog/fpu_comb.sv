module fpu_comb (
	input logic [15:0] opA, opB,
	output logic [15:0] sum, diff, product, quotient
);
	
	fp_add add(.opA, .opB, .sum);

	fp_add sub(.opA, .opB({~opB[15], opB[14:0]}), .sum(diff));

	fp_mul multiply(.opA, .opB, .product);

	fp_div divide(.opA, .opB, .quotient);

endmodule
