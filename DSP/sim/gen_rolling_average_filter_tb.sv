module gen_rolling_average_filter_tb;

    localparam NUM_TAPS   = 4;   // power of 2
    localparam DATA_WIDTH = 8;

    logic clk;
    logic rst_n;

    logic                  enable;
    logic [DATA_WIDTH-1:0] data_in;
    logic                  data_in_valid;
    logic                  receiver_ready;

    logic                  filter_ready;
    logic [DATA_WIDTH-1:0] data_out;
    logic                  data_out_valid;

    gen_rolling_average_filter #(
        .NUM_TAPS(NUM_TAPS),
        .DATA_WIDTH(DATA_WIDTH)
    ) dut (
        .clk            (clk),
        .rst_n          (rst_n),
        .enable         (enable),
        .data_in        (data_in),
        .data_in_valid  (data_in_valid),
        .receiver_ready (receiver_ready),
        .filter_ready   (filter_ready),
        .data_out       (data_out),
        .data_out_valid (data_out_valid)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    integer i;
    integer expected_sum;
    logic [DATA_WIDTH-1:0] expected_window [0:NUM_TAPS-1];
    logic [DATA_WIDTH-1:0] expected_average;

    task automatic send_sample(input logic [DATA_WIDTH-1:0] sample);
        begin
            @(posedge clk);
            data_in        <= sample;
            data_in_valid  <= 1'b1;

            // Shift expected reference model
            for (i = NUM_TAPS-1; i > 0; i = i - 1)
                expected_window[i] = expected_window[i-1];

            expected_window[0] = sample;

            // Compute expected average
            expected_sum = 0;
            for (i = 0; i < NUM_TAPS; i = i + 1)
                expected_sum += expected_window[i];

            expected_average = expected_sum >> $clog2(NUM_TAPS);

            @(posedge clk);
            data_in_valid <= 1'b0;

            // // Small delay for signal settle
            // #1;

            $display("TIME=%0t | IN=%0d | OUT=%0d | EXP=%0d",
                     $time, sample, data_out, expected_average);

            if (data_out !== expected_average) begin
                $error("Mismatch! Expected=%0d Got=%0d",
                        expected_average, data_out);
            end
        end
    endtask

    initial begin
        // Initialize
        rst_n          = 0;
        data_in        = 0;
        data_in_valid  = 0;
        receiver_ready = 1;
        enable         = 1;

        for (i = 0; i < NUM_TAPS; i = i + 1)
            expected_window[i] = 0;

        // Reset
        repeat (5) @(posedge clk);
        rst_n = 1;

        $display("--------------------------------------------------");
        $display("Starting Rolling Average Filter Test");
        $display("--------------------------------------------------");

        // Directed test samples
        send_sample(8'd10);
        send_sample(8'd20);
        send_sample(8'd30);
        send_sample(8'd40);
        send_sample(8'd50);
        send_sample(8'd60);
        send_sample(8'd100);
        send_sample(8'd200);

        $display("--------------------------------------------------");
        $display("Test Complete");
        $display("--------------------------------------------------");

        #20;
        $finish;
    end
endmodule