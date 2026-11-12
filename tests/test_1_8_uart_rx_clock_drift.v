`default_nettype none
`timescale 1ns/1ps

module test_1_8_uart_rx_clock_drift;
    reg  [7:0] ui_in;
    wire [7:0] uo_out, uio_out, uio_oe;
    reg  [7:0] uio_in;
    reg        ena, clk, rst_n;

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
            if (cmd == 8'h01) begin
                $readmemh(op_file, dut.cpu1_rom_op);
                $readmemh(op1_file, dut.cpu1_rom_op1);
                $readmemh(op2_file, dut.cpu1_rom_op2);
                $readmemh(jmp_file, dut.cpu1_jmp_table);
            end else if (cmd == 8'h08) begin
                $readmemh(op_file, dut.cpu2_rom_op);
                $readmemh(op1_file, dut.cpu2_rom_op1);
                $readmemh(op2_file, dut.cpu2_rom_op2);
                $readmemh(jmp_file, dut.cpu2_jmp_table);
            end
        end
    endtask

    // Transmit UART byte with arbitrary nanosecond bit period
    task send_uart_byte_ns(input [7:0] data, input integer bit_period_ns);
        integer i; begin
            uio_in[1] = 0; // START BIT
            #(bit_period_ns);
            for (i = 0; i < 8; i = i + 1) begin
                uio_in[1] = data[i];
                #(bit_period_ns);
            end
            uio_in[1] = 1; // STOP BIT
            #(bit_period_ns);
            uio_in[1] = 1; // IDLE HIGH
            #(bit_period_ns);
        end
    endtask

    reg [7:0] rx_data;
    integer fail_cnt;

    initial begin
        $dumpfile("test_1_8_uart_rx_clock_drift.vcd");
        $dumpvars(0, test_1_8_uart_rx_clock_drift);

        fail_cnt = 0;
        ui_in = 0; ui_in[0] = 1; uio_in = 8'hFF; ena = 1; rst_n = 0;
        #50 rst_n = 1; #50;

        $display("[Test 1.8] UART RX Clock Drift Tolerance (+/- 4% frequency skew)");

        // Load CPU 1 (Sampling) and CPU 2 (Deserializer)
        load_cpu_ram(8'h01, "protocols/uart/uart_rx_core0");
        load_cpu_ram(8'h08, "protocols/uart/uart_rx_core1");

        ui_in[5] = 1; ui_in[6] = 1; #20; // Run CPU 1 & 2
        #100;

        // Receiver nominal baud rate: 100 cycles per bit (2000 ns)
        // Overhead offset: 86 cycles
        ui_in[0] = 0; spi_send_byte(8'h03); spi_send_byte(8'd86); ui_in[0] = 1; #20;
        #500;

        // 1. FAST TRANSMITTER (+4% Faster -> 1920 ns per bit instead of 2000 ns)
        $display("Sending 0x55 with +4%% fast transmitter (1920ns/bit)...");
        send_uart_byte_ns(8'h55, 1920);
        #4000;

        ui_in[0] = 0; spi_send_byte(8'h0C); spi_read_byte(rx_data); ui_in[0] = 1;
        $display("Fast transmitter received: 0x%h (Expected: 0x55)", rx_data);
        if (rx_data !== 8'h55) begin
            $display("FAILED: Fast transmitter test failed!");
            fail_cnt = fail_cnt + 1;
        end

        #2000;

        // 2. SLOW TRANSMITTER (-4% Slower -> 2080 ns per bit instead of 2000 ns)
        $display("Sending 0xA6 with -4%% slow transmitter (2080ns/bit)...");
        send_uart_byte_ns(8'hA6, 2080);
        #4000;

        ui_in[0] = 0; spi_send_byte(8'h0C); spi_read_byte(rx_data); ui_in[0] = 1;
        $display("Slow transmitter received: 0x%h (Expected: 0xA6)", rx_data);
        if (rx_data !== 8'hA6) begin
            $display("FAILED: Slow transmitter test failed!");
            fail_cnt = fail_cnt + 1;
        end

        if (fail_cnt == 0) begin
            $display("SUCCESS: UART RX Clock Drift tolerance passed!");
        end else begin
            $display("FAILED with %0d errors", fail_cnt);
        end

        #200;
        $finish;
    end

endmodule

