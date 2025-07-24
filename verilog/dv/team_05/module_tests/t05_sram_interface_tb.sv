`timescale 1ms/1ns
module t05_sram_interface_tb;

  logic clk, rst;
  logic [31:0] histogram;
  logic [7:0] histgram_addr;
  logic hist_r_wr;
  logic [8:0] find_least;
  logic [7:0] charwipe1, charwipe2;
  logic flv_r_wr;
  logic [70:0] new_node;
  logic [6:0] htreeindex;
  logic htree_r_wr;
  logic [7:0] char_index;
  logic [6:0] curr_index;
  logic [127:0] codebook_path;
  logic [7:0] translation;
  logic [2:0] state;
  logic [31:0] sram_data_out_his;
  logic [63:0] sram_data_out_flv;
  logic [127:0] sram_data_out_trn;
  logic [70:0] sram_data_out_cb;
  logic [70:0] sram_data_out_ht;
  logic wr_en, r_en;
  logic [3:0] select;
  logic [31:0] old_char, addr, sram_data_in_hist;
  logic [63:0] sram_data_in_flv, sram_data_in_ht;
  logic [127:0] cb_path_sram, path;
  logic [63:0] comp_val;
  logic [70:0] h_element;
  logic [2:0] ctrl_done;
  logic busy_o;
  logic cb_done;
  logic ht_done;
  logic [63:0] nulls;
  // Instantiate the DUT
  t05_sram_interface dut (
    .clk(clk),
    .rst(rst),
    .busy_o(busy_o),
    .cb_done(cb_done),
    .ht_done(ht_done),
    .histogram(histogram),
    .histgram_addr(histgram_addr),
    .hist_r_wr(hist_r_wr),
    .find_least(find_least),
    .charwipe1(charwipe1),
    .charwipe2(charwipe2),
    .flv_r_wr(flv_r_wr),
    .new_node(new_node),
    .htreeindex(htreeindex),
    .htree_r_wr(htree_r_wr),
    .char_index(char_index),
    .curr_index(curr_index),
    .codebook_path(codebook_path),
    .translation(translation),
    .state(state),
    .sram_data_out_his(sram_data_out_his),
    .sram_data_out_flv(sram_data_out_flv),
    .sram_data_out_trn(sram_data_out_trn),
    .sram_data_out_cb(sram_data_out_cb),
    .sram_data_out_ht(sram_data_out_ht),
    .wr_en(wr_en),
    .r_en(r_en),
    .select(select),
    .nulls(nulls),
    .old_char(old_char),
    .addr(addr),
    .sram_data_in_flv(sram_data_in_flv),
    .sram_data_in_hist(sram_data_in_hist),
    .sram_data_in_ht(sram_data_in_ht),
    .comp_val(comp_val),
    .h_element(h_element),
    .cb_path_sram(cb_path_sram),
    .path(path),
    .ctrl_done(ctrl_done)
  );

  // Clock generator
  initial clk = 0;
  always #1 clk = ~clk;

  // Test sequence
  initial begin
    $display("Starting t05_sram_interface testbench");
    $dumpfile("t05_sram_interface.vcd");
    $dumpvars(0, t05_sram_interface_tb);

    // Initialize
    rst = 1;
    histogram = 32'b0;
    histgram_addr = 8'd0;
    find_least = 9'd0;
    new_node = 71'b0;
    htreeindex = 7'd0;
    char_index = 8'd0;
    codebook_path = 128'b0;
    translation = 8'd0;
    state = 3'b000; // HIST state
    sram_data_out_his = 32'b0;
    sram_data_out_flv = 64'b0;
    sram_data_out_trn = 128'b0;
    sram_data_out_cb = 71'b0;
    sram_data_out_ht = 71'b0;

    #1 rst = 0;  //testing the rst, everything back to 0

    // Histogram write test
    state = 3'd1;
    hist_r_wr = 1; // write mode
    histgram_addr = 8'd10;
    histogram = 32'd7;
    #5;
    rst = 1;
    #1;
    rst = 0;
    #5;
    // FLV write test
    state = 3'b010;
    flv_r_wr = 1;
    charwipe1 = 8'd23;
    #5;
    rst = 1;
    #1;
    rst = 0;
    #5;
    state = 3'b010;
    flv_r_wr =1;
    charwipe2 = 8'd23;
    #5;
    rst = 1;
    #1;
    rst = 0;
    #5;
    //htree write
    state = 3'd3;
    htree_r_wr = 1;
    new_node[6:0] = 7'd42;
    new_node[70:7] = 64'd695;
    htreeindex = 7'd14;
    #5;
    rst = 1;
    #1;
    rst = 0;
    #5;
    //codebook write
    state = 3'd5;
    char_index = 8'd33;
    codebook_path = 128'd62597;
    #5;
    rst = 1;
    #1;
    rst = 0;
    #5;

  //hist read
    state = 3'd1;
    hist_r_wr = 0; // switch to read
    histgram_addr = 8'd10; //should output the same vaule that was inputted before "10"
    sram_data_out_his = 32'd14;
    #5;
    rst = 1;
    #1;
    rst = 0;
    #5;
  //flv read
    state = 3'd2;
    flv_r_wr = 0;
    find_least = 249;
    sram_data_out_flv = 64'd514;
    #5;
    rst = 1;
    #1;
    rst = 0;
    #5;
    state = 3'd2;
    flv_r_wr = 0;
    find_least = 279;
    sram_data_out_flv = 64'd714;
    #5;
    rst = 1;
    #1;
    rst = 0;
    #5;

    //htree read
    state = 3'b011;
    htree_r_wr = 0; // read mode
    htreeindex = 7'd11;
    sram_data_out_ht = 71'd971;
    #5;
    rst = 1;
    #1;
    rst = 0;
    #5;

    // Codebook test
    state = 3'b101;
    curr_index = 7'd9;
    codebook_path = 128'd122;
    sram_data_out_cb = 71'd625;
    #5;
    rst = 1;
    #1;
    rst = 0;
    #5;
  // Translation read test
    state = 3'b110;
    translation = 8'd44;
    sram_data_out_trn = 77;
    #5;
    rst = 1;
    #1;
    rst = 0;
    #5;


    $display("Test complete. Inspect signals in waveform.");
    $finish;
  end

endmodule
