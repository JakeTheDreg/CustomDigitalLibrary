////////////////////////////////////////////////
// Module name: gen_serializer
// Author: Jake Bramhall
// Purpose: Convert parallel data to serial data
//          TODO: Needs to be tested
////////////////////////////////////////////////
module gen_serializer
  #(parameter IN_DATA_WIDTH = 8,
    parameter BIG_ENDIAN = 1            // default big endian
) (
    input clk,
    input rst_n,
    input [IN_DATA_WIDTH-1:0] data_in,
    input enable,
    input data_in_valid,                // data_in is valid
    output ready,                       // ready for new data
    output reg data_out_valid,
    output reg data_out                 // TODO: parameterize data_out to be more than one bit
);

    localparam COUNTER_WIDTH = $clog2(IN_DATA_WIDTH+1);
    reg [COUNTER_WIDTH-1:0] shift_counter;
    reg [IN_DATA_WIDTH-1:0] shift_reg;

    typedef enum logic {IDLE = 1'b0, SHIFTING = 1'b1} state_t;
    state_t state, next_state;
    
    // Only signal ready to accept new data when there is enabled in IDLE
    assign ready = (state == IDLE) && enable;

    logic start_shifting;
    assign start_shifting = (state == IDLE) && data_in_valid && enable;

    // state machine
    always_comb begin
        next_state = state;         // default
        if (state == IDLE) begin
            if (data_in_valid && enable) next_state = SHIFTING;
            else next_state = IDLE;
        end else begin              // SHIFTING
            if (shift_counter == 1 && enable) next_state = IDLE;
            else next_state = SHIFTING;
        end
    end

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end


    // shift counter
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            shift_counter <= 'b0;
        end else if (enable) begin
            if (start_shifting) begin
                shift_counter <= IN_DATA_WIDTH;
            end else if (state == SHIFTING && shift_counter > 0) begin
                shift_counter <= shift_counter - 1;
            end
        end
    end

    // serializer
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            data_out <= 'b0;
            shift_reg <= 'b0;
        end else if (enable) begin
            if (start_shifting) begin
                shift_reg <= BIG_ENDIAN ? (data_in << 1) : (data_in >> 1);
                data_out <= BIG_ENDIAN ? data_in[IN_DATA_WIDTH-1] : data_in[0];
            end else if (state == SHIFTING && shift_counter > 0) begin
                if (BIG_ENDIAN) begin
                    data_out <= shift_reg[IN_DATA_WIDTH-1];
                    shift_reg <= shift_reg << 1;
                end else begin
                    data_out <= shift_reg[0];
                    shift_reg <= shift_reg >> 1;
                end
            end
        end
    end

    // data out valid flag
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            data_out_valid <= 'b0;
        end else begin
            data_out_valid <= (state == SHIFTING) && shift_counter > 0;
        end
    end

endmodule