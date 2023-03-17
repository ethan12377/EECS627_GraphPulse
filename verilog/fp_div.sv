// fp_add takes 2 16-bit operands and outputs a 16-bit quotient as well as 
// underflow, overflow, inexact, and cout flags. 
module fp_div(
    input logic [15:0] opA, opB,
    output logic [15:0] quotient
);

// eB >= 5'b00001. Divider cannot handle subnormal denominator.
// In pagerank, we only divide by integers. So this divider is fine.

    logic sA, sB, sign;
    logic [4:0] eA, eB, biasedEDiff, finalE, shiftAmount;
    logic [4:0] eDiff;
    logic [5:0] normalizedE;
    logic [9:0] mA, mB, finalM, normalizedM;
    logic dbz;
    logic [20:0] mQuotient, r;
    logic eSub0, eNormal0;
    logic [10:0] fullmA, fullmB;
    logic [20:0] op1, op2;
    logic diffOverflow;
    
    logic implicit_one_opA, implicit_one_opB;
    // if exponent is zero, there is no implicit '1' for mantissa
    assign implicit_one_opA = (eA != 5'b00000);
    assign implicit_one_opB = (eB != 5'b00000);

    assign dbz = (opB == 16'd0);
    
    assign sA = opA[15];
    assign eA = opA[14:10];
    assign mA = opA[9:0];
    assign sB = opB[15];
    assign eB = opB[14:10];
    assign mB = opB[9:0];

    /////////////////////////////////////////////////////////
    // Divide mantissas
    // ------------------------------

    assign fullmA = {implicit_one_opA, mA};
    assign fullmB = {implicit_one_opB, mB};
    assign op1 = {fullmA, 10'b0000000000};
    assign op2 = {10'b0000000000, fullmB};
    // concatenate 0's to operands for fixed point division
    // 10 0's for 10 fractional bits
    assign mQuotient = op1 / op2;
    assign r = op1 % op2;

    /////////////////////////////////////////////////////////
    // Subtract exponents
    // ------------------------------
    logic [4:0] eA_adjusted, eB_adjusted;
    assign eA_adjusted = (eA == 5'b00000) ? 5'b00001 : eA;
    assign eB_adjusted = (eB == 5'b00000) ? 5'b00001 : eB;

    assign {diffOverflow, eDiff} = eA_adjusted - eB_adjusted;
    assign biasedEDiff = eDiff + 15;
    // exponent difference is too small
    assign eSub0 = ((diffOverflow) & (eDiff < 5'd18)) ? 1'b1 : 1'b0;
        
    /////////////////////////////////////////////////////////
    // Normalize
    // ------------------------------
    
    assign sign = sA ^ sB;
    always_comb begin
        casez(mQuotient)
            11'b1??????????: shiftAmount = 0;
            11'b01?????????: shiftAmount = 1;
            11'b001????????: shiftAmount = 2;
            11'b0001???????: shiftAmount = 3;
            11'b00001??????: shiftAmount = 4;
            11'b000001?????: shiftAmount = 5;
            11'b0000001????: shiftAmount = 6;
            11'b00000001???: shiftAmount = 7;
            11'b000000001??: shiftAmount = 8;
            11'b0000000001?: shiftAmount = 9;
            11'b00000000001: shiftAmount = 10;
            11'b00000000000: shiftAmount = 11;
            default: shiftAmount = 11;
        endcase
    end

    assign normalizedM = mQuotient << shiftAmount;
    assign normalizedE = biasedEDiff - shiftAmount;
    assign finalE = normalizedE[4:0];
    // exponent normalizes to 0
    assign eNormal0 = (finalE == 5'd0) ? 1'b1 : 1'b0;

    // handle overflow
    assign finalM = (finalE == 5'b11111) ? 8'd0 : normalizedM;

    assign quotient = {sign, finalE, finalM[9:0]};

endmodule
