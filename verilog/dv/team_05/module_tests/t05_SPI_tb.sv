`timescale 1ms/10ns
module t05_SPI_tb; 
    logic clk;
    logic rst;
    logic miso;
    logic mosi;
    logic [7:0] read_output;
    logic writebit;
    logic read_en, write_en;
    logic slave_select;
    logic finish;
    logic serialclk;
    logic read_stop;
    logic write_stop;
    logic reading;
    logic freq_flag;
    logic nextCharEn;

    // Instantiate the SPI module
    t05_SPI test(
        .clk(clk),
        .rst(rst),
        .serial_clk(serialclk),
        .miso(miso),
        .mosi(mosi),
        .read_output(read_output),
        .writebit(writebit),
        .read_en(read_en),
        .write_en(write_en),
        .write_stop(write_stop),
        .read_stop(read_stop),
        .nextCharEn(nextCharEn),
        .reading(reading),
        .slave_select(slave_select),
        .freq_flag(freq_flag),
        .finish(finish)
    );

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
        write_stop = 0;
        read_stop = 0;
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
        write_en = 1;
                
        // Test for READ state
        #500
        write_en = 0;
        miso = 1; 
        #10
        miso = 0;
        #10
        miso = 1; 
        #10
        miso = 0;
        #40
        //read_en = 1;
        #10
        //read_en = 0;
        #10
        #1000
        write_stop = 1;
        #10 
        write_stop = 0;
        #100000
        rst = 1;
        #10 
        rst = 0;
        #10
        write_en = 1;
        #10
        write_en = 0;
        #10

        read_stop = 1;
        #500


         // Test for WRITE state
        write_en = 1;
        #540
        writebit = 0;
        #10
        writebit = 1;
        #10
        writebit = 0;
        #10
        write_en = 0;
        #100

        #1000 $finish; // End simulation
    end
endmodule