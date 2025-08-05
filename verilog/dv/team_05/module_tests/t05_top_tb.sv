`timescale 1ms/1ns
module t05_top_tb;

  // I/O ports
  logic hwclk, reset;
  logic [20:0] pb;
  logic [7:0] left, right,
    ss7, ss6, ss5, ss4, ss3, ss2, ss1, ss0;
  logic red, green, blue;

  // UART ports
  logic [7:0] txdata;
  logic [7:0] rxdata;
  logic txclk, rxclk;
  logic txready, rxready;

  // Instantiate the DUT
  top dut(
    .*
  );

  // Clock generator
  initial hwclk = 0;
  always #1 hwclk = ~hwclk;

  // Test sequence
  initial begin
    $display("Starting top testbench");
    $dumpfile("t05_top.vcd");
    $dumpvars(0, t05_top_tb);
    reset = 1;
    #5
    reset = 0;
    #1000000;
    $display("Test complete. Inspect signals in waveform.");
    $finish;
  end

endmodule