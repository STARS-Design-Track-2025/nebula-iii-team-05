`default_nettype none

// FPGA top module for Team 00

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
  
  // Assign GPIO outputs to SSDs
  assign {ss7, ss6, ss5, ss4, ss3[7:6]} = gpio_out;
  
  // Team 00 Design Instance
  team_00 team_00_inst (
    .clk(hwclk),
    .nrst(~reset),
    .en(1'b1),

    .gpio_in(gpio_in),
    .gpio_out(gpio_out),
    .gpio_oeb(),  // don't really need it her since it is an output

    // Uncomment only if using LA
    .la_data_in({30'b0, pb[1], ~pb[0]}),
    .la_data_out(),
    .la_oenb({{30{1'b1}}, 2'b00}),

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
    .prescaler(14'd1000),  // each output will be high for 250 ms
    .done(blue)
  );

  
  // WISHBONE MANAGER TEST!!


  // logic wbs_ack_i, wbs_we_o, wbs_stb_o, wbs_cyc_o;
  // logic [3:0] wbs_sel_o;
  // logic [31:0] wbs_dat_i, wbs_adr_o, wbs_dat_o;
  // logic [31:0] data_out;
  
  // // Wishbone Manager
  //   wishbone_manager manager(
  //       .CLK(hwclk),
  //       .nRST(~pb[19]),

  //       .DAT_I(wbs_dat_i),
  //       .ACK_I(wbs_ack_i),

  //       .WRITE_I(pb[1]),
  //       .READ_I(pb[0]),
  //       .ADR_I({28'h0, pb[7:4]}),
  //       .CPU_DAT_I(32'h12345678),
  //       .SEL_I('1),

  //       //outputs
  //       .ADR_O(wbs_adr_o),
  //       .DAT_O(wbs_dat_o),
  //       .SEL_O(wbs_sel_o),
  //       .WE_O(wbs_we_o),
  //       .STB_O(wbs_stb_o),
  //       .CYC_O(wbs_cyc_o),

  //       .CPU_DAT_O(data_out),
  //       .BUSY_O(red)
  //   );

  //   // SRAM
  //   sram_WB_Wrapper sram (

  //       .wb_clk_i(hwclk),
  //       .wb_rst_i(pb[19]),

  //       // MGMT SoC Wishbone Slave

  //       .wbs_stb_i(wbs_stb_o),
  //       .wbs_cyc_i(wbs_cyc_o),
  //       .wbs_we_i(wbs_we_o),
  //       .wbs_sel_i(wbs_sel_o),
  //       .wbs_dat_i(wbs_dat_o),
  //       .wbs_adr_i(wbs_adr_o),
  //       .wbs_ack_o(wbs_ack_i),
  //       .wbs_dat_o(wbs_dat_i)
  //   );

  //   // SSDECs
  //   t00_ssdec ssdec0 (
  //     .in(data_out[3:0]),
  //     .enable(1),
  //     .out(ss0)
  //   );

  //   t00_ssdec ssdec1 (
  //     .in(data_out[7:4]),
  //     .enable(1),
  //     .out(ss1)
  //   );

  //   t00_ssdec ssdec2 (
  //     .in(data_out[11:8]),
  //     .enable(1),
  //     .out(ss2)
  //   );

  //   t00_ssdec ssdec3 (
  //     .in(data_out[15:12]),
  //     .enable(1),
  //     .out(ss3)
  //   );

  //   t00_ssdec ssdec4 (
  //     .in(data_out[19:16]),
  //     .enable(1),
  //     .out(ss4)
  //   );

  //   t00_ssdec ssdec5 (
  //     .in(data_out[23:20]),
  //     .enable(1),
  //     .out(ss5)
  //   );

  //   t00_ssdec ssdec6 (
  //     .in(data_out[27:24]),
  //     .enable(1),
  //     .out(ss6)
  //   );

  //   t00_ssdec ssdec7 (
  //     .in(data_out[31:28]),
  //     .enable(1),
  //     .out(ss7)
  //   );

endmodule
