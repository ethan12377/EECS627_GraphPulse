module pe (
    input logic clk,
    input logic reset,

    input  logic [23:0] event_in,
    input logic valid, // start
    output logic status,  // busy bit for upstream scheduler
    output logic [23:0] event_out,

    // read node information from memory
    output logic [31:0] pe2mem_req,
    input logic [63:0] mem2pe_data;
);

    logic [7:0] node_id;
    logic [16:0] delta;

    assign node_id = event_in[23:16];
    assign delta = event_in[15:0];

    always_ff @(posedge clk)
    begin
        // if receiving a valid input, send a request to memory and check if delta over threshold
        // read node data, apply delta with fpu, update data in mem
        // grab adjacency list from mem
        // new event stream generation: pipelined fpu for 1 per cycle?
        // update status to scheduler when done
    end

endmodule
