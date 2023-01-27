// fp_add takes 2 16-bit operands and outputs a 16-bit product as well as 
// underflow, overflow, inexact, and cout flags. 
module fp_mul(
    input logic [15:0] opA, opB,
    output logic [15:0] product,
    output logic underflow, overflow, inexact
    );

    logic sA, sB;
    logic [7:0] eA, eB;
    logic [6:0] mA, mB;

    logic [15:0] mProduct, normalP, finalP;
    logic [10:0] eSum; // should just be 8:0?
    logic [7:0] biasedESum, normalE, finalE;
    logic sign, cout, eAddOverflow, eNormalOverflow;
    
    assign sA = opA[15];
    assign eA = opA[14:7];
    assign mA = opA[6:0];
    assign sB = opB[15];
    assign eB = opB[14:7];
    assign mB = opB[6:0];
    
    /////////////////////////////////////////////////////////
    // Multiply mantissas
    // ------------------------------

    assign mProduct = {1'b1, mA} * {1'b1, mB};

    /////////////////////////////////////////////////////////
    // Add exponents
    // ------------------------------
    assign eSum = eA + eB;
    assign {cout, biasedESum} = eSum - 127;
    assign eAddOverflow = (cout | (biasedESum == 8'b11111111)) ? 1'b1 : 1'b0;

    /////////////////////////////////////////////////////////
    // Normalize
    // ------------------------------

    assign normalP = mProduct[15] ? mProduct >> 1 : mProduct;
    assign normalE = mProduct[15] ? biasedESum + 1 : biasedESum;
    assign eNormalOverflow = (normalE == 8'b11111111);
    assign finalE = (eAddOverflow | eNormalOverflow) ? 8'd255 : normalE;
    assign finalP = (eAddOverflow | eNormalOverflow) ? 8'd0 : normalP;
    assign sign = sA ^ sB;

    assign product = {sign, finalE, finalP[13:7]}; // 15=overflow, 14=hidden
    assign overflow = (eAddOverflow | eNormalOverflow);
    assign inexact = |normalP[7:0];
    assign underflow = 1'b0;

endmodule

