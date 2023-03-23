/////////////////////////////////////////////////////////////////////////
//                                                                     //
//  Modulename  :  int16_to_float16.sv                                 //
//                                                                     //
//  Description :  convert an input from int16 to float16 format       // 
//                                                                     //
/////////////////////////////////////////////////////////////////////////

// this module assumes that int16 is unsigned

module int16_to_float16 (
    input   logic [15:0] int16_i,
    output  logic [15:0] float16_o
);

// ====================================================================
// Local Parameters Declarations Start
// ====================================================================

// ====================================================================
// Local Parameters Declarations End
// ====================================================================

// ====================================================================
// Signal Declarations Start
// ====================================================================
    logic sign;
    logic [4:0] exponent;
    logic [9:0] mantissa;

// ====================================================================
// Signal Declarations End
// ====================================================================

// ====================================================================
// Module Instantiations Start
// ====================================================================

// ====================================================================
// Module Instantiations End
// ====================================================================

// ====================================================================
// RTL Logic Start
// ====================================================================
    assign sign = 1'b0; // unsigned integer is always positive
    assign float16_o = {sign, exponent, mantissa};
    always_comb
    begin
        casez (int16_i)
            16'b1???_????_????_????: begin
                exponent = 5'd30;
                mantissa = int16_i[14:5];
            end
            16'b01??_????_????_????: begin
                exponent = 5'd29;
                mantissa = int16_i[13:4];
            end
            16'b001?_????_????_????: begin
                exponent = 5'd28;
                mantissa = int16_i[12:3];
            end
            16'b0001_????_????_????: begin
                exponent = 5'd27;
                mantissa = int16_i[11:2];
            end
            16'b0000_1???_????_????: begin
                exponent = 5'd26;
                mantissa = int16_i[10:1];
            end
            16'b0000_01??_????_????: begin
                exponent = 5'd25;
                mantissa = int16_i[9:0];
            end
            16'b0000_001?_????_????: begin
                exponent = 5'd24;
                mantissa = {int16_i[8:0], 1'b0};
            end
            16'b0000_0001_????_????: begin
                exponent = 5'd23;
                mantissa = {int16_i[7:0], 2'b0};
            end
            16'b0000_0000_1???_????: begin
                exponent = 5'd22;
                mantissa = {int16_i[6:0], 3'b0};
            end
            16'b0000_0000_01??_????: begin
                exponent = 5'd21;
                mantissa = {int16_i[5:0], 4'b0};
            end
            16'b0000_0000_001?_????: begin
                exponent = 5'd20;
                mantissa = {int16_i[4:0], 5'b0};
            end
            16'b0000_0000_0001_????: begin
                exponent = 5'd19;
                mantissa = {int16_i[3:0], 6'b0};
            end
            16'b0000_0000_0000_1???: begin
                exponent = 5'd18;
                mantissa = {int16_i[2:0], 7'b0};
            end
            16'b0000_0000_0000_01??: begin
                exponent = 5'd17;
                mantissa = {int16_i[1:0], 8'b0};
            end
            16'b0000_0000_0000_001?: begin
                exponent = 5'd16;
                mantissa = {int16_i[0], 9'b0};
            end
            16'b0000_0000_0000_0001: begin
                exponent = 5'd15;
                mantissa = 10'b0;
            end
            default: begin // int16 = 0
                exponent = '0;
                mantissa = '0;
            end
        endcase
    end

// ====================================================================
// RTL Logic End
// ====================================================================


endmodule
