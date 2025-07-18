`timescale 1ms/10ns
module t05_translation_tb;
    logic clk, rst, writeBin;
    logic [31:0] totChar;
    logic [7:0] charIn;
    logic [127:0] path;

    t05_translation test (.clk(clk), .rst(rst), .totChar(totChar), .charIn(charIn), .writeBin(writeBin), .path(path));

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
        #8

        rst = 1;
        #8
        rst = 0;
        #62
        
        totChar = 32'd4;
        charIn = 65;
        path = 128'b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001010;
        #256
        charIn = 66;
        path = 128'b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001011;
        #256
        charIn = 65;
        path = 128'b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001010;
        #256
        #100

        #4 $finish;
    end
endmodule