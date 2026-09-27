module FIRRegMap #(
    parameter NUM_COEFFS = 20,
    parameter COEFF_WIDTH = 16
) (
    input logic clk,
    input logic rst_n,
    
    // Host Register Bus (from QSPI bridge)
    input logic [ADDR_WIDTH-1:0]    addr,
    input logic                     wr_en,
    input logic [COEFF_WIDTH-1:0]   wr_data,
    
    // Hardware side
    output logic [3:0]              control,
    output logic signed [0:NUM_COEFFS-1][COEFF_WIDTH-1:0] coeffs_to_taps
);
    localparam CONTROL_REG = 8'h00;
    localparam ADDR_WIDTH = 4 + $clog2(NUM_COEFFS);
    
    // control logic
    logic write_coeffs, enable_filter, soft_reset;

    // Control register
    always_ff @(posedge clk) begin : control_reg
        if (!rst_n) begin
            control <= 'b0;
        end else begin
            if (addr == CONTROL_REG && wr_en) begin
                control <= wr_data;
            end else if (soft_reset) begin      // need to clear the control register so we're not stuck in soft reset
                control <= 'b0;
            end
        end
    end

    assign enable_filter = control[1];
    assign soft_reset = control[0];

    // Status register TODO

    // address decoding
    always_comb begin : address_decoding
        if (addr[ADDR_WIDTH-1:4] != 0 && wr_en) begin
            write_coeffs = 1;
        end else begin
            write_coeffs = 0;
        end
    end

    // Coefficient registers
    always_ff @(posedge clk) begin : coeff_reg
        if (!rst_n) begin
            coeffs_to_taps <= 'b0;
        end else begin
            if (soft_reset) begin
                coeffs_to_taps <= 'b0;
            end else if (write_coeffs) begin
                coeffs_to_taps[addr-5'h10] <= wr_data;
            end
        end
    end    
    
endmodule
