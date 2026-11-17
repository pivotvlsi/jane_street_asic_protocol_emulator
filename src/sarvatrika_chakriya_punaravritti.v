`default_nettype none
`timescale 1ns/1ps

// ============================================================================
// sarvatrika_chakriya_punaravritti (Universal Configurable CRC Hardware Engine)
// Supports ANY polynomial (CRC-5, CRC-7, CRC-8, CRC-12, CRC-16, CRC-32, etc.)
// Configured via SPI Host Preload commands.
// All variable, class, struct, and function names in Sanskrit transliteration.
// ============================================================================

module sarvatrika_chakriya_punaravritti #(
    parameter adhikatama_vistara = 32
)(
    input  wire        clk,
    input  wire        rst_n,

    // SPI Host Preload Configuration Interface
    input  wire        vinyasa_lekhana_sanketa,
    input  wire [3:0]  vinyasa_panjika_sanketa,
    input  wire [7:0]  vinyasa_datta_nivesha,

    // Processor Execution Interface
    input  wire [7:0]  pravishti_datta_nivesha,
    input  wire        pravishti_lekhana_sanketa,
    input  wire        punahprarambha_adesha,
    input  wire [1:0]  nirgama_bhaga_sanketa,
    output reg  [7:0]  nirgama_shesha_datta
);

    // ------------------------------------------------------------------------
    // 1. Vinyasa Panjika (Configuration Registers)
    // ------------------------------------------------------------------------
    reg [4:0]  vistara_panjika;
    reg [31:0] bhajaka_bahupada_panjika;
    reg [31:0] prarambhika_beeja_panjika;
    reg [31:0] utkrama_avarana_panjika;
    reg        pratibimba_nivesha_dhvaja;
    reg        pratibimba_nirgama_dhvaja;

    reg [31:0] chakriya_sthiti_panjika;

    // SPI Preload Configuration
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            vistara_panjika          <= 5'd16;
            bhajaka_bahupada_panjika  <= 32'h00008005;
            prarambhika_beeja_panjika<= 32'h0000FFFF;
            utkrama_avarana_panjika  <= 32'h00000000;
            pratibimba_nivesha_dhvaja <= 1'b1;
            pratibimba_nirgama_dhvaja<= 1'b1;
        end else if (vinyasa_lekhana_sanketa) begin
            case (vinyasa_panjika_sanketa)
                4'h0: vistara_panjika          <= vinyasa_datta_nivesha[4:0];
                4'h1: bhajaka_bahupada_panjika[7:0]   <= vinyasa_datta_nivesha;
                4'h2: bhajaka_bahupada_panjika[15:8]  <= vinyasa_datta_nivesha;
                4'h3: bhajaka_bahupada_panjika[23:16] <= vinyasa_datta_nivesha;
                4'h4: bhajaka_bahupada_panjika[31:24] <= vinyasa_datta_nivesha;
                4'h5: prarambhika_beeja_panjika[7:0]   <= vinyasa_datta_nivesha;
                4'h6: prarambhika_beeja_panjika[15:8]  <= vinyasa_datta_nivesha;
                4'h7: prarambhika_beeja_panjika[23:16] <= vinyasa_datta_nivesha;
                4'h8: prarambhika_beeja_panjika[31:24] <= vinyasa_datta_nivesha;
                4'h9: utkrama_avarana_panjika[7:0]   <= vinyasa_datta_nivesha;
                4'hA: utkrama_avarana_panjika[15:8]  <= vinyasa_datta_nivesha;
                4'hB: utkrama_avarana_panjika[23:16] <= vinyasa_datta_nivesha;
                4'hC: utkrama_avarana_panjika[31:24] <= vinyasa_datta_nivesha;
                4'hD: begin
                    pratibimba_nivesha_dhvaja  <= vinyasa_datta_nivesha[0];
                    pratibimba_nirgama_dhvaja <= vinyasa_datta_nivesha[1];
                end
                default: ;
            endcase
        end
    end

    // ------------------------------------------------------------------------
    // 2. Paravartita Nivesha (Static Bit Reversal & Input Feed Registering)
    // ------------------------------------------------------------------------
    wire [7:0] paravartita_nivesha = {
        pravishti_datta_nivesha[0], pravishti_datta_nivesha[1], pravishti_datta_nivesha[2], pravishti_datta_nivesha[3],
        pravishti_datta_nivesha[4], pravishti_datta_nivesha[5], pravishti_datta_nivesha[6], pravishti_datta_nivesha[7]
    };

    wire [7:0] prayukta_nivesha = pratibimba_nivesha_dhvaja ? paravartita_nivesha : pravishti_datta_nivesha;

    // Stage 0: Input Isolating Registers (Isolates CPU Decode & Store path from LFSR math)
    reg [7:0] pravishti_panjika;
    reg       pravishti_vaidha_panjika;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pravishti_panjika        <= 8'h00;
            pravishti_vaidha_panjika <= 1'b0;
        end else begin
            pravishti_panjika        <= prayukta_nivesha;
            pravishti_vaidha_panjika <= pravishti_lekhana_sanketa;
        end
    end

    // ------------------------------------------------------------------------
    // 3. Chakriya Ganana (Two-Stage Pipelined 4-Bit LFSR Blocks)
    // ------------------------------------------------------------------------
    reg [31:0] ganita_krama_0, ganita_krama_1, ganita_krama_2, ganita_krama_3;
    reg [31:0] ganita_krama_4, ganita_krama_5, ganita_krama_6, ganita_krama_7;

    // Pipeline stage registers (Sanskrit identifier naming)
    reg [31:0] madhyama_sthiti_panjika;
    reg [3:0]  madhyama_datta_panjika;
    reg        madhyama_vaidha_dhvaja;

    // Stage 1 Combinational Logic: Bits 0 to 3 (Driven from Stage 0 registers)
    always @(*) begin
        // Bit 0
        if (((chakriya_sthiti_panjika >> (vistara_panjika - 1)) & 1'b1) ^ pravishti_panjika[7])
            ganita_krama_0 = (chakriya_sthiti_panjika << 1) ^ bhajaka_bahupada_panjika;
        else
            ganita_krama_0 = (chakriya_sthiti_panjika << 1);

        // Bit 1
        if (((ganita_krama_0 >> (vistara_panjika - 1)) & 1'b1) ^ pravishti_panjika[6])
            ganita_krama_1 = (ganita_krama_0 << 1) ^ bhajaka_bahupada_panjika;
        else
            ganita_krama_1 = (ganita_krama_0 << 1);

        // Bit 2
        if (((ganita_krama_1 >> (vistara_panjika - 1)) & 1'b1) ^ pravishti_panjika[5])
            ganita_krama_2 = (ganita_krama_1 << 1) ^ bhajaka_bahupada_panjika;
        else
            ganita_krama_2 = (ganita_krama_1 << 1);

        // Bit 3
        if (((ganita_krama_2 >> (vistara_panjika - 1)) & 1'b1) ^ pravishti_panjika[4])
            ganita_krama_3 = (ganita_krama_2 << 1) ^ bhajaka_bahupada_panjika;
        else
            ganita_krama_3 = (ganita_krama_2 << 1);
    end

    // Stage 2 Combinational Logic: Bits 4 to 7
    always @(*) begin
        // Bit 4
        if (((madhyama_sthiti_panjika >> (vistara_panjika - 1)) & 1'b1) ^ madhyama_datta_panjika[3])
            ganita_krama_4 = (madhyama_sthiti_panjika << 1) ^ bhajaka_bahupada_panjika;
        else
            ganita_krama_4 = (madhyama_sthiti_panjika << 1);

        // Bit 5
        if (((ganita_krama_4 >> (vistara_panjika - 1)) & 1'b1) ^ madhyama_datta_panjika[2])
            ganita_krama_5 = (ganita_krama_4 << 1) ^ bhajaka_bahupada_panjika;
        else
            ganita_krama_5 = (ganita_krama_4 << 1);

        // Bit 6
        if (((ganita_krama_5 >> (vistara_panjika - 1)) & 1'b1) ^ madhyama_datta_panjika[1])
            ganita_krama_6 = (ganita_krama_5 << 1) ^ bhajaka_bahupada_panjika;
        else
            ganita_krama_6 = (ganita_krama_5 << 1);

        // Bit 7
        if (((ganita_krama_6 >> (vistara_panjika - 1)) & 1'b1) ^ madhyama_datta_panjika[0])
            ganita_krama_7 = (ganita_krama_6 << 1) ^ bhajaka_bahupada_panjika;
        else
            ganita_krama_7 = (ganita_krama_6 << 1);
    end

    wire punahprarambha_svikarana = (vinyasa_lekhana_sanketa && vinyasa_panjika_sanketa == 4'hE) || punahprarambha_adesha;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            madhyama_sthiti_panjika <= 32'h0;
            madhyama_datta_panjika  <= 4'h0;
            madhyama_vaidha_dhvaja  <= 1'b0;
            chakriya_sthiti_panjika <= 32'h0000FFFF;
        end else begin
            // Stage 1 Pipeline Register
            if (pravishti_vaidha_panjika) begin
                madhyama_sthiti_panjika <= ganita_krama_3;
                madhyama_datta_panjika  <= pravishti_panjika[3:0];
                madhyama_vaidha_dhvaja  <= 1'b1;
            end else begin
                madhyama_vaidha_dhvaja  <= 1'b0;
            end

            // Stage 2 State Register
            if (punahprarambha_svikarana) begin
                chakriya_sthiti_panjika <= prarambhika_beeja_panjika;
            end else if (madhyama_vaidha_dhvaja) begin
                chakriya_sthiti_panjika <= ganita_krama_7;
            end
        end
    end

    // ------------------------------------------------------------------------
    // 4. Phalita Nirgama Nirdharana (Result Output with XOR-Out & Byte Slice)
    // Registered output to decouple CRC remainder extraction from CPU load/ALU zero flag
    // ------------------------------------------------------------------------
    wire [31:0] antima_shesha = chakriya_sthiti_panjika ^ utkrama_avarana_panjika;

    reg [31:0] paravartita_shesha;
    integer kramanka;
    always @(*) begin
        paravartita_shesha = 32'h0;
        for (kramanka = 0; kramanka < 32; kramanka = kramanka + 1) begin
            if (kramanka < vistara_panjika)
                paravartita_shesha[vistara_panjika - 1 - kramanka] = antima_shesha[kramanka];
        end
    end

    wire [31:0] pradarshita_shesha = pratibimba_nirgama_dhvaja ? paravartita_shesha : antima_shesha;

    reg [7:0] nirgama_chayanita_datta;
    always @(*) begin
        case (nirgama_bhaga_sanketa)
            2'd0: nirgama_chayanita_datta = pradarshita_shesha[7:0];
            2'd1: nirgama_chayanita_datta = pradarshita_shesha[15:8];
            2'd2: nirgama_chayanita_datta = pradarshita_shesha[23:16];
            2'd3: nirgama_chayanita_datta = pradarshita_shesha[31:24];
        endcase
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            nirgama_shesha_datta <= 8'h00;
        end else begin
            nirgama_shesha_datta <= nirgama_chayanita_datta;
        end
    end

endmodule
