`timescale 1ns/1ns

module tb_gen_serializer;

    localparam IN_DATA_WIDTH = 8;
    localparam BIG_ENDIAN = 1;

    logic clk;
    logic rst_n;
    logic [IN_DATA_WIDTH-1:0] data_in;
    logic enable;
    logic data_in_valid;
    logic ready;
    logic data_out_valid;
    logic data_out;

    // DUT
    gen_serializer #(
        .IN_DATA_WIDTH(IN_DATA_WIDTH),
        .BIG_ENDIAN(BIG_ENDIAN)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .data_in(data_in),
        .enable(enable),
        .data_in_valid(data_in_valid),
        .ready(ready),
        .data_out_valid(data_out_valid),
        .data_out(data_out)
    );

    // Clock generation (10ns period)
    always #5 clk = ~clk;

    // Stimulus
    initial begin
        // Init
        clk = 0;
        rst_n = 0;
        enable = 0;
        data_in_valid = 0;
        data_in = 0;

        // Reset
        #20;
        rst_n = 1;
        enable = 1;

        // Wait a few cycles
        #20;

        // Send first byte
        @(posedge clk);
        data_in = 8'b1011_0011;
        data_in_valid = 1;

        @(posedge clk);
        data_in_valid = 0;

        // Wait for serialization to complete
        wait (ready == 1);

        // Send another byte
        @(posedge clk);
        data_in = 8'b1100_1100;
        data_in_valid = 1;

        @(posedge clk);
        data_in_valid = 0;

        // Let it run
        #200;

        $finish;
    end

    // Monitor signals
    initial begin
        $display("Time\tclk\trst\tenable\tdata_in_valid\tready\tdata_out\tshift?");
        $monitor("%0t\t%b\t%b\t%b\t%b\t%b\t%b",
                 $time, clk, rst_n, enable, data_in_valid, ready, data_out);
    end

endmodule