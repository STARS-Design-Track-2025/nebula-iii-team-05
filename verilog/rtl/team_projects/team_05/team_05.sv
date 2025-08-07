// $Id: $
// File name:   team_05.sv
// Created:     
// Author:      
// Description: 

`default_nettype none

module team_05 (
    `ifdef USE_POWER_PINS
        inout vccd1,	// User area 1 1.8V supply
        inout vssd1,	// User area 1 digital ground
    `endif
    // HW
    input logic clk, nrst,
    
    input logic en, //This signal is an enable signal for your chip. Your design should disable if this is low.
    
    // Logic Analyzer - Grant access to all 128 LA
    // input logic [31:0] la_data_in,
    // output logic [31:0] la_data_out,
    // input logic [31:0] la_oenb,


    // Wishbone master interface
    output wire [31:0] ADR_O,
    output wire [31:0] DAT_O,
    output wire [3:0]  SEL_O,
    output wire        WE_O,
    output wire        STB_O,
    output wire        CYC_O,
    input wire [31:0]  DAT_I,
    input wire         ACK_I,

    // 34 out of 38 GPIOs (Note: if you need up to 38 GPIO, discuss with a TA)
    input  logic [33:0] gpio_in, // Breakout Board Pins
    output logic [33:0] gpio_out, // Breakout Board Pins
    output logic [33:0] gpio_oeb // Active Low Output Enable
    
    /*
    * Add other I/O ports that you wish to interface with the
    * Wishbone bus to the management core. For examples you can 
    * add registers that can be written to with the Wishbone bus
    */

    // You can also have input registers controlled by the Caravel Harness's on chip processor
);

    
    // Set unused outputs to 0
    assign {gpio_out[33:2], gpio_out[1:0]} = '0;

    // Se OEBs
    assign gpio_oeb[10:2] = '1;  //Inputs
   // assign gpio_oeb[1] = '0;  //Outputs
    assign {gpio_oeb[33:11], gpio_oeb[1:0]} = '1;  //Unused set to all 1s (doesn't really matter)
    
    // T05 Top Instantiation
    t05_top top (
        .hwclk(clk), 
        .reset(~nrst | ~en),

        // HISTOGRAM
        .read_in_pulse(gpio_in[3]),
        .in(gpio_in[10:4]),
        .esp_ack(gpio_in[2]),

        //WRAPPER
        .wbs_stb_o(STB_O),
        .wbs_cyc_o(CYC_O),
        .wbs_we_o(WE_O),
        .wbs_sel_o(SEL_O),
        .wbs_dat_o(DAT_O),
        .wbs_adr_o(ADR_O),
        .wbs_ack_i(ACK_I),
        .wbs_dat_i(DAT_I)
    );

endmodule