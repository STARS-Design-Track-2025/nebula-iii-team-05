`timescale 10ms/10ns
module t05_top (

    input logic hwclk, reset,

    //HISTOGRAM
    input logic read_in_pulse,
    input logic [6:0] in,

    //TRN
    input logic esp_ack,
    // input logic [31:0] sram_in,
    // output logic [31:0] sram_out,
    // output logic [7:0] hist_addr,
    // output logic out_of_init,
    // output logic busy_o,
    // output logic nextChar,
    // output logic init,

    //SPI
    // output logic mosi, 
    // input logic miso,

    //WRAPPER
    output logic wbs_stb_o,
    output logic wbs_cyc_o,
    output logic wbs_we_o,
    output logic [3:0] wbs_sel_o,
    output logic [31:0] wbs_dat_o,
    output logic [31:0] wbs_adr_o,
    input logic wbs_ack_i,
    input logic [31:0] wbs_dat_i
    //input logic pulse_in
);
  logic serial_clk;

  //FLV hTREE
  logic [8:0] least1_FLV, least2_FLV;
  logic [63:0] sum;
  logic [5:0] op_fin;
  // logic finished_signal;
  logic [3:0] en_state;
  logic [1:0] wr;
  logic readEn;
  logic spi_confirm_out;
  logic [31:0] sram_in;
  logic [31:0] sram_out;
  logic [7:0] hist_addr;
  logic out_of_init;
  logic busy_o;
  logic nextChar;
  logic init;

//   assign mosi = 0;
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
  logic [7:0] max_index;

  //HTREE SRAM
  logic [63:0] nulls;
  logic SRAM_finished;
  logic [71:0] node_reg;
  logic [6:0] nullSumIndex;
  logic WorR;

  //SRAM CB
  logic [70:0] h_element;

  //CB To Header Syn
  logic char_found;
  logic [7:0] char;
  logic [7:0] char_index;
  // logic write_finish;  // TODO: Does it even do anything?
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
  //logic readEn;

  //CB SRAM
  logic [7:0] curr_index;
  logic SRAM_enable;
  logic cb_r_wr;
  //assign cb_r_wr = 0;

  //SPI
  logic writeBit_HS, writeBit_TL;
  logic flag;
  logic [6:0] read_out, read_out_n;
  assign writeBit_HS = 0;
  assign writeEn_HS = 0;
  
  //SOMETHING
  logic HT_fin_reg;
  logic fin_state_idle, fin_state_HG, fin_state_FLV, fin_state_HT, fin_state_CB, fin_state_TL, fin_state_SPI;
  assign fin_state_idle = 1;

  logic nextCharEn;
  logic writeEn_HS, writeEn_TL;
  logic [7:0] fin_State;
  assign fin_State = {fin_state_idle, fin_state_HG, fin_state_FLV, HT_fin_reg, fin_state_HT, fin_state_CB, fin_state_TL, '0};
  assign fin_state_SPI = 0;

  //WB & SRAM INTERFACE
  logic write_i, read_i;
  logic [31:0] addr_i;
  logic [3:0] sel_i;
  //logic busy_o;

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
  logic nextChar_FLV;
  logic FLV_done;
  logic wipe_the_char_1, wipe_the_char_2;
  logic write_HT_fin;
  logic pulse_HTREE;
  logic HT_complete;
  logic [3:0] HT_state;
  logic sum_2;
  logic HT_read_complete;
  logic CB_read_complete;
  logic CB_write_complete;
  logic pulse_CB;
  logic HT_over_complete;
  logic [7:0] TRN_char_index;
  logic pulse_TRN;
  logic TRN_sram_complete;

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
    .FLV_done(FLV_done),
    .wipe_the_char_1(wipe_the_char_1),
    .wipe_the_char_2(wipe_the_char_2),
    //HTREE INPUTS
    .new_node(node_reg),
    .htreeindex(nullSumIndex),
    .htree_write(max_index),
    .htree_r_wr(WorR),
    .hist_read_latch(hist_read_latch),
    .pulse_HTREE(pulse_HTREE),
    .HT_state(HT_state),
    .least1_HTREE(least1_FLV),
    .least2_HTREE(least2_FLV),
    //CB INPUTS
    .curr_index(curr_index),
    .char_index(char_index),
    .codebook_path(char_path),
    .cb_r_wr(cb_r_wr),
    .pulse_CB(pulse_CB),
    //TLN INPUT
    .translation(TRN_char_index),
    .pulse_TRN(pulse_TRN),
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
    .write_HT_fin(write_HT_fin),
    .HTREE_complete(HT_complete),
    .HT_read_complete(HT_read_complete),
    .HT_over_complete(HT_over_complete),
    .sum_2(sum_2),
    //HISTOGRAM OUTPUTS
    .old_char(hist_data_o),       //data going to histogram
    .init(init),
    .nextChar(nextChar),
    //FLV OUTPUTS
    .comp_val(compVal),        //Data going to FLV
    .nextChar_FLV(nextChar_FLV),
    .word_cnt(word_cnt),
    //CB OUTPUTS
    .h_element(h_element),    //data going to CB
    .cb_done(SRAM_enable),  //1 bit enable going to the codebook to let it know that the sram has finished writing/reading the data it was given
    .CB_read_complete(CB_read_complete),
    .CB_write_complete(CB_write_complete),
    //TLN OUTPUTS
    .path(path),
    .TRN_complete(TRN_sram_complete)
    //Controller Output
    // .ctrl_done(ctrl_state) //output going to the controller to let it kow which module hase finished reading/writing
  );

  // logic [5:0] ctrl_state;
  //logic [3:0] in_state;
  logic [31:0] hist_data_o;

  logic [3:0] word_cnt;

  t05_controller controller (
    .clk(hwclk),
    .rst(reset), 
    // .cont_en(1),  // // TODO: Seems like this is not used anywhere inside. Set to 1.
    // .restart_en('0), 
    // .op_fin(ctrl_state), 
    .finState(fin_State), 
    .fin_idle(fin_state_idle),
    .fin_HG(fin_state_HG),
    .fin_FLV(fin_state_FLV),
    .fin_HT(HT_fin_reg),
    .fin_FINISHED(fin_state_HT),
    .fin_CBS(fin_state_CB),
    .fin_TRN(fin_state_TL),
    .fin_SPI(fin_state_SPI),
    .state_reg(en_state)
    // .finished_signal(finished_signal)
    );

    logic [7:0] out;
    logic out_valid;
    logic [2:0] leftover_count;
    logic [6:0] leftover_data;
    // logic eof_check;

    t05_bytecount dut (
        .clk(hwclk),                        //clock
        .en(1'd1),                          //synchronous enable
        .nrst(!reset),                      //active-low reset
        .pulse(read_in_pulse),              //pulse: new 7-bit input available this cycle
        .in(in),                            //7-bit chunk
        .out(out),                          //assembled byte
        .out_valid(out_valid),              //high when `out` is valid this cycle
        .leftover_data(leftover_data),      //leftover bits (right-aligned)
        .leftover_count(leftover_count)     //number of valid leftover bits (0..7)
    );

  always_ff @(posedge hwclk, posedge reset) begin
    if(reset) begin
      read_out <= '0;
    end else begin
      read_out <= read_out_n;
    end
  end

  always_comb begin
    read_out_n = read_out;
    // eof_check = 0;
    if(read_in_pulse) begin
      read_out_n = in;
    end
    // if(out_valid) begin
    //   if(out == 8'h1A) begin
    //     eof_check = 1;
    //   end
    // end
  end

  t05_histogram histogram (
    .clk(hwclk), 
    .rst(reset), 
    .busy_i(busy_o),
    .init(init),
    .pulse(read_in_pulse),
    .en_state(en_state),
    .spi_in({1'd0, read_out}), 
    .write_i(write_i),
    .read_i(read_i),
    .sram_in(hist_data_o), 
    .eof(fin_state_HG),
    .out_valid(out_valid), 
    .out(out),
    .complete(readEn),
    .total(totChar), 
    .sram_out(sram_out), 
    .hist_addr(hist_addr),
    .wr_r_en(wr),
    .get_data(hist_read_latch),
    .confirm(spi_confirm_out),
    .out_of_init(out_of_init)
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
    .pulse_FLV(pulse_FLV),
    .nextChar(nextChar_FLV),
    .word_cnt(word_cnt),
    .FLV_done(FLV_done),
    .wipe_the_char_1(wipe_the_char_1),
    .wipe_the_char_2(wipe_the_char_2),
    .HTREE_complete(HT_complete),
    .HT_fin(HT_fin_reg)
    );

  t05_hTree hTree (
    .clk(hwclk), 
    .rst_n(reset), 
    .least1(least1_FLV), 
    .least2(least2_FLV), 
    .sum(sum),
    .nulls(nulls), 
    .HT_en(en_state), 
    .SRAM_finished(SRAM_finished),
    .node_reg(node_reg),
    .clkCount(max_index),
    .nullSumIndex(nullSumIndex), 
    .WriteorRead(WorR),
    .HT_Finished(fin_state_HT),
    .HT_fin_reg(HT_fin_reg),
    .write_HT_fin(write_HT_fin),
    .pulse(pulse_HTREE),
    .sram_complete(HT_complete),
    .state(HT_state),
    .read_complete(HT_read_complete),
    .sum_2(sum_2),
    .over_complete(HT_over_complete)
    );

  //logic [3:0] curr_state;
  logic [127:0] curr_path;
  logic left;
  logic [7:0] num_lefts;
  logic [8:0] header;
  logic state_3;

  //Curr_state should be changed to logic can not pass typedefs through instantiation
  t05_cb_synthesis cb_syn (
    .clk(hwclk),
    .rst(reset),
    .max_index(max_index), 
    .h_element(h_element), 
    // .write_finish(),  // TODO: This doesn't do anything in t05_cb_synthesis bruh
    .en_state(en_state), 
    .char_found(char_found),
    .char_path(char_path), 
    .char_index(char_index), 
    .curr_index(curr_index), 
    .state_3(state_3),
    .curr_path(curr_path),
    .num_lefts(num_lefts),
    .left(left),
    .finished(fin_state_CB),
    .track_length(track_length),
    .SRAM_enable(SRAM_enable),
    .read_complete(CB_read_complete),
    .write_complete(CB_write_complete),
    .pulse(pulse_CB),
    .cb_r_wr(cb_r_wr)
    );

  logic write_complete_HS;

  // TODO: Had to uncomment this because it's cooked
  t05_header_synthesis header_synthesis (
    .clk(hwclk), 
    .rst(reset) 
    // .char_index(char_index), 
    // .char_found(char_found), 
    // .curr_path(curr_path[0]),
    // .track_length(track_length),
    // .state_3(state_3),
    // .left(left),
    // .num_lefts(num_lefts),
    // .enable(writeEn_HS), 
    // .bit1(writeBit_HS)
    );

  t05_translation translation (
    .clk(hwclk), 
    .rst(reset), 
    .totChar(totChar),
    .charIn({1'd0, read_out}), 
    .path(path), 
    .writeBin(writeBit_TL), 
    .writeEn(writeEn_TL),
    .nextCharEn(nextCharEn),
    .en_state(en_state),
    .fin_state(fin_state_TL),
    .pulse(pulse_TRN),
    .esp_ack(esp_ack),
    .sram_complete(TRN_sram_complete),
    .char_index(TRN_char_index),
    .word_cnt(word_cnt),
    .head_bit(writeBit_HS),
    .head_write_en(writeEn_HS)
    // .write_complete_HS(write_complete_HS)
    );

endmodule