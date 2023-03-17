module fp_tb;

    logic [15:0] opA, opB, addsub_result, mul_result, div_result;

    fp_add fpadd (.opA(opA), .opB(opB), .sum(addsub_result));

    fp_mul fpmul (.opA(opA), .opB(opB), .product(mul_result));

    fp_div fpdiv (.opA(opA), .opB(opB), .quotient(div_result));

    initial begin
        opA = 16'h22fc; opB = 16'h37dc;
        #10;
        $display("opA = %h\t opB = %h\t addsub = %h\t mul = %h\t div = %h\t", opA, opB, addsub_result, mul_result, div_result);
        opA = 16'h39e3; opB = 16'h3b38;
        #10;
        $display("opA = %h\t opB = %h\t addsub = %h\t mul = %h\t div = %h\t", opA, opB, addsub_result, mul_result, div_result);
        $finish;
    end


endmodule
