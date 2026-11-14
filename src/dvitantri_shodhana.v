`default_nettype none
`timescale 1ns/1ps

// ============================================================================
// dvitantri_shodhana (Two-Wire Debug Controller)
// Host Debugger (RP2040) controls execution, halts cores, and inspects registers
// ============================================================================

module dvitantri_shodhana (
    input  wire        clk,
    input  wire        rst_n,

    // Physical Debug Pins
    input  wire        shodhana_ghatika,   // Debug Serial Clock (dbg_sclk)
    input  wire        shodhana_nivesha,   // Debug Serial Data In (dbg_mosi/din)
    output reg         shodhana_nirgama,   // Debug Serial Data Out (dbg_miso/dout)

    // Halt control to 6 cores
    output reg  [5:0]  virama_sanketa,     // dbg_halt to core 0..5

    // Core select & Register readout multiplexer
    output reg  [2:0]  sansadhaka_kramanka,// Target Core ID (0..5)
    output reg  [3:0]  panjika_sanketa,    // Target Register Address (0..15)
    
    // Core Readout Data Inputs from Cores (Direct inspection bus)
    input  wire [7:0]  sanchayaka_datta,   // ACC data
    input  wire [7:0]  sahayaka_datta,     // B reg data
    input  wire [7:0]  dhvaja_datta,       // STATUS_FLAGS data
    input  wire [6:0]  ganaka_sanketa_0,   // PC_OP (7-bit)
    input  wire [5:0]  ganaka_sanketa_1,   // PC_OP1 (6-bit)
    input  wire [3:0]  ganaka_sanketa_2,   // PC_OP2 (4-bit)
    input  wire [7:0]  samanya_panjika,    // General register R[addr]
    input  wire [7:0]  pin_disha_datta,    // Pin direction register (pin_dir)
    input  wire [7:0]  pin_nirgama_datta   // Pin output register (pin_out)
);

    // Synchronizers for debug clock & data
    reg ghatika_samakalika_1, ghatika_samakalika_2;
    reg nivesha_samakalika_1, nivesha_samakalika_2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ghatika_samakalika_1 <= 1'b0;
            ghatika_samakalika_2 <= 1'b0;
            nivesha_samakalika_1 <= 1'b0;
            nivesha_samakalika_2 <= 1'b0;
        end else begin
            ghatika_samakalika_1 <= shodhana_ghatika;
            ghatika_samakalika_2 <= ghatika_samakalika_1;
            nivesha_samakalika_1 <= shodhana_nivesha;
            nivesha_samakalika_2 <= nivesha_samakalika_1;
        end
    end

    wire ghatika_aroha  = (ghatika_samakalika_1 && !ghatika_samakalika_2);
    wire ghatika_avaroha = (!ghatika_samakalika_1 && ghatika_samakalika_2);

    // Internal State Machine
    // Command format: 16-bit shift frame:
    // [15:14] : Command (00 = NOP, 01 = HALT/RESUME, 10 = READ_REG, 11 = READ_PC)
    // [13:11] : Core ID (0 to 5)
    // [10:7]  : Register Address / Sub-command
    // [6:0]   : Control Mask / Argument
    reg [15:0] adesha_panjika;
    reg [4:0]  ganana_anka;
    reg [15:0] nirgama_panjika;

    // Multiplex selected register to readout bus
    reg [15:0] shodhana_parinama;
    always @(*) begin
        case (panjika_sanketa)
            4'h0: shodhana_parinama = {8'h00, sanchayaka_datta};
            4'h1: shodhana_parinama = {8'h00, sahayaka_datta};
            4'h8: shodhana_parinama = {8'h00, dhvaja_datta};
            4'hE: shodhana_parinama = {8'h00, pin_disha_datta};
            4'hF: shodhana_parinama = {8'h00, pin_nirgama_datta};
            default: begin
                // Read general register or PC
                if (adesha_panjika[15:14] == 2'b11) begin
                    // Read PC: {pc_op[6:0], pc_op1[5:0], pc_op2[3:0]} -> 17 bits packed in 16
                    shodhana_parinama = {ganaka_sanketa_0[5:0], ganaka_sanketa_1[5:0], ganaka_sanketa_2[3:0]};
                end else begin
                    shodhana_parinama = {8'h00, samanya_panjika};
                end
            end
        endcase
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            virama_sanketa      <= 6'b000000;
            sansadhaka_kramanka <= 3'b000;
            panjika_sanketa    <= 4'h0;
            adesha_panjika     <= 16'h0000;
            nirgama_panjika    <= 16'h0000;
            ganana_anka        <= 5'd0;
            shodhana_nirgama   <= 1'b0;
        end else begin
            if (ghatika_aroha) begin
                // Shift in MSB first
                adesha_panjika <= {adesha_panjika[14:0], nivesha_samakalika_2};
                ganana_anka <= ganana_anka + 1;

                if (ganana_anka == 5'd15) begin
                    ganana_anka <= 5'd0;
                    // Command Dispatch
                    case ({adesha_panjika[14:13]})
                        2'b01: begin
                            // Halt / Resume Command: [12:10] = Core ID, [6] = 1 (Halt), 0 (Resume)
                            if (adesha_panjika[12:10] <= 3'd5) begin
                                virama_sanketa[adesha_panjika[12:10]] <= nivesha_samakalika_2;
                            end
                            nirgama_panjika <= {10'h0, virama_sanketa};
                        end
                        2'b10: begin
                            // Read Register Command
                            sansadhaka_kramanka <= adesha_panjika[12:10];
                            panjika_sanketa     <= adesha_panjika[9:6];
                            nirgama_panjika     <= shodhana_parinama;
                        end
                        2'b11: begin
                            // Read PC Command
                            sansadhaka_kramanka <= adesha_panjika[12:10];
                            nirgama_panjika     <= {ganaka_sanketa_0[5:0], ganaka_sanketa_1[5:0], ganaka_sanketa_2[3:0]};
                        end
                        default: begin
                            nirgama_panjika <= 16'hAAAA; // Echo / NOP response
                        end
                    endcase
                end
            end else if (ghatika_avaroha) begin
                // Shift out on falling edge
                shodhana_nirgama <= nirgama_panjika[15];
                nirgama_panjika  <= {nirgama_panjika[14:0], 1'b0};
            end
        end
    end

endmodule
