// opmem holds the randomly generated operation and operands to validate
// the fpu
module opmem (
    input logic [7:0] address,
    output logic [15:0] opA, opB,
    output logic [1:0] op
);


    // The data storage itself.
	logic [33:0] mem [255:0];
	
	// Load the program - change the filename to pick a different program.
	initial begin
		$readmemb("bin_input.txt", mem);
	end

    always_comb begin
        op = mem[address][33:32];
        opA = mem[address][31:16];
        opB = mem[address][15:0];
    end
endmodule
