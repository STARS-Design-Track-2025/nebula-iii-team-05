`timescale 10ms/10ns
module t05_top_tb;
    
    logic hwclk, reset, miso;
    logic [3:0] en_state;
    logic mosi, SRAM_finished;
    logic [3:0] fin_state_HG, fin_state_FLV, fin_state_HT, fin_state_CB, fin_state_TL;
    logic [7:0] read_out;
    logic [63:0] compVal, nulls;

    t05_top top (.hwclk(hwclk),
    .reset(reset),
    .mosi(mosi),
    .miso(miso),
    .en_state(en_state),
    .fin_state_HG(fin_state_HG),
    .fin_state_FLV(fin_state_FLV),
    .fin_state_HT(fin_state_HT),
    .fin_state_CB(fin_state_CB),
    .fin_state_TL(fin_state_TL),
    .read_out(read_out),
    .compVal(compVal),
    .nulls(nulls),
    .SRAM_finished(SRAM_finished)
    );

    task resetOn ();
        begin
            reset = 1;
            #10
            reset = 0;
        end
    endtask

    task readA ();
        begin
            miso = 0; 
            #6
            miso = 1;
            #6
            miso = 0;
            #33
            miso = 1;
            #6;
            miso = 0;
            #6;
        end
    endtask

    task readB ();
        begin
            miso = 0; 
            #6
            miso = 1;
            #6
            miso = 0;
            #24
            miso = 1;
            #6
            miso = 0;
            #6;
        end
    endtask

    task readC ();
        begin
            miso = 0; 
            #6
            miso = 1;
            #6
            miso = 0;
            #24
            miso = 1;
            #12;
        end
    endtask

    always begin
        #1
        hwclk = ~hwclk;
    end

    always begin
        #10000
        $finish;
    end

    initial begin
        $dumpfile("t05_top.vcd");
        $dumpvars(0, t05_top_tb);

        hwclk = 0;
        reset = 0;
        miso = 0;
        en_state = 0;
        read_out = '0;
        compVal = '0;
        resetOn();
        #100
        read_out = 8'h1A;
        //compVal = 20;

        en_state = 1;
        $display("1");
        @(posedge |fin_state_HG)
        en_state = 2;
        $display("2");
        // #100
        // compVal = 20;
        // #100
        // compVal = 40;
        @(posedge |fin_state_FLV)
        en_state = 3;
        $display("3");
        nulls = 64'd500;
        #100
        SRAM_finished = 1;
        
        while (|fin_state_HT == 0) begin
            #0.01;
        end
        //$display("fin_state_HT: %4d", fin_state_HT);
        en_state = 4;
        $display("4");        
        @(posedge |fin_state_CB)
        en_state = 5;
        $display("5");
        @(posedge |fin_state_TL)
        #100

        #1 $finish;
    end

endmodule