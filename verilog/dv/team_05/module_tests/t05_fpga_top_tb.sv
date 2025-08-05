`timescale 1ns/100ps

module t05_fpga_top_tb;
    // Testbench signals
    logic clk, rst;
    logic [20:0] pb;
    logic [7:0] left, right, ss7, ss6, ss5, ss4, ss3, ss2, ss1, ss0;
    logic red, green, blue;
    
    // UART signals
    logic [7:0] txdata, rxdata;
    logic txclk, rxclk;
    logic txready, rxready;

    // Clock generation - 100MHz
    always begin
        clk = 1'b0;
        #5;  // 5ns
        clk = 1'b1;
        #5;  // 5ns -> 100MHz clock (10ns period)
    end

    // DUT instantiation
    top dut(
        .hz100(clk),
        .reset(rst),
        .pb(pb),
        .left(left),
        .right(right),
        .ss7(ss7),
        .ss6(ss6),
        .ss5(ss5),
        .ss4(ss4),
        .ss3(ss3),
        .ss2(ss2),
        .ss1(ss1),
        .ss0(ss0),
        .red(red),
        .green(green),
        .blue(blue),
        // UART connections
        .txdata(txdata),
        .rxdata(rxdata),
        .txclk(txclk),
        .rxclk(rxclk),
        .txready(txready),
        .rxready(rxready)
    );
    
    // VGA signals monitoring
    initial begin 
        #10000000;
        $display("TIMEOUT");
        $finish;    
    end

    // Test stimulus
    initial begin
        $dumpfile("t05_fpga_top.vcd");
        $dumpvars(0, t05_fpga_top_tb);
        
        // Initialize signals

        rst = 1'b1;           // Assert reset
        pb = 21'b0;           // Initialize pushbuttons
        #100;                 // Wait 100ns
        rst = 1'b0;           // Release reset
        #1000000000;            // Run for 10ms to see state changes
        $finish;
    end

endmodule




