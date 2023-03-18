module fp_tb;

    logic [15:0] opA, opB, sum, diff, product, quotient;

    fpu_comb dut (.*);

    task calculate;
        input [15:0] opA_val, opB_val;
        opA = opA_val; opB = opB_val;
        #10;
        $display("opA = %h\t opB = %h\t add = %h\t sub = %h\t mul = %h\t div = %h\t", opA, opB, sum, diff, product, quotient);
    endtask

    initial begin
        calculate(16'h22fc, 16'h37dc);
        calculate(16'h39e3, 16'h3b38);
        $finish;
    end


endmodule
