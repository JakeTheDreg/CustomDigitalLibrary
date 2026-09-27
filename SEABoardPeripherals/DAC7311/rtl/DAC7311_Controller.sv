module DAC7311_Controller #(
    parameter IN_DATA_WIDTH = 8 // If more than 12, only top 12-bits of data_in will be accepted
    ) (       
    input clk,
    input rst_n,
    input enable,
    input data_in_valid,
    input [IN_DATA_WIDTH-1:0] data_in,
    output logic dac_clk,
    output logic sync_n,
    output logic dac_data,
    output logic ready
);

    localparam DAC_FRAME_WIDTH = 16;    // DAC7311 expects 16-bit data frame
    localparam DAC_DATA_FIELD = 12;     // DB11:DB0
    localparam DAC_POWER_ON = 2'b00;

    typedef enum logic [1:0] {
        IDLE = 2'b0,
        SHIFTING = 2'b01,
        EXIT = 2'b10
    } state_t;
    state_t state, next_state;

    reg [DAC_FRAME_WIDTH-1:0] data_reg;
    reg [$clog2(DAC_FRAME_WIDTH)-1:0] shift_counter;
    logic [DAC_DATA_FIELD-1:0] data_field;

    // pack the data field up front to ensure the correct data is fed to the DAC
    generate
        if (IN_DATA_WIDTH >= DAC_DATA_FIELD) begin
            assign data_field = data_in[IN_DATA_WIDTH-1 -: DAC_DATA_FIELD];
        end else begin
            assign data_field = {data_in, {(DAC_DATA_FIELD-IN_DATA_WIDTH){1'b0}}};
        end
    endgenerate

    ////////////////////////////////////////////////////////////
    // State machine
    ////////////////////////////////////////////////////////////
    always_comb begin : state_table
        case (state)
            IDLE: begin
                if (data_in_valid) next_state = SHIFTING;
                else next_state = IDLE;
            end
            SHIFTING: begin
                if (shift_counter > 0) next_state = SHIFTING;
                else next_state = EXIT;
            end
            EXIT: next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end

    always_ff @(posedge clk) begin : state_reg
        if (!rst_n) begin
            state <= IDLE;
        end else if (enable) begin
            state <= next_state;
        end
    end

    ////////////////////////////////////////////////////////////
    // Shift Register
    ////////////////////////////////////////////////////////////
    always_ff @(posedge clk) begin : data_reg_control
        if (!rst_n) begin
            data_reg <= '0;
            shift_counter <= '0;
        end else if (enable) begin
            case (state)
                IDLE: begin
                    if (data_in_valid) begin
                        data_reg <= {DAC_POWER_ON, data_field, 2'b00};
                        shift_counter <= DAC_FRAME_WIDTH - 1;
                    end
                end

                SHIFTING: begin
                    data_reg <= {data_reg[DAC_FRAME_WIDTH-2:0], 1'b0};
                    shift_counter <= shift_counter - 1'b1;
                end

                EXIT: begin
                    data_reg <= '0;
                    shift_counter <= DAC_FRAME_WIDTH - 1;
                end
            endcase
        end
    end


    ////////////////////////////////////////////////////////////
    // Output Assignment
    ////////////////////////////////////////////////////////////
    assign dac_clk = clk;

    always_comb begin : dac_data_map
        case (state)
            IDLE: dac_data = 1'b0;
            SHIFTING: dac_data = data_reg[DAC_FRAME_WIDTH-1];
            EXIT: dac_data = 1'b0;
            default: dac_data = 1'b0;
        endcase
    end

    always_comb begin : DAC7311_enable_bit
        if (enable) begin
            case(state)
                IDLE: sync_n = 1'b1;
                SHIFTING: sync_n = 1'b0;
                EXIT: sync_n = 1'b1;
                default: sync_n = 1'b1;
            endcase
        end else begin
            sync_n = 1'b1;
        end
    end

    assign ready = (state == IDLE);

endmodule