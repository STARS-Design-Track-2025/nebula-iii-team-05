module t05_top (
    input logic hwclk, reset, miso, SRAM_finished,
    input logic [3:0] en_state,
    input logic [7:0] read_out,
    input logic [63:0] compVal, nulls,
    output logic mosi,
    output logic [3:0] fin_state_HG, fin_state_FLV, fin_state_HT, fin_state_CB, fin_state_TL
);
  logic serial_clk;
  logic sclk;

  //FLV hTREE
  logic [8:0] least1_FLV, least2_FLV;
  logic [63:0] sum;

  //Controller
  //logic [3:0] en_state;
  //logic [3:0] fin_state;
  
  //HISTO SRAM
  logic [31:0] sram_in, sram_out;

  //Histo to TRN
  logic [31:0] totChar;

  //HTREE CB
  logic [6:0] max_index;

  //HTREE SRAM
  //logic [63:0] nulls;
  //logic SRAM_finished;
  logic [70:0] node_reg;
  logic [6:0] nullSumIndex;
  logic WorR;

  //SRAM CB
  logic [70:0] h_element;

  //CB To Header Syn
  logic char_found;
  logic [7:0] char;
  logic [7:0] index_of_root;
  logic [7:0] char_index;
  logic write_finish;
  logic [127:0] char_path;
  logic [6:0] track_length;
  logic [8:0] least1_CB, least2_CB;


  //FLV SRAM
  logic [7:0] cw1, cw2;
  logic [8:0] histo_index;
  //logic [63:0] compVal;

  //SRAM TRN
  logic [127:0] path;
  logic readEn;

  //CB SRAM
  logic [7:0] curr_index;

  //SPI
  logic writeBit_HS, writeBit_TL;
  logic flag;
  //logic [7:0] read_out;
  logic nextCharEn;
  logic writeEn_HS, writeEn_TL;
//   t05_controller controller (
//     .clk(hwclk), 
//     .rst_n(reset), 
//     .cont_en(), 
//     .restart_en(), 
//     .finState(fin_state), 
//     .op_fin(), 
//     .state_reg(en_state), 
//     .finished_signal()
//     );

  t05_histogram histogram (
    .clk(hwclk), 
    .rst(reset), 
    .en_state(en_state),
    .spi_in(read_out), 
    .sram_in(sram_in), 
    .eof(fin_state_HG), 
    .complete(readEn),
    .total(totChar), 
    .sram_out(sram_out), 
    .hist_addr(),
    .wr_r_en()
    );

  t05_findLeastValue findLeastValue (
    .clk(hwclk), 
    .rst(reset), 
    .compVal(compVal), 
    .en_state(en_state), 
    .sum(sum), 
    .charWipe1(cw1), 
    .charWipe2(cw2), 
    .least1(least1_FLV), 
    .least2(least2_FLV), 
    .histo_index(histo_index), 
    .fin_state(fin_state_FLV)
    );

  t05_hTree hTree (
    .clk(hwclk), 
    .rst_n(!reset), 
    .least1(least1_FLV), 
    .least2(least2_FLV), 
    .sum(sum),
    .nulls(nulls), 
    .HT_en(en_state), 
    .SRAM_finished(SRAM_finished),
    .node_reg(node_reg),
    .clkCount(max_index), 
    .nullSumIndex(nullSumIndex), 
    .op_fin(fin_state_HT), 
    .WriteorRead(WorR)
    );

  //Curr_state should be changed to logic can not pass typedefs through instantiation
  t05_cb_synthesis cb_syn (
    .clk(hwclk),
    .rst(reset),
    .max_index(index_of_root), 
    .h_element(h_element), 
    .write_finish(write_finish),
    .en_state(en_state), 
    .char_found(char_found),
    .char_path(char_path), 
    .char_index(char_index), 
    .curr_index(curr_index), 
    .least1(least1_CB), 
    .least2(least2_CB), 
    .finished(fin_state_CB),
    .track_length(track_length)
    );

  t05_header_synthesis header_synthesis (
    .clk(hwclk), 
    .rst(reset), 
    .char_index(char_index), 
    .char_found(char_found), 
    .least1(least1_CB),
    .least2(least2_CB), 
    .char_path(char_path), 
    .enable(writeEn_HS), 
    .bit1(writeBit_HS),
    .write_finish(write_finish), 
    .track_length(track_length)
    );

  t05_translation translation (
    .clk(hwclk), 
    .rst(reset), 
    .totChar(totChar),
    .charIn(read_out), 
    .path(path), 
    .writeBin(writeBit_TL), 
    .writeEn(writeEn_TL),
    .nextCharEn(nextCharEn),
    .en_state(en_state),
    .fin_state(fin_state_TL)
    );



endmodule