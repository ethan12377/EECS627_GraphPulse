module GraphPulse (
    input           clock,
    input           reset,
    input [15:0]    num_vertex,
    input  [3:0]    edgemem_response,
    input [63:0]    edgemem_ld_data,
    input  [3:0]    edgemem_tag,
    input  [3:0]    vertexmem_response,
    input [63:0]    vertexmem_ld_data,
    input  [3:0]    vertexmem_tag,

    output          converge,
    output [1:0]    edgemem_command,
    output [`XLEN-1:0] edgemem_addr,
    output [63:0]   edgemem_st_data,
    output [1:0]    edgemem_size,
    output [1:0]    vertexmem_command,
    output [`XLEN-1:0] vertexmem_addr,
    output [63:0]   vertexmem_st_data,
    output [1:0]    vertexmem_size
);

endmodule // GraphPulse
