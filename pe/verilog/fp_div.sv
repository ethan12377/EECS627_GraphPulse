// fp_add takes 2 16-bit operands and outputs a 16-bit quotient as well as 
// underflow, overflow, inexact, and cout flags. 
module fp_div(
    input logic [15:0] opA, opB,
    output logic [15:0] quotient,
    output logic underflow, overflow, inexact
    );

    logic sA, sB, sign;
    logic [7:0] eA, eB, biasedEDiff, finalE;
    logic [7:0] eDiff;
    logic [8:0] normalizedE;
    logic [6:0] mA, mB, finalM, normalizedM;
    logic dbz, ovf;
    logic [7:0] mQuotient, r, shiftAmount;
    logic sticky, eSub0, eNormal0;
    logic [7:0] fullmA, fullmB;
    logic [14:0] op1, op2;
    logic diffOverflow;
    
    assign dbz = (opB == 16'd0);
    
    assign sA = opA[15];
    assign eA = opA[14:7];
    assign mA = opA[6:0];
    assign sB = opB[15];
    assign eB = opB[14:7];
    assign mB = opB[6:0];

    /////////////////////////////////////////////////////////
    // Divide mantissas
    // ------------------------------

    assign fullmA = {1'b1, mA};
    assign fullmB = {1'b1, mB};
    assign op1 = {fullmA, 7'b0000000};
    assign op2 = {7'b0000000, fullmB};
    // concatenate 0's to operands for fixed point division
    // 7 0's for 7 fractional bits
    assign mQuotient = op1 / op2;
    assign r = op1 % op2;

    /////////////////////////////////////////////////////////
    // Subtract exponents
    // ------------------------------

    assign {diffOverflow, eDiff} = eA - eB;
    assign biasedEDiff = eDiff + 127;
    // exponent difference is too small
    assign eSub0 = ((diffOverflow) & (eDiff < 8'd130)) ? 1'b1 : 1'b0;
        
    /////////////////////////////////////////////////////////
    // Normalize
    // ------------------------------
    
    assign sign = sA ^ sB;
    always_comb begin
        casez(mQuotient)
            8'b1???????: shiftAmount = 0;
            8'b01??????: shiftAmount = 1;
            8'b001?????: shiftAmount = 2;
            8'b0001????: shiftAmount = 3;
            8'b00001???: shiftAmount = 4;
            8'b000001??: shiftAmount = 5;
            8'b0000001?: shiftAmount = 6;
            8'b00000001: shiftAmount = 7;
            8'b00000000: shiftAmount = 8;
            default: shiftAmount = 10;
        endcase
    end

    assign normalizedM = mQuotient << shiftAmount;
    assign normalizedE = biasedEDiff - shiftAmount;
    assign finalE = normalizedE[7:0];
    // exponent normalizes to 0
    assign eNormal0 = (finalE == 8'd0) ? 1'b1 : 1'b0;
    assign sticky = (r != 8'd0);

    // handle overflow
    assign finalM = (finalE == 8'b11111111) ? 8'd0 : normalizedM;
    assign ovf = (finalE == 8'b11111111) ? 1'b1 : 1'b0;

    assign quotient = {sign, finalE, finalM[6:0]};
    assign overflow = ovf;
    assign inexact = sticky;
    // google says underflow needs sticky flag true too, but
    // that's not necessarily true if quotient is too small
    assign underflow = (eSub0 | eNormal0);

endmodule
