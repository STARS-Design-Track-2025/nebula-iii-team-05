`timescale 1ms/1ns
module t05_bytecount_tb;
logic clk, en, nrst;
logic pulse; //pulse to indicate new input
logic [6:0] in;
logic [7:0] out;
logic out_valid;
logic [2:0] leftover_count;
logic [6:0] leftover_data;
  t05_bytecount dut (
    .*
  );
  always begin
    #1;
    clk = ~clk;
  end
  int seed = 32'hABCDEF;
  initial begin
    // make sure to dump the signals so we can see them in the waveform
    $dumpfile("t05_bytecount.vcd"); //change the vcd vile name to your source file name
    $dumpvars(0, t05_bytecount_tb);
    en = 1;
    clk = 0;
    pulse = 0;
    nrst = 0;
    #5;
    nrst = 1;
    for (int i = 0; i < 32; i ++) begin
        in = $random(seed) % 128;
        @(negedge clk);
        pulse = 1;
        @(negedge clk);
        pulse = 0;
    end

    // finish the simulation
    #1 $finish;
  end
endmodule