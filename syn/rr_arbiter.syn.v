/////////////////////////////////////////////////////////////
// Created by: Synopsys DC Expert(TM) in wire load mode
// Version   : T-2022.03-SP3
// Date      : Tue Mar 21 17:47:18 2023
/////////////////////////////////////////////////////////////


module priority_arbiter_1 ( req_i, grant_o, valid_o );
  input [7:0] req_i;
  output [2:0] grant_o;
  output valid_o;
  wire   n1, n2, n3, n4, n5, n6, n7, n8, n9, n10, n11, n12;

  OAI21X1TR U3 ( .A0(req_i[4]), .A1(n12), .B0(n2), .Y(n11) );
  CLKINVX2TR U4 ( .A(req_i[3]), .Y(n2) );
  AOI21X1TR U5 ( .A0(req_i[7]), .A1(n1), .B0(req_i[5]), .Y(n12) );
  CLKINVX2TR U6 ( .A(req_i[6]), .Y(n1) );
  OAI31X1TR U7 ( .A0(req_i[4]), .A1(req_i[5]), .A2(n7), .B0(n9), .Y(n8) );
  NOR2X1TR U8 ( .A(req_i[2]), .B(req_i[3]), .Y(n9) );
  NOR2X1TR U9 ( .A(req_i[7]), .B(req_i[6]), .Y(n7) );
  CLKINVX2TR U10 ( .A(req_i[2]), .Y(n3) );
  NOR3BX1TR U11 ( .AN(n7), .B(req_i[4]), .C(req_i[5]), .Y(n4) );
  NAND3BX1TR U12 ( .AN(req_i[0]), .B(n4), .C(n5), .Y(valid_o) );
  NOR3X1TR U13 ( .A(req_i[1]), .B(req_i[3]), .C(req_i[2]), .Y(n5) );
  OR3X1TR U14 ( .A(req_i[1]), .B(req_i[2]), .C(req_i[3]), .Y(n6) );
  NOR3BX1TR U15 ( .AN(n8), .B(req_i[1]), .C(req_i[0]), .Y(grant_o[1]) );
  NOR2X1TR U16 ( .A(req_i[0]), .B(n10), .Y(grant_o[0]) );
  AOI21X1TR U17 ( .A0(n11), .A1(n3), .B0(req_i[1]), .Y(n10) );
  NOR3X1TR U18 ( .A(n6), .B(req_i[0]), .C(n4), .Y(grant_o[2]) );
endmodule


module priority_arbiter_0 ( req_i, grant_o, valid_o );
  input [7:0] req_i;
  output [2:0] grant_o;
  output valid_o;
  wire   n13, n14, n15, n16, n17, n18, n19, n20, n21, n22, n23, n24;

  NOR3BX1TR U3 ( .AN(n17), .B(req_i[1]), .C(req_i[0]), .Y(grant_o[1]) );
  OAI31X1TR U4 ( .A0(req_i[4]), .A1(req_i[5]), .A2(n18), .B0(n16), .Y(n17) );
  NOR3BX1TR U5 ( .AN(n18), .B(req_i[4]), .C(req_i[5]), .Y(n21) );
  NAND3BX1TR U6 ( .AN(req_i[0]), .B(n21), .C(n20), .Y(valid_o) );
  NOR3X1TR U7 ( .A(req_i[1]), .B(req_i[3]), .C(req_i[2]), .Y(n20) );
  NOR2X1TR U8 ( .A(req_i[7]), .B(req_i[6]), .Y(n18) );
  NOR2X1TR U9 ( .A(req_i[0]), .B(n15), .Y(grant_o[0]) );
  AOI21X1TR U10 ( .A0(n14), .A1(n22), .B0(req_i[1]), .Y(n15) );
  CLKINVX2TR U11 ( .A(req_i[2]), .Y(n22) );
  OAI21X1TR U12 ( .A0(req_i[4]), .A1(n13), .B0(n23), .Y(n14) );
  CLKINVX2TR U13 ( .A(req_i[3]), .Y(n23) );
  AOI21X1TR U14 ( .A0(req_i[7]), .A1(n24), .B0(req_i[5]), .Y(n13) );
  CLKINVX2TR U15 ( .A(req_i[6]), .Y(n24) );
  NOR3X1TR U16 ( .A(n19), .B(req_i[0]), .C(n21), .Y(grant_o[2]) );
  OR3X1TR U17 ( .A(req_i[1]), .B(req_i[2]), .C(req_i[3]), .Y(n19) );
  NOR2X1TR U18 ( .A(req_i[2]), .B(req_i[3]), .Y(n16) );
endmodule


module rr_arbiter ( clk_i, rst_i, en_i, ack_i, req_i, grant_o, grant_onehot_o, 
        valid_o, mask_o );
  input [7:0] req_i;
  output [2:0] grant_o;
  output [7:0] grant_onehot_o;
  output [7:0] mask_o;
  input clk_i, rst_i, en_i, ack_i;
  output valid_o;
  wire   valid_unmasked, valid_masked, n18, n19, n20, n21, n22, n23, n24, n25,
         n26, n27, n28, n29, n30, n31, n32, n33, n34, n35, n36, n37, n38, n39,
         n40, n41, n42, n43, n44, n45, n46, n47, n48, n49, n50, n51, n52, n53,
         n54, n55, n56, n57, n58, n59, n60, n61, n62, n63;
  wire   [2:0] grant_unmasked;
  wire   [7:0] req_masked;
  wire   [2:0] grant_masked;

  priority_arbiter_1 priority_arbiter_inst_0 ( .req_i({n29, n30, n31, n32, n33, 
        n34, n35, n36}), .grant_o(grant_unmasked), .valid_o(valid_unmasked) );
  priority_arbiter_0 priority_arbiter_inst_1 ( .req_i(req_masked), .grant_o(
        grant_masked), .valid_o(valid_masked) );
  DFFX1TR mask_reg_0_ ( .D(n63), .CK(clk_i), .Q(mask_o[0]), .QN(n26) );
  DFFX1TR mask_reg_1_ ( .D(n62), .CK(clk_i), .Q(mask_o[1]), .QN(n25) );
  DFFX1TR mask_reg_5_ ( .D(n58), .CK(clk_i), .Q(mask_o[5]), .QN(n21) );
  DFFX1TR mask_reg_4_ ( .D(n59), .CK(clk_i), .Q(mask_o[4]), .QN(n22) );
  DFFX1TR mask_reg_3_ ( .D(n60), .CK(clk_i), .Q(mask_o[3]), .QN(n23) );
  DFFX1TR mask_reg_2_ ( .D(n61), .CK(clk_i), .Q(mask_o[2]), .QN(n24) );
  DFFX1TR mask_reg_7_ ( .D(n56), .CK(clk_i), .Q(mask_o[7]), .QN(n19) );
  DFFX1TR mask_reg_6_ ( .D(n57), .CK(clk_i), .Q(mask_o[6]), .QN(n20) );
  AOI22X2TR U61 ( .A0(grant_unmasked[0]), .A1(n18), .B0(grant_masked[0]), .B1(
        valid_masked), .Y(n54) );
  AOI22X2TR U62 ( .A0(grant_unmasked[1]), .A1(n18), .B0(grant_masked[1]), .B1(
        valid_masked), .Y(n52) );
  NAND2X1TR U63 ( .A(valid_o), .B(n51), .Y(n55) );
  AOI22X1TR U64 ( .A0(grant_unmasked[2]), .A1(n18), .B0(valid_masked), .B1(
        grant_masked[2]), .Y(n51) );
  NOR2X1TR U65 ( .A(n42), .B(n24), .Y(req_masked[2]) );
  NOR2X1TR U66 ( .A(n41), .B(n23), .Y(req_masked[3]) );
  NOR2X1TR U67 ( .A(n39), .B(n21), .Y(req_masked[5]) );
  NOR2X1TR U68 ( .A(n40), .B(n22), .Y(req_masked[4]) );
  NOR2X1TR U69 ( .A(n43), .B(n25), .Y(req_masked[1]) );
  NOR2X1TR U70 ( .A(n44), .B(n26), .Y(req_masked[0]) );
  NOR2X1TR U71 ( .A(n48), .B(n55), .Y(grant_onehot_o[0]) );
  NOR2X1TR U72 ( .A(n48), .B(n53), .Y(grant_onehot_o[4]) );
  NAND2X1TR U73 ( .A(grant_o[2]), .B(valid_o), .Y(n53) );
  CLKINVX2TR U74 ( .A(n52), .Y(grant_o[1]) );
  CLKINVX2TR U75 ( .A(valid_masked), .Y(n18) );
  CLKINVX2TR U76 ( .A(n54), .Y(grant_o[0]) );
  NOR3X1TR U77 ( .A(n55), .B(grant_o[1]), .C(n54), .Y(grant_onehot_o[1]) );
  NOR3X1TR U78 ( .A(n53), .B(grant_o[1]), .C(n54), .Y(grant_onehot_o[5]) );
  NAND2X1TR U79 ( .A(n54), .B(n52), .Y(n48) );
  NOR3X1TR U80 ( .A(n55), .B(grant_o[0]), .C(n52), .Y(grant_onehot_o[2]) );
  NOR3X1TR U81 ( .A(n53), .B(grant_o[0]), .C(n52), .Y(grant_onehot_o[6]) );
  NAND2X1TR U82 ( .A(n28), .B(n51), .Y(n49) );
  CLKAND2X2TR U83 ( .A(n49), .B(n27), .Y(n47) );
  NOR3X1TR U84 ( .A(n53), .B(n54), .C(n52), .Y(grant_onehot_o[7]) );
  CLKINVX2TR U85 ( .A(n51), .Y(grant_o[2]) );
  NOR3X1TR U86 ( .A(n55), .B(n54), .C(n52), .Y(grant_onehot_o[3]) );
  NAND2BX1TR U87 ( .AN(valid_unmasked), .B(n18), .Y(valid_o) );
  OA21X2TR U88 ( .A0(grant_o[1]), .A1(n45), .B0(n47), .Y(n46) );
  AOI21X1TR U89 ( .A0(n51), .A1(n52), .B0(rst_i), .Y(n50) );
  CLKINVX2TR U90 ( .A(n38), .Y(n30) );
  CLKINVX2TR U91 ( .A(n41), .Y(n33) );
  CLKINVX2TR U92 ( .A(n42), .Y(n34) );
  CLKINVX2TR U93 ( .A(n37), .Y(n29) );
  CLKINVX2TR U94 ( .A(n39), .Y(n31) );
  CLKINVX2TR U95 ( .A(n40), .Y(n32) );
  CLKINVX2TR U96 ( .A(n44), .Y(n36) );
  CLKINVX2TR U97 ( .A(n43), .Y(n35) );
  CLKINVX2TR U98 ( .A(n45), .Y(n28) );
  CLKINVX2TR U99 ( .A(rst_i), .Y(n27) );
  OAI221X1TR U100 ( .A0(n19), .A1(n28), .B0(grant_o[0]), .B1(n45), .C0(n46), 
        .Y(n56) );
  NAND2X1TR U101 ( .A(req_i[6]), .B(en_i), .Y(n38) );
  NOR2X1TR U102 ( .A(n38), .B(n20), .Y(req_masked[6]) );
  NAND2X1TR U103 ( .A(req_i[7]), .B(en_i), .Y(n37) );
  NOR2X1TR U104 ( .A(n37), .B(n19), .Y(req_masked[7]) );
  OAI21X1TR U105 ( .A0(n20), .A1(n28), .B0(n46), .Y(n57) );
  NAND2X1TR U106 ( .A(req_i[2]), .B(en_i), .Y(n42) );
  NAND2X1TR U107 ( .A(req_i[3]), .B(en_i), .Y(n41) );
  NAND2X1TR U108 ( .A(req_i[5]), .B(en_i), .Y(n39) );
  NAND2X1TR U109 ( .A(req_i[4]), .B(en_i), .Y(n40) );
  NAND2X1TR U110 ( .A(req_i[1]), .B(en_i), .Y(n43) );
  OAI222X1TR U111 ( .A0(n45), .A1(n50), .B0(grant_o[0]), .B1(n49), .C0(n23), 
        .C1(n28), .Y(n60) );
  NAND2X1TR U112 ( .A(req_i[0]), .B(en_i), .Y(n44) );
  OAI221X1TR U113 ( .A0(n48), .A1(n49), .B0(n25), .B1(n28), .C0(n27), .Y(n62)
         );
  OAI221X1TR U114 ( .A0(n45), .A1(n48), .B0(n21), .B1(n28), .C0(n47), .Y(n58)
         );
  OAI22X1TR U115 ( .A0(n24), .A1(n28), .B0(n45), .B1(n50), .Y(n61) );
  OAI21X1TR U116 ( .A0(n22), .A1(n28), .B0(n47), .Y(n59) );
  NOR2X2TR U117 ( .A(ack_i), .B(rst_i), .Y(n45) );
  OAI21X1TR U118 ( .A0(n26), .A1(n28), .B0(n27), .Y(n63) );
endmodule

