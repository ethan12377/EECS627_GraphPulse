/////////////////////////////////////////////////////////////
// Created by: Synopsys DC Expert(TM) in wire load mode
// Version   : T-2022.03-SP3
// Date      : Tue Mar 28 15:22:00 2023
/////////////////////////////////////////////////////////////


module priority_arbiter_C_REQ_NUM8_C_REQ_IDX_WIDTH3_1 ( req_i, grant_o, 
        valid_o );
  input [7:0] req_i;
  output [2:0] grant_o;
  output valid_o;
  wire   n4, n5, n6, n7, n8, n9, n10, n11, n12, n1, n2, n3;

  OAI21X1TR U3 ( .A0(req_i[4]), .A1(n12), .B0(n2), .Y(n11) );
  CLKINVX2TR U4 ( .A(req_i[3]), .Y(n2) );
  AOI21X1TR U5 ( .A0(req_i[7]), .A1(n3), .B0(req_i[5]), .Y(n12) );
  CLKINVX2TR U6 ( .A(req_i[6]), .Y(n3) );
  OAI31X1TR U7 ( .A0(req_i[4]), .A1(req_i[5]), .A2(n7), .B0(n9), .Y(n8) );
  NOR2X1TR U8 ( .A(req_i[2]), .B(req_i[3]), .Y(n9) );
  NOR2X1TR U9 ( .A(req_i[7]), .B(req_i[6]), .Y(n7) );
  NOR3BX1TR U10 ( .AN(n7), .B(req_i[4]), .C(req_i[5]), .Y(n4) );
  NAND3BX1TR U11 ( .AN(req_i[0]), .B(n4), .C(n5), .Y(valid_o) );
  NOR3X1TR U12 ( .A(req_i[1]), .B(req_i[3]), .C(req_i[2]), .Y(n5) );
  CLKINVX2TR U13 ( .A(req_i[2]), .Y(n1) );
  OR3X1TR U14 ( .A(req_i[1]), .B(req_i[2]), .C(req_i[3]), .Y(n6) );
  NOR3BX1TR U15 ( .AN(n8), .B(req_i[1]), .C(req_i[0]), .Y(grant_o[1]) );
  NOR2X1TR U16 ( .A(req_i[0]), .B(n10), .Y(grant_o[0]) );
  AOI21X1TR U17 ( .A0(n11), .A1(n1), .B0(req_i[1]), .Y(n10) );
  NOR3X1TR U18 ( .A(n6), .B(req_i[0]), .C(n4), .Y(grant_o[2]) );
endmodule


module priority_arbiter_C_REQ_NUM8_C_REQ_IDX_WIDTH3_0 ( req_i, grant_o, 
        valid_o );
  input [7:0] req_i;
  output [2:0] grant_o;
  output valid_o;
  wire   n1, n2, n3, n13, n14, n15, n16, n17, n18, n19, n20, n21;

  NOR3BX1TR U3 ( .AN(n17), .B(req_i[1]), .C(req_i[0]), .Y(grant_o[1]) );
  OAI31X1TR U4 ( .A0(req_i[4]), .A1(req_i[5]), .A2(n18), .B0(n16), .Y(n17) );
  NOR3BX1TR U5 ( .AN(n18), .B(req_i[4]), .C(req_i[5]), .Y(n21) );
  NAND3BX1TR U6 ( .AN(req_i[0]), .B(n21), .C(n20), .Y(valid_o) );
  NOR3X1TR U7 ( .A(req_i[1]), .B(req_i[3]), .C(req_i[2]), .Y(n20) );
  NOR2X1TR U8 ( .A(req_i[7]), .B(req_i[6]), .Y(n18) );
  NOR2X1TR U9 ( .A(req_i[0]), .B(n15), .Y(grant_o[0]) );
  NOR3X1TR U10 ( .A(n19), .B(req_i[0]), .C(n21), .Y(grant_o[2]) );
  OR3X1TR U11 ( .A(req_i[1]), .B(req_i[2]), .C(req_i[3]), .Y(n19) );
  AOI21X1TR U12 ( .A0(n14), .A1(n1), .B0(req_i[1]), .Y(n15) );
  CLKINVX2TR U13 ( .A(req_i[2]), .Y(n1) );
  OAI21X1TR U14 ( .A0(req_i[4]), .A1(n13), .B0(n3), .Y(n14) );
  CLKINVX2TR U15 ( .A(req_i[3]), .Y(n3) );
  AOI21X1TR U16 ( .A0(req_i[7]), .A1(n2), .B0(req_i[5]), .Y(n13) );
  CLKINVX2TR U17 ( .A(req_i[6]), .Y(n2) );
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
  wire   valid_unmasked, valid_masked, n19, n20, n21, n22, n23, n24, n25, n26,
         n37, n38, n39, n40, n41, n42, n43, n44, n45, n46, n47, n48, n49, n50,
         n51, n52, n53, n54, n55, n56, n57, n58, n59, n60, n61, n62, n63, n4,
         n5, n6, n7, n8, n9, n10, n11, n12, n13, n14;
  wire   [2:0] grant_unmasked;
  wire   [7:0] req_masked;
  wire   [2:0] grant_masked;

  priority_arbiter_C_REQ_NUM8_C_REQ_IDX_WIDTH3_1 priority_arbiter_inst_0 ( 
        .req_i({n12, n11, n10, n9, n8, n7, n6, n5}), .grant_o(grant_unmasked), 
        .valid_o(valid_unmasked) );
  priority_arbiter_C_REQ_NUM8_C_REQ_IDX_WIDTH3_0 priority_arbiter_inst_1 ( 
        .req_i(req_masked), .grant_o(grant_masked), .valid_o(valid_masked) );
  DFFX1TR mask_reg_0_ ( .D(n63), .CK(clk_i), .Q(mask_o[0]), .QN(n26) );
  DFFX1TR mask_reg_1_ ( .D(n62), .CK(clk_i), .Q(mask_o[1]), .QN(n25) );
  DFFX1TR mask_reg_5_ ( .D(n58), .CK(clk_i), .Q(mask_o[5]), .QN(n21) );
  DFFX1TR mask_reg_4_ ( .D(n59), .CK(clk_i), .Q(mask_o[4]), .QN(n22) );
  DFFX1TR mask_reg_3_ ( .D(n60), .CK(clk_i), .Q(mask_o[3]), .QN(n23) );
  DFFX1TR mask_reg_2_ ( .D(n61), .CK(clk_i), .Q(mask_o[2]), .QN(n24) );
  DFFX1TR mask_reg_7_ ( .D(n56), .CK(clk_i), .Q(mask_o[7]), .QN(n19) );
  DFFX1TR mask_reg_6_ ( .D(n57), .CK(clk_i), .Q(mask_o[6]), .QN(n20) );
  AOI22X1TR U3 ( .A0(grant_unmasked[2]), .A1(n4), .B0(valid_masked), .B1(
        grant_masked[2]), .Y(n51) );
  NOR2X1TR U4 ( .A(n42), .B(n24), .Y(req_masked[2]) );
  NOR2X1TR U5 ( .A(n41), .B(n23), .Y(req_masked[3]) );
  NOR2X1TR U6 ( .A(n39), .B(n21), .Y(req_masked[5]) );
  NOR2X1TR U7 ( .A(n40), .B(n22), .Y(req_masked[4]) );
  NOR2X1TR U8 ( .A(n43), .B(n25), .Y(req_masked[1]) );
  NOR2X1TR U9 ( .A(n44), .B(n26), .Y(req_masked[0]) );
  NAND2X1TR U10 ( .A(grant_o[2]), .B(valid_o), .Y(n53) );
  CLKINVX2TR U11 ( .A(n52), .Y(grant_o[1]) );
  CLKINVX2TR U12 ( .A(valid_masked), .Y(n4) );
  CLKINVX2TR U13 ( .A(n54), .Y(grant_o[0]) );
  NAND2X1TR U14 ( .A(n54), .B(n52), .Y(n48) );
  CLKINVX2TR U15 ( .A(n51), .Y(grant_o[2]) );
  NAND2X1TR U16 ( .A(n14), .B(n51), .Y(n49) );
  CLKAND2X2TR U17 ( .A(n49), .B(n13), .Y(n47) );
  NAND2X1TR U18 ( .A(valid_o), .B(n51), .Y(n55) );
  NAND2BX1TR U19 ( .AN(valid_unmasked), .B(n4), .Y(valid_o) );
  AOI22X2TR U20 ( .A0(grant_unmasked[1]), .A1(n4), .B0(grant_masked[1]), .B1(
        valid_masked), .Y(n52) );
  OA21X2TR U21 ( .A0(grant_o[1]), .A1(n45), .B0(n47), .Y(n46) );
  AOI22X2TR U22 ( .A0(grant_unmasked[0]), .A1(n4), .B0(grant_masked[0]), .B1(
        valid_masked), .Y(n54) );
  AOI21X1TR U23 ( .A0(n51), .A1(n52), .B0(rst_i), .Y(n50) );
  CLKINVX2TR U24 ( .A(n38), .Y(n11) );
  CLKINVX2TR U25 ( .A(n42), .Y(n7) );
  CLKINVX2TR U26 ( .A(n41), .Y(n8) );
  CLKINVX2TR U27 ( .A(n39), .Y(n10) );
  CLKINVX2TR U28 ( .A(n37), .Y(n12) );
  CLKINVX2TR U29 ( .A(n40), .Y(n9) );
  CLKINVX2TR U30 ( .A(n43), .Y(n6) );
  CLKINVX2TR U31 ( .A(n44), .Y(n5) );
  CLKINVX2TR U32 ( .A(n45), .Y(n14) );
  CLKINVX2TR U33 ( .A(rst_i), .Y(n13) );
  NOR3X1TR U34 ( .A(n55), .B(n54), .C(n52), .Y(grant_onehot_o[3]) );
  NOR2X1TR U35 ( .A(n48), .B(n53), .Y(grant_onehot_o[4]) );
  NOR3X1TR U36 ( .A(n53), .B(grant_o[1]), .C(n54), .Y(grant_onehot_o[5]) );
  NOR3X1TR U37 ( .A(n53), .B(grant_o[0]), .C(n52), .Y(grant_onehot_o[6]) );
  NOR3X1TR U38 ( .A(n53), .B(n54), .C(n52), .Y(grant_onehot_o[7]) );
  NOR2X1TR U39 ( .A(n48), .B(n55), .Y(grant_onehot_o[0]) );
  NOR3X1TR U40 ( .A(n55), .B(grant_o[1]), .C(n54), .Y(grant_onehot_o[1]) );
  NOR3X1TR U41 ( .A(n55), .B(grant_o[0]), .C(n52), .Y(grant_onehot_o[2]) );
  OAI221X1TR U42 ( .A0(n19), .A1(n14), .B0(grant_o[0]), .B1(n45), .C0(n46), 
        .Y(n56) );
  NOR2X1TR U43 ( .A(n38), .B(n20), .Y(req_masked[6]) );
  NAND2X1TR U44 ( .A(req_i[6]), .B(en_i), .Y(n38) );
  NOR2X1TR U45 ( .A(n37), .B(n19), .Y(req_masked[7]) );
  NAND2X1TR U46 ( .A(req_i[7]), .B(en_i), .Y(n37) );
  OAI21X1TR U47 ( .A0(n20), .A1(n14), .B0(n46), .Y(n57) );
  NAND2X1TR U48 ( .A(req_i[2]), .B(en_i), .Y(n42) );
  NAND2X1TR U49 ( .A(req_i[3]), .B(en_i), .Y(n41) );
  NAND2X1TR U50 ( .A(req_i[5]), .B(en_i), .Y(n39) );
  NAND2X1TR U51 ( .A(req_i[4]), .B(en_i), .Y(n40) );
  NAND2X1TR U52 ( .A(req_i[1]), .B(en_i), .Y(n43) );
  OAI222X1TR U53 ( .A0(n45), .A1(n50), .B0(grant_o[0]), .B1(n49), .C0(n23), 
        .C1(n14), .Y(n60) );
  NAND2X1TR U54 ( .A(req_i[0]), .B(en_i), .Y(n44) );
  OAI221X1TR U55 ( .A0(n48), .A1(n49), .B0(n25), .B1(n14), .C0(n13), .Y(n62)
         );
  OAI221X1TR U56 ( .A0(n45), .A1(n48), .B0(n21), .B1(n14), .C0(n47), .Y(n58)
         );
  OAI22X1TR U57 ( .A0(n24), .A1(n14), .B0(n45), .B1(n50), .Y(n61) );
  OAI21X1TR U58 ( .A0(n22), .A1(n14), .B0(n47), .Y(n59) );
  NOR2X2TR U59 ( .A(ack_i), .B(rst_i), .Y(n45) );
  OAI21X1TR U60 ( .A0(n26), .A1(n14), .B0(n13), .Y(n63) );
endmodule


module queue_scheduler ( clk_i, rst_i, initialFinish_i, CUClean_i, binValid_i, 
        binSelected_o, PEready_i, readEn_o );
  input [3:0] initialFinish_i;
  input [7:0] CUClean_i;
  input [7:0] binValid_i;
  output [7:0] binSelected_o;
  input [3:0] PEready_i;
  input clk_i, rst_i;
  output readEn_o;
  wire   N25, N26, N27, grant_ack, grant_valid, PEReady, N70, N71, N72, N73,
         N74, N79, N86, N88, N94, N95, N96, N97, N98, N99, N100, N101, N102,
         N103, N104, bin_buf_7__3_, bin_buf_6__3_, bin_buf_5__3_,
         bin_buf_4__3_, bin_buf_3__3_, bin_buf_2__3_, bin_buf_1__3_,
         bin_buf_0__3_, n51, n52, n53, n55, n56, n57, n59, n60, n61, n63, n64,
         n65, n67, n68, n69, n710, n720, n730, n75, n76, n77, n790, n80, n81,
         n84, n85, n860, n87, n880, n89, n90, n91, n92, n93, n940, n950, n960,
         n970, n980, n990, n1000, n1010, n1020, n1030, n1040, n105, n106, n107,
         n108, n109, n110, n111, n112, n113, n114, n115, n116, n117, n118,
         n119, n120, n121, n122, n123, n124, n125, n126, n127, n128, n129,
         n130, n131, n132, n133, n134, n135, n136, n137, n138, n139, n140,
         n141, n142, n143, n144, n145, n146, n147, n148, n149, n150, n151,
         n152, n153, n154, n155, n156, n157, n158, n159, n160, n161, n162,
         n163, n164, n165, n166, n167, n168, n169, n170, n171, n172, n173,
         n174, n175, n176, n177, n178, n179, n180, n181, n182, n183, n184,
         n185, n186, n187, n188, n189, n190, n191, n192, n193, n194, n195,
         n196, n197, n198, n199, n200, n201, n202, n203, n204, n205, n206,
         n207, n208, n209, n210, n211, n212, n213, n214, n215, n216, n217,
         n218, n219, n220, n221, n222, n223, n224, n225, n226, n227, n228,
         n229, n230, n231, n232, n233, n234, n235, n236, n237, n238, n239,
         n240, n241, n242, n243, n244, n245, n246, n247;
  wire   [2:0] grant;
  wire   [7:0] grant_onehot;
  wire   [2:0] qs_state;
  wire   [3:0] delaycount;
  wire   [7:0] prebinSelected;

  rr_arbiter qs_rr_arbiter ( .clk_i(clk_i), .rst_i(rst_i), .en_i(1'b1), 
        .ack_i(grant_ack), .req_i(binValid_i), .grant_o(grant), 
        .grant_onehot_o(grant_onehot), .valid_o(grant_valid) );
  DFFQX1TR binSelected_o_reg_2_ ( .D(n193), .CK(clk_i), .Q(binSelected_o[2])
         );
  DFFQX1TR binSelected_o_reg_1_ ( .D(n194), .CK(clk_i), .Q(binSelected_o[1])
         );
  DFFQX1TR binSelected_o_reg_0_ ( .D(n195), .CK(clk_i), .Q(binSelected_o[0])
         );
  DFFQX1TR binSelected_o_reg_7_ ( .D(n196), .CK(clk_i), .Q(binSelected_o[7])
         );
  DFFQX1TR binSelected_o_reg_6_ ( .D(n189), .CK(clk_i), .Q(binSelected_o[6])
         );
  DFFQX1TR binSelected_o_reg_5_ ( .D(n190), .CK(clk_i), .Q(binSelected_o[5])
         );
  DFFQX1TR binSelected_o_reg_4_ ( .D(n191), .CK(clk_i), .Q(binSelected_o[4])
         );
  DFFQX1TR binSelected_o_reg_3_ ( .D(n192), .CK(clk_i), .Q(binSelected_o[3])
         );
  DFFQX1TR prebinSelected_reg_2_ ( .D(N99), .CK(clk_i), .Q(prebinSelected[2])
         );
  DFFQX1TR prebinSelected_reg_1_ ( .D(N98), .CK(clk_i), .Q(prebinSelected[1])
         );
  DFFQX1TR prebinSelected_reg_0_ ( .D(N97), .CK(clk_i), .Q(prebinSelected[0])
         );
  DFFQX1TR prebinSelected_reg_7_ ( .D(N104), .CK(clk_i), .Q(prebinSelected[7])
         );
  DFFQX1TR prebinSelected_reg_6_ ( .D(N103), .CK(clk_i), .Q(prebinSelected[6])
         );
  DFFQX1TR prebinSelected_reg_5_ ( .D(N102), .CK(clk_i), .Q(prebinSelected[5])
         );
  DFFQX1TR prebinSelected_reg_4_ ( .D(N101), .CK(clk_i), .Q(prebinSelected[4])
         );
  DFFQX1TR prebinSelected_reg_3_ ( .D(N100), .CK(clk_i), .Q(prebinSelected[3])
         );
  DFFQX1TR readEn_o_reg ( .D(N86), .CK(clk_i), .Q(readEn_o) );
  DFFQX1TR PEReady_reg ( .D(N74), .CK(clk_i), .Q(PEReady) );
  DFFQX1TR bin_buf_reg_3__3_ ( .D(n173), .CK(clk_i), .Q(bin_buf_3__3_) );
  DFFQX1TR bin_buf_reg_2__3_ ( .D(n177), .CK(clk_i), .Q(bin_buf_2__3_) );
  DFFQX1TR bin_buf_reg_1__3_ ( .D(n181), .CK(clk_i), .Q(bin_buf_1__3_) );
  DFFQX1TR bin_buf_reg_7__3_ ( .D(n157), .CK(clk_i), .Q(bin_buf_7__3_) );
  DFFQX1TR bin_buf_reg_0__3_ ( .D(n185), .CK(clk_i), .Q(bin_buf_0__3_) );
  DFFQX1TR bin_buf_reg_6__3_ ( .D(n161), .CK(clk_i), .Q(bin_buf_6__3_) );
  DFFQX1TR bin_buf_reg_5__3_ ( .D(n165), .CK(clk_i), .Q(bin_buf_5__3_) );
  DFFQX1TR bin_buf_reg_4__3_ ( .D(n169), .CK(clk_i), .Q(bin_buf_4__3_) );
  DFFQX1TR grant_ack_reg ( .D(n225), .CK(clk_i), .Q(grant_ack) );
  DFFQX1TR delaycount_reg_3_ ( .D(N73), .CK(clk_i), .Q(delaycount[3]) );
  DFFQX1TR delaycount_reg_2_ ( .D(N72), .CK(clk_i), .Q(delaycount[2]) );
  DFFQX1TR delaycount_reg_0_ ( .D(N70), .CK(clk_i), .Q(delaycount[0]) );
  DFFX1TR bin_buf_reg_7__0_ ( .D(n160), .CK(clk_i), .QN(n53) );
  DFFQX1TR delaycount_reg_1_ ( .D(N71), .CK(clk_i), .Q(delaycount[1]) );
  DFFX1TR bin_buf_reg_7__1_ ( .D(n159), .CK(clk_i), .QN(n52) );
  DFFX1TR bin_buf_reg_7__2_ ( .D(n158), .CK(clk_i), .QN(n51) );
  DFFQX1TR qs_state_reg_2_ ( .D(n199), .CK(clk_i), .Q(qs_state[2]) );
  DFFX1TR bin_buf_reg_3__0_ ( .D(n176), .CK(clk_i), .QN(n69) );
  DFFX1TR bin_buf_reg_3__1_ ( .D(n175), .CK(clk_i), .QN(n68) );
  DFFX1TR bin_buf_reg_2__0_ ( .D(n180), .CK(clk_i), .QN(n730) );
  DFFX1TR bin_buf_reg_1__0_ ( .D(n184), .CK(clk_i), .QN(n77) );
  DFFX1TR bin_buf_reg_2__1_ ( .D(n179), .CK(clk_i), .QN(n720) );
  DFFX1TR bin_buf_reg_0__0_ ( .D(n188), .CK(clk_i), .QN(n81) );
  DFFX1TR bin_buf_reg_6__0_ ( .D(n164), .CK(clk_i), .QN(n57) );
  DFFX1TR bin_buf_reg_3__2_ ( .D(n174), .CK(clk_i), .QN(n67) );
  DFFX1TR bin_buf_reg_1__1_ ( .D(n183), .CK(clk_i), .QN(n76) );
  DFFX1TR bin_buf_reg_5__0_ ( .D(n168), .CK(clk_i), .QN(n61) );
  DFFX1TR bin_buf_reg_2__2_ ( .D(n178), .CK(clk_i), .QN(n710) );
  DFFX1TR bin_buf_reg_0__1_ ( .D(n187), .CK(clk_i), .QN(n80) );
  DFFX1TR bin_buf_reg_4__0_ ( .D(n172), .CK(clk_i), .QN(n65) );
  DFFX1TR bin_buf_reg_6__1_ ( .D(n163), .CK(clk_i), .QN(n56) );
  DFFX1TR bin_buf_reg_1__2_ ( .D(n182), .CK(clk_i), .QN(n75) );
  DFFX1TR bin_buf_reg_5__1_ ( .D(n167), .CK(clk_i), .QN(n60) );
  DFFX1TR bin_buf_reg_0__2_ ( .D(n186), .CK(clk_i), .QN(n790) );
  DFFX1TR bin_buf_reg_6__2_ ( .D(n162), .CK(clk_i), .QN(n55) );
  DFFX1TR bin_buf_reg_4__1_ ( .D(n171), .CK(clk_i), .QN(n64) );
  DFFX1TR bin_buf_reg_5__2_ ( .D(n166), .CK(clk_i), .QN(n59) );
  DFFX1TR bin_buf_reg_4__2_ ( .D(n170), .CK(clk_i), .QN(n63) );
  DFFQX2TR qs_state_reg_0_ ( .D(n197), .CK(clk_i), .Q(qs_state[0]) );
  DFFQX1TR qs_state_reg_1_ ( .D(n198), .CK(clk_i), .Q(qs_state[1]) );
  DFFQX1TR reading_bin_reg_2_ ( .D(N96), .CK(clk_i), .Q(N27) );
  DFFQX1TR reading_bin_reg_1_ ( .D(N95), .CK(clk_i), .Q(N26) );
  DFFQX1TR reading_bin_reg_0_ ( .D(N94), .CK(clk_i), .Q(N25) );
  CLKBUFX2TR U163 ( .A(n85), .Y(n205) );
  CLKBUFX2TR U164 ( .A(n85), .Y(n206) );
  CLKINVX2TR U165 ( .A(N88), .Y(n228) );
  CLKINVX2TR U166 ( .A(n1040), .Y(n224) );
  NAND2X1TR U167 ( .A(n208), .B(n226), .Y(n860) );
  OR2X2TR U168 ( .A(n860), .B(n234), .Y(n85) );
  CLKBUFX2TR U169 ( .A(n84), .Y(n208) );
  CLKINVX2TR U170 ( .A(n150), .Y(n227) );
  CLKINVX2TR U171 ( .A(n980), .Y(n229) );
  CLKINVX2TR U172 ( .A(n940), .Y(n236) );
  CLKINVX2TR U173 ( .A(n1000), .Y(n225) );
  CLKBUFX2TR U174 ( .A(n84), .Y(n207) );
  NAND2X1TR U175 ( .A(n90), .B(n226), .Y(n1040) );
  CLKINVX2TR U176 ( .A(n200), .Y(n221) );
  CLKINVX2TR U177 ( .A(n201), .Y(n222) );
  OAI222X1TR U178 ( .A0(n105), .A1(n1040), .B0(n234), .B1(n1000), .C0(n238), 
        .C1(n90), .Y(n199) );
  CLKAND2X2TR U179 ( .A(n141), .B(n960), .Y(n105) );
  AO22X1TR U180 ( .A0(grant[0]), .A1(n203), .B0(n143), .B1(N25), .Y(N94) );
  AO22X1TR U181 ( .A0(grant[1]), .A1(n203), .B0(n143), .B1(N26), .Y(N95) );
  AO22X1TR U182 ( .A0(grant[2]), .A1(n203), .B0(n143), .B1(N27), .Y(N96) );
  CLKINVX2TR U183 ( .A(n202), .Y(n223) );
  CLKBUFX2TR U184 ( .A(n142), .Y(n203) );
  NOR2X1TR U185 ( .A(n155), .B(rst_i), .Y(n142) );
  OAI22X1TR U186 ( .A0(n245), .A1(n84), .B0(n244), .B1(n205), .Y(n161) );
  OAI22X1TR U187 ( .A0(n244), .A1(n84), .B0(n243), .B1(n205), .Y(n165) );
  OAI22X1TR U188 ( .A0(n243), .A1(n84), .B0(n242), .B1(n205), .Y(n169) );
  OAI22X1TR U189 ( .A0(n242), .A1(n207), .B0(n241), .B1(n206), .Y(n173) );
  OAI22X1TR U190 ( .A0(n241), .A1(n207), .B0(n240), .B1(n206), .Y(n177) );
  OAI22X1TR U191 ( .A0(n240), .A1(n207), .B0(n239), .B1(n206), .Y(n181) );
  OR2X2TR U192 ( .A(n87), .B(rst_i), .Y(n84) );
  NAND2BX1TR U193 ( .AN(n147), .B(n146), .Y(n150) );
  AOI21X1TR U194 ( .A0(n233), .A1(n227), .B0(N70), .Y(n151) );
  CLKINVX2TR U195 ( .A(n990), .Y(n234) );
  OAI32X1TR U196 ( .A0(n152), .A1(n230), .A2(n233), .B0(n151), .B1(n231), .Y(
        N72) );
  NAND2X1TR U197 ( .A(n227), .B(n231), .Y(n152) );
  CLKINVX2TR U198 ( .A(rst_i), .Y(n226) );
  NOR2X2TR U199 ( .A(n204), .B(rst_i), .Y(n89) );
  CLKINVX2TR U200 ( .A(n960), .Y(n235) );
  CLKBUFX2TR U201 ( .A(n880), .Y(n204) );
  NOR2X1TR U202 ( .A(rst_i), .B(n235), .Y(n880) );
  NAND2X1TR U203 ( .A(n1020), .B(n1030), .Y(n980) );
  NOR4X1TR U204 ( .A(binValid_i[3]), .B(binValid_i[2]), .C(binValid_i[1]), .D(
        binValid_i[0]), .Y(n1020) );
  NOR4X1TR U205 ( .A(binValid_i[7]), .B(binValid_i[6]), .C(binValid_i[5]), .D(
        binValid_i[4]), .Y(n1030) );
  NAND2X1TR U206 ( .A(n237), .B(n238), .Y(n940) );
  OAI21X1TR U207 ( .A0(n239), .A1(n208), .B0(n860), .Y(n185) );
  NAND2X1TR U208 ( .A(n87), .B(n226), .Y(n1000) );
  NOR2X1TR U209 ( .A(n146), .B(n147), .Y(N74) );
  NAND2X1TR U210 ( .A(n226), .B(n140), .Y(n90) );
  OAI222X1TR U211 ( .A0(N79), .A1(n960), .B0(n950), .B1(n228), .C0(PEReady), 
        .C1(n141), .Y(n140) );
  OAI21X1TR U212 ( .A0(n247), .A1(n90), .B0(n91), .Y(n197) );
  AOI22X1TR U213 ( .A0(n225), .A1(n234), .B0(n224), .B1(n92), .Y(n91) );
  OAI211X1TR U214 ( .A0(n93), .A1(n940), .B0(n950), .C0(n960), .Y(n92) );
  AOI32X1TR U215 ( .A0(initialFinish_i[3]), .A1(initialFinish_i[2]), .A2(n970), 
        .B0(n229), .B1(qs_state[0]), .Y(n93) );
  CLKBUFX2TR U216 ( .A(N25), .Y(n200) );
  OAI221X1TR U217 ( .A0(n237), .A1(n90), .B0(n990), .B1(n1000), .C0(n1010), 
        .Y(n198) );
  NAND4X1TR U218 ( .A(n224), .B(n236), .C(qs_state[0]), .D(n980), .Y(n1010) );
  CLKBUFX2TR U219 ( .A(N26), .Y(n201) );
  AND3X2TR U220 ( .A(n155), .B(n226), .C(n156), .Y(n143) );
  NAND3X1TR U221 ( .A(qs_state[0]), .B(n228), .C(n236), .Y(n156) );
  AO22X1TR U222 ( .A0(grant_onehot[3]), .A1(n203), .B0(n143), .B1(
        prebinSelected[3]), .Y(N100) );
  AO22X1TR U223 ( .A0(grant_onehot[4]), .A1(n203), .B0(n143), .B1(
        prebinSelected[4]), .Y(N101) );
  AO22X1TR U224 ( .A0(grant_onehot[5]), .A1(n203), .B0(n143), .B1(
        prebinSelected[5]), .Y(N102) );
  AO22X1TR U225 ( .A0(grant_onehot[6]), .A1(n203), .B0(n143), .B1(
        prebinSelected[6]), .Y(N103) );
  AO22X1TR U226 ( .A0(grant_onehot[7]), .A1(n203), .B0(n143), .B1(
        prebinSelected[7]), .Y(N104) );
  AO22X1TR U227 ( .A0(grant_onehot[0]), .A1(n203), .B0(n143), .B1(
        prebinSelected[0]), .Y(N97) );
  AO22X1TR U228 ( .A0(grant_onehot[1]), .A1(n203), .B0(n143), .B1(
        prebinSelected[1]), .Y(N98) );
  AO22X1TR U229 ( .A0(grant_onehot[2]), .A1(n203), .B0(n143), .B1(
        prebinSelected[2]), .Y(N99) );
  AOI21X1TR U230 ( .A0(n144), .A1(n145), .B0(rst_i), .Y(N86) );
  NAND2X1TR U231 ( .A(N79), .B(n235), .Y(n144) );
  OAI21X1TR U232 ( .A0(N88), .A1(n950), .B0(readEn_o), .Y(n145) );
  CLKBUFX2TR U233 ( .A(N27), .Y(n202) );
  NAND3X1TR U234 ( .A(n236), .B(qs_state[0]), .C(grant_valid), .Y(n155) );
  CLKINVX2TR U235 ( .A(qs_state[1]), .Y(n237) );
  NOR3X1TR U236 ( .A(qs_state[0]), .B(qs_state[2]), .C(n237), .Y(n87) );
  OAI22X1TR U237 ( .A0(n57), .A1(n84), .B0(n61), .B1(n205), .Y(n164) );
  OAI22X1TR U238 ( .A0(n61), .A1(n84), .B0(n65), .B1(n205), .Y(n168) );
  OAI22X1TR U239 ( .A0(n65), .A1(n207), .B0(n69), .B1(n205), .Y(n172) );
  OAI22X1TR U240 ( .A0(n69), .A1(n207), .B0(n730), .B1(n206), .Y(n176) );
  OAI22X1TR U241 ( .A0(n730), .A1(n207), .B0(n77), .B1(n206), .Y(n180) );
  OAI22X1TR U242 ( .A0(n77), .A1(n208), .B0(n81), .B1(n206), .Y(n184) );
  OAI22X1TR U243 ( .A0(n56), .A1(n84), .B0(n60), .B1(n205), .Y(n163) );
  OAI22X1TR U244 ( .A0(n60), .A1(n84), .B0(n64), .B1(n205), .Y(n167) );
  OAI22X1TR U245 ( .A0(n64), .A1(n207), .B0(n68), .B1(n205), .Y(n171) );
  OAI22X1TR U246 ( .A0(n68), .A1(n207), .B0(n720), .B1(n206), .Y(n175) );
  OAI22X1TR U247 ( .A0(n720), .A1(n207), .B0(n76), .B1(n206), .Y(n179) );
  OAI22X1TR U248 ( .A0(n76), .A1(n208), .B0(n80), .B1(n85), .Y(n183) );
  OAI22X1TR U249 ( .A0(n55), .A1(n84), .B0(n59), .B1(n205), .Y(n162) );
  OAI22X1TR U250 ( .A0(n59), .A1(n84), .B0(n63), .B1(n205), .Y(n166) );
  OAI22X1TR U251 ( .A0(n63), .A1(n84), .B0(n67), .B1(n205), .Y(n170) );
  OAI22X1TR U252 ( .A0(n67), .A1(n207), .B0(n710), .B1(n85), .Y(n174) );
  OAI22X1TR U253 ( .A0(n710), .A1(n207), .B0(n75), .B1(n85), .Y(n178) );
  OAI22X1TR U254 ( .A0(n75), .A1(n207), .B0(n790), .B1(n85), .Y(n182) );
  NAND3X1TR U255 ( .A(n247), .B(n237), .C(qs_state[2]), .Y(n960) );
  CLKINVX2TR U256 ( .A(qs_state[0]), .Y(n247) );
  OAI32X1TR U257 ( .A0(n148), .A1(n233), .A2(n231), .B0(n149), .B1(n232), .Y(
        N73) );
  NAND3X1TR U258 ( .A(n227), .B(n232), .C(delaycount[0]), .Y(n148) );
  OA21X2TR U259 ( .A0(n150), .A1(delaycount[2]), .B0(n151), .Y(n149) );
  CLKINVX2TR U260 ( .A(delaycount[3]), .Y(n232) );
  OAI22X1TR U261 ( .A0(n246), .A1(n207), .B0(n245), .B1(n206), .Y(n157) );
  CLKINVX2TR U262 ( .A(bin_buf_7__3_), .Y(n246) );
  NAND4X1TR U263 ( .A(PEready_i[3]), .B(PEready_i[2]), .C(n154), .D(
        PEready_i[1]), .Y(n147) );
  NOR2BX1TR U264 ( .AN(PEready_i[0]), .B(rst_i), .Y(n154) );
  NAND3X1TR U265 ( .A(qs_state[2]), .B(n237), .C(qs_state[0]), .Y(n950) );
  OAI22X1TR U266 ( .A0(n53), .A1(n84), .B0(n57), .B1(n206), .Y(n160) );
  OAI22X1TR U267 ( .A0(n52), .A1(n208), .B0(n56), .B1(n206), .Y(n159) );
  OAI22X1TR U268 ( .A0(n51), .A1(n208), .B0(n55), .B1(n206), .Y(n158) );
  NAND4X1TR U269 ( .A(n112), .B(n113), .C(n114), .D(bin_buf_4__3_), .Y(n111)
         );
  XOR2X1TR U270 ( .A(n65), .B(N25), .Y(n112) );
  XOR2X1TR U271 ( .A(n64), .B(N26), .Y(n113) );
  XOR2X1TR U272 ( .A(n63), .B(N27), .Y(n114) );
  NOR2X1TR U273 ( .A(n106), .B(n107), .Y(n990) );
  NAND4X1TR U274 ( .A(n124), .B(n125), .C(n126), .D(n127), .Y(n106) );
  NAND4X1TR U275 ( .A(n108), .B(n109), .C(n110), .D(n111), .Y(n107) );
  NAND4X1TR U276 ( .A(n137), .B(n138), .C(n139), .D(bin_buf_3__3_), .Y(n124)
         );
  NAND4X1TR U277 ( .A(n115), .B(n116), .C(n117), .D(bin_buf_5__3_), .Y(n110)
         );
  XOR2X1TR U278 ( .A(n61), .B(n200), .Y(n115) );
  XOR2X1TR U279 ( .A(n60), .B(n201), .Y(n116) );
  XOR2X1TR U280 ( .A(n59), .B(n202), .Y(n117) );
  NAND4X1TR U281 ( .A(n128), .B(n129), .C(n130), .D(bin_buf_0__3_), .Y(n127)
         );
  XOR2X1TR U282 ( .A(n81), .B(N25), .Y(n128) );
  XOR2X1TR U283 ( .A(n80), .B(N26), .Y(n129) );
  XOR2X1TR U284 ( .A(n790), .B(N27), .Y(n130) );
  NAND4X1TR U285 ( .A(n118), .B(n119), .C(n120), .D(bin_buf_6__3_), .Y(n109)
         );
  XOR2X1TR U286 ( .A(n57), .B(n200), .Y(n118) );
  XOR2X1TR U287 ( .A(n56), .B(n201), .Y(n119) );
  XOR2X1TR U288 ( .A(n55), .B(n202), .Y(n120) );
  NAND4X1TR U289 ( .A(n131), .B(n132), .C(n133), .D(bin_buf_1__3_), .Y(n126)
         );
  XOR2X1TR U290 ( .A(n77), .B(n200), .Y(n131) );
  XOR2X1TR U291 ( .A(n76), .B(n201), .Y(n132) );
  XOR2X1TR U292 ( .A(n75), .B(n202), .Y(n133) );
  NAND4X1TR U293 ( .A(n134), .B(n135), .C(n136), .D(bin_buf_2__3_), .Y(n125)
         );
  XOR2X1TR U294 ( .A(n730), .B(N25), .Y(n134) );
  XOR2X1TR U295 ( .A(n720), .B(N26), .Y(n135) );
  XOR2X1TR U296 ( .A(n710), .B(n202), .Y(n136) );
  XOR2X1TR U297 ( .A(n67), .B(n202), .Y(n139) );
  XOR2X1TR U298 ( .A(n68), .B(n201), .Y(n138) );
  NAND4X1TR U299 ( .A(n121), .B(n122), .C(n123), .D(bin_buf_7__3_), .Y(n108)
         );
  XOR2X1TR U300 ( .A(n53), .B(n200), .Y(n121) );
  XOR2X1TR U301 ( .A(n52), .B(n201), .Y(n122) );
  XOR2X1TR U302 ( .A(n51), .B(n202), .Y(n123) );
  XOR2X1TR U303 ( .A(n69), .B(n200), .Y(n137) );
  NOR2X1TR U304 ( .A(n150), .B(delaycount[0]), .Y(N70) );
  CLKINVX2TR U305 ( .A(qs_state[2]), .Y(n238) );
  NAND3X1TR U306 ( .A(qs_state[1]), .B(n238), .C(qs_state[0]), .Y(n141) );
  NAND4X1TR U307 ( .A(delaycount[3]), .B(n230), .C(n233), .D(n231), .Y(n146)
         );
  CLKINVX2TR U308 ( .A(delaycount[1]), .Y(n233) );
  CLKINVX2TR U309 ( .A(delaycount[0]), .Y(n230) );
  CLKINVX2TR U310 ( .A(delaycount[2]), .Y(n231) );
  AO22X1TR U311 ( .A0(binSelected_o[3]), .A1(n204), .B0(prebinSelected[3]), 
        .B1(n89), .Y(n192) );
  AO22X1TR U312 ( .A0(binSelected_o[4]), .A1(n204), .B0(prebinSelected[4]), 
        .B1(n89), .Y(n191) );
  AO22X1TR U313 ( .A0(binSelected_o[5]), .A1(n204), .B0(prebinSelected[5]), 
        .B1(n89), .Y(n190) );
  AO22X1TR U314 ( .A0(binSelected_o[6]), .A1(n204), .B0(prebinSelected[6]), 
        .B1(n89), .Y(n189) );
  AO22X1TR U315 ( .A0(binSelected_o[7]), .A1(n204), .B0(prebinSelected[7]), 
        .B1(n89), .Y(n196) );
  AO22X1TR U316 ( .A0(binSelected_o[0]), .A1(n204), .B0(prebinSelected[0]), 
        .B1(n89), .Y(n195) );
  AO22X1TR U317 ( .A0(binSelected_o[1]), .A1(n204), .B0(prebinSelected[1]), 
        .B1(n89), .Y(n194) );
  AO22X1TR U318 ( .A0(binSelected_o[2]), .A1(n204), .B0(prebinSelected[2]), 
        .B1(n89), .Y(n193) );
  AND3X2TR U319 ( .A(initialFinish_i[0]), .B(n247), .C(initialFinish_i[1]), 
        .Y(n970) );
  OAI22X1TR U320 ( .A0(n81), .A1(n208), .B0(n221), .B1(n860), .Y(n188) );
  OAI22X1TR U321 ( .A0(n80), .A1(n208), .B0(n222), .B1(n860), .Y(n187) );
  OAI22X1TR U322 ( .A0(n790), .A1(n208), .B0(n223), .B1(n860), .Y(n186) );
  NOR2X1TR U323 ( .A(n153), .B(n150), .Y(N71) );
  XOR2X1TR U324 ( .A(n230), .B(delaycount[1]), .Y(n153) );
  CLKINVX2TR U325 ( .A(bin_buf_6__3_), .Y(n245) );
  CLKINVX2TR U326 ( .A(bin_buf_5__3_), .Y(n244) );
  CLKINVX2TR U327 ( .A(bin_buf_4__3_), .Y(n243) );
  CLKINVX2TR U328 ( .A(bin_buf_3__3_), .Y(n242) );
  CLKINVX2TR U329 ( .A(bin_buf_2__3_), .Y(n241) );
  CLKINVX2TR U330 ( .A(bin_buf_1__3_), .Y(n240) );
  CLKINVX2TR U331 ( .A(bin_buf_0__3_), .Y(n239) );
  NOR2X1TR U332 ( .A(n222), .B(n200), .Y(n218) );
  NOR2X1TR U333 ( .A(n222), .B(n221), .Y(n217) );
  NOR2X1TR U334 ( .A(n221), .B(n201), .Y(n215) );
  NOR2X1TR U335 ( .A(n200), .B(n201), .Y(n214) );
  AO22X1TR U336 ( .A0(binValid_i[5]), .A1(n215), .B0(binValid_i[4]), .B1(n214), 
        .Y(n209) );
  AOI221X1TR U337 ( .A0(binValid_i[6]), .A1(n218), .B0(binValid_i[7]), .B1(
        n217), .C0(n209), .Y(n212) );
  AO22X1TR U338 ( .A0(binValid_i[1]), .A1(n215), .B0(binValid_i[0]), .B1(n214), 
        .Y(n210) );
  AOI221X1TR U339 ( .A0(binValid_i[2]), .A1(n218), .B0(binValid_i[3]), .B1(
        n217), .C0(n210), .Y(n211) );
  OAI22X1TR U340 ( .A0(n223), .A1(n212), .B0(n202), .B1(n211), .Y(N88) );
  AO22X1TR U341 ( .A0(CUClean_i[5]), .A1(n215), .B0(CUClean_i[4]), .B1(n214), 
        .Y(n213) );
  AOI221X1TR U342 ( .A0(CUClean_i[6]), .A1(n218), .B0(CUClean_i[7]), .B1(n217), 
        .C0(n213), .Y(n220) );
  AO22X1TR U343 ( .A0(CUClean_i[1]), .A1(n215), .B0(CUClean_i[0]), .B1(n214), 
        .Y(n216) );
  AOI221X1TR U344 ( .A0(CUClean_i[2]), .A1(n218), .B0(CUClean_i[3]), .B1(n217), 
        .C0(n216), .Y(n219) );
  OAI22X1TR U345 ( .A0(n220), .A1(n223), .B0(N27), .B1(n219), .Y(N79) );
endmodule

