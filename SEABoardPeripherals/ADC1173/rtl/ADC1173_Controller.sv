module ADC1173_Controller
#(parameter CYCLES_PER_SAMPLE = 1, 
  parameter DATA_BUFFER_LEN = 8
)(
    input clk,                      // Logic clk for controller
    input rst_n,                    // active low reset
    input receiver_ready,           // downstream device ready to accept data
    input [ADC_DATA_WIDTH-1:0] adc_data_i,
    output reg [ADC_DATA_WIDTH-1:0] adc_data_o,
    output logic adc_data_valid,
    output reg adc_en_n,            // ADC1173 enable active low
    output adc_clk                  // adc_clk, feed through clk
);

localparam ADC_DATA_WIDTH = 8;
localparam COUNTER_WIDTH = (CYCLES_PER_SAMPLE > 1) ? $clog2(CYCLES_PER_SAMPLE) : 1;

assign adc_clk = clk;                                                       // Max 100 MHz

reg [ADC_DATA_WIDTH-1:0] data_buffer [0:DATA_BUFFER_LEN-1];                 // circular data buffer
logic [$clog2(DATA_BUFFER_LEN)-1:0] waddr, raddr, next_waddr, next_raddr;   // r/w pointers for data buffer
logic waddr_phase, raddr_phase, next_waddr_phase, next_raddr_phase;         // phase bits to determine if full or empty
logic buffer_full, buffer_empty;                                            // buffer status flags

logic [COUNTER_WIDTH-1:0] cycle_counter;                                    // used to decimate sample rate

// buffer status calculation
always_comb begin
    buffer_empty = 1'b1;
    buffer_full = 1'b0;
    if(waddr == raddr) begin
        if(waddr_phase == raddr_phase) begin
            buffer_full = 1'b1;
        end else begin
            buffer_empty = 1'b1;
        end
    end
    adc_data_valid = !buffer_empty;
end

// adc_en_n control
always_ff@(posedge clk) begin
    if(!rst_n) begin
        adc_en_n <= 1'b1;
    end else begin
        adc_en_n <= 1'b0;
    end
end

// counter for decimation
always_ff @(posedge clk) begin
    if (!rst_n) begin
        cycle_counter <= 'b0;
    end else begin
        if (cycle_counter == CYCLES_PER_SAMPLE-1) begin
            cycle_counter <= 'b0;
        end else begin
            cycle_counter <= cycle_counter + 1'b1;
        end
    end
end

// write data control
always_comb begin
    if (waddr == DATA_BUFFER_LEN - 1) begin
        next_waddr = 'b0;
        next_waddr_phase = !waddr_phase;
    end else begin
        next_waddr = waddr + 1'b1;
        next_waddr_phase = waddr_phase;
    end
end

always_ff @(posedge clk) begin
    if(!rst_n) begin
        waddr <= 'b0;
        waddr_phase <= 'b0;
    end else begin
        if (cycle_counter == CYCLES_PER_SAMPLE-1 && !buffer_full) begin
            data_buffer[waddr] <= adc_data_i;
            waddr <= next_waddr;
            waddr_phase <= next_waddr_phase;
        end
    end
end

// read data control
always_comb begin
    if (raddr == DATA_BUFFER_LEN - 1) begin
        next_raddr = 'b0;
        next_raddr_phase = !raddr_phase;
    end else begin
        next_raddr = raddr + 1'b1;
        next_raddr_phase = raddr_phase;
    end
end

always_ff @(posedge clk) begin
    if (!rst_n) begin
        raddr <= 'b0;
        raddr_phase <= 'b1;
        adc_data_o <= 'b0;
    end else begin
        if (receiver_ready && !buffer_empty) begin
            adc_data_o <= data_buffer[raddr];
            raddr <= next_raddr;
            raddr_phase <= next_raddr_phase;
        end
    end
end

endmodule