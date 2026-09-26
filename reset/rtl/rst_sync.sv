// Generic reset synchronizer for FPGA
module rst_sync #(
    parameter IS_NEGEDGE = 1,
    parameter NUM_STAGES = 2
)
(
    input clk,
    input rst_i,
    output rst_o
);

logic [NUM_STAGES-1:0] rst_pipe;

generate
    if(IS_NEGEDGE == 1) begin
        always_ff @(posedge clk or negedge rst_i) begin : g_neg_rst
            if(!rst_i) rst_pipe <= '0;
            else rst_pipe <= {rst_pipe[NUM_STAGES-2:0], 1'b1};
        end
        
        assign rst_o = rst_pipe[NUM_STAGES-1];
        
    end else begin
        always_ff @(posedge clk or posedge rst_i) begin : g_pos_rst
            if(rst_i) rst_pipe <= '1;
            else rst_pipe <= {rst_pipe[NUM_STAGES-2:0], 1'b0};
        end

        assign rst_o = rst_pipe[NUM_STAGES-1];

    end
endgenerate

endmodule