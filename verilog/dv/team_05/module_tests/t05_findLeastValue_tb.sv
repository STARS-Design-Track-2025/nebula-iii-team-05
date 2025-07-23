`timescale 1ms/10ns
module t05_findLeastValue_tb;
    logic clk, rst;
    logic [3:0] en_state, fin_state;
    logic [7:0] charWipe1, charWipe2;
    logic [8:0] least1, least2, histo_index;
    logic [63:0] compVal, sum;

    t05_findLeastValue test (.clk(clk), .rst(rst), .en_state(en_state), .fin_state(fin_state), .charWipe1(charWipe1), .charWipe2(charWipe2), .least1(least1), .least2(least2), .histo_index(histo_index), .compVal(compVal), .sum(sum));

    always begin
        #1
        clk = ~clk;
    end

    initial begin
        $dumpfile("t05_findLeastValue.vcd");
        $dumpvars(0, t05_findLeastValue_tb);

        clk = 0;
        rst = 0;
        en_state = 0;
        compVal = 0;
        #8

        rst = 1;
        #8
        rst = 0;
        #8
        
        en_state = 2;
        compVal = 500;
        #2
        compVal = 800;
        #2
        compVal = 1000;
        #66
        compVal = 0;
        #10
        compVal = 400;
        #50
        rst = 1;
        #50
        rst = 0;
        compVal = 400;
        #2 
        compVal = 300;
        #500
        compVal = 50;
        #2
        compVal = 30;
        #2
        compVal = 40;
        #2
        compVal = 20;
        #200

        rst = 1;
        #40
        rst = 0;

        compVal = 0;
        #10
        compVal = 0;
        #10
        #700

        rst = 1;
        #40
        rst = 0;

        #40 
        compVal = 100;
        #2
        compVal = 0;
        #750

        rst = 1;
        #40
        rst = 0;

        #600
        compVal = 100;
        #2
        compVal = 0;
        #400

        #4 $finish;
    end
endmodule