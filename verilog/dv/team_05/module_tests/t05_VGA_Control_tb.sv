// Testbench for VGA Control Module
// Tests all screen transitions and display states
// Author: Team 05

`timescale 1ns / 1ps

module t05_VGA_Control_tb;

    // Testbench signals
    logic clk_25mhz;
    logic rst;
    logic [2:0] system_state;
    logic [3:0] progress;
    logic select_compression;
    logic start_selected;
    logic [9:0] hpos, vpos;
    logic red_out, green_out, blue_out;
    logic [2:0] current_screen;
    
    // VGA Driver signals for simulation
    logic [9:0] h_count, v_count;
    logic h_active, v_active;
    
    // Loop variables
    integer state, i;
    
    // DUT instantiation
    t05_VGA_Control dut (
        .clk_25mhz(clk_25mhz),
        .rst(rst),
        .system_state(system_state),
        .progress(progress),
        .select_compression(select_compression),
        .start_selected(start_selected),
        .hpos(hpos),
        .vpos(vpos),
        .red_out(red_out),
        .green_out(green_out),
        .blue_out(blue_out),
        .current_screen(current_screen)
    );
    
    // Clock generation (25MHz)
    initial begin
        clk_25mhz = 0;
        forever #20 
        clk_25mhz = ~clk_25mhz; // 25MHz = 40ns period
    end
    
    
    // Test sequence
    initial begin
        $dumpfile("t05_VGA_Control.vcd");
        $dumpvars(0, t05_VGA_Control_tb);
        
        // Initialize signals
      
endmodule
