`default_nettype none
`timescale 1ns/1ps

module test_5_2_usb_rx;
    reg clk;
    reg rst_n;
    reg [7:0] ui_in;
    wire [7:0] uo_out;
    reg [7:0] uio_in;
    wire [7:0] uio_out;
    wire [7:0] uio_oe;

    top dut (
        .ui_in(ui_in),
        .uo_out(uo_out),
        .uio_in(uio_in),
        .uio_out(uio_out),
        .uio_oe(uio_oe),
        .ena(1'b1),
        .clk(clk),
        .rst_n(rst_n)
    );

    always #10 clk = ~clk; // 50 MHz (20ns period)

    task spi_read_byte(input [7:0] cmd, output [7:0] data);
        integer i;
        begin
            data = 0;
            @(posedge clk);
            ui_in[0] = 0; // CS low
            for (i=15; i>=0; i=i-1) begin
                @(posedge clk);
                ui_in[1] = 0; // SCLK low
                if (i >= 8) ui_in[2] = (cmd >> (i-8)) & 1;
                else ui_in[2] = 0;
                @(posedge clk);
                @(posedge clk);
                ui_in[1] = 1; // SCLK high
                @(posedge clk);
                if (i < 8) data[i] = uo_out[0]; // MISO
                @(posedge clk);
            end
            @(posedge clk);
            ui_in[0] = 1; // CS high
            @(posedge clk);
        end
    endtask

    // USB Low-Speed bit generator (33 cycles @ 20ns = 660ns per bit)
    reg current_usb_state; // 0 = J, 1 = K

    task drive_usb_state(input st);
        begin
            current_usb_state = st;
            if (st == 0) begin
                uio_in[0] = 0; // D+
                uio_in[1] = 1; // D- (J-state)
            end else begin
                uio_in[0] = 1; // D+
                uio_in[1] = 0; // D- (K-state)
            end
            #660; // 33 clock cycles
        end
    endtask

    task send_usb_bit(input bit_val);
        begin
            if (bit_val == 0) begin
                // NRZI 0: Toggle state
                drive_usb_state(~current_usb_state);
            end else begin
                // NRZI 1: Maintain state
                drive_usb_state(current_usb_state);
            end
        end
    endtask

    task send_usb_byte(input [7:0] b);
        integer i;
        begin
            for (i=0; i<8; i=i+1) begin
                send_usb_bit((b >> i) & 1);
            end
        end
    endtask

    task send_usb_eop;
        begin
            // SE0 for 2 bit times (1320ns)
            uio_in[0] = 0;
            uio_in[1] = 0;
            #1320;
            // J-state for 1 bit time (660ns)
            drive_usb_state(0);
        end
    endtask

    reg [7:0] recv_byte_0;
    reg [7:0] recv_byte_1;

    initial begin
        $dumpfile("test_5_2_usb_rx.vcd");
        $dumpvars(0, test_5_2_usb_rx);

        clk = 0;
        rst_n = 0;
        ui_in = 8'h01;   // CS high
        uio_in = 8'h02;  // Idle J-State: Pin 0(D+)=0, Pin 1(D-)=1
        current_usb_state = 0; // J-state

        #100;
        rst_n = 1;
        #100;

        $display("[Test 5.2] USB 1.1 Low-Speed RX Verification");

        // 1. Load Firmware for CPU 4, CPU 5, and CPU 0
        $readmemh("protocols/usb/usb_cpu4_rx_sampler_op.hex", dut.cpu4_rom_op);
        $readmemh("protocols/usb/usb_cpu4_rx_sampler_op1.hex", dut.cpu4_rom_op1);
        $readmemh("protocols/usb/usb_cpu4_rx_sampler_op2.hex", dut.cpu4_rom_op2);
        $readmemh("protocols/usb/usb_cpu4_rx_sampler_jmp.hex", dut.cpu4_jmp_table);

        $readmemh("protocols/usb/usb_cpu5_rx_decoder_op.hex", dut.cpu5_rom_op);
        $readmemh("protocols/usb/usb_cpu5_rx_decoder_op1.hex", dut.cpu5_rom_op1);
        $readmemh("protocols/usb/usb_cpu5_rx_decoder_op2.hex", dut.cpu5_rom_op2);
        $readmemh("protocols/usb/usb_cpu5_rx_decoder_jmp.hex", dut.cpu5_jmp_table);

        $readmemh("protocols/usb/usb_cpu0_rx_deserializer_op.hex", dut.cpu0_rom_op);
        $readmemh("protocols/usb/usb_cpu0_rx_deserializer_op1.hex", dut.cpu0_rom_op1);
        $readmemh("protocols/usb/usb_cpu0_rx_deserializer_op2.hex", dut.cpu0_rom_op2);
        $readmemh("protocols/usb/usb_cpu0_rx_deserializer_jmp.hex", dut.cpu0_jmp_table);

        // Enable CPU 0 (CPU 4 and CPU 5 run automatically by default)
        ui_in[4] = 1;

        #2000;

        // 2. Stream USB Low-Speed Packet from Host
        // USB SYNC byte = 0x80 (K J K J K J K K)
        $display("Sending USB Low-Speed Packet: SYNC (0x80) + Payload (0x5A)...");
        send_usb_byte(8'h80);

        // Data Payload byte = 0x5A
        send_usb_byte(8'h5A);

        // End of Packet (SE0 for 2 bit times + J-state for 1 bit time)
        send_usb_eop;

        #5000;

        // 3. Read back received bytes from CPU 0 TX FIFO (SPI command = 0x04)
        $display("Reading CPU 0 TX FIFO...");
        spi_read_byte(8'h04, recv_byte_0);
        #500;
        spi_read_byte(8'h04, recv_byte_1);

        $display("Received Byte 0 (SYNC): 0x%02X (Expected: 0x80)", recv_byte_0);
        $display("Received Byte 1 (DATA): 0x%02X (Expected: 0x5A)", recv_byte_1);

        if (recv_byte_0 == 8'h80 && recv_byte_1 == 8'h5A) begin
            $display("USB 1.1 LOW-SPEED RX PASSED!");
            $display("LOOPBACK PASSED!");
        end else begin
            $display("USB 1.1 LOW-SPEED RX FAILED!");
            $display("LOOPBACK FAILED!");
        end

        #2000;
        $finish;
    end

endmodule
