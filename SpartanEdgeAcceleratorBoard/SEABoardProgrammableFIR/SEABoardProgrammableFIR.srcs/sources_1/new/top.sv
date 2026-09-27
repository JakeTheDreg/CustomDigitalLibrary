module top (
    input logic sys_clk,            // from board. Pin Name sysclk. 100MHz. Pin ID H4
    input logic rst_n,              // from board. Pin Name FPGA_RST. Pin ID D14
    input logic esp32_spi_clk,      // from MCU. Pin name FPGA_QSPI_CLK. Pin ID H14
    input logic esp32_d,            // mosi. Pin name FPGA_QSPI_D. Pin ID D2
    input logic esp32_q,            // miso. Pin name FPGA_QSPI_Q. Pin ID L14
    input logic esp32_wp,           // qio. Pin name FPGA_QSPI_WP. Pin ID J13
    input logic esp32_hd,           // qio. Pin name FPGA_QSPI_HD. Pin ID D13
    input logic esp32_cs_n          // chip select, active low. Pin name FPGA_QSPI_CS. Pin ID M13
);

    (* keep = "yes" *) logic [3:0] slave_cmd_reg;
    (* keep = "yes" *) logic [8:0] slave_addr_reg;
    (* keep = "yes" *) logic [15:0] slave_data_reg;
    (* keep = "yes" *) logic slave_data_ready_reg;
    (* keep = "yes" *) logic enable_filter, soft_reset;
    (* keep = "yes" *) logic [19:0] [15:0] coeffs_to_taps;

    qspi_slave u_qspi_slave(
        .fpga_clk(sys_clk),
        .rst_n(rst_n),
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
        .rst_n(rst_n),
        .addr(slave_addr_reg),
        .wr_en(slave_data_ready_reg),
        .wr_data(slave_data_reg),
        .control({enable_filter, soft_reset}),
        .coeffs_to_taps(coeffs_to_taps)
    );

endmodule