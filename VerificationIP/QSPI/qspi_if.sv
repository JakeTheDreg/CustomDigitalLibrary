////////////////////////////////////////////////
// Module name: qspi_if
// Author: Jake Bramhall
// Purpose: Aid in verification of qspi slaves for digital design projects
//          Send commands to slave using send_data()
//          Run monitor() task in a forever block to observe transactions
//          This interface currently only supports sampling data on the posedge of sclk
//          and uses an active low csb.
//
//
////////////////////////////////////////////////
import qspi_pkg::*;

interface qspi_if #(
    parameter NUM_CMD_FRAMES = 1,
    parameter NUM_ADDR_FRAMES = 2,
    parameter NUM_DATA_FRAMES = 4
) (
    output qspi_t bus
);

    localparam TRANSACTION_CMD_LENGTH = NUM_CMD_FRAMES * 4;
    localparam TRANSACTION_ADDR_LENGTH = NUM_ADDR_FRAMES * 4;
    localparam TRANSACTION_DATA_LENGTH = NUM_DATA_FRAMES * 4;
    localparam TRANSACTION_REG_WIDTH = TRANSACTION_CMD_LENGTH + TRANSACTION_ADDR_LENGTH + TRANSACTION_DATA_LENGTH;
    localparam FRAME_COUNTER_WIDTH = $clog2(NUM_CMD_FRAMES+NUM_ADDR_FRAMES+NUM_DATA_FRAMES);

    task automatic reset();
        bus.csb = 1;
        bus.sclk = 1;
        bus.hd = 0;
        bus.wp = 0;
        bus.miso = 0;
        bus.mosi = 0;
    endtask

    task automatic wait_start();
        forever begin
            @(negedge bus.csb);
            return;
        end
    endtask

    task automatic sample_nibble(
        output bit [3:0] s_nibble
    );
        forever begin
            @(posedge bus.sclk);
            if (!bus.csb) s_nibble = {bus.hd, bus.wp, bus.miso, bus.mosi};
            return;
        end
    endtask

    task automatic send_data(
        input bit [TRANSACTION_CMD_LENGTH-1:0] cmd,
        input bit [TRANSACTION_ADDR_LENGTH-1:0] addr,
        input bit [TRANSACTION_DATA_LENGTH-1:0] data,
        input int sclk_period
    );
        automatic bit [TRANSACTION_CMD_LENGTH-1:0] transaction_cmd;
        automatic bit [TRANSACTION_ADDR_LENGTH-1:0] transaction_addr;
        automatic bit [TRANSACTION_DATA_LENGTH-1:0] transaction_data;
        transaction_cmd = cmd;
        transaction_addr = addr;
        transaction_data = data;
        // start by lowering sclk and csb to engage transaction
        bus.csb = 0;
        bus.sclk = 0;

        // for each frame, set bits, delay half a period, toggle clock, delay half a period
        for (int i = NUM_CMD_FRAMES-1; i >= 0; i--) begin
            {bus.hd, bus.wp, bus.miso, bus.mosi} = transaction_cmd[TRANSACTION_CMD_LENGTH-1:TRANSACTION_CMD_LENGTH-4];
            transaction_cmd = transaction_cmd << 4;
            #(sclk_period/2);
            bus.sclk = 1;
            #(sclk_period/2);
            bus.sclk = 0;
        end
        
        for (int i = NUM_ADDR_FRAMES-1; i >= 0; i--) begin
            {bus.hd, bus.wp, bus.miso, bus.mosi} = transaction_addr[TRANSACTION_ADDR_LENGTH-1:TRANSACTION_ADDR_LENGTH-4];
            transaction_addr = transaction_addr << 4;
            #(sclk_period/2);
            bus.sclk = 1;
            #(sclk_period/2);
            bus.sclk = 0;
        end

        for (int i = NUM_DATA_FRAMES-1; i >= 0; i--) begin
            {bus.hd, bus.wp, bus.miso, bus.mosi} = transaction_data[TRANSACTION_DATA_LENGTH-1:TRANSACTION_DATA_LENGTH-4];
            transaction_data = transaction_data << 4;
            #(sclk_period/2);
            bus.sclk = 1;
            #(sclk_period/2);
            bus.sclk = 0;
        end

        // delay for one clock period, then end transaction
        #(sclk_period);
        bus.csb = 1;
        bus.sclk = 1;
        // final delay to ensure csb is reset to signal end of transaction
        #(sclk_period);
    endtask

    task automatic monitor (
        output bit [TRANSACTION_CMD_LENGTH-1:0] cmd,
        output bit [TRANSACTION_ADDR_LENGTH-1:0] addr,
        output bit [TRANSACTION_DATA_LENGTH-1:0] data
    );
        automatic bit [3:0] sampled_nibble;
        automatic bit [TRANSACTION_REG_WIDTH-1:0] transaction_data;
        automatic bit got_transaction;

        got_transaction = 0;
        while(!got_transaction) begin
            // wait for the start of a spi transfer
            wait_start();

            // read nibbles
            for (int i = NUM_CMD_FRAMES+NUM_ADDR_FRAMES+NUM_DATA_FRAMES-1; i >= 0; i--) begin
                sample_nibble(sampled_nibble);
                if (!bus.csb) begin
                    transaction_data = {transaction_data[(TRANSACTION_REG_WIDTH-5):0], sampled_nibble};
                    if (i == 0) got_transaction = 1;
                end else begin
                    got_transaction = 0;
                    break;
                end
            end
        end
        
        // now we have a full transaction
        cmd = transaction_data[TRANSACTION_REG_WIDTH-1:TRANSACTION_ADDR_LENGTH+TRANSACTION_DATA_LENGTH];
        addr = transaction_data[TRANSACTION_ADDR_LENGTH+TRANSACTION_DATA_LENGTH-1:TRANSACTION_DATA_LENGTH];
        data = transaction_data[TRANSACTION_DATA_LENGTH-1:0];
    endtask

endinterface