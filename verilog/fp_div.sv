// fp_add takes 2 16-bit operands and outputs a 16-bit quotient
`define C_LONG_M_WIDTH 52 // extend to double precision (52-bit mantissa) for complete alignment with python calculation results

module fp_div(
    input logic [15:0] opA, opB,
    output logic [15:0] quotient
);

    logic sA, sB, sign;
    logic [4:0] eA, eB, finalE;
    logic signed [6:0] shiftAmount, biasedEDiff, normalizedE;
    logic [9:0] mA, mB, finalM, normalizedM;
    logic dbz;
    logic [`C_LONG_M_WIDTH-1:0] op1, op2, mQuotient_rounded, mQuotient_prerounding, normalizedM_convergent, normalizedM_prerounding, normalizedM_shifted, r;
    logic [10:0] fullmA, fullmB;
    
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
    assign op1 = {fullmA, {(`C_LONG_M_WIDTH-11){1'b0}}};
    assign op2 = {{(`C_LONG_M_WIDTH-11){1'b0}}, fullmB};
    // concatenate 0's to operands for fixed point division
    assign mQuotient_prerounding = op1 / op2;
    assign r = op1 % op2;

    logic round_amount;
    always_comb // round to nearest, ties to even
    begin
        if ((r + r) > op2) round_amount = 1;
        else if ((r + r) < op2) round_amount = 0;
        else round_amount = mQuotient_prerounding[0];
    end
    assign mQuotient_rounded = mQuotient_prerounding + round_amount;

    /////////////////////////////////////////////////////////
    // Subtract exponents
    // ------------------------------
    logic [4:0] eA_adjusted, eB_adjusted;
    assign eA_adjusted = (eA == 5'b00000) ? 5'b00001 : eA;
    assign eB_adjusted = (eB == 5'b00000) ? 5'b00001 : eB;

    assign biasedEDiff = eA_adjusted - eB_adjusted + 15;
        
    /////////////////////////////////////////////////////////
    // Normalize
    // ------------------------------
    
    assign sign = sA ^ sB;
    logic firstOneNotFound;
    always_comb begin
        firstOneNotFound = 1'b1;
        shiftAmount = 0;
        for (integer i = 0; i < `C_LONG_M_WIDTH; i = i + 1)
        begin
            if (mQuotient_rounded[`C_LONG_M_WIDTH-1-i]) firstOneNotFound = 1'b0;
            shiftAmount = shiftAmount + firstOneNotFound;
        end
    end

    assign normalizedE = biasedEDiff - shiftAmount + 10;
    // shift mantissa to the right to compensate for insufficient exponent
    assign normalizedM_shifted = mQuotient_rounded << shiftAmount;
    
    always_comb
    begin
        if (normalizedE <= 0) // shift mantissa to the right to compensate for insufficient exponent
        begin
            finalE = 5'b00000;
            normalizedM_prerounding = normalizedM_shifted >> (1 - normalizedE);
        end
        else if (normalizedE > 30) // overflow
        begin
            finalE = 5'b11111;
            normalizedM_prerounding = '0;
        end
        else
        begin
            finalE = normalizedE[4:0];
            normalizedM_prerounding = normalizedM_shifted;
        end
    end

    // Rounding
    assign normalizedM_convergent = normalizedM_prerounding[(`C_LONG_M_WIDTH-1):0] // first bit is hidden
                + { {(11){1'b0}},
                    normalizedM_prerounding[(`C_LONG_M_WIDTH-11)],
                    {(`C_LONG_M_WIDTH-11-1){!normalizedM_prerounding[(`C_LONG_M_WIDTH-11)]}}};
    assign normalizedM = normalizedM_convergent[`C_LONG_M_WIDTH-2:`C_LONG_M_WIDTH-2-9];
    assign quotient = {sign, finalE, normalizedM};

endmodule
