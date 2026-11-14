`default_nettype none
`timescale 1ns/1ps

// ============================================================================
// द्वितन्त्री_शोधन (Two-Wire Debug Controller)
// Host Debugger (RP2040) controls execution, halts cores, and inspects registers
// ============================================================================

module dvitantri_shodhana (
    input  wire        clk,
    input  wire        rst_n,

    // द्वितन्त्री पिन् (Two-wire Debug Physical Pins)
    input  wire        \शोधन_घटिका , // Debug Serial Clock (dbg_sclk)
    input  wire        \शोधन_निवेश ,  // Debug Serial Data In (dbg_mosi/din)
    output reg         \शोधन_निर्गम , // Debug Serial Data Out (dbg_miso/dout)

    // ६ संसाधकाः विराम-संकेताः (Halt control to 6 cores)
    output reg  [5:0]  \विराम_संकेत , // dbg_halt to core 0..5

    // संसाधक चयन एवं पञ्जिका पठन (Core select & Register readout multiplexer)
    output reg  [2:0]  \संसाधक_क्रमांक , // Target Core ID (0..5)
    output reg  [3:0]  \पञ्जिका_संकेत ,   // Target Register Address (0..15)
    
    // Core Readout Data Inputs from Cores (Direct inspection bus)
    input  wire [7:0]  \सञ्चायक_दत्त ,   // ACC data
    input  wire [7:0]  \सहायक_दत्त ,     // B reg data
    input  wire [7:0]  \ध्वज_दत्त ,       // STATUS_FLAGS data
    input  wire [6:0]  \गणक_संकेत_० ,   // PC_OP (7-bit)
    input  wire [5:0]  \गणक_संकेत_१ ,   // PC_OP1 (6-bit)
    input  wire [3:0]  \गणक_संकेत_२ ,   // PC_OP2 (4-bit)
    input  wire [7:0]  \सामान्य_पञ्जिका , // General register R[addr]
    input  wire [7:0]  \पिन्_दिश_दत्त ,   // Pin direction register (pin_dir)
    input  wire [7:0]  \पिन्_निर्गम_दत्त   // Pin output register (pin_out)
);

    // Synchronizers for debug clock & data
    reg \घटिका_समकालिक_१ , \घटिका_समकालिक_२ ;
    reg \निवेश_समकालिक_१ , \निवेश_समकालिक_२ ;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            \घटिका_समकालिक_१ <= 1'b0;
            \घटिका_समकालिक_२ <= 1'b0;
            \निवेश_समकालिक_१ <= 1'b0;
            \निवेश_समकालिक_२ <= 1'b0;
        end else begin
            \घटिका_समकालिक_१ <= \शोधन_घटिका ;
            \घटिका_समकालिक_२ <= \घटिका_समकालिक_१ ;
            \निवेश_समकालिक_१ <= \शोधन_निवेश ;
            \निवेश_समकालिक_२ <= \निवेश_समकालिक_१ ;
        end
    end

    wire \घटिका_आरोह = (\घटिका_समकालिक_१ && !\घटिका_समकालिक_२ );
    wire \घटिका_अवरोह = (!\घटिका_समकालिक_१ && \घटिका_समकालिक_२ );

    // Internal State Machine
    // Command format: 16-bit shift frame:
    // [15:14] : Command (00 = NOP, 01 = HALT/RESUME, 10 = READ_REG, 11 = READ_PC)
    // [13:11] : Core ID (0 to 5)
    // [10:7]  : Register Address / Sub-command
    // [6:0]   : Control Mask / Argument
    reg [15:0] \आदेश_पञ्जिका ;
    reg [4:0]  \गणन_अंक ;
    reg [15:0] \निर्गम_पञ्जिका ;

    // Multiplex selected register to readout bus
    reg [15:0] \शोधन_परिणाम ;
    always @(*) begin
        case (\पञ्जिका_संकेत )
            4'h0: \शोधन_परिणाम = {8'h00, \सञ्चायक_दत्त };
            4'h1: \शोधन_परिणाम = {8'h00, \सहायक_दत्त };
            4'h8: \शोधन_परिणाम = {8'h00, \ध्वज_दत्त };
            4'hE: \शोधन_परिणाम = {8'h00, \पिन्_दिश_दत्त };
            4'hF: \शोधन_परिणाम = {8'h00, \पिन्_निर्गम_दत्त };
            default: begin
                // Read general register or PC
                if (\आदेश_पञ्जिका [15:14] == 2'b11) begin
                    // Read PC: {pc_op[6:0], pc_op1[5:0], pc_op2[3:0]} -> 17 bits packed in 16
                    \शोधन_परिणाम = {\गणक_संकेत_० [5:0], \गणक_संकेत_१ [5:0], \गणक_संकेत_२ [3:0]};
                end else begin
                    \शोधन_परिणाम = {8'h00, \सामान्य_पञ्जिका };
                end
            end
        endcase
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            \विराम_संकेत     <= 6'b000000;
            \संसाधक_क्रमांक  <= 3'b000;
            \पञ्जिका_संकेत   <= 4'h0;
            \आदेश_पञ्जिका    <= 16'h0000;
            \निर्गम_पञ्जिका  <= 16'h0000;
            \गणन_अंक        <= 5'd0;
            \शोधन_निर्गम    <= 1'b0;
        end else begin
            if (\घटिका_आरोह ) begin
                // Shift in MSB first
                \आदेश_पञ्जिका <= {\आदेश_पञ्जिका [14:0], \निवेश_समकालिक_२ };
                \गणन_अंक <= \गणन_अंक + 1;

                if (\गणन_अंक == 5'd15) begin
                    \गणन_अंक <= 5'd0;
                    // Command Dispatch
                    case ({\आदेश_पञ्जिका [14:13]})
                        2'b01: begin
                            // Halt / Resume Command: [12:10] = Core ID, [6] = 1 (Halt), 0 (Resume)
                            if (\आदेश_पञ्जिका [12:10] <= 3'd5) begin
                                \विराम_संकेत [\आदेश_पञ्जिका [12:10]] <= \निवेश_समकालिक_२ ;
                            end
                            \निर्गम_पञ्जिका <= {10'h0, \विराम_संकेत };
                        end
                        2'b10: begin
                            // Read Register Command
                            \संसाधक_क्रमांक <= \आदेश_पञ्जिका [12:10];
                            \पञ्जिका_संकेत  <= \आदेश_पञ्जिका [9:6];
                            \निर्गम_पञ्जिका  <= \शोधन_परिणाम ;
                        end
                        2'b11: begin
                            // Read PC Command
                            \संसाधक_क्रमांक <= \आदेश_पञ्जिका [12:10];
                            \निर्गम_पञ्जिका  <= {\गणक_संकेत_० [5:0], \गणक_संकेत_१ [5:0], \गणक_संकेत_२ [3:0]};
                        end
                        default: begin
                            \निर्गम_पञ्जिका <= 16'hAAAA; // Echo / NOP response
                        end
                    endcase
                end
            end else if (\घटिका_अवरोह ) begin
                // Shift out on falling edge
                \शोधन_निर्गम   <= \निर्गम_पञ्जिका [15];
                \निर्गम_पञ्जिका <= {\निर्गम_पञ्जिका [14:0], 1'b0};
            end
        end
    end

endmodule
