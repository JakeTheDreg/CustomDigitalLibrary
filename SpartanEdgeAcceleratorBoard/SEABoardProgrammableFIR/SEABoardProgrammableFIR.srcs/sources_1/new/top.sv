module top (
    input logic clk,                            // from board. Pin Name sysclk. 100MHz. Pin ID H4
    input logic rst_n,                          // from board. Pin Name FPGA_RST. Pin ID D14
    input logic enable,                         // from board. Pin Name FPGA_IO10. Pin ID C3

    // QSPI inputs
    input logic esp32_spi_clk,                  // from MCU. Pin name FPGA_QSPI_CLK. Pin ID H14
    input logic esp32_d,                        // mosi. Pin name FPGA_QSPI_D. Pin ID D2
    input logic esp32_q,                        // miso. Pin name FPGA_QSPI_Q. Pin ID L14
    input logic esp32_wp,                       // qio. Pin name FPGA_QSPI_WP. Pin ID J13
    input logic esp32_hd,                       // qio. Pin name FPGA_QSPI_HD. Pin ID D13
    input logic esp32_cs_n,                     // chip select, active low. Pin name FPGA_QSPI_CS. Pin ID M13

    // ADC interface
    input logic [ADC_DATA_WIDTH-1:0] adc_data,  // Pin Name ADC_D*. Pin ID 7:0 is H12, H11, C11, F12, E12, D12, J2, J3
    output logic adc_en_n,                      // Pin Name ADC_EN. Pin ID J4
    output logic adc_clk,                       // Pin Name ADC_CLK. Pin ID C5

    // DAC interface
    output logic dac_clk,                       // Pin Name DAC_SCLK. Pin ID M1
    output logic dac_data,                      // Pin Name DAC_DIN. Pin ID L1
    output logic dac_sync_n                     // Pin Name DAC_SYNC. Pin ID N1
);
    localparam ADC_DATA_WIDTH = 8;

    // clk and reset signals
    logic sys_clk;  // 50MHz main clock from pll
    logic clk_locked;
    logic sys_enable;
    logic clk_domain_rst_n;
    logic ext_rst_n_sync;
    logic lock_rst_n_sync;
    
    // control signals
    logic [3:0] slave_cmd_reg;
    logic [8:0] slave_addr_reg;
    logic [15:0] slave_data_reg;
    logic slave_data_ready_reg;
    logic enable_filter, soft_reset;
    logic [19:0] [15:0] coeffs_to_taps;

    // adc signals
    logic [ADC_DATA_WIDTH-1:0] adc_2_filter_data;
    logic adc_data_valid;

    // filter signals
    logic [ADC_DATA_WIDTH-1:0] filter_2_dac_data;
    logic filter_ready;
    logic filter_data_valid;

    // dac signals
    logic dac_ready;

    
    /////////////////////////////////////////
    // CLK gen and Reset sync
    /////////////////////////////////////////
    // Clean up the raw external async reset in the `clk` (reference clock)
    // domain before it drives the clocking wizard's own reset input.
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
    rst_sync #(.IS_NEGEDGE(1)) u_ext_rst_sync (
        .clk   (sys_clk),
        .rst_i (rst_n),
        .rst_o (ext_rst_n_sync)
    );

    rst_sync #(.IS_NEGEDGE(1)) u_lock_sync (
        .clk   (sys_clk),
        .rst_i (clk_locked),
        .rst_o (lock_rst_n_sync)
    );
    
    logic sys_rst_n = ext_rst_n_sync & lock_rst_n_sync;

    generic_pipe #(
        .DATA_WIDTH(1),
        .PIPE_DEPTH(2)
    ) u_enable_sync (
        .clk(sys_clk),
        .rst_n(sys_rst_n),
        .data_i(enable),
        .data_o(sys_enable)
    );

    /////////////////////////////////////////
    // Control Path
    /////////////////////////////////////////
    qspi_slave u_qspi_slave(
        .fpga_clk(sys_clk),
        .rst_n(sys_rst_n),
        .spi_clk(esp32_spi_clk),
        .d(esp32_d),
        .q(esp32_q),
        .wp(esp32_wp),
        .hd(esp32_hd),
        .cs_n(esp32_cs_n),
        .cmd_out(slave_cmd_reg),
        .addr_out(slave_addr_reg),
        .data_out(slave_data_reg),
        .data_out_ready(slave_data_ready_reg)
    );

    FIRRegMap u_regmap(
        .clk(sys_clk),
        .rst_n(sys_rst_n),
        .addr(slave_addr_reg),
        .wr_en(slave_data_ready_reg),
        .wr_data(slave_data_reg),
        .control({enable_filter, soft_reset}),
        .coeffs_to_taps(coeffs_to_taps)
    );

    /////////////////////////////////////////
    // Datapath
    /////////////////////////////////////////
    ADC1173_Controller_simple u_adc_controller(
        .clk(sys_clk),                
        .rst_n(sys_rst_n),          
        .enable(sys_enable),
        .receiver_ready(filter_ready),
        .adc_data_i(adc_data),
        .adc_data_o(adc_2_filter_data),
        .adc_data_valid(adc_data_valid),
        .adc_en_n(adc_en_n),      
        .adc_clk(adc_clk)    
    );

    // Filter
    // placeholder

    DAC7311_Controller u_dac_controller(
        .clk(sys_clk),
        .rst_n(sys_rst_n),
        .enable(sys_enable),
        .data_in_valid(filter_data_valid),
        .data_in(filter_2_dac_data),
        .dac_clk(dac_clk),
        .sync_n(dac_sync_n),
        .dac_data(dac_data),
        .ready(dac_ready)
    );

endmodule