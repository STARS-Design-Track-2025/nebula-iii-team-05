`timescale 10ms/10ns
module t05_top (

    input logic hwclk, reset,

    //HISTOGRAM
    input logic read_in_pulse,
    input logic [6:0] in,
    // input logic [31:0] sram_in,
    // output logic [31:0] sram_out,
    // output logic [7:0] hist_addr,
    output logic out_of_init,
    output logic busy_o,
    output logic nextChar,
    output logic init,

    //SPI
    output logic mosi, 
    input logic miso,

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


    // DECOMPRESSION
    // input logic [7:0] SPI_data_in, // byte sent by SPI
    // input logic controller_enable,
    // output logic SPI_data_out, // bit sent to SPI
    // output logic SPI_read_en,
    // output logic [1:0] curr_state,
    // output logic SRAM_r_en,
    // //input logic [127:0] tr_SRAM_data_in,
    // output logic SRAM_wr_en
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
  // logic out_of_init;
  // logic busy_o;
  // logic nextChar;
  // logic init;

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
  logic [6:0] cb_length;
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

  // logic [3:0] comp_state;
  // logic [1:0] decomp_state;
  // logic [3:0] opFin;
  // logic finished_signal;
  // logic compEN_reg;
  // logic decompEN_reg;

  // OPFIN opfin1 ( // top level controller 
  //   .clk(hwclk), .rst(reset), .cont_en(cont_en), .restart_en(restart_en), .compDecomp(compDecomp),
  //   .comp_state(comp_state), 
  //   .decomp_state(decomp_state), // assumed to be registered
  //   .opFin(opFin), // NOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO (lol stop pls Van)
  //   .finished_signal(finished_signal), 
  //   .compEN_reg(compEN_reg), .decompEN_reg(decompEN_reg)
  // );

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
    //.compEN_reg(compEN_reg),
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
  logic [7:0] zeroes;
  logic state8;
  logic state6;
  logic [7:0] zero_count;

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
    //.state_3(state_3),
    .curr_path(curr_path),
    .num_lefts(num_lefts),
    .left(left),
    .finished(fin_state_CB),
    .cb_length(cb_length),
    .SRAM_enable(SRAM_enable),
    .read_complete(CB_read_complete),
    .write_complete(CB_write_complete),
    .pulse(pulse_CB),
    .cb_r_wr(cb_r_wr),
    .zeroes(zeroes),
    .state8(state8),
    .state6(state6),
    .zero_count(zero_count)
    );

  logic write_complete_HS;

  // TODO: Had to uncomment this because it's cooked
  t05_header_synthesis header_synthesis (
    .clk(hwclk), 
    .rst(reset), 
    .char_index(char_index), 
    .char_found(char_found), 
    .curr_path(char_path[0]),
    .cb_length(cb_length),
    //.state_3(state_3),
    .left(left),
    .num_lefts(num_lefts),
    .enable(writeEn_HS), 
    .bit1(writeBit_HS),
    .ser_pulse(ser_pulse),
    .write_complete(),
    .zeroes(zeroes),
    .state8(state8),
    .state6(state6),
    .zero_count(zero_count)
    // .write_finish(write_finish)
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
    .sram_complete(TRN_sram_complete),
    .char_index(TRN_char_index),
    .word_cnt(word_cnt),
    .ser_pulse(ser_pulse),
    .head_bit(writeBit_HS),
    .head_write_en(writeEn_HS),
    .input_valid(input_valid_TL),
    .write_complete_HS(write_complete_HS)
    );

    logic ser_pulse;
    assign ser_pulse = 1;
    logic sclk;
    logic busy;
    logic cs_n;
    logic done;
    logic input_valid_TL;

    /*

    t05_sd_spi_tx spi (
    .clk(),                                             // System clock
    .rst_n(!reset),                                     // Active low reset
    .start(),                                           // Start transmission (pulse) - SPI Controller
    .command(),                                         // 6-bit command to SD card - SPI Controller
    .argument(),                                        // 32-bit command argument - SPI Controller
    .crc(),                                             // 7-bit cyclic redundancy check - SPI Controller
    .write_mode(writeEn_TL | writeEn_HS),               // 0: Command, 1: continuous write
    .ser_w_data(writeBit_TL),                           // Serial write data from translation
    .input_valid(input_valid_TL),                       // Provided serial input is valid
    .ser_pulse(ser_pulse),                              // Pulse to request new serial data
    .sdo(mosi),                                         // Serial data out (MOSI)
    .sclk(sclk),                                            // SPI clock
    .cs_n(cs_n),                                            // Chip select (active low)
    .busy(busy),                                            // Transmission in progress
    .done(done)                                             // Transmission complete (pulse)
    );

    */


    // DECOMPRESSION

    // SRAM
//   logic [127:0] hd_SRAM_data_out; // write char path
//   logic [127:0] tr_SRAM_data_in; // read char path
//   logic [7:0] char_index_hd;
//   //logic init1;
//   logic [7:0] char_index_tr;
//   //logic SRAM_finished1;

//   logic SRAM_controller_en;

//   t05_sram_interface_decode sramd1 (
//     .clk(hwclk), .rst(reset),

//     .SRAM_controller_en(SRAM_controller_en),
//     .controller_state(curr_state), // controller state
//     .init(init),

//     .char_index_hd(char_index_hd), // index to store path at
//     // write paths from hd_decode to SRAM
//     .char_index_tr(char_index_tr),
//     .SRAM_write_en(SRAM_wr_en),
//     .SRAM_data_out(hd_SRAM_data_out),

//     // translation read from SRAM
//     .SRAM_read_en(SRAM_r_en),
//     .SRAM_data_in(tr_SRAM_data_in),
//     .SRAM_finished(SRAM_finished),

//     // wishbone connects
//     .wr_en(write_i),
//     .r_en(read_i),
//     .select(sel_i),
//     .addr(addr_i),
//     .data_i(data_i_wish),
//     .data_o(data_o_wish),
//     .busy_o(busy_o)
// );

// // SPI SIGNALS
//   logic SPI_read_en_hd;
// logic SPI_read_en_tr;
// logic SPI_write_en;
// // t05_SPI SPI1 (
// //     .miso(miso), // Read
// //     .rst(reset),
// //     .serial_clk(s_clk), .clk(hwclk),
// //     .writebit(SPI_data_out),
// //     .read_en(SPI_read_en), .write_en(SPI_write_en), read_stop, nextCharEn,
// //     .read_address, write_address,
// //     output logic slave_select,
// //     output logic [7:0] read_output,
// //     output logic [3:0] finish, 
// //     output logic freq_flag, cmd_en,
// //     output logic mosi // Write
// // );


// // CONTROLLER SIGNALS (enables and finish signals)
// logic tr_en_controller; 
// logic hd_en_controller;
// logic tr_finished_controller;
// logic hd_finished_controller;
// //logic SRAM_wr_en;
// //logic [1:0] curr_state;
// logic decompress_finished;

// t05_controller_decode cd1 (
//     .controller_enable(decompEN_reg),
//     .clk(hwclk), .rst(reset),
//     .init(init),
//     .SRAM_r_en(SRAM_r_en), .SRAM_wr_en(SRAM_wr_en), 
//     .hd_finished(hd_finished_controller),
//     .tr_finished(tr_finished_controller),
//     .hd_enable(hd_en_controller),
//     .tr_enable(tr_en_controller),
//     .curr_state(curr_state),
//     .finished(decompress_finished),
//     .SPI_read_en_hd(SPI_read_en_hd),
//     .SPI_read_en_tr(SPI_read_en_tr),
//     .SPI_read_en(SPI_read_en),
//     .SRAM_finished(SRAM_finished),
//     .SRAM_controller_en(SRAM_controller_en)
// );

// // INTERNAL (HD_DECODE to TRANSLATION)
// logic [31:0] tot_chars; // total # of chars in decompressed file (end condtion for translation, read by hd_decode)
// logic [3:0] hd_offset;

// t05_hd_decode hdd1 (.clk(hwclk), .rst(reset),
//     .hd_enable(hd_en_controller),
//     .SPI_data_in(SPI_data_in), // read byte of header from SPI
//     .SPI_read_en(SPI_read_en_hd), // sent to SPI to enable a new byte to be read
//     .SRAM_data_out(hd_SRAM_data_out), // write a char path to SRAM
//     .char_index(char_index_hd), // set to SRAM to store address
//     .SRAM_write_en(SRAM_wr_en), // sent to SRAM to enable writing a char path
//     .finished(hd_finished_controller), // sent to controller
//     .tot_chars(tot_chars), // read from compressed file and sent to translation to determine the finish condition)
//     .hd_offset(hd_offset)
// );
// t05_translation_decode trd1 (
//     .clk(hwclk), .rst(reset),
//     .translation_enable(tr_en_controller),
//     .tot_chars(tot_chars), // total characters read in the hd_decode
//     .SPI_read_data(SPI_data_in), // read in char bytes from the SPI
//     .SRAM_read_data(tr_SRAM_data_in), // read in path from the SRAM
//     .SPI_read_en(SPI_read_en_tr),
//     .SRAM_read_en(SRAM_r_en),
//     .char_index(char_index_tr), // char index for char path (written by hd_decode) to get in SRAM
//     .SPI_write_data(SPI_data_out), // given an char index from SRAM, write the char (bit by bit) based on the corresponding code
//     .SPI_write_en(SPI_write_en),
//     .finished(tr_finished_controller),
//     .hd_offset(hd_offset)
// ); 



endmodule