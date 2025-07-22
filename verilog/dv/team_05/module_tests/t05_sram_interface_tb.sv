`timescale 1ms/1ns
module t05_sram_interface_tb;

  logic clk, rst, trn_nxt_char;
  logic [31:0] histogram;
  logic [7:0] histgram_addr;
  logic hist_r_wr;
  logic [7:0] find_least;
  logic [70:0] new_node;
  logic [6:0] htreeindex;
  logic htree_r_wr;
  logic [7:0] codebook;
  logic [127:0] codebook_path;
  logic [7:0] translation;
  logic [2:0] state;
  logic [31:0] sram_data_out_his;
  logic [63:0] sram_data_out_flv;
  logic [128:0] sram_data_out_trn;
  logic [70:0] sram_data_out_cb;
  logic [31:0] sram_data_out_ht;
  logic wr_en, r_en;
  logic [3:0] select;
  logic [31:0] old_char, addr, sram_data_in;
  logic [63:0] comp_val;
  logic [70:0] h_element;
  logic [128:0] char_code;
  logic busy_o;

  // Instantiate the DUT
  t05_sram_interface dut (
    .clk(clk),
    .rst(rst),
    .busy_o(busy_o),
    .trn_nxt_char(trn_nxt_char),
    .histogram(histogram),
    .histgram_addr(histgram_addr),
    .hist_r_wr(hist_r_wr),
    .find_least(find_least),
    .new_node(new_node),
    .htreeindex(htreeindex),
    .htree_r_wr(htree_r_wr),
    .codebook(codebook),
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
    .old_char(old_char),
    .addr(addr),
    .sram_data_in(sram_data_in),
    .comp_val(comp_val),
    .h_element(h_element),
    .char_code(char_code)
  );

  // Clock generator
  initial clk = 0;
  always #1 clk = ~clk;

  // Test sequence
  initial begin
    $display("Starting t05_sram_interface testbench");
    $dumpfile("waves/t05_sram_interface.vcd");
    $dumpvars(0, t05_sram_interface_tb);

    // Initialize
    rst = 1;
    trn_nxt_char = 0;
    histogram = 32'hAABBCCDD;
    histgram_addr = 8'd3;
    hist_r_wr = 0; // read first
    find_least = 8'd20;
    new_node = 71'h123456789ABCD;
    htreeindex = 7'd5;
    htree_r_wr = 1;
    codebook = 8'd15;
    codebook_path = 128'hCAFEBABE12345678CAFEBABE12345678;
    translation = 8'd7;
    state = 3'b001; // HIST state
    sram_data_out_his = 32'hDEADBEEF;
    sram_data_out_flv = 64'h1122334455667788;
    sram_data_out_trn = 129'hFEDCBA9876543210FEDCBA987654321;
    sram_data_out_cb = 71'h13579BDF13579;
    sram_data_out_ht = 32'hFEEDFACE;

    #1 rst = 0;  //testing the rst, everything back to 0

    // Histogram write test
    state = 3'd1;
    hist_r_wr = 1; // write mode
    histgram_addr = 8'd10;
    histogram = 32'd7;
    #20;
    rst = 1;
    #1;
    rst = 0;
    hist_r_wr = 0; // switch to read
    histgram_addr = 8'd10; //should output the same vaule that was inputted before "10"
    #20;
    rst = 1;
    #1;
    rst = 0;
    // FLV test
    state = 3'b010;
    find_least = 8'd23;

    #20;
    rst = 1;
    #1;
    rst = 0;
    // Translation test
    state = 3'b110;
    trn_nxt_char = 1;
    translation = 8'd44;
    #20;
    rst = 1;
    #1;
    rst = 0;
    // Codebook test
    state = 3'b101;
    codebook = 8'd9;
    codebook_path = 128'd122;
    #20;
    rst = 1;
    #1;
    rst = 0;

    // HTREE test
    state = 3'b011;
    htree_r_wr = 0; // read mode
    htreeindex = 7'd11;
    rst = 1;
    #1;
    rst = 0;
    htree_r_wr = 1;
    new_node = 71'd695;
    htreeindex = 7'd14;
    #20;
    rst = 1;
    #1;
    rst = 0;
    $display("Test complete. Inspect signals in waveform.");
    $finish;
  end

endmodule