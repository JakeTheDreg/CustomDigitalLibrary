module ADC1173_Controller_tb;

    localparam CLK_PERIOD = 10;
    localparam DATA_BUFFER_LEN = 8;

    logic clk;
    logic rst_n;
    logic receiver_ready;
    logic [7:0] adc_data_i;
    logic [7:0] adc_data_o0, adc_data_o1;
    logic adc_data_valid0, adc_data_valid1;
    logic adc_en_n;
    logic adc_clk;
    logic enable;

    // DUT
    ADC1173_Controller_simple #(
        .CYCLES_PER_SAMPLE_N1(0) // constant updates
    ) dut_0 (
        .clk(clk),
        .rst_n(rst_n),
        .enable(enable),
        .receiver_ready(receiver_ready),
        .adc_data_i(adc_data_i),
        .adc_data_o(adc_data_o0),
        .adc_data_valid(adc_data_valid0),
        .adc_en_n(adc_en_n),
        .adc_clk(adc_clk)
    );

    ADC1173_Controller_simple #(
        .CYCLES_PER_SAMPLE_N1(1)    // new data every 2 cycles
    ) dut_1 (
        .clk(clk),
        .rst_n(rst_n),
        .enable(enable),
        .receiver_ready(receiver_ready),
        .adc_data_i(adc_data_i),
        .adc_data_o(adc_data_o1),
        .adc_data_valid(adc_data_valid1),
        .adc_en_n(adc_en_n),
        .adc_clk(adc_clk)
    );

    // Clock
    always #(CLK_PERIOD/2) clk = ~clk;

    // always_ff @(posedge clk) begin
    //     if (!rst_n) receiver_ready <= 0;
    //     else begin
    //         if (adc_data_valid1 && receiver_ready) receiver_ready <= 0;
    //         else if (adc_data_valid1) receiver_ready <= 1;
    //     end
    // end

    // Stimulus
    initial begin
        clk = 0;
        rst_n = 0;
        receiver_ready = 1;
        adc_data_i = 0;
        enable = 1;

        // Reset
        #20;
        rst_n = 1;

        // Feed ADC data
        repeat (50) begin
            @(posedge clk);
            adc_data_i <= adc_data_i + 1;
        end

        // Enable reading
        #50;
        receiver_ready = 1;

        // Continue simulation
        repeat (50) @(posedge clk);

        $finish;
    end

    // Monitor
    initial begin
        $display("Time | rst | adc_i | valid0 | valid1 | adc_o0 | adc_o1 | ready");
        $monitor("%4t | %0d | %3d | %0d | %0d | %3d | %3d | %0d",
                 $time, rst_n, adc_data_i, adc_data_valid0, adc_data_valid1, adc_data_o0, adc_data_o1, receiver_ready);
    end

endmodule