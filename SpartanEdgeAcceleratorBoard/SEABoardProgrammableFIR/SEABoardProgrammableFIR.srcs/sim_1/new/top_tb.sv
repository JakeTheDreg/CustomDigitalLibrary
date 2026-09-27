`timescale 1ns / 1ns

import qspi_pkg::*;

module top_tb();

    logic clk;
    logic rst_n;
    
    qspi_t qspi_bus;

    // qspi interface / driver monitor
    qspi_if qspi_interface (
        .bus(qspi_bus)
    );

    // DUT
    top dut(
        .sys_clk(clk),                      // from board. Pin Name sysclk. 100MHz. Pin ID H4
        .rst_n(rst_n),                        // from board. Pin Name FPGA_RST. Pin ID D14
        .esp32_spi_clk(qspi_bus.sclk),      // from MCU. Pin name FPGA_QSPI_CLK. Pin ID H14
        .esp32_d(qspi_bus.mosi),            // mosi. Pin name FPGA_QSPI_D. Pin ID D2
        .esp32_q(qspi_bus.miso),            // miso. Pin name FPGA_QSPI_Q. Pin ID L14
        .esp32_wp(qspi_bus.wp),             // qio. Pin name FPGA_QSPI_WP. Pin ID J13
        .esp32_hd(qspi_bus.hd),             // qio. Pin name FPGA_QSPI_HD. Pin ID D13
        .esp32_cs_n(qspi_bus.csb)           // chip select, active low. Pin name FPGA_QSPI_CS. Pin ID M13
    );
    
    // clk gen
    initial begin : clk_gen
        clk = 1;
        forever #2 clk = !clk;
    end 
    
    // RST gen
    initial begin : rst_gen
        rst_n = 1;
        #50;
        rst_n = 0;
        qspi_interface.reset();
        #50;
        rst_n = 1;
    end
    
    // monitor bus
    logic [3:0] monitor_cmd;
    logic [7:0] monitor_addr;
    logic [15:0] monitor_data;
    initial begin : monitor
        forever begin
            qspi_interface.monitor(.cmd(monitor_cmd), .addr(monitor_addr), .data(monitor_data));
            $display("Transaction captured: cmd=%0h, addr=%0h, data=%0h", monitor_cmd, monitor_addr, monitor_data);
        end
    end
    
    // test
    initial begin : test
        #200;
        // qspi_interface.send_data(.cmd(4'b0), .addr(8'h10), .data(16'h0000), .sclk_period(100));
        // qspi_interface.send_data(.cmd(4'b0), .addr(8'h11), .data(16'h1111), .sclk_period(100));
        // qspi_interface.send_data(.cmd(4'b0), .addr(8'h20), .data(16'h2200), .sclk_period(100));
        // qspi_interface.send_data(.cmd(4'b0), .addr(8'h21), .data(16'h2211), .sclk_period(100));

        // write to all coefficients
        for(int i = 16; i < 36; i++) begin
            qspi_interface.send_data(.cmd(4'b0), .addr(i), .data(i*2), .sclk_period(100));
        end
        
        // send enable
        qspi_interface.send_data(.cmd(4'b0), .addr(8'h00), .data(4'b0010), .sclk_period(100));

        // send soft reset
        qspi_interface.send_data(.cmd(4'b0), .addr(8'h00), .data(4'b0001), .sclk_period(100));

        #300;
        $finish;
    end

endmodule
