// fp_add takes 2 16-bit operands and outputs a 16-bit sum

module fp_add(
    input logic [15:0] opA, opB,
    output logic [15:0] sum
);

    logic sA, sB, cout;
    logic [4:0] eA, eB;
    logic [9:0] mA, mB;
    
    logic [4:0] diffE, absDiffE;
    logic [10:0] shiftInput;
    logic [39:0] shiftOutput, op2;
    logic subtract;

    logic [39:0] mSum_long, mSum_convergent, sumM_long, sumM_shifted, sumM_convergent, diffM, absDiffM;

    logic finalS;
    logic signed [6:0] sumE, bigE, addShiftAmount, subShiftAmount;
    logic [4:0] finalE;
    logic [10:0] sumM;

    logic implicit_one_opA, implicit_one_opB;
     
    /////////////////////////////////////////////////////////
    // Match exponents
    // ------------------------------
    
    assign sA = opA[15];
    assign eA = opA[14:10];
    assign mA = opA[9:0];
    assign sB = opB[15];
    assign eB = opB[14:10];
    assign mB = opB[9:0];

    // if exponent is zero, there is no implicit '1' for mantissa
    assign implicit_one_opA = (eA != 5'b00000);
    assign implicit_one_opB = (eB != 5'b00000);

    // subtract exponents
    logic [4:0] eA_adjusted, eB_adjusted;
    assign eA_adjusted = (eA == 5'b00000) ? 5'b00001 : eA;
    assign eB_adjusted = (eB == 5'b00000) ? 5'b00001 : eB;
    assign diffE = eA_adjusted - eB_adjusted;
    assign absDiffE = (eA_adjusted < eB_adjusted) ? eB_adjusted - eA_adjusted : eA_adjusted - eB_adjusted;
    // choose the mantissa with the smaller exponent to be shifted
    assign shiftInput = (eA_adjusted < eB_adjusted) ? {implicit_one_opA, mA} : {implicit_one_opB, mB};
    assign op2 = (eA_adjusted < eB_adjusted) ? {implicit_one_opB, mB, 29'b0} : {implicit_one_opA, mA, 29'b0};
    assign shiftOutput = {shiftInput, 29'b0} >> absDiffE;
    
    assign subtract = sA ^ sB;
    assign bigE = (eA_adjusted < eB_adjusted) ? eB : eA;

    /////////////////////////////////////////////////////////
    // Add mantissas
    // ------------------------------
    assign diffM = op2 - shiftOutput;
    assign absDiffM = (op2 < shiftOutput) ? ~diffM+1 : diffM; 
    assign {cout, mSum_long} = subtract ? (absDiffM) : (op2 + shiftOutput);
    
    /////////////////////////////////////////////////////////
    // Normalize & set flags 
    // ------------------------------

    // determine sign of result
    always_comb begin
        if (subtract) begin
            if (eA == eB) begin
                if (mA > mB)
                    finalS = sA;
                else
                    finalS = sB;
            end else begin
                if (eA > eB)
                    finalS = sA;
                else 
                    finalS = sB;
            end
        end else begin
            finalS = sA;
        end
    end

    // determine shift amount needed on mantissa for subtraction/addition
    logic firstOneNotFound;
    always_comb begin
        firstOneNotFound = 1'b1;
        subShiftAmount = 0;
        for (integer i = 0; i < 40; i = i + 1)
        begin
            if (mSum_long[39-i]) firstOneNotFound = 1'b0;
            subShiftAmount = subShiftAmount + firstOneNotFound;
        end
        case(cout)
            1'b1: addShiftAmount = 1;
            1'b0: addShiftAmount = 0;
        endcase
    end

    // calculate E with the determined shift amount
    assign sumE = subtract ? (bigE - subShiftAmount) : (bigE + addShiftAmount);
    assign sumM_shifted = subtract ? (mSum_long << subShiftAmount) : (mSum_long >> addShiftAmount);

    // calculate special cases
    always_comb
    begin
        if (sumE <= 0) // shift mantissa to the right to compensate for insufficient exponent
        begin
            finalE = 5'b00000;
            sumM_long = sumM_shifted >> (1 - sumE);
        end
        else if (sumE > 30) // overflow
        begin
            finalE = 5'b11111;
            sumM_long = '0;
        end
        else
        begin
            finalE = sumE[4:0];
            sumM_long = sumM_shifted;
        end
    end

    // Round sumM with "round half to even", 40-bit mSum_long to 11-bit mSum
    assign sumM_convergent = sumM_long[39:0]
                + { {(11){1'b0}},
                    sumM_long[(40-11)],
                    {(40-11-1){!sumM_long[(40-11)]}}};
    assign sumM = sumM_convergent[39:29];

    // assemble final output
    always_comb begin
        if(subtract & (opA[14:0]==opB[14:0]) & (opA[15] != opB[15])) sum = 16'b0000000000000000;
        else sum = {finalS, finalE, sumM[9:0]};
    end
endmodule 
