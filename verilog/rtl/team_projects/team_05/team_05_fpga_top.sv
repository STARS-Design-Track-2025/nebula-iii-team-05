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
  
  // Team 05 Design Instance
  t05_spiClockDivider spiClockDivider (
    .current_clock_signal(hwclk),
    .reset(reset),
    .divided_clock_signal(serial_clk),
    .sclk(sclk) // Not used in this context, but can be connected if needed
  );

  t05_SPI test (.mosi(right[6]), .miso(pb[18]), .rst(pb[19]), .serial_clk(serial_clk), .clk(hwclk), .slave_select(green), .read_output(), .writebit(pb[5]), .read_en(pb[4]), .write_en(pb[6]), .read_stop(pb[1]), .read_address(32'd0), .write_address(32'd0), .finish(ss0[0]));

  assign ss1[6] = sclk; // Connect the serial clock to one of the slave select lines for debugging
  team_05 team_05_inst (
    .clk(hwclk),
    .nrst(~reset),
    .en(1'b1),

    .gpio_in(gpio_in),
    .gpio_out(gpio_out),
    .gpio_oeb(),  // don't really need it her since it is an output

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
