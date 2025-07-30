`timescale 10ms/10ns
module t05_top (
    // output logic HT_fin_reg,
    // output logic fin_state_HG, fin_state_FLV, fin_state_HT, fin_state_CB, fin_state_TL, fin_state_SPI,
    // output logic error_FIN_HG, error_FIN_FLV, error_FIN_HT, error_FIN_FINISHED, error_FIN_CBS, error_FIN_TRN, error_FIN_SPI,
    //output logic [3:0] fin_state_HG, fin_state_FLV, fin_state_HT, fin_state_CB, fin_state_TL
    input logic hwclk, reset,

    //CONTROLLER
    input logic cont_en,
    input logic [5:0] op_fin,
    output logic finished_signal,

    //HISTOGRAM
    input logic [31:0] sram_in,
    output logic [31:0] sram_out,
    output logic [7:0] hist_addr,
    output logic [1:0] wr,

    //FLV
    //input logic [63:0] compVal,
    //output logic [8:0] histo_index,

    //HTREE
    //input logic SRAM_finished,
    //input logic [63:0] nulls,

    //CB
    //input logic [70:0] h_element,

    //SPI
    output logic mosi, 
    input logic miso,
    input logic [7:0] read_out,

    //Starting states
    output logic [3:0] en_state,
    output logic [8:0] fin_State,

    //WRAPPER
    output logic wbs_stb_o,
    output logic wbs_cyc_o,
    output logic wbs_we_o,
    output logic [3:0] wbs_sel_o,
    output logic [31:0] wbs_dat_o,
    output logic [31:0] wbs_adr_o,
    output spi_confirm_out,
    output logic nextChar,
    output logic init,
    input logic wbs_ack_i,
    input logic [31:0] wbs_dat_i,
    input logic pulse_in
);
  logic serial_clk;
  logic sclk;

  //FLV hTREE
  logic [8:0] least1_FLV, least2_FLV;
  logic [63:0] sum;

  assign mosi = 0;
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
  logic [63:0] nulls;
  logic SRAM_finished;
  logic [70:0] node_reg;
  logic [6:0] nullSumIndex;
  logic WorR;

  //SRAM CB
  logic [70:0] h_element;

  //CB To Header Syn
  logic char_found;
  logic [7:0] char;
  logic [7:0] char_index;
  logic write_finish;
  logic [127:0] char_path;
  logic [6:0] track_length;
  logic [8:0] least1_CB, least2_CB;

  //FLV SRAM
  logic [7:0] cw1, cw2;
  logic [8:0] histo_index;
  logic [63:0] compVal;
  logic flv_r_wr;

  //SRAM TRN
  logic [127:0] path;
  logic readEn;

  //CB SRAM
  logic [7:0] curr_index;
  logic SRAM_enable;
  logic cb_r_wr;
  assign cb_r_wr = 0;

  //SPI
  logic writeBit_HS, writeBit_TL;
  logic flag;

  //SOMETHING
  logic HT_fin_reg;
  logic fin_state_idle, fin_state_HG, fin_state_FLV, fin_state_HT, fin_state_CB, fin_state_TL, fin_state_SPI;
  assign fin_state_idle = 1;
  logic error_FIN_HG, error_FIN_FLV, error_FIN_HT, error_FIN_FINISHED, error_FIN_CBS, error_FIN_TRN, error_FIN_SPI;
  assign error_FIN_HG = 0;
  assign error_FIN_FLV = 0;
  assign error_FIN_FINISHED = 0;
  assign error_FIN_CBS = 0;
  assign error_FIN_TRN = 0;
  assign error_FIN_SPI = 0;

  logic temp;
  assign temp = /* error_FIN_HG || error_FIN_FLV || */ error_FIN_HT; //|| error_FIN_FINISHED; //|| error_FIN_CBS || error_FIN_TRN;// || error_FIN_SPI;

  //logic [7:0] read_out;
  logic nextCharEn;
  logic writeEn_HS, writeEn_TL;
  assign fin_State = {fin_state_idle, fin_state_HG, fin_state_FLV, HT_fin_reg, fin_state_HT, fin_state_CB, fin_state_TL, '0, temp};//fin_state_SPI,temp };
  assign fin_state_SPI = 0;

  //assign fin_state_idle = 1;

  //WB & SRAM INTERFACE
  logic write_i, read_i;
  logic [31:0] addr_i;
  logic [3:0] sel_i;
  logic busy_o;

  //logic init;

  wishbone_manager WB (
    .nRST(!reset),
    .CLK(hwclk),
    .DAT_I(wbs_dat_i),
    .ACK_I(wbs_ack_i),
    .CPU_DAT_I(data_i_wish),
    .ADR_I(addr_i),
    .SEL_I(sel_i),
    .WRITE_I(write_i),
    .READ_I(read_i),
    .ADR_O(wbs_adr_o),
    .DAT_O(wbs_dat_o),
    .SEL_O(wbs_sel_o),
    .WE_O(wbs_we_o),
    .STB_O(wbs_stb_o),
    .CYC_O(wbs_cyc_o),
    .CPU_DAT_O(data_o_wish),
    .BUSY_O(busy_o)
  );

  logic [31:0] data_i_wish, data_o_wish;
  logic hist_read_latch;
  logic pulse_FLV;

  t05_sram_interface sram_interface (
    .clk(hwclk),
    .rst(reset),
    //HISTOGRAM INPUTS
    .histogram(sram_out),
    .histgram_addr(hist_addr),
    .hist_r_wr(wr),
    //FLV INPUTS
    .find_least(histo_index),
    .charwipe1(cw1),
    .charwipe2(cw2),
    .flv_r_wr(flv_r_wr),
    .pulse_FLV(pulse_FLV),
    //HTREE INPUTS
    .new_node(node_reg),
    .htreeindex(nullSumIndex),
    .htree_r_wr(WorR),
    .hist_read_latch(hist_read_latch),
    //CB INPUTS
    .curr_index(curr_index),
    .char_index(char_index),
    .codebook_path(char_path),
    .cb_r_wr(cb_r_wr),
    //TLN INPUT
    .translation(read_out),
    //CONTROLLER INPUT
    .state(en_state),
    //INPUTS FROM SRAM
    .data_o(data_o_wish),
    .busy_o(busy_o),

    //OUTPUTS to SRAM
    .wr_en(write_i),
    .r_en(read_i),
    .select(sel_i),
    .addr(addr_i),
    .data_i(data_i_wish),
    //HTREE OUTPUTS
    .nulls(nulls),             //data going to hTree
    .ht_done(SRAM_finished),  //enable going to the htree to let it know that the sram has finished reading or writing data
    //HISTOGRAM OUTPUTS
    .old_char(hist_data_o),       //data going to histogram
    .init(init),
    .nextChar(nextChar),
    //FLV OUTPUTS
    .comp_val(compVal),        //Data going to FLV 
    //CB OUTPUTS
    .h_element(h_element),    //data going to CB
    .cb_done(SRAM_enable),  //1 bit enable going to the codebook to let it know that the sram has finished writing/reading the data it was given
    //TLN OUTPUTS
    .path(path),
    //Controller Output
    .ctrl_done(ctrl_state) //output going to the controller to let it kow which module hase finished reading/writing
  );

  logic [5:0] ctrl_state;
  //logic [3:0] in_state;
  logic [31:0] hist_data_o;

  t05_controller controller (
    .clk(hwclk),
    .rst(reset), 
    .cont_en(cont_en), 
    .restart_en('0), 
    .finState(fin_State), 
    .op_fin(ctrl_state), 
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
    .busy_i(busy_o),
    .init(init),
    .pulse(pulse_in),
    .en_state(en_state),
    .spi_in(read_out), 
    .write_i(write_i),
    .read_i(read_i),
    .sram_in(hist_data_o), 
    .eof(fin_state_HG), 
    .complete(readEn),
    .total(totChar), 
    .sram_out(sram_out), 
    .hist_addr(hist_addr),
    .wr_r_en(wr),
    .get_data(hist_read_latch),
    .confirm(spi_confirm_out)
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
    .fin_state(fin_state_FLV),
    .flv_r_wr(flv_r_wr),
    .pulse_FLV(pulse_FLV)
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
    .WriteorRead(WorR),
    .HT_Finished(fin_state_HT),
    .HT_fin_reg(HT_fin_reg)
    );

  //Curr_state should be changed to logic can not pass typedefs through instantiation
  t05_cb_synthesis cb_syn (
    .clk(hwclk),
    .rst(reset),
    .max_index({1'b0, max_index}), 
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
    .track_length(track_length),
    .SRAM_enable(SRAM_enable)
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