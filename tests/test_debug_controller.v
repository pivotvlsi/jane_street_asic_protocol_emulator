`default_nettype none
`timescale 1ns/1ps

module test_debug_controller;
    reg clk;
    reg rst_n;
    reg [7:0] ui_in;
    wire [7:0] uo_out;
    reg  [7:0] uio_in;
    wire [7:0] uio_out;
    wire [7:0] uio_oe;
    reg ena;

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

    // 2-Wire Debug Send Task (16-bit serial frame)
    task dbg_send_16(input [15:0] frame, output [15:0] response);
        integer i;
        begin
            response = 16'h0000;
            for (i = 15; i >= 0; i = i - 1) begin
                ui_in[2] = frame[i]; // dbg_din
                #50;
                ui_in[3] = 1;        // dbg_sclk rising edge
                #50;
                response[i] = uo_out[7]; // sample dbg_dout
                ui_in[3] = 0;        // dbg_sclk falling edge
            end
            #100;
        end
    endtask

    reg [15:0] resp;

    initial begin
        $dumpfile("test_debug_controller.vcd");
        $dumpvars(0, test_debug_controller);

        ui_in = 8'h01; // spi_cs = 1, dbg_sclk = 0, dbg_din = 0
        uio_in = 8'h00;
        ena = 1;
        rst_n = 0;
        #100;
        rst_n = 1;
        #100;

        $display("==================================================");
        $display(" [Two-Wire Debug Test] Testing द्वितन्त्री_शोधन on 6 Cores ");
        $display("==================================================");

        // 1. Halt Core 0: CMD=01, CoreID=000, Data=1
        // Frame: [15:14]=01, [13:11]=000, [10:7]=0000, [6:0]=1 -> 16'b01_000_0000_0000001 = 0x4001
        $display("1. Sending HALT command to Core 0...");
        dbg_send_16(16'h4001, resp);
        #200;
        if (dut.dbg_halt[0] == 1'b1) begin
            $display("   ✅ Core 0 HALT asserted successfully: dbg_halt[0]=1");
        end else begin
            $display("   ❌ FAILED: Core 0 dbg_halt[0] is not asserted!");
            $finish;
        end

        // 2. Halt Core 4: CMD=01, CoreID=100 (4), Data=1
        // Frame: [15:14]=01, [13:11]=100, [10:0]=1 -> 16'b01_100_00000000001 = 0x6001
        $display("2. Sending HALT command to Core 4...");
        dbg_send_16(16'h6001, resp);
        #200;
        if (dut.dbg_halt[4] == 1'b1) begin
            $display("   ✅ Core 4 HALT asserted successfully: dbg_halt[4]=1");
        end else begin
            $display("   ❌ FAILED: Core 4 dbg_halt[4] is not asserted!");
            $finish;
        end

        // 3. Inspect Core 0 PC Readout: CMD=11, CoreID=000
        // Frame: [15:14]=11, [13:11]=000, [10:0]=0 -> 0xC000
        $display("3. Reading Program Counter of Core 0...");
        dbg_send_16(16'hC000, resp);
        dbg_send_16(16'h0000, resp); // Shift out readout
        $display("   ✅ Read Core 0 PC = 0x%04x", resp);

        // 4. Resume Core 0: CMD=01, CoreID=000, Data=0 -> 0x4000
        $display("4. Sending RESUME command to Core 0...");
        dbg_send_16(16'h4000, resp);
        #200;
        if (dut.dbg_halt[0] == 1'b0) begin
            $display("   ✅ Core 0 RESUMED successfully: dbg_halt[0]=0");
        end else begin
            $display("   ❌ FAILED: Core 0 did not resume!");
            $finish;
        end

        $display("==================================================");
        $display(" 🚀 ALL TWO-WIRE DEBUG CHECKS PASSED!");
        $display("==================================================");
        $finish;
    end
endmodule
