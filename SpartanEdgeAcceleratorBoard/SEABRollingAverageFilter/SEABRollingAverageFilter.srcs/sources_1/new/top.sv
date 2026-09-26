`timescale 1ns / 1ns
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Jake Bramhall
// 
// Create Date: 07/06/2026 05:53:19 PM
// Design Name: top
// Module Name: top
// Project Name: Spartan Edge Accelerator Board Rolling Average Filter
// Target Devices: Spartan Edge Accelerator Board
// Tool Versions: Vivado 2025.2
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
module top(
    input logic clk,
    input logic rst_n,
    input logic enable,
    input logic [ADC_DATA_WIDTH-1:0] adc_data,
    output logic adc_en_n,
    output logic adc_clk,
    output logic dac_clk,
    output logic dac_data,
    output logic dac_sync_n
);
localparam ADC_DATA_WIDTH = 8;
 
wire sys_clk;
wire clk_locked;
wire sys_enable;
wire filter_ready, dac_ready;
wire adc_valid, filter_valid;
wire [ADC_DATA_WIDTH-1:0] adc_2_filter_data, filter_2_dac_data;
 
////////////////////////////////////////////////////////////
// Reset tree
////////////////////////////////////////////////////////////
 
// Clean up the raw external async reset in the `clk` (reference clock)
// domain before it drives the clocking wizard's own reset input.
wire clk_domain_rst_n;
rst_sync #(.IS_NEGEDGE(1)) u_clkref_rst_sync (
    .clk   (clk),
    .rst_i (rst_n),
    .rst_o (clk_domain_rst_n)
);
 
clk_wiz_0 u_clk_div(
  .clk_out1(sys_clk),
  .resetn(clk_domain_rst_n),
  .locked(clk_locked),
  .clk_in1(clk)
 );
 
// Bring the same external reset into the sys_clk domain 
wire ext_rst_n_sync;
rst_sync #(.IS_NEGEDGE(1)) u_ext_rst_sync (
    .clk   (sys_clk),
    .rst_i (rst_n),
    .rst_o (ext_rst_n_sync)
);

wire lock_rst_n_sync;
rst_sync #(.IS_NEGEDGE(1)) u_lock_sync (
    .clk   (sys_clk),
    .rst_i (clk_locked),
    .rst_o (lock_rst_n_sync)
);
 
wire sys_rst_n = ext_rst_n_sync & lock_rst_n_sync;
 
////////////////////////////////////////////////////////////
// enable CDC
////////////////////////////////////////////////////////////
// enable is assumed to originate outside the sys_clk domain (board pin /
// control register) and directly gates state transitions in the ADC and
// DAC FSMs, so it gets its own 2-flop synchronizer.
generic_pipe #(
    .DATA_WIDTH(1),
    .PIPE_DEPTH(2)
) u_enable_sync (
    .clk(sys_clk),
    .rst_n(sys_rst_n),
    .data_i(enable),
    .data_o(sys_enable)
);
 
////////////////////////////////////////////////////////////
// Pipeline
////////////////////////////////////////////////////////////
ADC1173_Controller_simple u_adc(
    .clk(sys_clk),                      
    .rst_n(sys_rst_n),                    
    .enable(sys_enable),
    .receiver_ready(filter_ready),           
    .adc_data_i(adc_data),
    .adc_data_o(adc_2_filter_data),
    .adc_data_valid(adc_valid),
    .adc_en_n(adc_en_n),            
    .adc_clk(adc_clk)              
);
 
gen_rolling_average_filter #(
    .NUM_TAPS(64),
    .DATA_WIDTH(ADC_DATA_WIDTH)
) u_filter(
    .clk(sys_clk),
    .rst_n(sys_rst_n),
    .enable(sys_enable),
    .data_in(adc_2_filter_data),
    .data_in_valid(adc_valid),
    .receiver_ready(dac_ready),
    .filter_ready(filter_ready),
    .data_out(filter_2_dac_data),
    .data_out_valid(filter_valid)
);
 
DAC7311_Controller #(
    .IN_DATA_WIDTH(ADC_DATA_WIDTH)
) u_dac(
    .clk(sys_clk),
    .rst_n(sys_rst_n),
    .enable(sys_enable),
    .data_in_valid(filter_valid),
    .data_in(filter_2_dac_data),
    .dac_clk(dac_clk),
    .sync_n(dac_sync_n),
    .dac_data(dac_data),
    .ready(dac_ready)
);
 
endmodule
