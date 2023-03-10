// fp_add takes 2 16-bit operands and outputs a 16-bit sum has well as 
// underflow, overflow, inexact, and cout flags. 
module fp_add(
    input logic [15:0] opA, opB,
    output logic [15:0] sum,
    output logic underflow, overflow, inexact, cout
    );

    logic sA, sB;
    logic [4:0] eA, eB;
    logic [9:0] mA, mB;
    
    logic [4:0] diffE, absDiffE;
    logic [10:0] shiftInput, shiftOutput, op2;
    logic sticky, sticky2, subtract;

    logic [10:0] mSum, diffM, absDiffM;
    logic selBigE;

    logic finalS;
    logic [4:0] bigE, sumE, finalE, addShiftAmount, subShiftAmount;
    logic [10:0] sumM, finalM;
     
    /////////////////////////////////////////////////////////
    // Match exponents
    // ------------------------------
    
    assign sA = opA[15];
    assign eA = opA[14:10];
    assign mA = opA[9:0];
    assign sB = opB[15];
    assign eB = opB[14:10];
    assign mB = opB[9:0];

    // subtract exponents
    assign diffE = eA - eB;
    assign absDiffE = diffE[4] ? ~diffE+1 : diffE;

    // select operand w/ smaller exponent to shift mantissa to the right
    assign shiftInput = diffE[4] ? {1'b1, mA} : {1'b1, mB};
    
    always_comb begin
        casez(absDiffE)
            5'd0: sticky = 1'b0;
            5'd1: sticky = |shiftInput[0];
            5'd2: sticky = |shiftInput[1:0];
            5'd3: sticky = |shiftInput[2:0];
            5'd4: sticky = |shiftInput[3:0];
            default: sticky = |shiftInput;
        endcase
    end
    
    assign subtract = sA ^ sB;
    
    assign shiftOutput = shiftInput >> absDiffE;
    assign op2 = diffE[4] ? {1'b1, mB} : {1'b1, mA};
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
    assign sticky2 = cout & mSum[0];

    // Handle special cases
    assign finalM = (sumE == 5'b11111) ? 10'd0 : sumM;
    assign finalE = sumE;
    always_comb begin
        if(subtract & (opA[14:0]==opB[14:0]) & (opA[15] != opB[15])) sum = 16'b0000000000000000;
        else sum = {finalS, finalE, finalM[9:0]};
    end
    assign overflow = (sumE == 5'b11111) ? 1'b1 : 1'b0;
    assign underflow = (finalE == 5'd0 & sticky) ? 1'b1 : 1'b0;
    assign inexact = sticky | sticky2;
endmodule 
