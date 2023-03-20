module tb_fp_add;

    // Inputs
    logic [15:0] opA, opB;
    
    // Outputs
    logic [15:0] sum;
    
    // Instantiate the module
    fp_add dut(
        .opA(opA),
        .opB(opB),
        .sum(sum)
    );
    
    // Stimulus
    initial begin
        opA = 16'h22fc; 
        opB = 16'h37dc;  
        #10;
        $display("opA = %h, opB = %h, sum = %h", opA, opB, sum,"   expected output: 380a");
        
        opA = 16'h39e3;  
        opB = 16'h3b38;  
        #10;
        $display("opA = %h, opB = %h, sum = %h", opA, opB, sum,"   expected output: 3e8e");
        
        opA = 16'b0111111111000000;  
        opB = 16'b0100000001000000; 
        #10;
        $display("opA = %h, opB = %h, sum = %h", opA, opB, sum);
        
        opA = 16'b0111110000000000;  
        opB = 16'b0100000001000000; 
        #10;
        $display("opA = %h, opB = %h, sum = %h", opA, opB, sum);
    end
    
endmodule
