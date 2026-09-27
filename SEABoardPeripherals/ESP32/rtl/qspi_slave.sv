////////////////////////////////////////////////
// Module name: qspi_slave
// Author: Jake Bramhall
// Purpose: QSPI Interface slave for Spartan Edge Accelerator development Board. 
//          Host processor is an ESP32-D0WDQ5
//          Collects data from QSPI interface from MCU host by sampling the QSPI interface
//          and reconstructing the transaction with edge detectors (FPGA clock runs much
//          faster than QSPI clock)
//
// TODO:    Implement slave return data
////////////////////////////////////////////////

module qspi_slave #(
    parameter NUM_CMD_FRAMES = 1,
    parameter NUM_ADDR_FRAMES = 2,
    parameter NUM_DATA_FRAMES = 4
    ) (
    input logic fpga_clk,   // from FPGA
    input logic rst_n,
    input logic spi_clk,    // from MCU. Pin name FPGA_QSPI_CLK. Pin ID H14
    input logic d,          // mosi. Pin name FPGA_QSPI_D. Pin ID D2
    input logic q,          // miso. Pin name FPGA_QSPI_Q. Pin ID L14
    input logic wp,         // qio. Pin name FPGA_QSPI_WP. Pin ID J13
    input logic hd,         // qio. Pin name FPGA_QSPI_HD. Pin ID D13
    input logic cs_n,       // chip select, active low. Pin name FPGA_QSPI_CS. Pin ID M13
    output logic [TRANSACTION_CMD_LENGTH-1:0] cmd_out,
    output logic [TRANSACTION_ADDR_LENGTH-1:0] addr_out,
    output logic [TRANSACTION_DATA_LENGTH-1:0] data_out,
    output logic data_out_ready
);

    localparam TRANSACTION_CMD_LENGTH = NUM_CMD_FRAMES * 4;
    localparam TRANSACTION_ADDR_LENGTH = NUM_ADDR_FRAMES * 4;
    localparam TRANSACTION_DATA_LENGTH = NUM_DATA_FRAMES * 4;
    localparam TRANSACTION_REG_WIDTH = TRANSACTION_CMD_LENGTH + TRANSACTION_ADDR_LENGTH + TRANSACTION_DATA_LENGTH;
    localparam FRAME_COUNTER_WIDTH = $clog2(NUM_CMD_FRAMES+NUM_ADDR_FRAMES+NUM_DATA_FRAMES);

    reg [2:0] sclk_reg, cs_reg;
    reg [1:0] hd_reg, wp_reg, q_reg, d_reg;     // data frame from MSB to LSB order
    reg [FRAME_COUNTER_WIDTH-1:0] frame_counter;
    reg [TRANSACTION_REG_WIDTH-1:0] transaction;

    logic sclk_rise, cs_active;

    ////////////////////////////////////////////////
    // Interface Data detection
    ////////////////////////////////////////////////
    // All data is put through a minimum of a 2-flop synchronizer to prevent metastability. (CDC from QSPI to FPGA domain)
    // SCLK and CS require an extra flop to detect edges after metastability has cleared.
    // SCLK
    always_ff @(posedge fpga_clk) begin : sclk_reg_ff
        if (!rst_n) begin
            sclk_reg <= 'b0;
        end else begin
            sclk_reg <= {sclk_reg[1:0], spi_clk};
        end
    end
    assign sclk_rise = sclk_reg[2:1] == 2'b01;
    // CS
    always_ff @(posedge fpga_clk) begin : cs_reg_ff
        if (!rst_n) begin
            cs_reg <= 3'b111;   // CS inactive is high
        end else begin
            cs_reg <= {cs_reg[1:0], cs_n};
        end
    end
    assign cs_active = !cs_reg[1];  // chip select is active low
    // Data lines
    always_ff @(posedge fpga_clk) begin : qspi_data_lines
        if (!rst_n) begin
            hd_reg <= 'b0;
            wp_reg <= 'b0;
            q_reg <= 'b0;
            d_reg <= 'b0;
        end else begin
            hd_reg <= {hd_reg[0], hd};
            wp_reg <= {wp_reg[0], wp};
            q_reg <= {q_reg[0], q};
            d_reg <= {d_reg[0], d};
        end
    end

    ////////////////////////////////////////////////
    // Frame Counter and transaction construction
    ////////////////////////////////////////////////
    // For each transaction, there are 4 data frames, totaling 16 bits of data. 
    // To signal data ready for device, need to count the frames and construct the transaction
    always_ff @(posedge fpga_clk) begin : frame_counter_ff
        if (!rst_n) begin
            frame_counter <= 'b0;
            transaction <= 'b0;
        end else begin
            if (!cs_active) begin
                frame_counter <= 'b0;   // cs is active low. If high, no transaction present
                transaction <= 'b0;
            end else if (sclk_rise) begin
                frame_counter <= frame_counter + 1;
                transaction <= {transaction[TRANSACTION_REG_WIDTH-5:0], hd_reg[1], wp_reg[1], q_reg[1], d_reg[1]};
            end
        end
    end

    ////////////////////////////////////////////////
    // Data output
    ////////////////////////////////////////////////
    always_ff @(posedge fpga_clk) begin : data_out_ff
        if (!rst_n) begin
            data_out_ready <= 'b0;
        end else begin
            data_out_ready <= cs_active && sclk_rise && (frame_counter == NUM_CMD_FRAMES+NUM_ADDR_FRAMES+NUM_DATA_FRAMES-1);
        end
    end

    assign cmd_out = transaction[TRANSACTION_REG_WIDTH-1:TRANSACTION_ADDR_LENGTH+TRANSACTION_DATA_LENGTH];
    assign addr_out = transaction[TRANSACTION_ADDR_LENGTH+TRANSACTION_DATA_LENGTH-1:TRANSACTION_DATA_LENGTH];
    assign data_out = transaction[TRANSACTION_DATA_LENGTH-1:0];
endmodule