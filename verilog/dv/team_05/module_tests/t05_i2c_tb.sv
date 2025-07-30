`timescale 1ns/10ps
module t05_i2c_tb;

logic clk;
logic rst;
logic sda_i;
logic [1:0] effect;
logic [5:0] lcdData;
logic sda_o;
logic scl;
logic oeb;
logic trans; // input
logic [2:0] state; // Output
logic commsError; // Output
logic ready; // Output

// Instantiation of the i2c module
t05_i2c ben_tolu (
.clk(clk),
.rst(rst),
.sda_i(sda_i),
.trans(trans),
.lcdData(lcdData),
.sda_o(sda_o),
.scl(scl),
.oeb(oeb),
.state(state),
.commsError(commsError),
.ready(ready)
);


initial clk = 0;
always #12.5 clk = ~clk;

initial begin
    // Waveform Dumping
    $dumpfile("t05_i2c.vcd");
    $dumpvars(0, t05_i2c_tb);

    rst = 1;
    sda_i = 0;
    lcdData = 0;
    trans = 1;

    //effect would be 0,1,2, or 3
    //lcdData would be random 8 bit values
    //sda_i would be 1 or zero depending on whether we are receiveing acknowledge signal or not

    #50
    repeat(1024) @(posedge clk);
    rst = 0;
    sda_i = 1;
    lcdData = 0;

    repeat(1024*160) @(posedge clk);
    #50
    rst = 0;
    sda_i = 0;
    lcdData = 34;

    repeat(1024*160) @(posedge clk);
    #50
    rst = 0;
    sda_i = 1;
    lcdData = 63;

    repeat(1024*160) @(posedge clk);
    #50
    rst = 1;
    sda_i = 1;
    lcdData = 34;

    repeat(1024) @(posedge clk);
    #50
    rst = 0;
    sda_i = 1;
    lcdData = 34;

    #50
    repeat(1024*160) @(posedge clk);
    #50
    rst = 0;
    sda_i = 1;
    trans = 0;
    lcdData = 63;
    repeat(1024*160) @(posedge clk);
    
    #50
    rst = 0;
    #20
    $finish;



end
endmodule
// credits for this goes to Ben Sisk