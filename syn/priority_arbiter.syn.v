/////////////////////////////////////////////////////////////
// Created by: Synopsys DC Expert(TM) in wire load mode
// Version   : T-2022.03-SP3
// Date      : Tue Mar 21 17:40:20 2023
/////////////////////////////////////////////////////////////


module priority_arbiter ( req_i, grant_o, valid_o );
  input [7:0] req_i;
  output [2:0] grant_o;
  output valid_o;
  wire   n1, n2, n3, n4, n5, n6, n7, n8, n9, n10, n11, n12;

  NOR2X1TR U19 ( .A(req_i[0]), .B(n10), .Y(grant_o[0]) );
  AOI21X1TR U20 ( .A0(n11), .A1(n3), .B0(req_i[1]), .Y(n10) );
  CLKINVX2TR U21 ( .A(req_i[2]), .Y(n3) );
  OAI21X1TR U22 ( .A0(req_i[4]), .A1(n12), .B0(n2), .Y(n11) );
  NOR3BX1TR U23 ( .AN(n8), .B(req_i[1]), .C(req_i[0]), .Y(grant_o[1]) );
  OAI31X1TR U24 ( .A0(req_i[4]), .A1(req_i[5]), .A2(n7), .B0(n9), .Y(n8) );
  NOR2X1TR U25 ( .A(req_i[2]), .B(req_i[3]), .Y(n9) );
  NOR3BX1TR U26 ( .AN(n7), .B(req_i[4]), .C(req_i[5]), .Y(n4) );
  NAND3BX1TR U27 ( .AN(req_i[0]), .B(n4), .C(n5), .Y(valid_o) );
  NOR3X1TR U28 ( .A(req_i[1]), .B(req_i[3]), .C(req_i[2]), .Y(n5) );
  NOR3X1TR U29 ( .A(n6), .B(req_i[0]), .C(n4), .Y(grant_o[2]) );
  OR3X1TR U30 ( .A(req_i[1]), .B(req_i[2]), .C(req_i[3]), .Y(n6) );
  CLKINVX2TR U31 ( .A(req_i[3]), .Y(n2) );
  AOI21X1TR U32 ( .A0(req_i[7]), .A1(n1), .B0(req_i[5]), .Y(n12) );
  CLKINVX2TR U33 ( .A(req_i[6]), .Y(n1) );
  NOR2X1TR U34 ( .A(req_i[7]), .B(req_i[6]), .Y(n7) );
endmodule

