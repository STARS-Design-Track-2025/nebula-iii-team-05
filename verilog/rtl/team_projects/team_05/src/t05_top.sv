`timescale 10ms/10ns
module t05_top (
    input logic hwclk, reset, miso, SRAM_finished, cont_en,
    input logic [7:0] read_out,
    input logic [63:0] compVal, nulls,
    input logic [5:0] op_fin,
    input logic [31:0] sram_in,
    // output logic HT_fin_reg,
    // output logic fin_state_HG, fin_state_FLV, fin_state_HT, fin_state_CB, fin_state_TL, fin_state_SPI,
    // output logic error_FIN_HG, error_FIN_FLV, error_FIN_HT, error_FIN_FINISHED, error_FIN_CBS, error_FIN_TRN, error_FIN_SPI,
    output logic finished_signal,
    output logic [3:0] en_state,
    output logic [8:0] fin_State,
    output logic [31:0] sram_out,
    input logic [70:0] h_element,
    output logic [7:0] hist_addr,
    output logic mosi, 
    output logic [1:0] wr,
    output logic [8:0] histo_index
    //output logic [3:0] fin_state_HG, fin_state_FLV, fin_state_HT, fin_state_CB, fin_state_TL
);
  
  logic serial_clk;
  logic sclk;

  //FLV hTREE
  logic [8:0] least1_FLV, least2_FLV;
  logic [63:0] sum;

  //Controller
  // logic [3:0] en_state;
  //logic [3:0] fin_state;
  // input logic HT_fin_reg;
  // input logic fin_state_HG, fin_state_FLV, fin_state_HT, fin_state_CB, fin_state_TL;
  // output logic finished_signal;
  
  //HISTO SRAM
  //logic [31:0] sram_in, sram_out;

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
  //logic [70:0] h_element;

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
  //logic [8:0] histo_index;
  //logic [63:0] compVal;

  //SRAM TRN
  logic [127:0] path;
  logic readEn;

  //CB SRAM
  logic [7:0] curr_index;

  //SPI
  logic writeBit_HS, writeBit_TL;
  logic flag;

  //SOMETHING
  logic HT_fin_reg;
  logic fin_state_idle, fin_state_HG, fin_state_FLV, fin_state_HT, fin_state_CB, fin_state_TL, fin_state_SPI;
  assign fin_state_idle = 1;
  logic error_FIN_HG, error_FIN_FLV, error_FIN_HT, error_FIN_FINISHED, error_FIN_CBS, error_FIN_TRN, error_FIN_SPI;


  logic temp;
  assign temp = /* error_FIN_HG || error_FIN_FLV || */ error_FIN_HT; //|| error_FIN_FINISHED; //|| error_FIN_CBS || error_FIN_TRN;// || error_FIN_SPI;


  //logic [7:0] read_out;
  logic nextCharEn;
  logic writeEn_HS, writeEn_TL;
  assign fin_State = {fin_state_idle, fin_state_HG, fin_state_FLV, HT_fin_reg, fin_state_HT, fin_state_CB, fin_state_TL, '0, temp};//fin_state_SPI,temp };
  
  t05_controller controller (
    .clk(hwclk), 
    .rst(reset), 
    .cont_en(cont_en), 
    .restart_en('0), 
    .finState(fin_State), 
    .op_fin(op_fin), 
    .error_FIN_HG(error_FIN_HG), 
    .error_FIN_FLV(error_FIN_FLV), 
    .error_FIN_HT(error_FIN_HT),
    .error_FIN_FINISHED(error_FIN_FINISHED),
    .error_FIN_CBS(error_FIN_CBS),
    .error_FIN_TRN(error_FIN_TRN),
    .error_FIN_SPI(error_FIN_SPI),
    .fin_idle(fin_state_idle),
    .fin_HG(fin_state_HG),
    .fin_FLV(fin_state_FLV),
    .fin_HT(HT_fin_reg),
    .fin_FINISHED(fin_state_HT),
    .fin_CBS(fin_state_CB),
    .fin_TRN(fin_state_TL),
    .fin_SPI(fin_state_SPI),
    .state_reg(en_state), 
    .finished_signal(finished_signal)
    );

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
    .hist_addr(hist_addr),
    .wr_r_en(wr)
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
    .least2(least2_FLV) /*,task readA ()*/,
    .histo_index(histo_index), 
    .fin_state(fin_state_FLV)
    );

  t05_hTree hTree (
    .clk(hwclk), 
    .rst_n(reset), 
    .least1(least1_FLV), 
    .least2(least2_FLV), 
    .sum(sum),
    .nulls(nulls), 
    .HT_en(en_state), 
    .error(error_FIN_HT),
    .SRAM_finished(SRAM_finished),
    .node_reg(node_reg),
    .clkCount(max_index), 
    .nullSumIndex(nullSumIndex), 
    //.op_fin(fin_state_HT), 
    .WriteorRead(WorR),
    .HT_Finished(fin_state_HT),
    .HT_fin_reg(HT_fin_reg)
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