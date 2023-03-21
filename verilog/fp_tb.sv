module fp_tb;

    logic [15:0] opA, opB, sum, diff, product, quotient;

    fpu_comb dut (.*);

    task calculate;
        input [15:0] opA_val, opB_val;
        opA = opA_val; opB = opB_val;
        #10;
        $display("opA = %h  opB = %h  add = %h  sub = %h  mul = %h  div = %h\n", opA, opB, sum, diff, product, quotient);
    endtask

    integer fi, fo;
    initial begin
        calculate(16'h07ff, 16'h0001);
        fi = $fopen("fp_rand_ops.txt", "r");
        fo = $fopen("fp_results_verilog.txt", "w");
        while ($fscanf(fi, "%h %h", opA, opB) == 2)
        begin
            #10;
            $fdisplay(fo, "opA = %h  opB = %h  add = %h  sub = %h  mul = %h  div = %h", opA, opB, sum, diff, product, quotient);
        end
        $fclose(fi);
        $fclose(fo);
        $finish;
    end


endmodule
