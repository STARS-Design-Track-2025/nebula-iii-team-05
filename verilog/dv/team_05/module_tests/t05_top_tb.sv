`timescale 10ms/1ns
module t05_top_tb;
    
    logic hwclk, reset, mosi, miso;
    logic [3:0] en_state;

    t05_top top (.hwclk(hwclk), .reset(reset), .en_state(en_state), .mosi(mosi), .miso(miso));

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

    initial begin
        $dumpfile("t05_top.vcd");
        $dumpvars(0, t05_top_tb);

        hwclk = 0;
        reset = 0;
        miso = 0;
        en_state = 0;

        resetOn();

        en_state = 0;
        #750000;
        en_state = 5;
        #10024
        readA();
        #100000



        #1 $finish;
    end

endmodule