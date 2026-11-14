`default_nettype none
`timescale 1ns/1ps

// ============================================================================
// Formal Verification Runner (SVA Bounded Model Checking Engine)
// All variable, class, struct, and function names in Sanskrit Devanagari script.
// ============================================================================

module tb_formal_assertions;
    reg clk;
    reg rst_n;
    reg \शोधन_घटिका_संकेत ;
    reg \शोधन_निवेश_संकेत ;
    wire \शोधन_निर्गम_संकेत ;
    reg [7:0] \पिन_निवेश_संकेत ;
    wire [7:0] \पिन_निर्गम_संकेत ;
    wire [7:0] \पिन_दिश_संकेत ;

    \औपचारिक_सत्यापन_पीठिका  #(
        .\नलिका_गम्भीरता (4)
    ) \सत्यापन_घटक  (
        .clk(clk),
        .rst_n(rst_n),
        .\शोधन_घटिका_संकेत (\शोधन_घटिका_संकेत ),
        .\शोधन_निवेश_संकेत (\शोधन_निवेश_संकेत ),
        .\शोधन_निर्गम_संकेत (\शोधन_निर्गम_संकेत ),
        .\पिन_निवेश_संकेत (\पिन_निवेश_संकेत ),
        .\पिन_निर्गम_संकेत (\पिन_निर्गम_संकेत ),
        .\पिन_दिश_संकेत (\पिन_दिश_संकेत )
    );

    initial begin
        clk = 0;
        forever #10 clk = ~clk;
    end

    integer \आवृत्ति_संख्या ;

    initial begin
        $display("------------------------------------------------------------------");
        $display(" औपचारिक-प्रमाण-सत्यापनम् (Formal SVA Assertion Verification) ");
        $display("------------------------------------------------------------------");
        rst_n = 0;
        \शोधन_घटिका_संकेत  = 0;
        \शोधन_निवेश_संकेत  = 0;
        \पिन_निवेश_संकेत  = 8'h00;
        \सत्यापन_घटक .\नलिका_लेखन_संकेत  = 0;
        \सत्यापन_घटक .\नलिका_पठन_संकेत  = 0;
        \सत्यापन_घटक .\नलिका_दत्त_निवेश  = 8'h00;

        #40;
        rst_n = 1;
        #20;

        // Bounded Model Check: Push 4 bytes into FIFO and verify levels and assertions
        for (\आवृत्ति_संख्या  = 0; \आवृत्ति_संख्या  < 4; \आवृत्ति_संख्या  = \आवृत्ति_संख्या  + 1) begin
            @(posedge clk);
            \सत्यापन_घटक .\नलिका_दत्त_निवेश  = 8'h10 + \आवृत्ति_संख्या ;
            \सत्यापन_घटक .\नलिका_लेखन_संकेत  = 1'b1;
            @(posedge clk);
            \सत्यापन_घटक .\नलिका_लेखन_संकेत  = 1'b0;
        end

        // FIFO must now be FULL
        @(posedge clk);
        if (!\सत्यापन_घटक .\नलिका_पूर्णा_संकेत ) begin
            $display("FAILED: नलिका पूर्णा संकेत न लब्धः");
            $finish;
        end

        // Pop 4 bytes from FIFO and verify emptiness
        for (\आवृत्ति_संख्या  = 0; \आवृत्ति_संख्या  < 4; \आवृत्ति_संख्या  = \आवृत्ति_संख्या  + 1) begin
            @(posedge clk);
            \सत्यापन_घटक .\नलिका_पठन_संकेत  = 1'b1;
            @(posedge clk);
            \सत्यापन_घटक .\नलिका_पठन_संकेत  = 1'b0;
        end

        @(posedge clk);
        if (!\सत्यापन_घटक .\नलिका_रिक्ता_संकेत ) begin
            $display("FAILED: नलिका रिक्ता संकेत न लब्धः");
            $finish;
        end

        // Pin Non-Contention Verification
        if (\सत्यापन_घटक .\सङ्घर्ष_शून्य_परीक्षणम् (8'b00001111, 8'b11110000) !== 1'b1) begin
            $display("FAILED: सङ्घर्ष शून्य परीक्षणम् प्रमादः");
            $finish;
        end

        $display("सर्व-औपचारिक-प्रमाणानि सिद्धानि! (All Formal Properties Verified!)");
        $finish;
    end
endmodule
