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
    logic [5:0] eSum; // should just be 8:0?
    logic [4:0] biasedESum, normalE, finalE;
    logic sign, cout, eAddOverflow, eNormalOverflow;
    
    assign sA = opA[15];
    assign eA = opA[14:10];
    assign mA = opA[9:0];
    assign sB = opB[15];
    assign eB = opB[14:10];
    assign mB = opB[9:0];
    
    /////////////////////////////////////////////////////////
    // Multiply mantissas
    // ------------------------------

    assign mProduct = {1'b1, mA} * {1'b1, mB};

    /////////////////////////////////////////////////////////
    // Add exponents
    // ------------------------------
    assign eSum = eA + eB;
    assign {cout, biasedESum} = eSum - 15;
    assign eAddOverflow = (cout | (biasedESum == 5'b11111)) ? 1'b1 : 1'b0;

    /////////////////////////////////////////////////////////
    // Normalize
    // ------------------------------

    assign normalP = mProduct[15] ? mProduct >> 1 : mProduct;
    assign normalE = mProduct[15] ? biasedESum + 1 : biasedESum;
    assign eNormalOverflow = (normalE == 5'b11111);
    assign finalE = (eAddOverflow | eNormalOverflow) ? 5'd31 : normalE;
    assign finalP = (eAddOverflow | eNormalOverflow) ? 5'd0 : normalP;
    assign sign = sA ^ sB;

    assign product = {sign, finalE, finalP[19:10]}; // 15=overflow, 14=hidden

endmodule

