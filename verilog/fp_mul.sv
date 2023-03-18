// fp_add takes 2 16-bit operands and outputs a 16-bit product as well as 
// underflow, overflow, inexact, and cout flags. 
module fp_mul(
    input logic [15:0] opA, opB,
    output logic [15:0] product
);

    logic sA, sB;
    logic [4:0] eA, eB;
    logic [9:0] mA, mB;

    logic [21:0] mProduct, normalP, finalP;
    logic [19:0] finalP_convergent; // omits overflow and hidden bits
    logic [5:0] eSum; // should just be 8:0?
    logic [4:0] biasedESum, normalE, finalE;
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

    /////////////////////////////////////////////////////////
    // Add exponents
    // ------------------------------
    logic [4:0] eA_adjusted, eB_adjusted;
    assign eA_adjusted = (eA == 5'b00000) ? 5'b00001 : eA;
    assign eB_adjusted = (eB == 5'b00000) ? 5'b00001 : eB;

    assign eSum = eA + eB;
    assign {cout, biasedESum} = eSum - 15;
    assign eAddOverflow = (cout | (biasedESum == 5'b10101)) ? 1'b1 : 1'b0;

    /////////////////////////////////////////////////////////
    // Normalize
    // ------------------------------

    assign normalP = mProduct[21] ? mProduct >> 1 : mProduct;
    assign normalE = mProduct[21] ? biasedESum + 1 : biasedESum;
    assign eNormalOverflow = (normalE == 5'b10101);
    assign finalE = (eAddOverflow | eNormalOverflow) ? 5'd31 : normalE;
    assign finalP = (eAddOverflow | eNormalOverflow) ? '0 : normalP;
    assign sign = sA ^ sB;

    assign finalP_convergent = finalP[(20-1):0]
                + { {(10){1'b0}},
                    finalP[(20-10)],
                    {(20-10-1){!finalP[(20-10)]}}};

    assign product = {sign, finalE, (finalP_convergent[19:10])}; // 21=overflow, 20=hidden

endmodule

