/////////////////////////////////////////////////////////////////////////
//                                                                     //
//   Modulename :  standard.vh                                         //
//                                                                     //
//  Description :  This file has the macro-defines for macros used in  //
//                 the GraphPulse design.                              //
//                                                                     //
/////////////////////////////////////////////////////////////////////////

`define VERILOG_CLOCK_PERIOD   10.0
`define SD #1

// Event
`define PE_IDX_WIDTH            $clog2(`PE_NUM)
`define DELTA_WIDTH             16
`define VERTEX_IDX_WIDTH        8

// Event Queues
`define COL_NUM                 8
`define COL_IDX_LSB             0
`define COL_IDX_WIDTH           $clog2(`COL_NUM)
`define BIN_NUM                 8
`define BIN_IDX_LSB             `COL_IDX_LSB + `COL_IDX_WIDTH
`define BIN_IDX_WIDTH           $clog2(`BIN_NUM)
`define ROW_NUM                 4
`define ROW_IDX_LSB             `BIN_IDX_LSB + `BIN_IDX_WIDTH
`define ROW_IDX_WIDTH           $clog2(`ROW_NUM)

// Xbar from Scheduler / Output Buffer to PEs
`define XBAR_0_STAGES_NUM       1

// PE
`define PE_NUM                  4
`define GEN_PER_PE              2
`define GEN_NUM                 `GEN_PER_PE * `PE_NUM

// Xbar from PEs to Event Queues
`define XBAR_1_STAGES_NUM       1
