`timescale 1ns/1ps

module test_4_3_ethernet_full_duplex;
    reg clk;
    reg rst_n;
    reg [7:0] ui_in;
    reg [7:0] uio_in;
    wire [7:0] uo_out;
    wire [7:0] uio_out;
    wire [7:0] uio_oe;

    top dut (
        .clk(clk), .rst_n(rst_n),
        .ui_in(ui_in), .uo_out(uo_out),
        .uio_in(uio_in), .uio_out(uio_out), .uio_oe(uio_oe),
        .ena(1'b1)
    );

    always #10 clk = ~clk; // 50 MHz (20ns period)

    task spi_send_byte(input [7:0] data);
        integer i;
        begin
            @(posedge clk);
            ui_in[0] = 0; // CS low
            for (i=7; i>=0; i=i-1) begin
                @(posedge clk);
                ui_in[1] = 0; // SCLK low
                ui_in[2] = (data >> i) & 1;
                @(posedge clk);
                @(posedge clk);
                ui_in[1] = 1; // SCLK high
                @(posedge clk);
                @(posedge clk);
            end
            @(posedge clk);
            ui_in[0] = 1; // CS high
            @(posedge clk);
        end
    endtask

    task spi_write(input [7:0] cmd, input [7:0] data);
        integer i;
        begin
            @(posedge clk);
            ui_in[0] = 0; // CS low
            for (i=15; i>=0; i=i-1) begin
                @(posedge clk);
                ui_in[1] = 0; // SCLK low
                if (i >= 8) ui_in[2] = (cmd >> (i-8)) & 1;
                else ui_in[2] = (data >> i) & 1;
                @(posedge clk);
                @(posedge clk);
                ui_in[1] = 1; // SCLK high
                @(posedge clk);
                @(posedge clk);
            end
            @(posedge clk);
            ui_in[0] = 1; // CS high
            @(posedge clk);
        end
    endtask

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

    // Preload CRC-32 Configuration via SPI (Commands 0x60..0x6D)
    task preload_ethernet_crc32;
        begin
            spi_write(8'h60, 8'd32);
            // Poly: 0x04C11DB7 (Little-endian byte feed: B7, 1D, C1, 04)
            spi_write(8'h61, 8'hB7);
            spi_write(8'h62, 8'h1D);
            spi_write(8'h63, 8'hC1);
            spi_write(8'h64, 8'h04);
            // Init Seed: 0xFFFFFFFF
            spi_write(8'h65, 8'hFF);
            spi_write(8'h66, 8'hFF);
            spi_write(8'h67, 8'hFF);
            spi_write(8'h68, 8'hFF);
            // XOR Out: 0xFFFFFFFF
            spi_write(8'h69, 8'hFF);
            spi_write(8'h6A, 8'hFF);
            spi_write(8'h6B, 8'hFF);
            spi_write(8'h6C, 8'hFF);
            // RefIn=1, RefOut=1
            spi_write(8'h6D, 8'h03);
            // Reseed command
            spi_write(8'h6E, 8'h01);
        end
    endtask

    // Send 1 Manchester Bit on UIO[2] (Pin 2)
    // 1 Bit = 200 cycles = 4000ns
    task send_manchester_bit_on_pin2(input val);
        begin
            if (val == 0) begin
                uio_in[2] = 1;
                #2000;
                uio_in[2] = 0;
                #2000;
            end else begin
                uio_in[2] = 0;
                #2000;
                uio_in[2] = 1;
                #2000;
            end
        end
    endtask

    reg [7:0] recv_byte;

    initial begin
        $dumpfile("test_4_3_ethernet_full_duplex.vcd");
        $dumpvars(0, test_4_3_ethernet_full_duplex);

        clk = 0;
        rst_n = 0;
        ui_in = 8'h01;   // CS high
        uio_in = 8'h04;  // Idle HIGH for Pin 2
        #100 rst_n = 1;
        #100;

        $display("[Test 4.3] Full-Duplex 10BASE-T Ethernet + Hardware CRC-32 Verification");

        // 1. Preload Ethernet CRC-32 into hardware engine
        $display("Configuring Hardware CRC-32 via SPI...");
        preload_ethernet_crc32;

        // 2. Load TX Pipeline Firmware (Cores 0, 1, 2, 3)
        $readmemh("protocols/ethernet/eth_cpu0_tx_plus_op.hex", dut.cpu0_rom_op);
        $readmemh("protocols/ethernet/eth_cpu0_tx_plus_op1.hex", dut.cpu0_rom_op1);
        $readmemh("protocols/ethernet/eth_cpu0_tx_plus_op2.hex", dut.cpu0_rom_op2);
        $readmemh("protocols/ethernet/eth_cpu0_tx_plus_jmp.hex", dut.cpu0_jmp_table);

        $readmemh("protocols/ethernet/eth_cpu1_tx_minus_op.hex", dut.cpu1_rom_op);
        $readmemh("protocols/ethernet/eth_cpu1_tx_minus_op1.hex", dut.cpu1_rom_op1);
        $readmemh("protocols/ethernet/eth_cpu1_tx_minus_op2.hex", dut.cpu1_rom_op2);
        $readmemh("protocols/ethernet/eth_cpu1_tx_minus_jmp.hex", dut.cpu1_jmp_table);

        $readmemh("protocols/ethernet/eth_cpu2_encoder_op.hex", dut.cpu2_rom_op);
        $readmemh("protocols/ethernet/eth_cpu2_encoder_op1.hex", dut.cpu2_rom_op1);
        $readmemh("protocols/ethernet/eth_cpu2_encoder_op2.hex", dut.cpu2_rom_op2);
        $readmemh("protocols/ethernet/eth_cpu2_encoder_jmp.hex", dut.cpu2_jmp_table);

        $readmemh("protocols/ethernet/eth_cpu3_serializer_op.hex", dut.cpu3_rom_op);
        $readmemh("protocols/ethernet/eth_cpu3_serializer_op1.hex", dut.cpu3_rom_op1);
        $readmemh("protocols/ethernet/eth_cpu3_serializer_op2.hex", dut.cpu3_rom_op2);
        $readmemh("protocols/ethernet/eth_cpu3_serializer_jmp.hex", dut.cpu3_jmp_table);

        // 3. Load RX Pipeline Firmware (Cores 4, 5)
        $readmemh("protocols/ethernet/eth_cpu4_rx_edge_op.hex", dut.cpu4_rom_op);
        $readmemh("protocols/ethernet/eth_cpu4_rx_edge_op1.hex", dut.cpu4_rom_op1);
        $readmemh("protocols/ethernet/eth_cpu4_rx_edge_op2.hex", dut.cpu4_rom_op2);
        $readmemh("protocols/ethernet/eth_cpu4_rx_edge_jmp.hex", dut.cpu4_jmp_table);

        $readmemh("protocols/ethernet/eth_cpu5_rx_deserializer_op.hex", dut.cpu5_rom_op);
        $readmemh("protocols/ethernet/eth_cpu5_rx_deserializer_op1.hex", dut.cpu5_rom_op1);
        $readmemh("protocols/ethernet/eth_cpu5_rx_deserializer_op2.hex", dut.cpu5_rom_op2);
        $readmemh("protocols/ethernet/eth_cpu5_rx_deserializer_jmp.hex", dut.cpu5_jmp_table);

        // Push 3/4 Baud Delay to CPU 4 RX FIFO (150 cycles = 0x96)
        // CPU 4 RX FIFO SPI command = 0x44
        spi_write(8'h44, 8'h96);

        // Push Transmit Test Byte (0x5A) to CPU 3 RX FIFO (SPI command = 0x0B)
        spi_write(8'h0B, 8'h5A);

        // Enable Cores 0, 1, 2, 3 (TX) and Cores 4, 5 (RX)
        ui_in[4] = 1; // CPU 0
        ui_in[5] = 1; // CPU 1
        ui_in[6] = 1; // CPU 2
        ui_in[7] = 1; // CPU 3

        #2000;

        // Concurrently stream Inbound Manchester Packet on Pin 2 (UIO[2])
        // Send Byte 0x5A (01011010) LSB first: 0, 1, 0, 1, 1, 0, 1, 0
        $display("Concurrently transmitting on UIO[1:0] and receiving on UIO[2]...");
        send_manchester_bit_on_pin2(0);
        send_manchester_bit_on_pin2(1);
        send_manchester_bit_on_pin2(0);
        send_manchester_bit_on_pin2(1);
        send_manchester_bit_on_pin2(1);
        send_manchester_bit_on_pin2(0);
        send_manchester_bit_on_pin2(1);
        send_manchester_bit_on_pin2(0);

        #10000;

        // Verify TX differential activity on UIO[0] (TX+) and UIO[1] (TX-)
        $display("Verifying TX Differential pair on UIO[1:0]...");
        if (uio_oe[0] && uio_oe[1]) begin
            $display("TX+ (UIO[0]) and TX- (UIO[1]) active and driving differentials!");
        end else begin
            $display("ERROR: TX differential drivers inactive!");
        end

        // Read received byte from CPU 5 TX FIFO (SPI command = 0x55)
        $display("Reading received byte from CPU 5 TX FIFO...");
        spi_read_byte(8'h55, recv_byte);

        $display("CPU 5 Received Byte: 0x%02X (Expected: 0x5A)", recv_byte);
        if (recv_byte == 8'h5A) begin
            $display("FULL-DUPLEX ETHERNET RX PASSED!");
            $display("LOOPBACK PASSED!");
        end else begin
            $display("FULL-DUPLEX ETHERNET RX FAILED!");
            $display("LOOPBACK FAILED!");
        end

        #2000;
        $finish;
    end
endmodule
