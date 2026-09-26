module FIRRegMap #(
    parameter DEVICE_ID = 4'h0,
    parameter VERSION_ID = 4'h0,
    parameter NUM_COEFFS = 20,
    parameter COEFF_W = 16
) (
    input logic clk,
    input logic rst_n,
    
    // Host Register Bus (from QSPI bridge)
    input logic [ADDR_W-1:0] addr,
    input logic              wr_en,
    input logic [15:0]       wr_data,
    input logic              rd_en,
    output logic [15:0]      rd_data,
    
    // Hardware side
    input logic [3:0]        status,
    output logic [3:0]       control,
    output logic signed [NUM_COEFFS-1:0][COEFF_W-1:0] coeffs
);
    
    localparam ADDR_W = 4 + (clog2(NUM_COEFFS)>>2);
    
    
    
endmodule
