`timescale 10ms/10ns

module t05_top_decompression (
    input logic clk, reset,
    // SPI
    input logic [7:0] SPI_data_in, // byte sent by SPI
    output logic SPI_data_out, // bit sent to SPI

    // SRAM START & FINISH
    // input SRAM_pulse,
    // output SRAM_finish,
    // CONTROLLER SIGNALS
    // input logic hd_finished,
    // input logic tr_finished,
    // output logic hd_enable,
    // output logic tr_enable,
    // output logic [1:0] controller_state


    // SPI
    // output logic mosi, 
    // input logic miso,
    // input logic [7:0] read_out,

    // //Starting states
    // output logic [3:0] en_state,
    // output logic [8:0] fin_State,

    // //WRAPPER
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
// WISHBONE SIGNALS
  logic write_i, read_i;
  logic [31:0] addr_i;
  logic [3:0] sel_i;
  logic busy_o;
  logic [31:0] data_i_wish, data_o_wish;

  wishbone_manager WB (
    .nRST(!reset),
    .CLK(clk),
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

// SRAM
logic [127:0] hd_SRAM_data_out; // write char path
logic [127:0] tr_SRAM_data_in; // read char path
logic [7:0] char_index;

  t05_sram_interface_decode sramd1 (
    .clk(clk), .rst(reset),

    .controller_state(curr_state), // controller state

    .char_index(char_index), // index to store path at
    // write paths from hd_decode to SRAM
    .SRAM_write_en(SRAM_wr_en),
    .SRAM_data_out(hd_SRAM_data_out),

    // translation read from SRAM
    .SRAM_read_en(SRAM_r_en),
    .SRAM_data_in(tr_SRAM_data_in),

    // wishbone connects
    .wr_en(write_i),
    .r_en(read_i),
    .select(sel_i),
    .addr(addr_i),
    .data_i(data_i_wish),
    .data_o(data_o_wish),
    .busy_o(busy_o)
);

// SPI SIGNALS
logic SPI_read_en;
logic SPI_write_en;
// module t05_SPI (
//     .miso(miso), // Read
//     .rst(reset),
//     .serial_clk(s_clk), .clk(hwclk),
//     .writebit(SPI_data_out),
//     .read_en(SPI_read_en), .write_en(SPI_write_en), read_stop, nextCharEn,
//     .read_address, write_address,
//     output logic slave_select,
//     output logic [7:0] read_output,
//     output logic [3:0] finish, 
//     output logic freq_flag, cmd_en,
//     output logic mosi // Write
// );


// CONTROLLER SIGNALS (enables and finish signals)
logic tr_en_controller; 
logic hd_en_controller;
logic tr_finished_controller;
logic hd_finished_controller;
logic SRAM_r_en, SRAM_wr_en;
logic [1:0] curr_state;
logic decompress_finished;

t05_controller_decode cd1 (
    .clk(clk), .rst(reset),
    .SRAM_r_en(SRAM_r_en), .SRAM_wr_en(SRAM_wr_en), 
    .hd_finished(hd_finished_controller),
    .tr_finished(tr_finished_controller),
    .hd_enable(hd_en_controller),
    .tr_enable(tr_en_controller),
    .curr_state(curr_state),
    .finished(decompress_finished)
);

// INTERNAL (HD_DECODE to TRANSLATION)
logic [31:0] tot_chars; // total # of chars in decompressed file (end condtion for translation, read by hd_decode)

t05_hd_decode hdd1 (.clk(clk), .rst(reset),
    .hd_enable(hd_en_controller),
    .SPI_data_in(SPI_data_in), // read byte of header from SPI
    .SPI_read_en(SPI_read_en), // sent to SPI to enable a new byte to be read
    .SRAM_data_out(hd_SRAM_data_out), // write a char path to SRAM
    .char_index(char_index), // set to SRAM to store address
    .SRAM_write_en(SRAM_wr_en), // sent to SRAM to enable writing a char path
    .finished(hd_finished_controller), // sent to controller
    .tot_chars(tot_chars) // read from compressed file and sent to translation to determine the finish condition)
);
t05_translation_decode trd1 (
    .clk(clk), .rst(reset),
    .translation_enable(tr_en_controller),
    .tot_chars(tot_chars), // total characters read in the hd_decode
    .SPI_read_data(SPI_data_in), // read in char bytes from the SPI
    .SRAM_read_data(tr_SRAM_data_in), // read in path from the SRAM
    .SPI_read_en(SPI_read_en),
    .SRAM_read_en(SRAM_r_en),
    .char_index(char_index), // char index for char path (written by hd_decode) to get in SRAM
    .SPI_write_data(SPI_data_out), // given an char index from SRAM, write the char (bit by bit) based on the corresponding code
    .SPI_write_en(SPI_write_en),
    .finished(tr_finished_controller)
); 




endmodule