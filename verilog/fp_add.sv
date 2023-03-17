// fp_add takes 2 16-bit operands and outputs a 16-bit sum has well as 
// underflow, overflow, inexact, and cout flags. 
module fp_add(
    input logic [15:0] opA, opB,
    output logic [15:0] sum
);

    logic sA, sB, cout;
    logic [4:0] eA, eB;
    logic [9:0] mA, mB;
    
    logic [4:0] diffE, absDiffE;
    logic [10:0] shiftInput, shiftOutput, op2;
    logic subtract;

    logic [10:0] mSum, diffM, absDiffM;
    logic selBigE;

    logic finalS;
    logic [4:0] bigE, sumE, finalE, addShiftAmount, subShiftAmount;
    logic [10:0] sumM, finalM;

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
    always_comb
    begin
        if (((eA == 5'b00001) || (eA == 5'b00000)) && ((eB == 5'b00001 || eB == 5'b00000))) diffE = 5'b00000; // 5'b00001 and 5'b00000 both represents exponent of -14
        else diffE = eA - eB;
    end
    assign absDiffE = diffE[4] ? ~diffE+1 : diffE;

    // select operand w/ smaller exponent to shift mantissa to the right
    assign shiftInput = diffE[4] ? {implicit_one_opA, mA} : {implicit_one_opB, mB};
    
    assign subtract = sA ^ sB;
    
    assign shiftOutput = shiftInput >> absDiffE;
    assign op2 = diffE[4] ? {implicit_one_opB, mB} : {implicit_one_opA, mA};
    assign selBigE = diffE[4];

    
    /////////////////////////////////////////////////////////
    // Add mantissas
    // ------------------------------
    assign diffM = op2 - shiftOutput;
    assign absDiffM = (op2 < shiftOutput) ? ~diffM+1 : diffM; 
    assign {cout, mSum} = subtract ? (absDiffM) : 
                                    (op2 + shiftOutput);
    
    /////////////////////////////////////////////////////////
    // Normalize & set flags 
    // ------------------------------

    // Normalize
    // assign finalS = (subtract & selBigE) ? sB : sA;
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

    assign bigE = selBigE ? eB : eA;
    always_comb begin
        casez(mSum)
            11'b1??????????: subShiftAmount = 0;
            11'b01?????????: subShiftAmount = 1;
            11'b001????????: subShiftAmount = 2;
            11'b0001???????: subShiftAmount = 3;
            11'b00001??????: subShiftAmount = 4;
            11'b000001?????: subShiftAmount = 5;
            11'b0000001????: subShiftAmount = 6;
            11'b00000001???: subShiftAmount = 7;
            11'b000000001??: subShiftAmount = 8;
            11'b0000000001?: subShiftAmount = 9;
            11'b00000000001: subShiftAmount = 10;
            11'b00000000000: subShiftAmount = 11;
            default: subShiftAmount = 11;
        endcase
        case(cout)
            1'b1: addShiftAmount = 10'd1;
            1'b0: addShiftAmount = 10'd0;
        endcase
    end

    assign sumE = subtract ? (bigE - subShiftAmount) : (bigE + addShiftAmount);
    assign sumM = subtract ? (mSum << subShiftAmount) : 
                             (mSum >> addShiftAmount);

    // Handle special cases
    assign finalM = (sumE == 5'b11111) ? 10'd0 : sumM;
    assign finalE = sumE;
    always_comb begin
        if(subtract & (opA[14:0]==opB[14:0]) & (opA[15] != opB[15])) sum = 16'b0000000000000000;
        else sum = {finalS, finalE, finalM[9:0]};
    end
endmodule 
