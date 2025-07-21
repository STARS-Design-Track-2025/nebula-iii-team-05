`timescale 1ms/10ns 
module t05_spiClockDivider_tb;
    logic current_clock_signal;
    logic reset;
    logic divided_clock_signal;

    // Instantiate the SPI Clock Divider module
    t05_spiClockDivider test(.current_clock_signal(current_clock_signal),
                         .reset(reset),
                         .divided_clock_signal(divided_clock_signal));  

    always begin
        #1
        current_clock_signal = ~current_clock_signal;
    end

    // 12MHz clock
    initial begin
        $dumpfile("t05_spiClockDivider.vcd");
        $dumpvars(0, t05_spiClockDivider_tb);

        current_clock_signal = 0;
         #1 
        
        reset = 1;
        #2 // 200ns reset duration;
        reset = 0;
        
        #1500 // Run for 50us
        $finish;
    end
endmodule