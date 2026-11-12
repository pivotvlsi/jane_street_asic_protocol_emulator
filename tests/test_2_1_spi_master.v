`default_nettype none
`timescale 1ns/1ps

module test_2_1_spi_master;
    reg  [7:0] ui_in;
    wire [7:0] uo_out;
    wire [7:0] uio_in;
    wire [7:0] uio_out;
    wire [7:0] uio_oe;
    reg        ena, clk, rst_n;

    // SPI Bus connections on uio pins:
    // Pin 0: CS_N (Master output)
    // Pin 1: SCK  (Master output)
    // Pin 2: MOSI (Master output)
    // Pin 3: MISO (Master input from external slave)
    wire cs_n = uio_out[0];
    wire sck  = uio_out[1];
    wire mosi = uio_out[2];
    reg  slave_miso;

    assign uio_in[0] = cs_n;
    assign uio_in[1] = sck;
    assign uio_in[2] = mosi;
    assign uio_in[3] = slave_miso;
    assign uio_in[7:4] = 4'b0;

    top dut (
        .ui_in(ui_in),
        .uo_out(uo_out),
        .uio_in(uio_in),
        .uio_out(uio_out),
        .uio_oe(uio_oe),
        .ena(ena),
        .clk(clk),
        .rst_n(rst_n)
    );

    initial begin clk = 0; forever #10 clk = ~clk; end

    task spi_send_byte(input [7:0] data);
        integer i; begin
            for (i = 7; i >= 0; i = i - 1) begin
                ui_in[2] = data[i]; #100 ui_in[1] = 1; #100 ui_in[1] = 0;
            end
            #60;
        end
    endtask

    task spi_read_byte(output [7:0] data);
        integer i; begin
            data = 0;
            for (i = 7; i >= 0; i = i - 1) begin
                ui_in[2] = 0; #100 ui_in[1] = 1; data[i] = uo_out[0]; #100 ui_in[1] = 0;
            end
            #60;
        end
    endtask

    task load_cpu_ram(input [7:0] cmd, input [8*100-1:0] base_file);
        reg [8*150-1:0] op_file, op1_file, op2_file, jmp_file;
        begin
            op_file = {base_file, "_op.hex"};
            op1_file = {base_file, "_op1.hex"};
            op2_file = {base_file, "_op2.hex"};
            jmp_file = {base_file, "_jmp.hex"};

            if (cmd == 8'h00) begin
                $readmemh(op_file, dut.cpu0_rom_op);
                $readmemh(op1_file, dut.cpu0_rom_op1);
                $readmemh(op2_file, dut.cpu0_rom_op2);
                $readmemh(jmp_file, dut.cpu0_jmp_table);
            end
        end
    endtask

    // Simulated external SPI Slave (Mode 0: shift out on falling edge, sample on rising)
    reg [7:0] slave_shift_tx;
    reg [7:0] slave_received_byte;
    integer bit_idx;

    always @(negedge cs_n) begin
        // When CS_N goes low, slave pre-loads its response
        slave_shift_tx = 8'hA5; // Send 0xA5 back to master
        slave_miso = slave_shift_tx[7];
        slave_received_byte = 8'h00;
        bit_idx = 7;
    end

    always @(posedge sck) begin
        if (!cs_n) begin
            // Sample MOSI on rising edge
            slave_received_byte[bit_idx] = mosi;
        end
    end

    always @(negedge sck) begin
        if (!cs_n) begin
            // Shift next MISO bit out on falling edge
            if (bit_idx > 0) begin
                bit_idx = bit_idx - 1;
                slave_miso = slave_shift_tx[bit_idx];
            end
        end
    end

    reg [7:0] master_rx_result;
    integer fail_cnt;

    initial begin
        $dumpfile("test_2_1_spi_master.vcd");
        $dumpvars(0, test_2_1_spi_master);

        fail_cnt = 0;
        slave_miso = 0;
        ui_in = 8'h01; // CS inactive high
        ena = 1;
        rst_n = 0;
        #50 rst_n = 1; #50;

        $display("[Test 2.1] SPI Master Bit-Banging (Full-Duplex Mode 0)");

        // 1. Load CPU 0 with spi_master firmware
        load_cpu_ram(8'h00, "protocols/spi/spi_master");

        // 2. Start CPU 0
        ui_in[4] = 1;
        #200;

        // 3. Send byte 0x3C to CPU 0 RX FIFO over host SPI
        $display("Host sending 0x3C to CPU 0 TX buffer...");
        ui_in[0] = 0;
        spi_send_byte(8'h02); // Write to CPU 0 RX FIFO
        spi_send_byte(8'h3C); // Data payload
        ui_in[0] = 1;

        // 4. Wait for SPI transfer to complete on the bus
        @(posedge cs_n); // Wait until CS_N returns high
        #500;

        // Verify slave received 0x3C
        $display("SPI Master sent to Slave: 0x%h (Expected: 0x3C)", slave_received_byte);
        if (slave_received_byte !== 8'h3C) begin
            $display("FAILED: Slave received incorrect byte!");
            fail_cnt = fail_cnt + 1;
        end

        // 5. Read back received MISO byte from CPU 0 TX FIFO over host SPI
        ui_in[0] = 0;
        spi_send_byte(8'h04); // Read CPU 0 TX FIFO
        spi_read_byte(master_rx_result);
        ui_in[0] = 1;

        $display("SPI Master received from Slave: 0x%h (Expected: 0xA5)", master_rx_result);
        if (master_rx_result !== 8'hA5) begin
            $display("FAILED: Master received incorrect MISO byte!");
            fail_cnt = fail_cnt + 1;
        end

        if (fail_cnt == 0) begin
            $display("SUCCESS: Full-duplex SPI Master test passed!");
        end else begin
            $display("FAILED with %0d errors", fail_cnt);
        end

        #200;
        $finish;
    end

endmodule

