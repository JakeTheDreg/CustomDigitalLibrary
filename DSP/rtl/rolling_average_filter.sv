////////////////////////////////////////////////
// Module name: rolling_average_filter
// Author: Jake Bramhall
// Purpose: Implements a rolling average filter.
//          Requires NUM_TAPS to be power of two to simplify design.
////////////////////////////////////////////////
module rolling_average_filter
  #(parameter NUM_TAPS = 2,         // Must be power of 2
    parameter DATA_WIDTH = 8
) (
    input clk,
    input rst_n,
    input enable,
    input [DATA_WIDTH-1:0] data_in,
    input data_in_valid,
    input receiver_ready,
    output filter_ready,
    output [DATA_WIDTH-1:0] data_out,
    output data_out_valid
);

localparam DIVISOR = $clog2(NUM_TAPS);
localparam ACC_WIDTH = DATA_WIDTH + DIVISOR;

logic [DATA_WIDTH-1:0] data_line [0:NUM_TAPS-1];
logic [ACC_WIDTH-1:0] sum [0:NUM_TAPS-1];
logic [DATA_WIDTH-1:0] average;
logic advance_pipeline;

assign advance_pipeline = enable && data_in_valid && receiver_ready;

// tap line shift register
genvar i;
generate
    for (i = 0; i < NUM_TAPS; i = i + 1) begin
        always_ff @(posedge clk) begin
            if (!rst_n) begin
                data_line[i] <= 'b0;
            end else if (!enable) begin
                data_line[i] <= 'b0;
            end else if (advance_pipeline) begin
                if (i == 0) begin
                    data_line[i] <= data_in;
                end else begin
                    data_line[i] <= data_line[i-1];
                end
            end
        end
    end
endgenerate

// adder
generate
    for (i = 0; i < NUM_TAPS; i = i + 1) begin
        if (i == 0) begin
            assign sum[i] = data_line[i];
        end else begin
            assign sum[i] = sum[i-1] + data_line[i];
        end
    end
endgenerate

assign average = sum[NUM_TAPS-1] >> DIVISOR;

assign filter_ready = enable && receiver_ready;
assign data_out = average;
assign data_out_valid = 1;  // output is always the average of everything in the pipeline

endmodule