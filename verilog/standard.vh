/////////////////////////////////////////////////////////////////////////
//                                                                     //
//   Modulename :  standard.vh                                         //
//                                                                     //
//  Description :  This file has the macro-defines for macros used in  //
//                 the GraphPulse design.                              //
//                                                                     //
/////////////////////////////////////////////////////////////////////////

`define VERILOG_CLOCK_PERIOD   10.0
`define SYNTH_CLOCK_PERIOD     10.0 // Clock period for synth and memory latency
`define SD #1

// Event
`define PE_IDX_WIDTH            $clog2(`PE_NUM)
`define DELTA_WIDTH             16
`define VERTEX_IDX_WIDTH        8
`define EVENT_WIDTH             24

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
`define XBAR_0_STAGES_NUM       2

// FPU
`define FPU_ADD					2'b00
`define FPU_SUB					2'b01
`define FPU_MUL					2'b01
`define FPU_DIV					2'b11

// PE
`define PE_THRESH               16'h0010 // PE threshold for stopping event propagation, float16 representation of 9.6e-7
`define PE_FPU_PIPE_DEPTH       3
`define PE_DAMPING_FACTOR	    16'h3ACC // float16 representation of 0.85
`define PE_NUM_OF_CORES         4
`define GEN_PER_PE              2
`define GEN_NUM                 `GEN_PER_PE * `PE_NUM

// Xbar from PEs to Event Queues
`define XBAR_1_STAGES_NUM       2

// Output buffer
`define OB_DEPTH                16
`define OB_FIFO_INPUT_NUM       4
`define OB_FIFO_OUTPUT_NUM      `PE_NUM

`define XLEN 16

// Memory
`define EDGE_MEM_ADDR_WIDTH	   14
`define COL_IDX_WORD_TAG_WIDTH 13

`define NUM_MEM_TAGS           15
`define MEM_SIZE_IN_BYTES      (256*256+256*16)
`define MEM_64BIT_LINES        (`MEM_SIZE_IN_BYTES/8)
`define MEM_LATENCY 		   100.0
`define MEM_LATENCY_IN_CYCLES (`MEM_LATENCY/`SYNTH_CLOCK_PERIOD+0.49999)
// the 0.49999 is to force ceiling(100/period).  The default behavior for
// float to integer conversion is rounding to nearest

// Memory bus commands control signals
typedef enum logic [1:0] {
	BUS_NONE     = 2'h0,
	BUS_LOAD     = 2'h1,
	BUS_STORE    = 2'h2
} BUS_COMMAND;

`ifndef CACHE_MODE
typedef enum logic [1:0] {
	BYTE = 2'h0,
	HALF = 2'h1,
	WORD = 2'h2,
	DOUBLE = 2'h3
} MEM_SIZE;
`endif

// Queue scheduler states
typedef enum logic [2:0] {
	I   = 3'h0,
	C   = 3'h1,
	B   = 3'h2,
	W   = 3'h3,
	R   = 3'h4
} QS_STATE;
//
