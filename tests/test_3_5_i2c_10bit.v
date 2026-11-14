`default_nettype none
`timescale 1ns/1ps

module test_3_5_i2c_10bit;
    reg  [7:0] \ui_in_reg ;
    wire [7:0] \uo_out_wire ;
    wire [7:0] \uio_in_wire ;
    wire [7:0] \uio_out_wire ;
    wire [7:0] \uio_oe_wire ;
    reg        \ena_reg ;
    reg        \clk_reg ;
    reg        \rst_n_reg ;
    
    // I2C Open-Drain Bus Simulation on UIO[0] (SDA) and UIO[1] (SCL)
    wire \sda_bus  = (\uio_oe_wire [0] && !\uio_out_wire [0]) ? 1'b0 : 1'bz;
    wire \scl_bus  = (\uio_oe_wire [1] && !\uio_out_wire [1]) ? 1'b0 : 1'bz;
    
    pullup(\sda_bus );
    pullup(\scl_bus );
    
    assign \uio_in_wire [0] = \sda_bus ;
    assign \uio_in_wire [1] = \scl_bus ;
    assign \uio_in_wire [7:2] = 6'b0; 
    
    top dut (
        .ui_in(\ui_in_reg ),
        .uo_out(\uo_out_wire ),
        .uio_in(\uio_in_wire ),
        .uio_out(\uio_out_wire ),
        .uio_oe(\uio_oe_wire ),
        .ena(\ena_reg ),
        .clk(\clk_reg ),
        .rst_n(\rst_n_reg )
    );

    initial begin
        \clk_reg  = 0;
        forever #10 \clk_reg  = ~\clk_reg ; // 50 MHz
    end

    task spi_send_byte;
        input [7:0] data;
        integer i;
        begin
            for (i = 7; i >= 0; i = i - 1) begin
                \ui_in_reg [2] = data[i];
                #100 \ui_in_reg [1] = 1;
                #100 \ui_in_reg [1] = 0;
            end
            #60;
        end
    endtask

    task spi_read_byte;
        output [7:0] data;
        integer i;
        begin
            data = 0;
            for (i = 7; i >= 0; i = i - 1) begin
                \ui_in_reg [2] = 0;
                #100 \ui_in_reg [1] = 1;
                data[i] = \uo_out_wire [0]; // MISO
                #100 \ui_in_reg [1] = 0;
            end
            #60;
        end
    endtask

    task load_cpu_ram;
        input [7:0] cmd;
        input [8*100-1:0] base_file;
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
            end else if (cmd == 8'h01) begin
                $readmemh(op_file, dut.cpu1_rom_op);
                $readmemh(op1_file, dut.cpu1_rom_op1);
                $readmemh(op2_file, dut.cpu1_rom_op2);
                $readmemh(jmp_file, dut.cpu1_jmp_table);
            end
        end
    endtask

    reg [7:0] \received_byte ;

    initial begin
        \ui_in_reg  = 0;
        \ui_in_reg [0] = 1; // SPI CS inactive
        \ena_reg  = 1;
        \rst_n_reg  = 0;
        #50 \rst_n_reg  = 1;
        #50;
        
        $display("[Test 3.5] I2C 10-Bit Addressing Multi-Core Loopback (CPU0=Master_10Bit, CPU1=Slave_10Bit)");
        
        // Load CPU 0 with Master 10-bit, CPU 1 with Slave 10-bit
        load_cpu_ram(8'h00, "protocols/i2c/i2c_master_10bit");
        load_cpu_ram(8'h01, "protocols/i2c/i2c_slave_10bit");
        
        // Start Slave (CPU1) first to wait for START
        \ui_in_reg [5] = 1;
        #100;
        
        // Start Master (CPU0)
        \ui_in_reg [4] = 1;
        #100;
        
        // 10-bit Address: 0x027A (10'b1001111010)
        // Byte 1 (Header): 11110 || A[9:8] || W = 11110 || 10 || 0 = 8'hF4
        // Byte 2 (AddrLow): A[7:0] = 8'h7A
        // Byte 3 (Data): 0xBE
        $display("Host feeding 10-bit frame to CPU 0 Master: Header=0xF4, AddrLow=0x7A, Payload=0xBE");
        \ui_in_reg [0] = 0; spi_send_byte(8'h02); spi_send_byte(8'hF4); \ui_in_reg [0] = 1; #100;
        \ui_in_reg [0] = 0; spi_send_byte(8'h02); spi_send_byte(8'h7A); \ui_in_reg [0] = 1; #100;
        \ui_in_reg [0] = 0; spi_send_byte(8'h02); spi_send_byte(8'hBE); \ui_in_reg [0] = 1; #100;
        
        // Wait for 10-bit I2C transaction to complete
        #400000;
        
        // Read received payload data from CPU 1 (Slave) TX FIFO
        $display("Reading received payload from CPU 1 (Slave) TX FIFO...");
        \ui_in_reg [0] = 0; spi_send_byte(8'h05); spi_read_byte(\received_byte ); \ui_in_reg [0] = 1;
        
        $display("10-Bit I2C Slave Received Data: 0x%02X (Expected: 0xBE)", \received_byte );
        if (\received_byte  == 8'hBE) begin
            $display("LOOPBACK PASSED!");
        end else begin
            $display("LOOPBACK FAILED!");
        end
            
        #1000;
        $finish;
    end
    
    initial begin
        $dumpfile("test_3_5_i2c_10bit.vcd");
        $dumpvars(0, test_3_5_i2c_10bit);
    end
endmodule
