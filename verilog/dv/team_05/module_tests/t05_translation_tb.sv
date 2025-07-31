`timescale 1ms/10ns
module t05_translation_tb;
    logic clk, rst, writeBin, nextCharEn, writeEn, fin_state;
    logic [31:0] totChar;
    logic [7:0] charIn;
    logic [127:0] path;
    logic [3:0] en_state;
    

    t05_translation test (.clk(clk), .rst(rst), .en_state(en_state), .totChar(totChar), .charIn(charIn), .writeBin(writeBin), .path(path), .nextCharEn(nextCharEn), .writeEn(writeEn), .fin_state(fin_state));

    always begin
        #1
        clk = ~clk;
    end

    initial begin
        $dumpfile("t05_translation.vcd");
        $dumpvars(0, t05_translation_tb);

        clk = 0;
        rst = 0;
        totChar = '0;
        path = '0;
        charIn = '0;
        en_state = 0;
        totChar = 32'd35;
        #8

        rst = 1;
        #8
        rst = 0;
        en_state = 5;
        #62
        
        charIn = 65;
        path = 128'b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010000000000000000001010;
        #259
        charIn = 66;
        path = 128'b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010000110000010001011;
        #100
        rst = 1;
        #158
        rst = 0;
        #62
        charIn = 70;
        path = 128'b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000;
        #258
        charIn = 75;
        path = 128'b11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111;
        #258
        charIn = 80;
        path = 128'b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001010;
        #258
        charIn = 8'b00011010;
        path = 128'd0;
        #100

        #4 $finish;
    end
endmodule