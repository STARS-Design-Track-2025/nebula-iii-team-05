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
  logic flag;
  logic [7:0] read_out;
  logic [8:0] least1, least2;
  logic [45:0] sum;
  logic [7:0] index_of_root;
  
  //CB To Header Syn
  logic char_found;
  logic [7:0] char;
  logic [2:0] CB_state;

  //To SPI
  logic writeBit;
  
  // Team 05 Design Instance
  t05_controller controller (.clk(hwclk), .rst_n(reset), .cont_en(), .restart_en(), .finState(), .op_fin(), .state_reg(), .finished_signal());

  t05_histogram histogram (.clk(hwclk), .rst(reset), .addr_i(), .sram_addr_in(), .sram_in(), .eof(), .complete(), .total(), .sram_out(), .hist_addr());

  t05_findLeastValue findLeastValue (.clk(hwclk), .rst(reset), .compVal(), .state(), .sum(sum), .charWipe1(), .charWipe2(), 
    .least1(least1), .least2(least2), .count(), .fin(), .nextCharEn());

  t05_hTree hTree (.clk(hwclk), .rst_n(reset), .least1(least1), .least2(least2), .sum(sum), .nulls(), .HT_en(), .SRAM_finished(),
   .tree_reg(), .null1_reg(), .null2_reg(), .clkCount(), .nullSumIndex(), .HT_Finished(), .HT_fin_reg(),
   .error(), .WorR());

  //Curr_state should be changed to logic can not pass typedefs through instantiation
  t05_cb_synthesis cb_syn (.clk(hwclk), .rst(reset), .max_index(index_of_root), .h_element(), .write_finish(), .char_found(char_found),
   .char_path(), .char_index(), .curr_state(), .curr_index(), .curr_path(), .least1(least1), .least2(least2), .finished(), .track_length(), .pos());

  t05_header_synthesis header_synthesis (.clk(hwclk), .rst(reset), .char_index(), .char_found(char_found), .least1(least1),
   .least2(least2), .char_path(), .header(), .enable(), .bit1(writeBit), .write_finish());

  t05_translation translation (.clk(hwclk), .rst(reset), .totChar(), .charIn(), .path(), .writeBin(writeBit), .nextCharEn(), .outEn());

  t05_spiClockDivider spiClockDivider (
    .current_clock_signal(hwclk), .reset(reset), .divided_clock_signal(serial_clk), .sclk(sclk), .freq_flag(flag));

  t05_SPI SPI (.mosi(right[6]), .miso(pb[18]), .rst(pb[19]), .serial_clk(serial_clk), 
    .clk(hwclk), .slave_select(green), .read_output(read_out), .writebit(writeBit), .read_en(pb[4]), 
    .write_en(pb[6]), .read_stop(pb[1]), .read_address(32'd0), .write_address(32'd0), .finish(ss0[0]), .freq_flag(flag));

  assign ss1[6] = sclk; // Connect the serial clock to one of the slave select lines for debugging
  team_05 team_05_inst (
    .clk(hwclk),
    .nrst(~reset),
    .en(1'b1),

    .gpio_in(gpio_in),
    .gpio_out(gpio_out),
    .gpio_oeb(),  // don't really need it here since it is an output

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