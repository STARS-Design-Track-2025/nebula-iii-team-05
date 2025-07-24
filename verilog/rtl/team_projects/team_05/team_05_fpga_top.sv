`default_nettype none

// FPGA top module for Team 05

module top (
  // I/O ports
  input  logic hwclk, reset,
  input  logic [20:0] pb,
  output logic [7:0] left, right,
         ss7, ss6, ss5, ss4, ss3, ss2, ss1, ss0,
  output logic red, green, blue,

  // UART ports
  output logic [7:0] txdata,
  input  logic [7:0] rxdata,
  output logic txclk, rxclk,
  input  logic txready, rxready
);

  // GPIOs
  // Don't forget to assign these to the ports above as needed
  logic [33:0] gpio_in, gpio_out;
  
  logic serial_clk;
  logic sclk;

  //FLV hTREE
  logic [8:0] least1, least2;
  logic [45:0] sum;

  //Controller
  logic [3:0] en_state;
  logic [3:0] fin_state;
  
  //HISTO SRAM
  logic [31:0] sram_in, sram_out;

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

  //CB To Header Syn
  logic char_found;
  logic [7:0] char;
  logic [7:0] index_of_root;
  logic [7:0] char_index;
  logic write_finish;
  logic [127:0] char_path;
  logic [6:0] track_length;

  //FLV SRAM
  logic [7:0] cw1, cw2;
  logic [8:0] histo_index;
  logic [63:0] compVal;

  //SRAM TRN
  logic [127:0] path;
  logic readEn;

  //CB SRAM
  logic [6:0] curr_index;

  //SPI
  logic writeBit;
  logic flag;
  logic [7:0] read_out;
  logic nextCharEn;
  logic writeEn;
  
  // Team 05 Design Instance
  t05_controller controller (
    .clk(hwclk), 
    .rst_n(reset), 
    .cont_en(), 
    .restart_en(), 
    .finState(fin_state), 
    .op_fin(), 
    .state_reg(en_state), 
    .finished_signal()
    );

  t05_histogram histogram (
    .clk(hwclk), 
    .rst(reset), 
    .addr_i(read_out), 
    .sram_in(sram_in), 
    .eof(fin_state), 
    .complete(readEn),
    .total(totChar), 
    .sram_out(sram_out), 
    .hist_addr()
    );

  t05_findLeastValue findLeastValue (
    .clk(hwclk), 
    .rst(reset), 
    .compVal(compVal), 
    .state(en_state), 
    .sum(sum), 
    .charWipe1(cw1), 
    .charWipe2(cw2), 
    .least1(least1), 
    .least2(least2), 
    .histo_index(histo_index), 
    .fin(fin_state), 
    .nextCharEn(nextCharEn)
    );

  t05_hTree hTree (
    .clk(hwclk), 
    .rst_n(reset), 
    .least1(least1), 
    .least2(least2), 
    .sum(sum), 
    .nulls(nulls), 
    .HT_en(en_state), 
    .SRAM_finished(SRAM_finished),
    .node_reg(node_reg),
    .clkCount(max_index), 
    .nullSumIndex(nullSumIndex), 
    .op_fin(fin_state), 
    .WriteorRead(WorR)
    );

  //Curr_state should be changed to logic can not pass typedefs through instantiation
  t05_cb_synthesis cb_syn (
    .clk(hwclk), 
    .rst(reset), 
    .max_index(index_of_root), 
    .h_element(), 
    .write_finish(write_finish), 
    .char_found(char_found),
    .char_path(char_path), 
    .char_index(char_index), 
    .curr_index(curr_index), 
    .least1(least1), 
    .least2(least2), 
    .finished(fin_state), 
    .track_length(track_length)
    );

  t05_header_synthesis header_synthesis (
    .clk(hwclk), 
    .rst(reset), 
    .char_index(char_index), 
    .char_found(char_found), 
    .least1(least1),
    .least2(least2), 
    .char_path(char_path), 
    .header(writeBit), 
    .enable(writeEn), 
    .bit1(writeBit), 
    .write_finish(write_finish), 
    .track_length(track_length)
    );

  t05_translation translation (
    .clk(hwclk), 
    .rst(reset), 
    .totChar(totChar), 
    .charIn(read_out), 
    .path(path), 
    .writeBin(writeBit), 
    .writeEn(writeEn),
    .nextCharEn(nextCharEn)
    );

  t05_spiClockDivider spiClockDivider (
    .current_clock_signal(hwclk), 
    .reset(reset), 
    .divided_clock_signal(serial_clk), 
    .sclk(sclk), 
    .freq_flag(flag)
    );

  t05_SPI SPI (
    .mosi(right[6]), 
    .miso(pb[18]), 
    .rst(reset), 
    .serial_clk(serial_clk), 
    .clk(hwclk), 
    .slave_select(green), 
    .read_output(read_out), 
    .writebit(writeBit), 
    .read_en(readEn), 
    .write_en(writeEn), 
    .read_stop(pb[1]), 
    .read_address(32'd0), 
    .write_address(32'd0), 
    .finish(fin_state), 
    .freq_flag(flag), 
    .nextCharEn(nextCharEn)
    );

  assign ss1[6] = sclk; // Connect the serial clock to one of the slave select lines for debugging
  team_05 team_05_inst (
    .clk(hwclk),
    .nrst(~reset),
    .en(1'b1),

    .gpio_in(gpio_in),
    .gpio_out(gpio_out),
    .gpio_oeb()  // don't really need it here since it is an output

    // Uncomment only if using LA
    // .la_data_in(),
    // .la_data_out(),
    // .la_oenb(),

    // Uncomment only if using WB Master Ports (i.e., CPU teams)
    // You could also instantiate RAM in this module for testing
    // .ADR_O(ADR_O),
    // .DAT_O(DAT_O),
    // .SEL_O(SEL_O),
    // .WE_O(WE_O),
    // .STB_O(STB_O),
    // .CYC_O(CYC_O),
    // .ACK_I(ACK_I),
    // .DAT_I(DAT_I),

    // Add other I/O connections to WB bus here
  );

endmodule