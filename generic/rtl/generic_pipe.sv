////////////////////////////////////////////////
// Module name: gen_pipe
// Author: Jake Bramhall
// Purpose: Generic pipeline module.
//          Configurable width and depth.
//          Currently no internal peeking
////////////////////////////////////////////////
module gen_pipe #(
    parameter DATA_WIDTH = 1,
    parameter PIPE_DEPTH = 1
) (
    input clk,
    input rst_n,
    input [DATA_WIDTH-1:0] data_i,
    output [DATA_WIDTH-1:0] data_o
);
 
generate
    if (PIPE_DEPTH == 0) begin : g_wire
        assign data_o = data_i;
    end else begin : g_pipe
        logic [DATA_WIDTH-1:0] pipe_reg [0:PIPE_DEPTH-1];
        integer i;
 
        always_ff @(posedge clk or negedge rst_n) begin
            if (!rst_n) begin
                for (i = 0; i < PIPE_DEPTH; i = i + 1) begin
                    pipe_reg[i] <= '0;
                end
            end else begin
                pipe_reg[0] <= data_i;
                for (i = 1; i < PIPE_DEPTH; i = i + 1) begin
                    pipe_reg[i] <= pipe_reg[i-1];
                end
            end
        end
 
        assign data_o = pipe_reg[PIPE_DEPTH-1];
    end
endgenerate
 
endmodule