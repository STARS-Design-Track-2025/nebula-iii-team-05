`timescale 1ns/1ps
module clkdiv_tb;
    // Testbench signals
    logic clk_in;
    logic rst;
    logic five_ms_clk, fifty_ms_clk, hundred_ns_clk;

    // Clock divider instance
    clkdiv uut (
        .clk_in(clk_in),
        .rst(rst),
        .five_ms_clk(five_ms_clk),
        .fifty_ms_clk(fifty_ms_clk),
        .hundred_ns_clk(hundred_ns_clk)
    );

    // Generate 1 MHz clock (1 us period)
    always begin
        #1 clk_in = ~clk_in;  // Toggle every 0.5 us to get 1 MHz clock
    end

    // Initial block for applying testbench stimuli
    initial begin
        // Initialize inputs
        $dumpfile("clkdiv.vcd"); //change the vcd vile name to your source file name
        $dumpvars(0, clkdiv_tb);
        clk_in = 0;
        rst = 0;
        
        // Apply reset
        $display("Applying reset...");
        rst = 1;
        #5;  // Reset for 5 time units (5 us for a 1 MHz clock)
        
        // Deassert reset
        $display("Releasing reset...");
        rst = 0;

        // Run the simulation for a reasonable amount of time to observe behavior
        #1000000;  // Run for 5 ms (5000000 clock cycles at 1 MHz)
        
        // End the simulation
        $finish;
    end

    // Monitor signals for debugging
    initial begin
        $monitor("Time: %0t | rst: %b | five_ms_clk: %b", $time, rst, five_ms_clk);
    end

endmodule
