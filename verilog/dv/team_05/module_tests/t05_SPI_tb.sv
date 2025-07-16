`timescale 1ms/10ns
module t05_SPI_tb; 
    logic clk;
    logic rst;
    logic miso;
    logic [7:0] read_output;
    logic writebit;
    logic read_en, write_en;
    logic slave_select;
    logic finish;
    logic serialclk;

    // Instantiate the SPI module
    t05_SPI test(.clk(clk),
                 .rst(rst),
                 .miso(miso),
                 .read_output(read_output),
                 .writebit(writebit),
                 .read_en(read_en),
                 .write_en(write_en),
                 .slave_select(slave_select),
                 .finish(finish),
                 .serial_clk(serialclk));

    // Clock generation
    always begin
        #1 clk = ~clk; // 1ms clock period
    end

    always begin
        #8 serialclk = 1;
        #2 serialclk = 0;
    end

    // Testbench initial block
    initial begin
        $dumpfile("t05_SPI.vcd");
        $dumpvars(0, t05_SPI_tb);

        clk = 0;
        serialclk = 0;
        miso = 0;
        serialclk = 0;
        writebit = 0;
        read_en = 0;
        write_en = 0;
        rst = 1; // Start with reset high
        #2 
        rst = 0; // Release reset after 2ms

        // Test sequence
        read_en = 0;
        write_en = 0;
        writebit = 0;

        #300
        #1032
        miso = 1;
        #8
        miso = 0;

        #912
        miso = 1;
        #8
        miso = 0;
        #242
        miso = 1;
        #20
        miso = 0;
        #10
        miso = 1;
        #8
        miso = 0;  
        #10
        miso = 1;
        #8
        miso = 0;
        #10
        miso = 1;
        #10
        miso = 0;

        #5000; // Run for 5ms

        $finish; // End simulation
    end
endmodule