module ADC1173_Controller_simple #(
    parameter CYCLES_PER_SAMPLE_M1 = 17
) (
    input clk,                      // Logic clk for controller
    input rst_n,                    // active low reset
    input enable,
    input receiver_ready,           // downstream device ready to accept data
    input [ADC_DATA_WIDTH-1:0] adc_data_i,
    output logic [ADC_DATA_WIDTH-1:0] adc_data_o,
    output logic adc_data_valid,
    output logic adc_en_n,            // ADC1173 enable active low
    output logic adc_clk              // adc_clk, feed through clk
);
    localparam ADC_DATA_WIDTH = 8;

    assign adc_clk = clk;           // feed through clk
    assign adc_en_n = !enable;      // enable ADC when module enabled

    

    generate
        ////////////////////////////////////
        // Only scan ADC once every CYCLES-1
        ////////////////////////////////////
        if (CYCLES_PER_SAMPLE_M1 > 0) begin : g_delayed_samplerate
            localparam COUNTER_WIDTH = (CYCLES_PER_SAMPLE_M1 > 1) ? $clog2(CYCLES_PER_SAMPLE_M1+1) : 1;
            reg [COUNTER_WIDTH-1:0] cycle_counter;
            
            typedef enum logic [1:0] {
                IDLE,
                COUNTING,
                OUTPUT
            } state_t;
            state_t state, next_state;

            wire ready_to_output, handshake_good;
            assign ready_to_output = (cycle_counter == (CYCLES_PER_SAMPLE_M1));
            assign handshake_good = adc_data_valid && receiver_ready;
            
            // next state logic
            always_comb begin : state_table
                if (state == IDLE) begin
                    next_state = enable ? COUNTING : IDLE;
                end
                else if (state == COUNTING && enable) begin
                    next_state = ready_to_output ? OUTPUT : COUNTING;
                end
                else if (state == OUTPUT && enable) begin
                    next_state = handshake_good ? COUNTING : OUTPUT;
                end
                else begin
                    next_state = IDLE;
                end
            end

            always_ff @(posedge clk) begin : state_reg
                if (!rst_n) begin
                    state <= IDLE;
                end else begin
                    state <= next_state;
                end
            end

            // Counter
            always_ff @(posedge clk) begin : counter_reg
                if (!rst_n) begin
                    cycle_counter <= 'b0;
                end else begin
                    if (state == IDLE) begin
                        if (enable) cycle_counter <= 1;
                    end
                    else if(state == COUNTING) begin
                        cycle_counter <= cycle_counter + 1;
                    end
                    else if(state == OUTPUT) begin
                        if (enable && handshake_good) cycle_counter <= 1;
                    end
                end
            end

            // output data
            always_ff @( posedge clk ) begin : g_output_data
                if (!rst_n) begin
                    adc_data_o <= 0;
                end else begin
                    if (state == COUNTING && ready_to_output) begin
                        adc_data_o <= adc_data_i;
                    end
                end
            end

            assign adc_data_valid = (state == OUTPUT);

        end

        ////////////////////////////////////
        // Feed through ADC output
        ////////////////////////////////////
        else begin : g_feedthrough_samplerate
            always_ff @(posedge clk) begin : g_feedthrough_data
                if (!rst_n) begin
                    adc_data_o <= 'b0;
                end else begin
                    adc_data_o <= adc_data_i;
                end
            end

            assign adc_data_valid = 1'b1;

        end
                    
    endgenerate

    
endmodule