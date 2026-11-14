`default_nettype none
`timescale 1ns/1ps

module tt_um_protocol_emulator (
    input  wire [7:0] ui_in,
    output wire [7:0] uo_out,
    input  wire [7:0] uio_in,
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe,
    input  wire       ena,
    input  wire       clk,
    input  wire       rst_n
);

    wire spi_cs   = ui_in[0];
    wire spi_sclk = ui_in[1];
    wire spi_mosi = ui_in[2];
    wire spi_miso;
    assign uo_out[0] = spi_miso;

    wire dbg_sclk = ui_in[3];
    wire dbg_din  = ui_in[2];
    wire dbg_dout;
    assign uo_out[7] = dbg_dout;

    wire cpu0_run = ui_in[4];
    wire cpu1_run = ui_in[5];
    wire cpu2_run = ui_in[6];
    wire cpu3_run = ui_in[7];
    wire cpu4_run = 1'b1;
    wire cpu5_run = 1'b1;

    // SPI Slave Wires
    wire [6:0] cpu0_ram_op_waddr; wire [3:0] cpu0_ram_op_wdata; wire cpu0_ram_op_we;
    wire [5:0] cpu0_ram_op1_waddr; wire [3:0] cpu0_ram_op1_wdata; wire cpu0_ram_op1_we;
    wire [2:0] cpu0_ram_op2_waddr; wire [3:0] cpu0_ram_op2_wdata; wire cpu0_ram_op2_we;
    wire [3:0] cpu0_jmp_waddr; wire [15:0] cpu0_jmp_wdata; wire cpu0_jmp_we;
    wire [7:0] cpu0_rx_fifo_wdata; wire cpu0_rx_fifo_we;
    wire [7:0] cpu0_tx_fifo_rdata; wire cpu0_tx_fifo_re; wire cpu0_tx_fifo_empty;
    wire [6:0] cpu1_ram_op_waddr; wire [3:0] cpu1_ram_op_wdata; wire cpu1_ram_op_we;
    wire [5:0] cpu1_ram_op1_waddr; wire [3:0] cpu1_ram_op1_wdata; wire cpu1_ram_op1_we;
    wire [2:0] cpu1_ram_op2_waddr; wire [3:0] cpu1_ram_op2_wdata; wire cpu1_ram_op2_we;
    wire [3:0] cpu1_jmp_waddr; wire [15:0] cpu1_jmp_wdata; wire cpu1_jmp_we;
    wire [7:0] cpu1_rx_fifo_wdata; wire cpu1_rx_fifo_we;
    wire [7:0] cpu1_tx_fifo_rdata; wire cpu1_tx_fifo_re; wire cpu1_tx_fifo_empty;
    wire [6:0] cpu2_ram_op_waddr; wire [3:0] cpu2_ram_op_wdata; wire cpu2_ram_op_we;
    wire [5:0] cpu2_ram_op1_waddr; wire [3:0] cpu2_ram_op1_wdata; wire cpu2_ram_op1_we;
    wire [2:0] cpu2_ram_op2_waddr; wire [3:0] cpu2_ram_op2_wdata; wire cpu2_ram_op2_we;
    wire [3:0] cpu2_jmp_waddr; wire [15:0] cpu2_jmp_wdata; wire cpu2_jmp_we;
    wire [7:0] cpu2_rx_fifo_wdata; wire cpu2_rx_fifo_we;
    wire [7:0] cpu2_tx_fifo_rdata; wire cpu2_tx_fifo_re; wire cpu2_tx_fifo_empty;
    wire [6:0] cpu3_ram_op_waddr; wire [3:0] cpu3_ram_op_wdata; wire cpu3_ram_op_we;
    wire [5:0] cpu3_ram_op1_waddr; wire [3:0] cpu3_ram_op1_wdata; wire cpu3_ram_op1_we;
    wire [2:0] cpu3_ram_op2_waddr; wire [3:0] cpu3_ram_op2_wdata; wire cpu3_ram_op2_we;
    wire [3:0] cpu3_jmp_waddr; wire [15:0] cpu3_jmp_wdata; wire cpu3_jmp_we;
    wire [7:0] cpu3_rx_fifo_wdata; wire cpu3_rx_fifo_we;
    wire [7:0] cpu3_tx_fifo_rdata; wire cpu3_tx_fifo_re; wire cpu3_tx_fifo_empty;
    wire [6:0] cpu4_ram_op_waddr; wire [3:0] cpu4_ram_op_wdata; wire cpu4_ram_op_we;
    wire [5:0] cpu4_ram_op1_waddr; wire [3:0] cpu4_ram_op1_wdata; wire cpu4_ram_op1_we;
    wire [2:0] cpu4_ram_op2_waddr; wire [3:0] cpu4_ram_op2_wdata; wire cpu4_ram_op2_we;
    wire [3:0] cpu4_jmp_waddr; wire [15:0] cpu4_jmp_wdata; wire cpu4_jmp_we;
    wire [7:0] cpu4_rx_fifo_wdata; wire cpu4_rx_fifo_we;
    wire [7:0] cpu4_tx_fifo_rdata; wire cpu4_tx_fifo_re; wire cpu4_tx_fifo_empty;
    wire [6:0] cpu5_ram_op_waddr; wire [3:0] cpu5_ram_op_wdata; wire cpu5_ram_op_we;
    wire [5:0] cpu5_ram_op1_waddr; wire [3:0] cpu5_ram_op1_wdata; wire cpu5_ram_op1_we;
    wire [2:0] cpu5_ram_op2_waddr; wire [3:0] cpu5_ram_op2_wdata; wire cpu5_ram_op2_we;
    wire [3:0] cpu5_jmp_waddr; wire [15:0] cpu5_jmp_wdata; wire cpu5_jmp_we;
    wire [7:0] cpu5_rx_fifo_wdata; wire cpu5_rx_fifo_we;
    wire [7:0] cpu5_tx_fifo_rdata; wire cpu5_tx_fifo_re; wire cpu5_tx_fifo_empty;

    spi_slave spi_inst (
        .clk(clk), .rst_n(rst_n),
        .spi_cs(spi_cs), .spi_sclk(spi_sclk), .spi_mosi(spi_mosi), .spi_miso(spi_miso),
        .cpu0_ram_op_addr(cpu0_ram_op_waddr), .cpu0_ram_op_wdata(cpu0_ram_op_wdata), .cpu0_ram_op_we(cpu0_ram_op_we),
        .cpu0_ram_op1_addr(cpu0_ram_op1_waddr), .cpu0_ram_op1_wdata(cpu0_ram_op1_wdata), .cpu0_ram_op1_we(cpu0_ram_op1_we),
        .cpu0_ram_op2_addr(cpu0_ram_op2_waddr), .cpu0_ram_op2_wdata(cpu0_ram_op2_wdata), .cpu0_ram_op2_we(cpu0_ram_op2_we),
        .cpu0_jmp_addr(cpu0_jmp_waddr), .cpu0_jmp_wdata(cpu0_jmp_wdata), .cpu0_jmp_we(cpu0_jmp_we),
        .cpu0_rx_fifo_wdata(cpu0_rx_fifo_wdata), .cpu0_rx_fifo_we(cpu0_rx_fifo_we),
        .cpu0_tx_fifo_rdata(cpu0_tx_fifo_rdata), .cpu0_tx_fifo_re(cpu0_tx_fifo_re), .cpu0_tx_fifo_empty(cpu0_tx_fifo_empty),
        .cpu1_ram_op_addr(cpu1_ram_op_waddr), .cpu1_ram_op_wdata(cpu1_ram_op_wdata), .cpu1_ram_op_we(cpu1_ram_op_we),
        .cpu1_ram_op1_addr(cpu1_ram_op1_waddr), .cpu1_ram_op1_wdata(cpu1_ram_op1_wdata), .cpu1_ram_op1_we(cpu1_ram_op1_we),
        .cpu1_ram_op2_addr(cpu1_ram_op2_waddr), .cpu1_ram_op2_wdata(cpu1_ram_op2_wdata), .cpu1_ram_op2_we(cpu1_ram_op2_we),
        .cpu1_jmp_addr(cpu1_jmp_waddr), .cpu1_jmp_wdata(cpu1_jmp_wdata), .cpu1_jmp_we(cpu1_jmp_we),
        .cpu1_rx_fifo_wdata(cpu1_rx_fifo_wdata), .cpu1_rx_fifo_we(cpu1_rx_fifo_we),
        .cpu1_tx_fifo_rdata(cpu1_tx_fifo_rdata), .cpu1_tx_fifo_re(cpu1_tx_fifo_re), .cpu1_tx_fifo_empty(cpu1_tx_fifo_empty),
        .cpu2_ram_op_addr(cpu2_ram_op_waddr), .cpu2_ram_op_wdata(cpu2_ram_op_wdata), .cpu2_ram_op_we(cpu2_ram_op_we),
        .cpu2_ram_op1_addr(cpu2_ram_op1_waddr), .cpu2_ram_op1_wdata(cpu2_ram_op1_wdata), .cpu2_ram_op1_we(cpu2_ram_op1_we),
        .cpu2_ram_op2_addr(cpu2_ram_op2_waddr), .cpu2_ram_op2_wdata(cpu2_ram_op2_wdata), .cpu2_ram_op2_we(cpu2_ram_op2_we),
        .cpu2_jmp_addr(cpu2_jmp_waddr), .cpu2_jmp_wdata(cpu2_jmp_wdata), .cpu2_jmp_we(cpu2_jmp_we),
        .cpu2_rx_fifo_wdata(cpu2_rx_fifo_wdata), .cpu2_rx_fifo_we(cpu2_rx_fifo_we),
        .cpu2_tx_fifo_rdata(cpu2_tx_fifo_rdata), .cpu2_tx_fifo_re(cpu2_tx_fifo_re), .cpu2_tx_fifo_empty(cpu2_tx_fifo_empty),
        .cpu3_ram_op_addr(cpu3_ram_op_waddr), .cpu3_ram_op_wdata(cpu3_ram_op_wdata), .cpu3_ram_op_we(cpu3_ram_op_we),
        .cpu3_ram_op1_addr(cpu3_ram_op1_waddr), .cpu3_ram_op1_wdata(cpu3_ram_op1_wdata), .cpu3_ram_op1_we(cpu3_ram_op1_we),
        .cpu3_ram_op2_addr(cpu3_ram_op2_waddr), .cpu3_ram_op2_wdata(cpu3_ram_op2_wdata), .cpu3_ram_op2_we(cpu3_ram_op2_we),
        .cpu3_jmp_addr(cpu3_jmp_waddr), .cpu3_jmp_wdata(cpu3_jmp_wdata), .cpu3_jmp_we(cpu3_jmp_we),
        .cpu3_rx_fifo_wdata(cpu3_rx_fifo_wdata), .cpu3_rx_fifo_we(cpu3_rx_fifo_we),
        .cpu3_tx_fifo_rdata(cpu3_tx_fifo_rdata), .cpu3_tx_fifo_re(cpu3_tx_fifo_re), .cpu3_tx_fifo_empty(cpu3_tx_fifo_empty),
        .cpu4_ram_op_addr(cpu4_ram_op_waddr), .cpu4_ram_op_wdata(cpu4_ram_op_wdata), .cpu4_ram_op_we(cpu4_ram_op_we),
        .cpu4_ram_op1_addr(cpu4_ram_op1_waddr), .cpu4_ram_op1_wdata(cpu4_ram_op1_wdata), .cpu4_ram_op1_we(cpu4_ram_op1_we),
        .cpu4_ram_op2_addr(cpu4_ram_op2_waddr), .cpu4_ram_op2_wdata(cpu4_ram_op2_wdata), .cpu4_ram_op2_we(cpu4_ram_op2_we),
        .cpu4_jmp_addr(cpu4_jmp_waddr), .cpu4_jmp_wdata(cpu4_jmp_wdata), .cpu4_jmp_we(cpu4_jmp_we),
        .cpu4_rx_fifo_wdata(cpu4_rx_fifo_wdata), .cpu4_rx_fifo_we(cpu4_rx_fifo_we),
        .cpu4_tx_fifo_rdata(cpu4_tx_fifo_rdata), .cpu4_tx_fifo_re(cpu4_tx_fifo_re), .cpu4_tx_fifo_empty(cpu4_tx_fifo_empty),
        .cpu5_ram_op_addr(cpu5_ram_op_waddr), .cpu5_ram_op_wdata(cpu5_ram_op_wdata), .cpu5_ram_op_we(cpu5_ram_op_we),
        .cpu5_ram_op1_addr(cpu5_ram_op1_waddr), .cpu5_ram_op1_wdata(cpu5_ram_op1_wdata), .cpu5_ram_op1_we(cpu5_ram_op1_we),
        .cpu5_ram_op2_addr(cpu5_ram_op2_waddr), .cpu5_ram_op2_wdata(cpu5_ram_op2_wdata), .cpu5_ram_op2_we(cpu5_ram_op2_we),
        .cpu5_jmp_addr(cpu5_jmp_waddr), .cpu5_jmp_wdata(cpu5_jmp_wdata), .cpu5_jmp_we(cpu5_jmp_we),
        .cpu5_rx_fifo_wdata(cpu5_rx_fifo_wdata), .cpu5_rx_fifo_we(cpu5_rx_fifo_we),
        .cpu5_tx_fifo_rdata(cpu5_tx_fifo_rdata), .cpu5_tx_fifo_re(cpu5_tx_fifo_re), .cpu5_tx_fifo_empty(cpu5_tx_fifo_empty),
        .\चक्रीय_विन्यास_लेखन (spi_crc_we),
        .\चक्रीय_विन्यास_पञ्जिका (spi_crc_addr),
        .\चक्रीय_विन्यास_दत्त (spi_crc_wdata)
    );

    // ========================================================
    // सार्वत्रिक चक्रीय पुनरावृत्ति तपासक (Universal CRC Engine)
    // ========================================================
    wire        spi_crc_we;
    wire [3:0]  spi_crc_addr;
    wire [7:0]  spi_crc_wdata;

    wire        crc_feed_we = (cpu0_mem_we && cpu0_mem_addr == 4'hD) |
                              (cpu1_mem_we && cpu1_mem_addr == 4'hD) |
                              (cpu2_mem_we && cpu2_mem_addr == 4'hD) |
                              (cpu3_mem_we && cpu3_mem_addr == 4'hD) |
                              (cpu4_mem_we && cpu4_mem_addr == 4'hD) |
                              (cpu5_mem_we && cpu5_mem_addr == 4'hD);

    wire [7:0]  crc_feed_data = (cpu0_mem_we && cpu0_mem_addr == 4'hD) ? cpu0_mem_wdata :
                                (cpu1_mem_we && cpu1_mem_addr == 4'hD) ? cpu1_mem_wdata :
                                (cpu2_mem_we && cpu2_mem_addr == 4'hD) ? cpu2_mem_wdata :
                                (cpu3_mem_we && cpu3_mem_addr == 4'hD) ? cpu3_mem_wdata :
                                (cpu4_mem_we && cpu4_mem_addr == 4'hD) ? cpu4_mem_wdata : cpu5_mem_wdata;

    reg [1:0]   crc_slice_sel;
    wire        crc_ctrl_we = (cpu0_mem_we && cpu0_mem_addr == 4'hE) |
                              (cpu1_mem_we && cpu1_mem_addr == 4'hE) |
                              (cpu2_mem_we && cpu2_mem_addr == 4'hE) |
                              (cpu3_mem_we && cpu3_mem_addr == 4'hE) |
                              (cpu4_mem_we && cpu4_mem_addr == 4'hE) |
                              (cpu5_mem_we && cpu5_mem_addr == 4'hE);

    wire [7:0]  crc_ctrl_data = (cpu0_mem_we && cpu0_mem_addr == 4'hE) ? cpu0_mem_wdata :
                                (cpu1_mem_we && cpu1_mem_addr == 4'hE) ? cpu1_mem_wdata :
                                (cpu2_mem_we && cpu2_mem_addr == 4'hE) ? cpu2_mem_wdata :
                                (cpu3_mem_we && cpu3_mem_addr == 4'hE) ? cpu3_mem_wdata :
                                (cpu4_mem_we && cpu4_mem_addr == 4'hE) ? cpu4_mem_wdata : cpu5_mem_wdata;

    wire crc_reseed_cmd = crc_ctrl_we && crc_ctrl_data[2];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) crc_slice_sel <= 2'b00;
        else if (crc_ctrl_we) crc_slice_sel <= crc_ctrl_data[1:0];
    end

    wire [7:0] crc_result_byte;

    \सार्वत्रिक_चक्रीय_पुनरावृत्ति  crc_inst (
        .clk(clk),
        .rst_n(rst_n),
        .\विन्यास_लेखन_संकेत (spi_crc_we),
        .\विन्यास_पञ्जिका_संकेत (spi_crc_addr),
        .\विन्यास_दत्त_निवेश (spi_crc_wdata),
        .\प्रविष्टि_दत्त_निवेश (crc_feed_data),
        .\प्रविष्टि_लेखन_संकेत (crc_feed_we),
        .\पुनःप्रारम्भ_आदेश (crc_reseed_cmd),
        .\निर्गम_भाग_संकेत (crc_slice_sel),
        .\निर्गम_शेष_दत्त (crc_result_byte)
    );

    reg [7:0] shared_reg_0; reg shared_reg_0_valid;
    reg [7:0] shared_reg_1; reg shared_reg_1_valid;
    reg [7:0] shared_reg_2; reg shared_reg_2_valid;
    reg [7:0] shared_reg_3; reg shared_reg_3_valid;
    reg [7:0] shared_reg_4; reg shared_reg_4_valid;
    reg [7:0] shared_reg_5; reg shared_reg_5_valid;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shared_reg_0 <= 0; shared_reg_0_valid <= 0;
            shared_reg_1 <= 0; shared_reg_1_valid <= 0;
            shared_reg_2 <= 0; shared_reg_2_valid <= 0;
            shared_reg_3 <= 0; shared_reg_3_valid <= 0;
            shared_reg_4 <= 0; shared_reg_4_valid <= 0;
            shared_reg_5 <= 0; shared_reg_5_valid <= 0;
        end else begin
            if (cpu0_mem_re && cpu0_mem_addr == 4'h9 && shared_reg_0_valid) shared_reg_0_valid <= 1'b0;
            if (cpu1_mem_re && cpu1_mem_addr == 4'h9 && shared_reg_0_valid) shared_reg_0_valid <= 1'b0;
            if (cpu2_mem_re && cpu2_mem_addr == 4'h9 && shared_reg_0_valid) shared_reg_0_valid <= 1'b0;
            if (cpu3_mem_re && cpu3_mem_addr == 4'h9 && shared_reg_0_valid) shared_reg_0_valid <= 1'b0;
            if (cpu4_mem_re && cpu4_mem_addr == 4'h9 && shared_reg_0_valid) shared_reg_0_valid <= 1'b0;
            if (cpu5_mem_re && cpu5_mem_addr == 4'h9 && shared_reg_0_valid) shared_reg_0_valid <= 1'b0;

            if (cpu0_mem_we && cpu0_mem_addr == 4'h9) begin shared_reg_0 <= cpu0_mem_wdata; shared_reg_0_valid <= 1'b1; end
            if (cpu1_mem_we && cpu1_mem_addr == 4'h9) begin shared_reg_0 <= cpu1_mem_wdata; shared_reg_0_valid <= 1'b1; end
            if (cpu2_mem_we && cpu2_mem_addr == 4'h9) begin shared_reg_0 <= cpu2_mem_wdata; shared_reg_0_valid <= 1'b1; end
            if (cpu3_mem_we && cpu3_mem_addr == 4'h9) begin shared_reg_0 <= cpu3_mem_wdata; shared_reg_0_valid <= 1'b1; end
            if (cpu4_mem_we && cpu4_mem_addr == 4'h9) begin shared_reg_0 <= cpu4_mem_wdata; shared_reg_0_valid <= 1'b1; end
            if (cpu5_mem_we && cpu5_mem_addr == 4'h9) begin shared_reg_0 <= cpu5_mem_wdata; shared_reg_0_valid <= 1'b1; end

            if (cpu0_mem_re && cpu0_mem_addr == 4'hA && shared_reg_1_valid) shared_reg_1_valid <= 1'b0;
            if (cpu1_mem_re && cpu1_mem_addr == 4'hA && shared_reg_1_valid) shared_reg_1_valid <= 1'b0;
            if (cpu2_mem_re && cpu2_mem_addr == 4'hA && shared_reg_1_valid) shared_reg_1_valid <= 1'b0;
            if (cpu3_mem_re && cpu3_mem_addr == 4'hA && shared_reg_1_valid) shared_reg_1_valid <= 1'b0;
            if (cpu4_mem_re && cpu4_mem_addr == 4'hA && shared_reg_1_valid) shared_reg_1_valid <= 1'b0;
            if (cpu5_mem_re && cpu5_mem_addr == 4'hA && shared_reg_1_valid) shared_reg_1_valid <= 1'b0;

            if (cpu0_mem_we && cpu0_mem_addr == 4'hA) begin shared_reg_1 <= cpu0_mem_wdata; shared_reg_1_valid <= 1'b1; end
            if (cpu1_mem_we && cpu1_mem_addr == 4'hA) begin shared_reg_1 <= cpu1_mem_wdata; shared_reg_1_valid <= 1'b1; end
            if (cpu2_mem_we && cpu2_mem_addr == 4'hA) begin shared_reg_1 <= cpu2_mem_wdata; shared_reg_1_valid <= 1'b1; end
            if (cpu3_mem_we && cpu3_mem_addr == 4'hA) begin shared_reg_1 <= cpu3_mem_wdata; shared_reg_1_valid <= 1'b1; end
            if (cpu4_mem_we && cpu4_mem_addr == 4'hA) begin shared_reg_1 <= cpu4_mem_wdata; shared_reg_1_valid <= 1'b1; end
            if (cpu5_mem_we && cpu5_mem_addr == 4'hA) begin shared_reg_1 <= cpu5_mem_wdata; shared_reg_1_valid <= 1'b1; end

            if (cpu0_mem_re && cpu0_mem_addr == 4'hB && shared_reg_2_valid) shared_reg_2_valid <= 1'b0;
            if (cpu1_mem_re && cpu1_mem_addr == 4'hB && shared_reg_2_valid) shared_reg_2_valid <= 1'b0;
            if (cpu2_mem_re && cpu2_mem_addr == 4'hB && shared_reg_2_valid) shared_reg_2_valid <= 1'b0;
            if (cpu3_mem_re && cpu3_mem_addr == 4'hB && shared_reg_2_valid) shared_reg_2_valid <= 1'b0;
            if (cpu4_mem_re && cpu4_mem_addr == 4'hB && shared_reg_2_valid) shared_reg_2_valid <= 1'b0;
            if (cpu5_mem_re && cpu5_mem_addr == 4'hB && shared_reg_2_valid) shared_reg_2_valid <= 1'b0;

            if (cpu0_mem_we && cpu0_mem_addr == 4'hB) begin shared_reg_2 <= cpu0_mem_wdata; shared_reg_2_valid <= 1'b1; end
            if (cpu1_mem_we && cpu1_mem_addr == 4'hB) begin shared_reg_2 <= cpu1_mem_wdata; shared_reg_2_valid <= 1'b1; end
            if (cpu2_mem_we && cpu2_mem_addr == 4'hB) begin shared_reg_2 <= cpu2_mem_wdata; shared_reg_2_valid <= 1'b1; end
            if (cpu3_mem_we && cpu3_mem_addr == 4'hB) begin shared_reg_2 <= cpu3_mem_wdata; shared_reg_2_valid <= 1'b1; end
            if (cpu4_mem_we && cpu4_mem_addr == 4'hB) begin shared_reg_2 <= cpu4_mem_wdata; shared_reg_2_valid <= 1'b1; end
            if (cpu5_mem_we && cpu5_mem_addr == 4'hB) begin shared_reg_2 <= cpu5_mem_wdata; shared_reg_2_valid <= 1'b1; end

            if (cpu0_mem_re && cpu0_mem_addr == 4'hC && shared_reg_3_valid) shared_reg_3_valid <= 1'b0;
            if (cpu1_mem_re && cpu1_mem_addr == 4'hC && shared_reg_3_valid) shared_reg_3_valid <= 1'b0;
            if (cpu2_mem_re && cpu2_mem_addr == 4'hC && shared_reg_3_valid) shared_reg_3_valid <= 1'b0;
            if (cpu3_mem_re && cpu3_mem_addr == 4'hC && shared_reg_3_valid) shared_reg_3_valid <= 1'b0;
            if (cpu4_mem_re && cpu4_mem_addr == 4'hC && shared_reg_3_valid) shared_reg_3_valid <= 1'b0;
            if (cpu5_mem_re && cpu5_mem_addr == 4'hC && shared_reg_3_valid) shared_reg_3_valid <= 1'b0;

            if (cpu0_mem_we && cpu0_mem_addr == 4'hC) begin shared_reg_3 <= cpu0_mem_wdata; shared_reg_3_valid <= 1'b1; end
            if (cpu1_mem_we && cpu1_mem_addr == 4'hC) begin shared_reg_3 <= cpu1_mem_wdata; shared_reg_3_valid <= 1'b1; end
            if (cpu2_mem_we && cpu2_mem_addr == 4'hC) begin shared_reg_3 <= cpu2_mem_wdata; shared_reg_3_valid <= 1'b1; end
            if (cpu3_mem_we && cpu3_mem_addr == 4'hC) begin shared_reg_3 <= cpu3_mem_wdata; shared_reg_3_valid <= 1'b1; end
            if (cpu4_mem_we && cpu4_mem_addr == 4'hC) begin shared_reg_3 <= cpu4_mem_wdata; shared_reg_3_valid <= 1'b1; end
            if (cpu5_mem_we && cpu5_mem_addr == 4'hC) begin shared_reg_3 <= cpu5_mem_wdata; shared_reg_3_valid <= 1'b1; end

            if (cpu0_mem_re && cpu0_mem_addr == 4'hD && shared_reg_4_valid) shared_reg_4_valid <= 1'b0;
            if (cpu1_mem_re && cpu1_mem_addr == 4'hD && shared_reg_4_valid) shared_reg_4_valid <= 1'b0;
            if (cpu2_mem_re && cpu2_mem_addr == 4'hD && shared_reg_4_valid) shared_reg_4_valid <= 1'b0;
            if (cpu3_mem_re && cpu3_mem_addr == 4'hD && shared_reg_4_valid) shared_reg_4_valid <= 1'b0;
            if (cpu4_mem_re && cpu4_mem_addr == 4'hD && shared_reg_4_valid) shared_reg_4_valid <= 1'b0;
            if (cpu5_mem_re && cpu5_mem_addr == 4'hD && shared_reg_4_valid) shared_reg_4_valid <= 1'b0;

            if (cpu0_mem_we && cpu0_mem_addr == 4'hD) begin shared_reg_4 <= cpu0_mem_wdata; shared_reg_4_valid <= 1'b1; end
            if (cpu1_mem_we && cpu1_mem_addr == 4'hD) begin shared_reg_4 <= cpu1_mem_wdata; shared_reg_4_valid <= 1'b1; end
            if (cpu2_mem_we && cpu2_mem_addr == 4'hD) begin shared_reg_4 <= cpu2_mem_wdata; shared_reg_4_valid <= 1'b1; end
            if (cpu3_mem_we && cpu3_mem_addr == 4'hD) begin shared_reg_4 <= cpu3_mem_wdata; shared_reg_4_valid <= 1'b1; end
            if (cpu4_mem_we && cpu4_mem_addr == 4'hD) begin shared_reg_4 <= cpu4_mem_wdata; shared_reg_4_valid <= 1'b1; end
            if (cpu5_mem_we && cpu5_mem_addr == 4'hD) begin shared_reg_4 <= cpu5_mem_wdata; shared_reg_4_valid <= 1'b1; end

            if (cpu0_mem_re && cpu0_mem_addr == 4'hE && shared_reg_5_valid) shared_reg_5_valid <= 1'b0;
            if (cpu1_mem_re && cpu1_mem_addr == 4'hE && shared_reg_5_valid) shared_reg_5_valid <= 1'b0;
            if (cpu2_mem_re && cpu2_mem_addr == 4'hE && shared_reg_5_valid) shared_reg_5_valid <= 1'b0;
            if (cpu3_mem_re && cpu3_mem_addr == 4'hE && shared_reg_5_valid) shared_reg_5_valid <= 1'b0;
            if (cpu4_mem_re && cpu4_mem_addr == 4'hE && shared_reg_5_valid) shared_reg_5_valid <= 1'b0;
            if (cpu5_mem_re && cpu5_mem_addr == 4'hE && shared_reg_5_valid) shared_reg_5_valid <= 1'b0;

            if (cpu0_mem_we && cpu0_mem_addr == 4'hE) begin shared_reg_5 <= cpu0_mem_wdata; shared_reg_5_valid <= 1'b1; end
            if (cpu1_mem_we && cpu1_mem_addr == 4'hE) begin shared_reg_5 <= cpu1_mem_wdata; shared_reg_5_valid <= 1'b1; end
            if (cpu2_mem_we && cpu2_mem_addr == 4'hE) begin shared_reg_5 <= cpu2_mem_wdata; shared_reg_5_valid <= 1'b1; end
            if (cpu3_mem_we && cpu3_mem_addr == 4'hE) begin shared_reg_5 <= cpu3_mem_wdata; shared_reg_5_valid <= 1'b1; end
            if (cpu4_mem_we && cpu4_mem_addr == 4'hE) begin shared_reg_5 <= cpu4_mem_wdata; shared_reg_5_valid <= 1'b1; end
            if (cpu5_mem_we && cpu5_mem_addr == 4'hE) begin shared_reg_5 <= cpu5_mem_wdata; shared_reg_5_valid <= 1'b1; end

        end
    end

    // ========================================================
    // CPU 0 SUBSYSTEM (संसाधक_0)
    // ========================================================
    reg [3:0] cpu0_rom_op [0:127];
    reg [3:0] cpu0_rom_op1 [0:63];
    reg [3:0] cpu0_rom_op2 [0:15];
    reg [16:0] cpu0_jmp_table [0:15];

    always @(posedge clk) begin
        if (cpu0_ram_op_we) cpu0_rom_op[cpu0_ram_op_waddr] <= cpu0_ram_op_wdata;
        if (cpu0_ram_op1_we) cpu0_rom_op1[cpu0_ram_op1_waddr] <= cpu0_ram_op1_wdata;
        if (cpu0_ram_op2_we) cpu0_rom_op2[cpu0_ram_op2_waddr] <= cpu0_ram_op2_wdata;
        if (cpu0_jmp_we) cpu0_jmp_table[cpu0_jmp_waddr] <= {1'b0, cpu0_jmp_wdata};
    end

    wire [6:0] cpu0_pc_op;
    wire [5:0] cpu0_pc_op1;
    wire [3:0] cpu0_pc_op2;
    wire [3:0] cpu0_jmp_addr;
    
    wire [3:0] cpu0_rom_op_data = cpu0_rom_op[cpu0_pc_op];
    wire [3:0] cpu0_rom_op1_data = cpu0_rom_op1[cpu0_pc_op1];
    wire [3:0] cpu0_rom_op2_data = cpu0_rom_op2[cpu0_pc_op2];
    wire [16:0] cpu0_jmp_data = cpu0_jmp_table[cpu0_jmp_addr];

    wire [7:0] cpu0_pin_out, cpu0_pin_dir;
    wire [3:0] cpu0_mem_addr;
    wire [7:0] cpu0_mem_wdata;
    wire cpu0_mem_we, cpu0_mem_re;
    reg  [7:0] cpu0_mem_rdata;
    wire       cpu0_mem_stall;

    wire [7:0] cpu0_rx_rdata; wire cpu0_rx_empty, cpu0_rx_full;
    wire cpu0_rx_re = (cpu0_mem_addr == 4'h5) && cpu0_mem_re && !cpu0_rx_empty;
    fifo rx0 (.clk(clk), .rst_n(rst_n), .wdata(cpu0_rx_fifo_wdata), .we(cpu0_rx_fifo_we),
              .rdata(cpu0_rx_rdata), .re(cpu0_rx_re), .empty(cpu0_rx_empty), .full(cpu0_rx_full));
              
    wire cpu0_tx_full;
    wire cpu0_tx_we = (cpu0_mem_addr == 4'h4) && cpu0_mem_we && !cpu0_tx_full;
    fifo tx0 (.clk(clk), .rst_n(rst_n), .wdata(cpu0_mem_wdata), .we(cpu0_tx_we),
              .rdata(cpu0_tx_fifo_rdata), .re(cpu0_tx_fifo_re), .empty(cpu0_tx_fifo_empty), .full(cpu0_tx_full));

    wire [7:0] cpu0_timer_rdata; wire cpu0_timer_zero;
    wire cpu0_timer_we_l = (cpu0_mem_addr == 4'h7) && cpu0_mem_we;
    wire cpu0_timer_we_h = (cpu0_mem_addr == 4'h8) && cpu0_mem_we;
    timer tmr0 (.clk(clk), .rst_n(rst_n), .wdata(cpu0_mem_wdata), .we_l(cpu0_timer_we_l), .we_h(cpu0_timer_we_h),
                .rdata_l(cpu0_timer_rdata), .is_zero(cpu0_timer_zero));

    always @(*) begin
        cpu0_mem_rdata = 8'h00;
        if (cpu0_mem_addr == 4'h5) cpu0_mem_rdata = cpu0_rx_empty ? 8'h00 : cpu0_rx_rdata;
        else if (cpu0_mem_addr == 4'h6) cpu0_mem_rdata = uio_in;
        else if (cpu0_mem_addr == 4'h7) cpu0_mem_rdata = cpu0_timer_rdata;
        else if (cpu0_mem_addr == 4'h9) cpu0_mem_rdata = shared_reg_0;
        else if (cpu0_mem_addr == 4'hA) cpu0_mem_rdata = shared_reg_1;
        else if (cpu0_mem_addr == 4'hB) cpu0_mem_rdata = shared_reg_2;
        else if (cpu0_mem_addr == 4'hC) cpu0_mem_rdata = shared_reg_3;
        else if (cpu0_mem_addr == 4'hD) cpu0_mem_rdata = crc_result_byte;
        else if (cpu0_mem_addr == 4'hE) cpu0_mem_rdata = shared_reg_5;
    end
    
    assign cpu0_mem_stall = 
        (cpu0_mem_re && cpu0_mem_addr == 4'h5 && cpu0_rx_empty) || 
        (cpu0_mem_re && cpu0_mem_addr == 4'h7 && !cpu0_timer_zero) ||
        (cpu0_mem_re && cpu0_mem_addr == 4'h9 && !shared_reg_0_valid) ||
        (cpu0_mem_re && cpu0_mem_addr == 4'hA && !shared_reg_1_valid) ||
        (cpu0_mem_re && cpu0_mem_addr == 4'hB && !shared_reg_2_valid) ||
        (cpu0_mem_re && cpu0_mem_addr == 4'hC && !shared_reg_3_valid) ||
        (cpu0_mem_re && cpu0_mem_addr == 4'hD && !shared_reg_4_valid) ||
        (cpu0_mem_re && cpu0_mem_addr == 4'hE && !shared_reg_5_valid) ||
        (cpu0_mem_we && cpu0_mem_addr == 4'h4 && cpu0_tx_full);

    reg cpu0_tx_overrun;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) cpu0_tx_overrun <= 1'b0;
        else if (cpu0_mem_we && cpu0_mem_addr == 4'h4 && cpu0_tx_full) cpu0_tx_overrun <= 1'b1;
        else if (cpu0_mem_re && cpu0_mem_addr == 4'h8) cpu0_tx_overrun <= 1'b0;
    end

    wire [7:0] cpu0_dbg_acc, cpu0_dbg_b, cpu0_dbg_flags, cpu0_dbg_r;

    cpu_core core0 (
        .clk(clk), .rst_n(rst_n), .run(cpu0_run),
        .\शोधन_विराम (dbg_halt[0]),
        .pin_state(uio_in), .pin_out(cpu0_pin_out), .pin_dir(cpu0_pin_dir),
        .pc_op(cpu0_pc_op), .rom_op_data(cpu0_rom_op_data),
        .pc_op1(cpu0_pc_op1), .rom_op1_data(cpu0_rom_op1_data),
        .pc_op2(cpu0_pc_op2), .rom_op2_data(cpu0_rom_op2_data),
        .jmp_table_addr(cpu0_jmp_addr), .jmp_table_data(cpu0_jmp_data),
        .mem_addr(cpu0_mem_addr), .mem_wdata(cpu0_mem_wdata), .mem_we(cpu0_mem_we), .mem_re(cpu0_mem_re),
        .mem_rdata(cpu0_mem_rdata), .mem_stall(cpu0_mem_stall),
        .shared_valid({shared_reg_5_valid, shared_reg_4_valid, shared_reg_3_valid, shared_reg_2_valid, shared_reg_1_valid, shared_reg_0_valid}),
        .overrun_flag(cpu0_tx_overrun),
        .\शोधन_पञ्जिका_संकेत (dbg_reg_addr),
        .\शोधन_सञ्चायक (cpu0_dbg_acc),
        .\शोधन_सहायक (cpu0_dbg_b),
        .\शोधन_ध्वज (cpu0_dbg_flags),
        .\शोधन_सामान्य_पञ्जिका (cpu0_dbg_r)
    );

    // ========================================================
    // CPU 1 SUBSYSTEM (संसाधक_1)
    // ========================================================
    reg [3:0] cpu1_rom_op [0:127];
    reg [3:0] cpu1_rom_op1 [0:63];
    reg [3:0] cpu1_rom_op2 [0:15];
    reg [16:0] cpu1_jmp_table [0:15];

    always @(posedge clk) begin
        if (cpu1_ram_op_we) cpu1_rom_op[cpu1_ram_op_waddr] <= cpu1_ram_op_wdata;
        if (cpu1_ram_op1_we) cpu1_rom_op1[cpu1_ram_op1_waddr] <= cpu1_ram_op1_wdata;
        if (cpu1_ram_op2_we) cpu1_rom_op2[cpu1_ram_op2_waddr] <= cpu1_ram_op2_wdata;
        if (cpu1_jmp_we) cpu1_jmp_table[cpu1_jmp_waddr] <= {1'b0, cpu1_jmp_wdata};
    end

    wire [6:0] cpu1_pc_op;
    wire [5:0] cpu1_pc_op1;
    wire [3:0] cpu1_pc_op2;
    wire [3:0] cpu1_jmp_addr;
    
    wire [3:0] cpu1_rom_op_data = cpu1_rom_op[cpu1_pc_op];
    wire [3:0] cpu1_rom_op1_data = cpu1_rom_op1[cpu1_pc_op1];
    wire [3:0] cpu1_rom_op2_data = cpu1_rom_op2[cpu1_pc_op2];
    wire [16:0] cpu1_jmp_data = cpu1_jmp_table[cpu1_jmp_addr];

    wire [7:0] cpu1_pin_out, cpu1_pin_dir;
    wire [3:0] cpu1_mem_addr;
    wire [7:0] cpu1_mem_wdata;
    wire cpu1_mem_we, cpu1_mem_re;
    reg  [7:0] cpu1_mem_rdata;
    wire       cpu1_mem_stall;

    wire [7:0] cpu1_rx_rdata; wire cpu1_rx_empty, cpu1_rx_full;
    wire cpu1_rx_re = (cpu1_mem_addr == 4'h5) && cpu1_mem_re && !cpu1_rx_empty;
    fifo rx1 (.clk(clk), .rst_n(rst_n), .wdata(cpu1_rx_fifo_wdata), .we(cpu1_rx_fifo_we),
              .rdata(cpu1_rx_rdata), .re(cpu1_rx_re), .empty(cpu1_rx_empty), .full(cpu1_rx_full));
              
    wire cpu1_tx_full;
    wire cpu1_tx_we = (cpu1_mem_addr == 4'h4) && cpu1_mem_we && !cpu1_tx_full;
    fifo tx1 (.clk(clk), .rst_n(rst_n), .wdata(cpu1_mem_wdata), .we(cpu1_tx_we),
              .rdata(cpu1_tx_fifo_rdata), .re(cpu1_tx_fifo_re), .empty(cpu1_tx_fifo_empty), .full(cpu1_tx_full));

    wire [7:0] cpu1_timer_rdata; wire cpu1_timer_zero;
    wire cpu1_timer_we_l = (cpu1_mem_addr == 4'h7) && cpu1_mem_we;
    wire cpu1_timer_we_h = (cpu1_mem_addr == 4'h8) && cpu1_mem_we;
    timer tmr1 (.clk(clk), .rst_n(rst_n), .wdata(cpu1_mem_wdata), .we_l(cpu1_timer_we_l), .we_h(cpu1_timer_we_h),
                .rdata_l(cpu1_timer_rdata), .is_zero(cpu1_timer_zero));

    always @(*) begin
        cpu1_mem_rdata = 8'h00;
        if (cpu1_mem_addr == 4'h5) cpu1_mem_rdata = cpu1_rx_empty ? 8'h00 : cpu1_rx_rdata;
        else if (cpu1_mem_addr == 4'h6) cpu1_mem_rdata = uio_in;
        else if (cpu1_mem_addr == 4'h7) cpu1_mem_rdata = cpu1_timer_rdata;
        else if (cpu1_mem_addr == 4'h9) cpu1_mem_rdata = shared_reg_0;
        else if (cpu1_mem_addr == 4'hA) cpu1_mem_rdata = shared_reg_1;
        else if (cpu1_mem_addr == 4'hB) cpu1_mem_rdata = shared_reg_2;
        else if (cpu1_mem_addr == 4'hC) cpu1_mem_rdata = shared_reg_3;
        else if (cpu1_mem_addr == 4'hD) cpu1_mem_rdata = crc_result_byte;
        else if (cpu1_mem_addr == 4'hE) cpu1_mem_rdata = shared_reg_5;
    end
    
    assign cpu1_mem_stall = 
        (cpu1_mem_re && cpu1_mem_addr == 4'h5 && cpu1_rx_empty) || 
        (cpu1_mem_re && cpu1_mem_addr == 4'h7 && !cpu1_timer_zero) ||
        (cpu1_mem_re && cpu1_mem_addr == 4'h9 && !shared_reg_0_valid) ||
        (cpu1_mem_re && cpu1_mem_addr == 4'hA && !shared_reg_1_valid) ||
        (cpu1_mem_re && cpu1_mem_addr == 4'hB && !shared_reg_2_valid) ||
        (cpu1_mem_re && cpu1_mem_addr == 4'hC && !shared_reg_3_valid) ||
        (cpu1_mem_re && cpu1_mem_addr == 4'hD && !shared_reg_4_valid) ||
        (cpu1_mem_re && cpu1_mem_addr == 4'hE && !shared_reg_5_valid) ||
        (cpu1_mem_we && cpu1_mem_addr == 4'h4 && cpu1_tx_full);

    reg cpu1_tx_overrun;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) cpu1_tx_overrun <= 1'b0;
        else if (cpu1_mem_we && cpu1_mem_addr == 4'h4 && cpu1_tx_full) cpu1_tx_overrun <= 1'b1;
        else if (cpu1_mem_re && cpu1_mem_addr == 4'h8) cpu1_tx_overrun <= 1'b0;
    end

    wire [7:0] cpu1_dbg_acc, cpu1_dbg_b, cpu1_dbg_flags, cpu1_dbg_r;

    cpu_core core1 (
        .clk(clk), .rst_n(rst_n), .run(cpu1_run),
        .\शोधन_विराम (dbg_halt[1]),
        .pin_state(uio_in), .pin_out(cpu1_pin_out), .pin_dir(cpu1_pin_dir),
        .pc_op(cpu1_pc_op), .rom_op_data(cpu1_rom_op_data),
        .pc_op1(cpu1_pc_op1), .rom_op1_data(cpu1_rom_op1_data),
        .pc_op2(cpu1_pc_op2), .rom_op2_data(cpu1_rom_op2_data),
        .jmp_table_addr(cpu1_jmp_addr), .jmp_table_data(cpu1_jmp_data),
        .mem_addr(cpu1_mem_addr), .mem_wdata(cpu1_mem_wdata), .mem_we(cpu1_mem_we), .mem_re(cpu1_mem_re),
        .mem_rdata(cpu1_mem_rdata), .mem_stall(cpu1_mem_stall),
        .shared_valid({shared_reg_5_valid, shared_reg_4_valid, shared_reg_3_valid, shared_reg_2_valid, shared_reg_1_valid, shared_reg_0_valid}),
        .overrun_flag(cpu1_tx_overrun),
        .\शोधन_पञ्जिका_संकेत (dbg_reg_addr),
        .\शोधन_सञ्चायक (cpu1_dbg_acc),
        .\शोधन_सहायक (cpu1_dbg_b),
        .\शोधन_ध्वज (cpu1_dbg_flags),
        .\शोधन_सामान्य_पञ्जिका (cpu1_dbg_r)
    );

    // ========================================================
    // CPU 2 SUBSYSTEM (संसाधक_2)
    // ========================================================
    reg [3:0] cpu2_rom_op [0:127];
    reg [3:0] cpu2_rom_op1 [0:63];
    reg [3:0] cpu2_rom_op2 [0:15];
    reg [16:0] cpu2_jmp_table [0:15];

    always @(posedge clk) begin
        if (cpu2_ram_op_we) cpu2_rom_op[cpu2_ram_op_waddr] <= cpu2_ram_op_wdata;
        if (cpu2_ram_op1_we) cpu2_rom_op1[cpu2_ram_op1_waddr] <= cpu2_ram_op1_wdata;
        if (cpu2_ram_op2_we) cpu2_rom_op2[cpu2_ram_op2_waddr] <= cpu2_ram_op2_wdata;
        if (cpu2_jmp_we) cpu2_jmp_table[cpu2_jmp_waddr] <= {1'b0, cpu2_jmp_wdata};
    end

    wire [6:0] cpu2_pc_op;
    wire [5:0] cpu2_pc_op1;
    wire [3:0] cpu2_pc_op2;
    wire [3:0] cpu2_jmp_addr;
    
    wire [3:0] cpu2_rom_op_data = cpu2_rom_op[cpu2_pc_op];
    wire [3:0] cpu2_rom_op1_data = cpu2_rom_op1[cpu2_pc_op1];
    wire [3:0] cpu2_rom_op2_data = cpu2_rom_op2[cpu2_pc_op2];
    wire [16:0] cpu2_jmp_data = cpu2_jmp_table[cpu2_jmp_addr];

    wire [7:0] cpu2_pin_out, cpu2_pin_dir;
    wire [3:0] cpu2_mem_addr;
    wire [7:0] cpu2_mem_wdata;
    wire cpu2_mem_we, cpu2_mem_re;
    reg  [7:0] cpu2_mem_rdata;
    wire       cpu2_mem_stall;

    wire [7:0] cpu2_rx_rdata; wire cpu2_rx_empty, cpu2_rx_full;
    wire cpu2_rx_re = (cpu2_mem_addr == 4'h5) && cpu2_mem_re && !cpu2_rx_empty;
    fifo rx2 (.clk(clk), .rst_n(rst_n), .wdata(cpu2_rx_fifo_wdata), .we(cpu2_rx_fifo_we),
              .rdata(cpu2_rx_rdata), .re(cpu2_rx_re), .empty(cpu2_rx_empty), .full(cpu2_rx_full));
              
    wire cpu2_tx_full;
    wire cpu2_tx_we = (cpu2_mem_addr == 4'h4) && cpu2_mem_we && !cpu2_tx_full;
    fifo tx2 (.clk(clk), .rst_n(rst_n), .wdata(cpu2_mem_wdata), .we(cpu2_tx_we),
              .rdata(cpu2_tx_fifo_rdata), .re(cpu2_tx_fifo_re), .empty(cpu2_tx_fifo_empty), .full(cpu2_tx_full));

    wire [7:0] cpu2_timer_rdata; wire cpu2_timer_zero;
    wire cpu2_timer_we_l = (cpu2_mem_addr == 4'h7) && cpu2_mem_we;
    wire cpu2_timer_we_h = (cpu2_mem_addr == 4'h8) && cpu2_mem_we;
    timer tmr2 (.clk(clk), .rst_n(rst_n), .wdata(cpu2_mem_wdata), .we_l(cpu2_timer_we_l), .we_h(cpu2_timer_we_h),
                .rdata_l(cpu2_timer_rdata), .is_zero(cpu2_timer_zero));

    always @(*) begin
        cpu2_mem_rdata = 8'h00;
        if (cpu2_mem_addr == 4'h5) cpu2_mem_rdata = cpu2_rx_empty ? 8'h00 : cpu2_rx_rdata;
        else if (cpu2_mem_addr == 4'h6) cpu2_mem_rdata = uio_in;
        else if (cpu2_mem_addr == 4'h7) cpu2_mem_rdata = cpu2_timer_rdata;
        else if (cpu2_mem_addr == 4'h9) cpu2_mem_rdata = shared_reg_0;
        else if (cpu2_mem_addr == 4'hA) cpu2_mem_rdata = shared_reg_1;
        else if (cpu2_mem_addr == 4'hB) cpu2_mem_rdata = shared_reg_2;
        else if (cpu2_mem_addr == 4'hC) cpu2_mem_rdata = shared_reg_3;
        else if (cpu2_mem_addr == 4'hD) cpu2_mem_rdata = crc_result_byte;
        else if (cpu2_mem_addr == 4'hE) cpu2_mem_rdata = shared_reg_5;
    end
    
    assign cpu2_mem_stall = 
        (cpu2_mem_re && cpu2_mem_addr == 4'h5 && cpu2_rx_empty) || 
        (cpu2_mem_re && cpu2_mem_addr == 4'h7 && !cpu2_timer_zero) ||
        (cpu2_mem_re && cpu2_mem_addr == 4'h9 && !shared_reg_0_valid) ||
        (cpu2_mem_re && cpu2_mem_addr == 4'hA && !shared_reg_1_valid) ||
        (cpu2_mem_re && cpu2_mem_addr == 4'hB && !shared_reg_2_valid) ||
        (cpu2_mem_re && cpu2_mem_addr == 4'hC && !shared_reg_3_valid) ||
        (cpu2_mem_re && cpu2_mem_addr == 4'hD && !shared_reg_4_valid) ||
        (cpu2_mem_re && cpu2_mem_addr == 4'hE && !shared_reg_5_valid) ||
        (cpu2_mem_we && cpu2_mem_addr == 4'h4 && cpu2_tx_full);

    reg cpu2_tx_overrun;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) cpu2_tx_overrun <= 1'b0;
        else if (cpu2_mem_we && cpu2_mem_addr == 4'h4 && cpu2_tx_full) cpu2_tx_overrun <= 1'b1;
        else if (cpu2_mem_re && cpu2_mem_addr == 4'h8) cpu2_tx_overrun <= 1'b0;
    end

    wire [7:0] cpu2_dbg_acc, cpu2_dbg_b, cpu2_dbg_flags, cpu2_dbg_r;

    cpu_core core2 (
        .clk(clk), .rst_n(rst_n), .run(cpu2_run),
        .\शोधन_विराम (dbg_halt[2]),
        .pin_state(uio_in), .pin_out(cpu2_pin_out), .pin_dir(cpu2_pin_dir),
        .pc_op(cpu2_pc_op), .rom_op_data(cpu2_rom_op_data),
        .pc_op1(cpu2_pc_op1), .rom_op1_data(cpu2_rom_op1_data),
        .pc_op2(cpu2_pc_op2), .rom_op2_data(cpu2_rom_op2_data),
        .jmp_table_addr(cpu2_jmp_addr), .jmp_table_data(cpu2_jmp_data),
        .mem_addr(cpu2_mem_addr), .mem_wdata(cpu2_mem_wdata), .mem_we(cpu2_mem_we), .mem_re(cpu2_mem_re),
        .mem_rdata(cpu2_mem_rdata), .mem_stall(cpu2_mem_stall),
        .shared_valid({shared_reg_5_valid, shared_reg_4_valid, shared_reg_3_valid, shared_reg_2_valid, shared_reg_1_valid, shared_reg_0_valid}),
        .overrun_flag(cpu2_tx_overrun),
        .\शोधन_पञ्जिका_संकेत (dbg_reg_addr),
        .\शोधन_सञ्चायक (cpu2_dbg_acc),
        .\शोधन_सहायक (cpu2_dbg_b),
        .\शोधन_ध्वज (cpu2_dbg_flags),
        .\शोधन_सामान्य_पञ्जिका (cpu2_dbg_r)
    );

    // ========================================================
    // CPU 3 SUBSYSTEM (संसाधक_3)
    // ========================================================
    reg [3:0] cpu3_rom_op [0:127];
    reg [3:0] cpu3_rom_op1 [0:63];
    reg [3:0] cpu3_rom_op2 [0:15];
    reg [16:0] cpu3_jmp_table [0:15];

    always @(posedge clk) begin
        if (cpu3_ram_op_we) cpu3_rom_op[cpu3_ram_op_waddr] <= cpu3_ram_op_wdata;
        if (cpu3_ram_op1_we) cpu3_rom_op1[cpu3_ram_op1_waddr] <= cpu3_ram_op1_wdata;
        if (cpu3_ram_op2_we) cpu3_rom_op2[cpu3_ram_op2_waddr] <= cpu3_ram_op2_wdata;
        if (cpu3_jmp_we) cpu3_jmp_table[cpu3_jmp_waddr] <= {1'b0, cpu3_jmp_wdata};
    end

    wire [6:0] cpu3_pc_op;
    wire [5:0] cpu3_pc_op1;
    wire [3:0] cpu3_pc_op2;
    wire [3:0] cpu3_jmp_addr;
    
    wire [3:0] cpu3_rom_op_data = cpu3_rom_op[cpu3_pc_op];
    wire [3:0] cpu3_rom_op1_data = cpu3_rom_op1[cpu3_pc_op1];
    wire [3:0] cpu3_rom_op2_data = cpu3_rom_op2[cpu3_pc_op2];
    wire [16:0] cpu3_jmp_data = cpu3_jmp_table[cpu3_jmp_addr];

    wire [7:0] cpu3_pin_out, cpu3_pin_dir;
    wire [3:0] cpu3_mem_addr;
    wire [7:0] cpu3_mem_wdata;
    wire cpu3_mem_we, cpu3_mem_re;
    reg  [7:0] cpu3_mem_rdata;
    wire       cpu3_mem_stall;

    wire [7:0] cpu3_rx_rdata; wire cpu3_rx_empty, cpu3_rx_full;
    wire cpu3_rx_re = (cpu3_mem_addr == 4'h5) && cpu3_mem_re && !cpu3_rx_empty;
    fifo rx3 (.clk(clk), .rst_n(rst_n), .wdata(cpu3_rx_fifo_wdata), .we(cpu3_rx_fifo_we),
              .rdata(cpu3_rx_rdata), .re(cpu3_rx_re), .empty(cpu3_rx_empty), .full(cpu3_rx_full));
              
    wire cpu3_tx_full;
    wire cpu3_tx_we = (cpu3_mem_addr == 4'h4) && cpu3_mem_we && !cpu3_tx_full;
    fifo tx3 (.clk(clk), .rst_n(rst_n), .wdata(cpu3_mem_wdata), .we(cpu3_tx_we),
              .rdata(cpu3_tx_fifo_rdata), .re(cpu3_tx_fifo_re), .empty(cpu3_tx_fifo_empty), .full(cpu3_tx_full));

    wire [7:0] cpu3_timer_rdata; wire cpu3_timer_zero;
    wire cpu3_timer_we_l = (cpu3_mem_addr == 4'h7) && cpu3_mem_we;
    wire cpu3_timer_we_h = (cpu3_mem_addr == 4'h8) && cpu3_mem_we;
    timer tmr3 (.clk(clk), .rst_n(rst_n), .wdata(cpu3_mem_wdata), .we_l(cpu3_timer_we_l), .we_h(cpu3_timer_we_h),
                .rdata_l(cpu3_timer_rdata), .is_zero(cpu3_timer_zero));

    always @(*) begin
        cpu3_mem_rdata = 8'h00;
        if (cpu3_mem_addr == 4'h5) cpu3_mem_rdata = cpu3_rx_empty ? 8'h00 : cpu3_rx_rdata;
        else if (cpu3_mem_addr == 4'h6) cpu3_mem_rdata = uio_in;
        else if (cpu3_mem_addr == 4'h7) cpu3_mem_rdata = cpu3_timer_rdata;
        else if (cpu3_mem_addr == 4'h9) cpu3_mem_rdata = shared_reg_0;
        else if (cpu3_mem_addr == 4'hA) cpu3_mem_rdata = shared_reg_1;
        else if (cpu3_mem_addr == 4'hB) cpu3_mem_rdata = shared_reg_2;
        else if (cpu3_mem_addr == 4'hC) cpu3_mem_rdata = shared_reg_3;
        else if (cpu3_mem_addr == 4'hD) cpu3_mem_rdata = crc_result_byte;
        else if (cpu3_mem_addr == 4'hE) cpu3_mem_rdata = shared_reg_5;
    end
    
    assign cpu3_mem_stall = 
        (cpu3_mem_re && cpu3_mem_addr == 4'h5 && cpu3_rx_empty) || 
        (cpu3_mem_re && cpu3_mem_addr == 4'h7 && !cpu3_timer_zero) ||
        (cpu3_mem_re && cpu3_mem_addr == 4'h9 && !shared_reg_0_valid) ||
        (cpu3_mem_re && cpu3_mem_addr == 4'hA && !shared_reg_1_valid) ||
        (cpu3_mem_re && cpu3_mem_addr == 4'hB && !shared_reg_2_valid) ||
        (cpu3_mem_re && cpu3_mem_addr == 4'hC && !shared_reg_3_valid) ||
        (cpu3_mem_re && cpu3_mem_addr == 4'hD && !shared_reg_4_valid) ||
        (cpu3_mem_re && cpu3_mem_addr == 4'hE && !shared_reg_5_valid) ||
        (cpu3_mem_we && cpu3_mem_addr == 4'h4 && cpu3_tx_full);

    reg cpu3_tx_overrun;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) cpu3_tx_overrun <= 1'b0;
        else if (cpu3_mem_we && cpu3_mem_addr == 4'h4 && cpu3_tx_full) cpu3_tx_overrun <= 1'b1;
        else if (cpu3_mem_re && cpu3_mem_addr == 4'h8) cpu3_tx_overrun <= 1'b0;
    end

    wire [7:0] cpu3_dbg_acc, cpu3_dbg_b, cpu3_dbg_flags, cpu3_dbg_r;

    cpu_core core3 (
        .clk(clk), .rst_n(rst_n), .run(cpu3_run),
        .\शोधन_विराम (dbg_halt[3]),
        .pin_state(uio_in), .pin_out(cpu3_pin_out), .pin_dir(cpu3_pin_dir),
        .pc_op(cpu3_pc_op), .rom_op_data(cpu3_rom_op_data),
        .pc_op1(cpu3_pc_op1), .rom_op1_data(cpu3_rom_op1_data),
        .pc_op2(cpu3_pc_op2), .rom_op2_data(cpu3_rom_op2_data),
        .jmp_table_addr(cpu3_jmp_addr), .jmp_table_data(cpu3_jmp_data),
        .mem_addr(cpu3_mem_addr), .mem_wdata(cpu3_mem_wdata), .mem_we(cpu3_mem_we), .mem_re(cpu3_mem_re),
        .mem_rdata(cpu3_mem_rdata), .mem_stall(cpu3_mem_stall),
        .shared_valid({shared_reg_5_valid, shared_reg_4_valid, shared_reg_3_valid, shared_reg_2_valid, shared_reg_1_valid, shared_reg_0_valid}),
        .overrun_flag(cpu3_tx_overrun),
        .\शोधन_पञ्जिका_संकेत (dbg_reg_addr),
        .\शोधन_सञ्चायक (cpu3_dbg_acc),
        .\शोधन_सहायक (cpu3_dbg_b),
        .\शोधन_ध्वज (cpu3_dbg_flags),
        .\शोधन_सामान्य_पञ्जिका (cpu3_dbg_r)
    );

    // ========================================================
    // CPU 4 SUBSYSTEM (संसाधक_4)
    // ========================================================
    reg [3:0] cpu4_rom_op [0:127];
    reg [3:0] cpu4_rom_op1 [0:63];
    reg [3:0] cpu4_rom_op2 [0:15];
    reg [16:0] cpu4_jmp_table [0:15];

    always @(posedge clk) begin
        if (cpu4_ram_op_we) cpu4_rom_op[cpu4_ram_op_waddr] <= cpu4_ram_op_wdata;
        if (cpu4_ram_op1_we) cpu4_rom_op1[cpu4_ram_op1_waddr] <= cpu4_ram_op1_wdata;
        if (cpu4_ram_op2_we) cpu4_rom_op2[cpu4_ram_op2_waddr] <= cpu4_ram_op2_wdata;
        if (cpu4_jmp_we) cpu4_jmp_table[cpu4_jmp_waddr] <= {1'b0, cpu4_jmp_wdata};
    end

    wire [6:0] cpu4_pc_op;
    wire [5:0] cpu4_pc_op1;
    wire [3:0] cpu4_pc_op2;
    wire [3:0] cpu4_jmp_addr;
    
    wire [3:0] cpu4_rom_op_data = cpu4_rom_op[cpu4_pc_op];
    wire [3:0] cpu4_rom_op1_data = cpu4_rom_op1[cpu4_pc_op1];
    wire [3:0] cpu4_rom_op2_data = cpu4_rom_op2[cpu4_pc_op2];
    wire [16:0] cpu4_jmp_data = cpu4_jmp_table[cpu4_jmp_addr];

    wire [7:0] cpu4_pin_out, cpu4_pin_dir;
    wire [3:0] cpu4_mem_addr;
    wire [7:0] cpu4_mem_wdata;
    wire cpu4_mem_we, cpu4_mem_re;
    reg  [7:0] cpu4_mem_rdata;
    wire       cpu4_mem_stall;

    wire [7:0] cpu4_rx_rdata; wire cpu4_rx_empty, cpu4_rx_full;
    wire cpu4_rx_re = (cpu4_mem_addr == 4'h5) && cpu4_mem_re && !cpu4_rx_empty;
    fifo rx4 (.clk(clk), .rst_n(rst_n), .wdata(cpu4_rx_fifo_wdata), .we(cpu4_rx_fifo_we),
              .rdata(cpu4_rx_rdata), .re(cpu4_rx_re), .empty(cpu4_rx_empty), .full(cpu4_rx_full));
              
    wire cpu4_tx_full;
    wire cpu4_tx_we = (cpu4_mem_addr == 4'h4) && cpu4_mem_we && !cpu4_tx_full;
    fifo tx4 (.clk(clk), .rst_n(rst_n), .wdata(cpu4_mem_wdata), .we(cpu4_tx_we),
              .rdata(cpu4_tx_fifo_rdata), .re(cpu4_tx_fifo_re), .empty(cpu4_tx_fifo_empty), .full(cpu4_tx_full));

    wire [7:0] cpu4_timer_rdata; wire cpu4_timer_zero;
    wire cpu4_timer_we_l = (cpu4_mem_addr == 4'h7) && cpu4_mem_we;
    wire cpu4_timer_we_h = (cpu4_mem_addr == 4'h8) && cpu4_mem_we;
    timer tmr4 (.clk(clk), .rst_n(rst_n), .wdata(cpu4_mem_wdata), .we_l(cpu4_timer_we_l), .we_h(cpu4_timer_we_h),
                .rdata_l(cpu4_timer_rdata), .is_zero(cpu4_timer_zero));

    always @(*) begin
        cpu4_mem_rdata = 8'h00;
        if (cpu4_mem_addr == 4'h5) cpu4_mem_rdata = cpu4_rx_empty ? 8'h00 : cpu4_rx_rdata;
        else if (cpu4_mem_addr == 4'h6) cpu4_mem_rdata = uio_in;
        else if (cpu4_mem_addr == 4'h7) cpu4_mem_rdata = cpu4_timer_rdata;
        else if (cpu4_mem_addr == 4'h9) cpu4_mem_rdata = shared_reg_0;
        else if (cpu4_mem_addr == 4'hA) cpu4_mem_rdata = shared_reg_1;
        else if (cpu4_mem_addr == 4'hB) cpu4_mem_rdata = shared_reg_2;
        else if (cpu4_mem_addr == 4'hC) cpu4_mem_rdata = shared_reg_3;
        else if (cpu4_mem_addr == 4'hD) cpu4_mem_rdata = crc_result_byte;
        else if (cpu4_mem_addr == 4'hE) cpu4_mem_rdata = shared_reg_5;
    end
    
    assign cpu4_mem_stall = 
        (cpu4_mem_re && cpu4_mem_addr == 4'h5 && cpu4_rx_empty) || 
        (cpu4_mem_re && cpu4_mem_addr == 4'h7 && !cpu4_timer_zero) ||
        (cpu4_mem_re && cpu4_mem_addr == 4'h9 && !shared_reg_0_valid) ||
        (cpu4_mem_re && cpu4_mem_addr == 4'hA && !shared_reg_1_valid) ||
        (cpu4_mem_re && cpu4_mem_addr == 4'hB && !shared_reg_2_valid) ||
        (cpu4_mem_re && cpu4_mem_addr == 4'hC && !shared_reg_3_valid) ||
        (cpu4_mem_re && cpu4_mem_addr == 4'hD && !shared_reg_4_valid) ||
        (cpu4_mem_re && cpu4_mem_addr == 4'hE && !shared_reg_5_valid) ||
        (cpu4_mem_we && cpu4_mem_addr == 4'h4 && cpu4_tx_full);

    reg cpu4_tx_overrun;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) cpu4_tx_overrun <= 1'b0;
        else if (cpu4_mem_we && cpu4_mem_addr == 4'h4 && cpu4_tx_full) cpu4_tx_overrun <= 1'b1;
        else if (cpu4_mem_re && cpu4_mem_addr == 4'h8) cpu4_tx_overrun <= 1'b0;
    end

    wire [7:0] cpu4_dbg_acc, cpu4_dbg_b, cpu4_dbg_flags, cpu4_dbg_r;

    cpu_core core4 (
        .clk(clk), .rst_n(rst_n), .run(cpu4_run),
        .\शोधन_विराम (dbg_halt[4]),
        .pin_state(uio_in), .pin_out(cpu4_pin_out), .pin_dir(cpu4_pin_dir),
        .pc_op(cpu4_pc_op), .rom_op_data(cpu4_rom_op_data),
        .pc_op1(cpu4_pc_op1), .rom_op1_data(cpu4_rom_op1_data),
        .pc_op2(cpu4_pc_op2), .rom_op2_data(cpu4_rom_op2_data),
        .jmp_table_addr(cpu4_jmp_addr), .jmp_table_data(cpu4_jmp_data),
        .mem_addr(cpu4_mem_addr), .mem_wdata(cpu4_mem_wdata), .mem_we(cpu4_mem_we), .mem_re(cpu4_mem_re),
        .mem_rdata(cpu4_mem_rdata), .mem_stall(cpu4_mem_stall),
        .shared_valid({shared_reg_5_valid, shared_reg_4_valid, shared_reg_3_valid, shared_reg_2_valid, shared_reg_1_valid, shared_reg_0_valid}),
        .overrun_flag(cpu4_tx_overrun),
        .\शोधन_पञ्जिका_संकेत (dbg_reg_addr),
        .\शोधन_सञ्चायक (cpu4_dbg_acc),
        .\शोधन_सहायक (cpu4_dbg_b),
        .\शोधन_ध्वज (cpu4_dbg_flags),
        .\शोधन_सामान्य_पञ्जिका (cpu4_dbg_r)
    );

    // ========================================================
    // CPU 5 SUBSYSTEM (संसाधक_5)
    // ========================================================
    reg [3:0] cpu5_rom_op [0:127];
    reg [3:0] cpu5_rom_op1 [0:63];
    reg [3:0] cpu5_rom_op2 [0:15];
    reg [16:0] cpu5_jmp_table [0:15];

    always @(posedge clk) begin
        if (cpu5_ram_op_we) cpu5_rom_op[cpu5_ram_op_waddr] <= cpu5_ram_op_wdata;
        if (cpu5_ram_op1_we) cpu5_rom_op1[cpu5_ram_op1_waddr] <= cpu5_ram_op1_wdata;
        if (cpu5_ram_op2_we) cpu5_rom_op2[cpu5_ram_op2_waddr] <= cpu5_ram_op2_wdata;
        if (cpu5_jmp_we) cpu5_jmp_table[cpu5_jmp_waddr] <= {1'b0, cpu5_jmp_wdata};
    end

    wire [6:0] cpu5_pc_op;
    wire [5:0] cpu5_pc_op1;
    wire [3:0] cpu5_pc_op2;
    wire [3:0] cpu5_jmp_addr;
    
    wire [3:0] cpu5_rom_op_data = cpu5_rom_op[cpu5_pc_op];
    wire [3:0] cpu5_rom_op1_data = cpu5_rom_op1[cpu5_pc_op1];
    wire [3:0] cpu5_rom_op2_data = cpu5_rom_op2[cpu5_pc_op2];
    wire [16:0] cpu5_jmp_data = cpu5_jmp_table[cpu5_jmp_addr];

    wire [7:0] cpu5_pin_out, cpu5_pin_dir;
    wire [3:0] cpu5_mem_addr;
    wire [7:0] cpu5_mem_wdata;
    wire cpu5_mem_we, cpu5_mem_re;
    reg  [7:0] cpu5_mem_rdata;
    wire       cpu5_mem_stall;

    wire [7:0] cpu5_rx_rdata; wire cpu5_rx_empty, cpu5_rx_full;
    wire cpu5_rx_re = (cpu5_mem_addr == 4'h5) && cpu5_mem_re && !cpu5_rx_empty;
    fifo rx5 (.clk(clk), .rst_n(rst_n), .wdata(cpu5_rx_fifo_wdata), .we(cpu5_rx_fifo_we),
              .rdata(cpu5_rx_rdata), .re(cpu5_rx_re), .empty(cpu5_rx_empty), .full(cpu5_rx_full));
              
    wire cpu5_tx_full;
    wire cpu5_tx_we = (cpu5_mem_addr == 4'h4) && cpu5_mem_we && !cpu5_tx_full;
    fifo tx5 (.clk(clk), .rst_n(rst_n), .wdata(cpu5_mem_wdata), .we(cpu5_tx_we),
              .rdata(cpu5_tx_fifo_rdata), .re(cpu5_tx_fifo_re), .empty(cpu5_tx_fifo_empty), .full(cpu5_tx_full));

    wire [7:0] cpu5_timer_rdata; wire cpu5_timer_zero;
    wire cpu5_timer_we_l = (cpu5_mem_addr == 4'h7) && cpu5_mem_we;
    wire cpu5_timer_we_h = (cpu5_mem_addr == 4'h8) && cpu5_mem_we;
    timer tmr5 (.clk(clk), .rst_n(rst_n), .wdata(cpu5_mem_wdata), .we_l(cpu5_timer_we_l), .we_h(cpu5_timer_we_h),
                .rdata_l(cpu5_timer_rdata), .is_zero(cpu5_timer_zero));

    always @(*) begin
        cpu5_mem_rdata = 8'h00;
        if (cpu5_mem_addr == 4'h5) cpu5_mem_rdata = cpu5_rx_empty ? 8'h00 : cpu5_rx_rdata;
        else if (cpu5_mem_addr == 4'h6) cpu5_mem_rdata = uio_in;
        else if (cpu5_mem_addr == 4'h7) cpu5_mem_rdata = cpu5_timer_rdata;
        else if (cpu5_mem_addr == 4'h9) cpu5_mem_rdata = shared_reg_0;
        else if (cpu5_mem_addr == 4'hA) cpu5_mem_rdata = shared_reg_1;
        else if (cpu5_mem_addr == 4'hB) cpu5_mem_rdata = shared_reg_2;
        else if (cpu5_mem_addr == 4'hC) cpu5_mem_rdata = shared_reg_3;
        else if (cpu5_mem_addr == 4'hD) cpu5_mem_rdata = crc_result_byte;
        else if (cpu5_mem_addr == 4'hE) cpu5_mem_rdata = shared_reg_5;
    end
    
    assign cpu5_mem_stall = 
        (cpu5_mem_re && cpu5_mem_addr == 4'h5 && cpu5_rx_empty) || 
        (cpu5_mem_re && cpu5_mem_addr == 4'h7 && !cpu5_timer_zero) ||
        (cpu5_mem_re && cpu5_mem_addr == 4'h9 && !shared_reg_0_valid) ||
        (cpu5_mem_re && cpu5_mem_addr == 4'hA && !shared_reg_1_valid) ||
        (cpu5_mem_re && cpu5_mem_addr == 4'hB && !shared_reg_2_valid) ||
        (cpu5_mem_re && cpu5_mem_addr == 4'hC && !shared_reg_3_valid) ||
        (cpu5_mem_re && cpu5_mem_addr == 4'hD && !shared_reg_4_valid) ||
        (cpu5_mem_re && cpu5_mem_addr == 4'hE && !shared_reg_5_valid) ||
        (cpu5_mem_we && cpu5_mem_addr == 4'h4 && cpu5_tx_full);

    reg cpu5_tx_overrun;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) cpu5_tx_overrun <= 1'b0;
        else if (cpu5_mem_we && cpu5_mem_addr == 4'h4 && cpu5_tx_full) cpu5_tx_overrun <= 1'b1;
        else if (cpu5_mem_re && cpu5_mem_addr == 4'h8) cpu5_tx_overrun <= 1'b0;
    end

    wire [7:0] cpu5_dbg_acc, cpu5_dbg_b, cpu5_dbg_flags, cpu5_dbg_r;

    cpu_core core5 (
        .clk(clk), .rst_n(rst_n), .run(cpu5_run),
        .\शोधन_विराम (dbg_halt[5]),
        .pin_state(uio_in), .pin_out(cpu5_pin_out), .pin_dir(cpu5_pin_dir),
        .pc_op(cpu5_pc_op), .rom_op_data(cpu5_rom_op_data),
        .pc_op1(cpu5_pc_op1), .rom_op1_data(cpu5_rom_op1_data),
        .pc_op2(cpu5_pc_op2), .rom_op2_data(cpu5_rom_op2_data),
        .jmp_table_addr(cpu5_jmp_addr), .jmp_table_data(cpu5_jmp_data),
        .mem_addr(cpu5_mem_addr), .mem_wdata(cpu5_mem_wdata), .mem_we(cpu5_mem_we), .mem_re(cpu5_mem_re),
        .mem_rdata(cpu5_mem_rdata), .mem_stall(cpu5_mem_stall),
        .shared_valid({shared_reg_5_valid, shared_reg_4_valid, shared_reg_3_valid, shared_reg_2_valid, shared_reg_1_valid, shared_reg_0_valid}),
        .overrun_flag(cpu5_tx_overrun),
        .\शोधन_पञ्जिका_संकेत (dbg_reg_addr),
        .\शोधन_सञ्चायक (cpu5_dbg_acc),
        .\शोधन_सहायक (cpu5_dbg_b),
        .\शोधन_ध्वज (cpu5_dbg_flags),
        .\शोधन_सामान्य_पञ्जिका (cpu5_dbg_r)
    );

    wire [5:0] dbg_halt;
    wire [2:0] dbg_core_id;
    wire [3:0] dbg_reg_addr;

    reg [7:0]  muxed_dbg_acc;
    reg [7:0]  muxed_dbg_b;
    reg [7:0]  muxed_dbg_flags;
    reg [6:0]  muxed_dbg_pc0;
    reg [5:0]  muxed_dbg_pc1;
    reg [3:0]  muxed_dbg_pc2;
    reg [7:0]  muxed_dbg_r;
    reg [7:0]  muxed_dbg_pindir;
    reg [7:0]  muxed_dbg_pinout;

    always @(*) begin
        case (dbg_core_id)
            3'd0: begin
                muxed_dbg_acc    = cpu0_dbg_acc;
                muxed_dbg_b      = cpu0_dbg_b;
                muxed_dbg_flags  = cpu0_dbg_flags;
                muxed_dbg_pc0    = cpu0_pc_op;
                muxed_dbg_pc1    = cpu0_pc_op1;
                muxed_dbg_pc2    = cpu0_pc_op2;
                muxed_dbg_r      = cpu0_dbg_r;
                muxed_dbg_pindir = cpu0_pin_dir;
                muxed_dbg_pinout = cpu0_pin_out;
            end
            3'd1: begin
                muxed_dbg_acc    = cpu1_dbg_acc;
                muxed_dbg_b      = cpu1_dbg_b;
                muxed_dbg_flags  = cpu1_dbg_flags;
                muxed_dbg_pc0    = cpu1_pc_op;
                muxed_dbg_pc1    = cpu1_pc_op1;
                muxed_dbg_pc2    = cpu1_pc_op2;
                muxed_dbg_r      = cpu1_dbg_r;
                muxed_dbg_pindir = cpu1_pin_dir;
                muxed_dbg_pinout = cpu1_pin_out;
            end
            3'd2: begin
                muxed_dbg_acc    = cpu2_dbg_acc;
                muxed_dbg_b      = cpu2_dbg_b;
                muxed_dbg_flags  = cpu2_dbg_flags;
                muxed_dbg_pc0    = cpu2_pc_op;
                muxed_dbg_pc1    = cpu2_pc_op1;
                muxed_dbg_pc2    = cpu2_pc_op2;
                muxed_dbg_r      = cpu2_dbg_r;
                muxed_dbg_pindir = cpu2_pin_dir;
                muxed_dbg_pinout = cpu2_pin_out;
            end
            3'd3: begin
                muxed_dbg_acc    = cpu3_dbg_acc;
                muxed_dbg_b      = cpu3_dbg_b;
                muxed_dbg_flags  = cpu3_dbg_flags;
                muxed_dbg_pc0    = cpu3_pc_op;
                muxed_dbg_pc1    = cpu3_pc_op1;
                muxed_dbg_pc2    = cpu3_pc_op2;
                muxed_dbg_r      = cpu3_dbg_r;
                muxed_dbg_pindir = cpu3_pin_dir;
                muxed_dbg_pinout = cpu3_pin_out;
            end
            3'd4: begin
                muxed_dbg_acc    = cpu4_dbg_acc;
                muxed_dbg_b      = cpu4_dbg_b;
                muxed_dbg_flags  = cpu4_dbg_flags;
                muxed_dbg_pc0    = cpu4_pc_op;
                muxed_dbg_pc1    = cpu4_pc_op1;
                muxed_dbg_pc2    = cpu4_pc_op2;
                muxed_dbg_r      = cpu4_dbg_r;
                muxed_dbg_pindir = cpu4_pin_dir;
                muxed_dbg_pinout = cpu4_pin_out;
            end
            default: begin
                muxed_dbg_acc    = cpu5_dbg_acc;
                muxed_dbg_b      = cpu5_dbg_b;
                muxed_dbg_flags  = cpu5_dbg_flags;
                muxed_dbg_pc0    = cpu5_pc_op;
                muxed_dbg_pc1    = cpu5_pc_op1;
                muxed_dbg_pc2    = cpu5_pc_op2;
                muxed_dbg_r      = cpu5_dbg_r;
                muxed_dbg_pindir = cpu5_pin_dir;
                muxed_dbg_pinout = cpu5_pin_out;
            end
        endcase
    end

    dvitantri_shodhana dbg_ctrl (
        .clk(clk),
        .rst_n(rst_n),
        .\शोधन_घटिका (dbg_sclk),
        .\शोधन_निवेश (dbg_din),
        .\शोधन_निर्गम (dbg_dout),
        .\विराम_संकेत (dbg_halt),
        .\संसाधक_क्रमांक (dbg_core_id),
        .\पञ्जिका_संकेत (dbg_reg_addr),
        .\सञ्चायक_दत्त (muxed_dbg_acc),
        .\सहायक_दत्त (muxed_dbg_b),
        .\ध्वज_दत्त (muxed_dbg_flags),
        .\गणक_संकेत_० (muxed_dbg_pc0),
        .\गणक_संकेत_१ (muxed_dbg_pc1),
        .\गणक_संकेत_२ (muxed_dbg_pc2),
        .\सामान्य_पञ्जिका (muxed_dbg_r),
        .\पिन्_दिश_दत्त (muxed_dbg_pindir),
        .\पिन्_निर्गम_दत्त (muxed_dbg_pinout)
    );

    assign uio_oe = cpu0_pin_dir | cpu1_pin_dir | cpu2_pin_dir | 
                    cpu3_pin_dir | cpu4_pin_dir | cpu5_pin_dir;

    wire [7:0] cpu0_safe_out = cpu0_pin_dir & cpu0_pin_out;
    wire [7:0] cpu1_safe_out = cpu1_pin_dir & cpu1_pin_out;
    wire [7:0] cpu2_safe_out = cpu2_pin_dir & cpu2_pin_out;
    wire [7:0] cpu3_safe_out = cpu3_pin_dir & cpu3_pin_out;
    wire [7:0] cpu4_safe_out = cpu4_pin_dir & cpu4_pin_out;
    wire [7:0] cpu5_safe_out = cpu5_pin_dir & cpu5_pin_out;

    assign uio_out = cpu0_safe_out | cpu1_safe_out | cpu2_safe_out | 
                     cpu3_safe_out | cpu4_safe_out | cpu5_safe_out;

    assign uo_out[1] = cpu0_rx_empty;
    assign uo_out[2] = cpu1_rx_empty;
    assign uo_out[3] = cpu2_rx_empty;
    assign uo_out[4] = cpu3_rx_empty;
    assign uo_out[5] = cpu0_tx_fifo_empty;
    assign uo_out[6] = cpu1_tx_fifo_empty;

endmodule
