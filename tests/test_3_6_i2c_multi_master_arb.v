`default_nettype none
`timescale 1ns/1ps

module test_3_6_i2c_multi_master_arb;
    reg  [7:0] \ui_in_reg ;
    wire [7:0] \uo_out_wire ;
    wire [7:0] \uio_in_wire ;
    wire [7:0] \uio_out_wire ;
    wire [7:0] \uio_oe_wire ;
    reg        \ena_reg ;
    reg        \clk_reg ;
    reg        \rst_n_reg ;
    
    // External Master driving SDA/SCL open-drain
    reg  \ext_master_pull_sda ;
    
    // I2C Open-Drain Bus Simulation on UIO[0] (SDA) and UIO[1] (SCL)
    wire \internal_sda_pull  = (\uio_oe_wire [0] && !\uio_out_wire [0]);
    wire \sda_wire  = (\internal_sda_pull  || \ext_master_pull_sda ) ? 1'b0 : 1'bz;
    wire \scl_wire  = (\uio_oe_wire [1] && !\uio_out_wire [1]) ? 1'b0 : 1'bz;
    
    pullup(\sda_wire );
    pullup(\scl_wire );
    
    assign \uio_in_wire [0] = \sda_wire ;
    assign \uio_in_wire [1] = \scl_wire ;
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

    task spi_send_byte(input [7:0] data);
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

    task spi_read_byte(output [7:0] data);
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

    reg [7:0] \received_code ;

    initial begin
        \ui_in_reg  = 0;
        \ui_in_reg [0] = 1; // SPI CS inactive
        \ena_reg  = 1;
        \rst_n_reg  = 0;
        \ext_master_pull_sda  = 0;
        #50 \rst_n_reg  = 1;
        #50;
        
        $display("[Test 3.6] I2C Multi-Master Arbitration Loss Detection");
        
        // Load CPU 0 with Arbitrated Master firmware
        load_cpu_ram(8'h00, "protocols/i2c/i2c_master_arb");
        
        // Push 0x80 into CPU 0 RX FIFO before starting the core
        $display("Preloading byte 0x80 into CPU 0 RX FIFO...");
        \ui_in_reg [0] = 0; spi_send_byte(8'h02); spi_send_byte(8'h80); \ui_in_reg [0] = 1;
        #100;

        // Start CPU 0 Master
        \ui_in_reg [4] = 1;
        
        // Wait until Master finishes START (SDA went Low, then SCL went Low)
        @(negedge \scl_wire );
        
        // Now Bit 7 ('1') is being transmitted! SCL will rise High
        @(posedge \scl_wire );
        $display("[%0t] Master transmitted bit 7 ('1') - SCL is HIGH! External master asserts SDA LOW...", $time);
        
        // External master asserts SDA Low while SCL is High!
        \ext_master_pull_sda  = 1;
        
        // Hold until SCL falls Low
        @(negedge \scl_wire );
        \ext_master_pull_sda  = 0;
        
        // Wait for CPU 0 to detect arbitration loss, release bus, and push 0xEE to TX_FIFO
        #50000;
        
        // Read CPU 0 TX FIFO to check if Arbitration Lost (0xEE) is reported
        $display("Reading CPU 0 TX FIFO for Arbitration Lost status...");
        \ui_in_reg [0] = 0; spi_send_byte(8'h04); spi_read_byte(\received_code ); \ui_in_reg [0] = 1;
        
        $display("Received Status Code: 0x%02X (Expected: 0xEE)", \received_code );
        if (\received_code  == 8'hEE) begin
            $display("LOOPBACK PASSED!");
        end else begin
            $display("LOOPBACK FAILED!");
        end
            
        #1000;
        $finish;
    end
    
    initial begin
        $dumpfile("test_3_6_i2c_multi_master_arb.vcd");
        $dumpvars(0, test_3_6_i2c_multi_master_arb);
    end
endmodule
