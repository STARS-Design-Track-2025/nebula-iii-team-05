`timescale 1ns / 1ps

module t05_sram_interface_tb;

  // Clock and reset
  logic clk, rst;

  // Inputs
  logic [31:0] histogram;
  logic [7:0] histgram_addr;
  logic hist_r_wr;

  logic [8:0] find_least;
  logic [7:0] charwipe1, charwipe2;
  logic flv_r_wr;

  logic [70:0] new_node;
  logic [6:0] htreeindex;
  logic htree_r_wr;

  logic [6:0] curr_index;
  logic [7:0] char_index;
  logic [127:0] codebook_path;

  logic [7:0] translation;
  logic [2:0] state;

  logic [31:0] sram_data_out_his;
  logic [63:0] sram_data_out_flv;
  logic [127:0] sram_data_out_trn;
  logic [70:0] sram_data_out_cb;
  logic [70:0] sram_data_out_ht;

  // Outputs
  logic wr_en, r_en, busy_o;
  logic [3:0] select;
  logic [31:0] addr;
  logic [63:0] sram_data_in_ht, nulls;
  logic [31:0] sram_data_in_hist, old_char;
  logic [63:0] comp_val, sram_data_in_flv;
  logic [70:0] h_element;
  logic [127:0] cb_path_sram, path;

  // Instantiate DUT
  t05_sram_interface dut (
    .clk(clk), .rst(rst),
    .histogram(histogram), .histgram_addr(histgram_addr), .hist_r_wr(hist_r_wr),
    .find_least(find_least), .charwipe1(charwipe1), .charwipe2(charwipe2), .flv_r_wr(flv_r_wr),
    .new_node(new_node), .htreeindex(htreeindex), .htree_r_wr(htree_r_wr),
    .curr_index(curr_index), .char_index(char_index), .codebook_path(codebook_path),
    .translation(translation), .state(state),
    .sram_data_out_his(sram_data_out_his), .sram_data_out_flv(sram_data_out_flv),
    .sram_data_out_trn(sram_data_out_trn), .sram_data_out_cb(sram_data_out_cb),
    .sram_data_out_ht(sram_data_out_ht),
    .wr_en(wr_en), .r_en(r_en), .busy_o(busy_o), .select(select), .addr(addr),
    .sram_data_in_ht(sram_data_in_ht), .nulls(nulls),
    .sram_data_in_hist(sram_data_in_hist), .old_char(old_char),
    .comp_val(comp_val), .sram_data_in_flv(sram_data_in_flv),
    .h_element(h_element), .cb_path_sram(cb_path_sram), .path(path)
  );

  // Clock generation
  always #1 clk = ~clk;

  // SRAM simulation variables
  logic [31:0] fake_sram_hist [0:255];  // simple histogram memory

  initial begin
    $dumpfile("t05_sram_interface.vcd");
    $dumpvars(0, t05_sram_interface_tb);
    // Initialize signals
    clk = 0;
    rst = 1;

    // Inputs
    histogram = 32'd0;
    histgram_addr = 8'd0;
    hist_r_wr = 1'b1; // write mode

    sram_data_out_his = 32'b0;
    find_least = 0;
    charwipe1 = 0; 
    charwipe2 = 0;
    flv_r_wr = 0;
    new_node = 0;
    htreeindex = 0;
    htree_r_wr = 0;
    curr_index = 0;
    char_index = 0;
    codebook_path = 0;
    translation = 0;
    state = 3'b000; // HIST

    // Hold reset
    #10 rst = 0;
//WRITING STAGE
    // --- HIST WRITE ---
    $display("Writing to histogram SRAM...");
    hist_r_wr = 1; // write
    state = 3'b001; // HIST
    histogram_addr = 8'd3;
    histogram = 32'd17;
    #10;
    rst = 1;
    #2;
    rst = 0;
    //FLV WRITE
    state = 3'd2;
    flv_r_wr = 1;
    charwipe1 = 8'd3;
    charwipe2 = 8'd42;
    #10;
    rst = 1;
    #2;
    rst =0;

    //HTREE WRITE
    htree_r_wr = 1;
    state = 3'd3;
    new_node[6:0] = 33;
    new_node[70:7] = 249;
    #10;
    rst = 1;
    #2;
    rst =0;
    //CODEBOOK WRITE
    state = 3'd5;
    char_index = 11;
    codebook_path = 128'd345;
    #10;
    rst = 1;
    #2;
    rst =0;
    //HIST READ

    //FLV READ
    state = 3'd2;
    flv_r_wr = 0;
    find_least = 67;
    
    //HTREE READ
    state = 3'd3;
    htree_r_wr = 0;
    htreeindex = 33;
    sram_data_out_ht = 249;
    #10;
    rst = 1;
    #2;
    rst =0;
    //CODEBOOK READ
    state = 3'd5;
    curr_index = 55;
    sram_data_out_cb = 249;
    #10;
    rst = 1;
    #2;
    rst =0;
    //TRANSLATION READ    
    state = 3'd6;
    translation = 11;
    sram_data_out_trn = 128'd345;
    #10;
    rst = 1;
    #2;
    rst =0;

    // --- HIST READ ---
    $display("Reading from histogram SRAM...");
    hist_r_wr = 0; // read
    sram_data_out_his = fake_sram_hist[histgram_addr]; // simulate return from SRAM
    #50;

    $display("Read old_char = %h", old_char);

    $finish;
  end

endmodule