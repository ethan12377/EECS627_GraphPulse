// fp_add takes 2 16-bit operands and outputs a 16-bit product as well as 
// underflow, overflow, inexact, and cout flags. 
module fp_mul(
    input logic [15:0] opA, opB,
    output logic [15:0] product
);

    logic sA, sB;
    logic [4:0] eA, eB;
    logic [9:0] mA, mB;

    logic [21:0] mProduct;
    logic [22:0] normalP; // can be shifted by one to compensate for m overflow
    logic [36:0] mProduct_extended, mProduct_rounded, finalP, finalP_convergent; // can be shifted to the right by 14 bits at most to compensate for E
    logic signed [6:0] eSum, biasedESum, normalE, shiftAmount;
    logic [4:0] finalE, finalE_compensated;
    logic sign, cout, eAddOverflow, eNormalOverflow;
    
    assign sA = opA[15];
    assign eA = opA[14:10];
    assign mA = opA[9:0];
    assign sB = opB[15];
    assign eB = opB[14:10];
    assign mB = opB[9:0];
    
    logic implicit_one_opA, implicit_one_opB;
    // if exponent is zero, there is no implicit '1' for mantissa
    assign implicit_one_opA = (eA != 5'b00000);
    assign implicit_one_opB = (eB != 5'b00000);

    /////////////////////////////////////////////////////////
    // Multiply mantissas
    // ------------------------------

    assign mProduct = {implicit_one_opA, mA} * {implicit_one_opB, mB};
    // extend before rounding to ensure uniform rounding
    assign mProduct_extended = {mProduct, 15'b0};
    // need to round once here to determine normalization
    assign mProduct_rounded = mProduct_extended[(37-1):0]
                + { {(12){1'b0}},
                    mProduct_extended[(37-12)],
                    {(37-12-1){!mProduct_extended[(37-12)]}}};

    /////////////////////////////////////////////////////////
    // Add exponents
    // ------------------------------
    logic [4:0] eA_adjusted, eB_adjusted;
    assign eA_adjusted = (eA == 5'b00000) ? 5'b00001 : eA;
    assign eB_adjusted = (eB == 5'b00000) ? 5'b00001 : eB;

    assign eSum = eA_adjusted + eB_adjusted;
    assign {cout, biasedESum} = eSum - 15;
    // assign eAddOverflow = (cout | (biasedESum == 5'b10101)) ? 1'b1 : 1'b0;

    /////////////////////////////////////////////////////////
    // Normalize
    // ------------------------------

    logic firstOneNotFound;
    always_comb
    begin
        firstOneNotFound = 1'b1;
        shiftAmount = 0;
        if (mProduct_rounded[36]) // overflow on mantissa. add 1 to E to compensate
        begin
            normalP = {1'b0, mProduct};
            normalE = biasedESum + 1;
        end
        else if (mProduct_rounded[36:35] == 2'b00) // mantissa needs to be shifted to the left to be normalized
        begin
            for (integer i = 0; i < 36; i = i + 1)
            begin
                if (mProduct_rounded[35-i]) firstOneNotFound = 1'b0;
                shiftAmount = shiftAmount + firstOneNotFound;
            end
            normalP = {mProduct, 1'b0} << shiftAmount;
            normalE = biasedESum - shiftAmount;
        end
        else
        begin
            normalP = {mProduct, 1'b0};
            normalE = biasedESum;
        end
    end

    always_comb
    begin
        if (normalE <= 0) // shift mantissa to the right to compensate for insufficient exponent
        begin
            finalE = 5'b00000;
            finalP = {normalP, 14'b0} >> (1 - normalE); 
        end
        else if (normalE > 30) // overflow
        begin
            finalE = 5'b11111;
            finalP = '0;
        end
        else
        begin
            finalE = normalE[4:0];
            finalP = {normalP, 14'b0};
        end
    end

    
    // assign eNormalOverflow = (normalE == 5'b10101);
    // assign finalE = (eAddOverflow | eNormalOverflow) ? 5'd31 : normalE;
    // assign finalP = (eAddOverflow | eNormalOverflow) ? '0 : normalP;
    assign sign = sA ^ sB;

    assign finalP_convergent = finalP[(37-1):0]
                + { {(12){1'b0}},
                    finalP[(37-12)],
                    {(37-12-1){!finalP[(37-12)]}}};
    
    assign finalE_compensated = finalE - 1;
    
    // TODO: compensate when MSB of two roundings are not in the same position
    always_comb
    begin
        if (finalE != 5'b00000 && finalE != 5'b11111 && ~finalP_convergent[35]) product = {sign, finalE_compensated, (finalP_convergent[33:24])}; // compensate, hidden bit needs to be 1 when finalE is normal
        else product = {sign, finalE, (finalP_convergent[34:25])}; // ignore overflow and hidden bits
    end
endmodule

