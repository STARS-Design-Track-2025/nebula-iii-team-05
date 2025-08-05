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
  logic [9:0] out;
  logic out_valid;
  // logic lcd_en, lcd_rw, lcd_rs;
  t05_driver_1602 #(
    .clk_div(24_000)
  ) lcd1602 (
  .clk(hwclk),
  .rst(~reset),      // active-high reset
  // 16 characters per row, each character is 8 bits, total 128 bits (row_1[127:120] is first char)
  .row_1(127'h42_49_47_47_49_45_20_73_6D_61_6C_6C_73_20_20_20),
  .row_2(127'h48_75_66_66_6D_61_6E_20_43_6F_6D_70_72_65_73_73),
  // LCD interface signals
  .out(out),
  .out_valid(out_valid)
  );

  logic start, sdo, sclk, cs_n, busy, done;
  logic [9:0] data_in;

  assign start = out_valid;
  assign data_in = out;

  t05_1602_spi #(
    .WIDTH(10),                    // Number of bits to transmit
    .CLK_DIV(40)                   // Clock divider (system_clk / CLK_DIV = spi_clk)
  ) spi (
    .clk    (hwclk),    // System clock
    .rst_n  (~reset),   // Active low reset
    .start  (start),    // Start transmission (pulse)
    .data_in(data_in),  // Data to transmit
    .sdo    (sdo),      // Serial data out (MOSI)
    .sclk   (sclk),     // SPI clock
    .cs_n   (cs_n),     // Chip select (active low)
    .busy   (busy),     // Transmission in progress
    .done   (done)      // Transmission complete (pulse)
);

  assign {ss0[6], ss0[5], ss0[0], ss7[4], ss0[2], ss0[1], right[0], ss0[7]} = {cs_n, sdo, sclk};
  assign ss0[3] = out[8];
  assign ss0[4] = out[9];
  // assign  ss1[7] = lcd_en;

endmodule