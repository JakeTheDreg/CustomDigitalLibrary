////////////////////////////////////////////////
// Module name: gen_mac
// Author: Jake Bramhall
// Purpose: Generic multiply accumulate module.
//          Can choose between using lookup tables or
//          DSP48 macro (recommended)
//          C = A * B + D
////////////////////////////////////////////////
module gen_mac #(
    parameter NUM_TAPS = 1,
    parameter A_DATA_WIDTH = 25,
    parameter B_DATA_WIDTH = 18,
    parameter D_DATA_WIDTH = 18,
    parameter C_DATA_WIDTH = A_DATA_WIDTH+B_DATA_WIDTH,     // If > 43, will not use a single DSP slice and LUT won't synth at 100MHz 
    parameter USE_DSP = "yes",
    parameter DSP_LATENCY = 1,                              // set pipeline latency of DSP48, only available if USE_DSP = "yes"
    parameter ADDSUB = 1                                    // parameter to select add or sub function for accumulator. 1 = +, 0 = -
) (
    input logic clk,
    input logic rst_n,
    input logic [A_DATA_WIDTH-1:0] a_data,
    input logic [B_DATA_WIDTH-1:0] b_data,
    input logic [D_DATA_WIDTH-1:0] d_data,
    input logic carryin,
    output logic [C_DATA_WIDTH-1:0] c_data
);

    generate
        if (USE_DSP == "no") begin         // implement in LUT
            // registering inputs
            logic [A_DATA_WIDTH-1:0] a_data_reg;
            logic [B_DATA_WIDTH-1:0] b_data_reg;
            logic [D_DATA_WIDTH-1:0] d_data_reg;

            always_ff @(posedge clk) begin
                if (!rst_n) begin
                    a_data_reg <= 'b0;
                    b_data_reg <= 'b0;
                    d_data_reg <= 'b0;
                    c_data <= 'b0;
                end else begin
                    a_data_reg <= a_data;
                    b_data_reg <= b_data;
                    d_data_reg <= d_data;
                    c_data <= ADDSUB ? (a_data_reg * b_data_reg + d_data_reg) :
                                    (a_data_reg * b_data_reg - d_data_reg);
                end
            end
        end else begin                              // implement in DSP48 slices
            logic dsp_rst = !rst_n;         // reset is active High for DSP slices
            MACC_MACRO #(
                .DEVICE("7SERIES"),         // Target Device: "7SERIES" 
                .LATENCY(DSP_LATENCY),      // Desired clock cycle latency, 1-4
                .WIDTH_A(A_DATA_WIDTH),     // Multiplier A-input bus width, 1-25
                .WIDTH_B(B_DATA_WIDTH),     // Multiplier B-input bus width, 1-18
                .WIDTH_P(C_DATA_WIDTH)      // Accumulator output bus width, 1-48
            ) MACC_MACRO_inst (
                .P(c_data),                 // MACC output bus, width determined by WIDTH_P parameter
                .A(a_data),                 // MACC input A bus, width determined by WIDTH_A parameter
                .ADDSUB(ADDSUB),            // 1-bit add/sub input, high selects add, low selects subtract
                .B(b_data),                 // MACC input B bus, width determined by WIDTH_B parameter
                .CARRYIN(carryin),          // 1-bit carry-in input to accumulator
                .CE(1),                     // 1-bit active high input clock enable
                .CLK(clk),                  // 1-bit positive edge clock input
                .LOAD(1),                   // 1-bit active high input load accumulator enable
                .LOAD_DATA(d_data),         // Load accumulator input data, width determined by WIDTH_P parameter
                .RST(dsp_rst)               // 1-bit input active high reset
            );
        end
    endgenerate
    
endmodule