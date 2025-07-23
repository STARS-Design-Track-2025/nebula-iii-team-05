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
    // output wire [31:0] ADR_O,
    // output wire [31:0] DAT_O,
    // output wire [3:0]  SEL_O,
    // output wire        WE_O,
    // output wire        STB_O,
    // output wire        CYC_O,
    // input wire [31:0]  DAT_I,
    // input wire         ACK_I,

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
    assign gpio_out = '0;
    assign gpio_oeb = '0;

    logic serial_clk;
    logic sclk;
    logic flag;
    logic [7:0] read_out;
    logic [8:0] least1, least2;
    logic [45:0] sum;
    logic [7:0] index_of_root;
    
    //CONTROLLER
    logic [3:0] en_state, fin_state;

    //HISTO SRAM
    logic [31:0] sram_in, sram_out;

    //Histo to TRN
    logic [31:0] totChar;

    //CB To Header Syn
    logic char_found;
    logic [7:0] char;
    logic [2:0] CB_state;
    logic nextCharEn;

    //FLV SRAM
    logic [7:0] count;
    logic [63:0] compVal;
    logic [7:0] cw1, cw2;

    //To SPI
    logic writeBit;

    t05_histogram histogram (.clk(clk), .rst(nrst), .addr_i(read_out), .sram_in(sram_in), .eof(fin_state), .complete(),
    .total(totChar), .sram_out(sram_out), .hist_addr());

    t05_findLeastValue findLeastValue (.clk(clk), .rst(nrst), .compVal(compVal), .state(en_state), .sum(sum), .charWipe1(cw1), .charWipe2(cw2), 
    .least1(least1), .least2(least2), .count(count), .fin(fin_state), .nextCharEn(nextCharEn));

endmodule