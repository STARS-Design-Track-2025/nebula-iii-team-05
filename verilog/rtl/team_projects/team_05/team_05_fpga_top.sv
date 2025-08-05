`default_nettype none
// Empty top module

module top (
  // I/O ports
  input  logic hz100, reset,
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
  // VGA signals
  logic clk_25mhz;
  logic [10:0] hpos_full, vpos_full;  // Full width from VGA driver
  logic hsync, vsync;
  logic vga_red, vga_green, vga_blue;
  logic red_in, green_in, blue_in;
  
  // Controller interface signals
  logic [2:0] system_state;
  logic select_compression;
  logic start_selected;
  logic [2:0] current_screen;
  
  // Clock divider for 25MHz VGA clock (assuming 100MHz input)
  assign clk_25mhz = hz100; // Divide by 4: 100MHz/4 = 25MHz
  
  // Simple pushbutton-driven controller for VGA
  logic [31:0] demo_counter;
  logic [2:0] button_counter;  // 3-bit counter for system state
  
  // Synchronize button inputs to avoid metastability
  logic [4:0] pb_sync, pb_prev;
  logic button2_edge, button3_edge, button4_edge;
  logic software_reset;  // Software reset from pb[3]
  logic combined_reset;  // Combined hardware + software reset
  logic start_selected_prev;  // Track start button edge
  logic start_edge;  // Edge detection for start button
  
  // Combined reset logic
  assign combined_reset = reset || software_reset;
  
  always_ff @(posedge clk_25mhz, posedge reset) begin
    if (reset) begin
      pb_sync <= 5'b00000;
      pb_prev <= 5'b00000;
      button_counter <= 3'b000;
      demo_counter <= 0;
      software_reset <= 1'b0;
      start_selected_prev <= 1'b0;
    end else begin
      pb_sync <= {pb[4], pb[3], pb[2], pb[1], pb[0]};
      pb_prev <= pb_sync;
      demo_counter <= demo_counter + 1;
      start_selected_prev <= pb_sync[1];
      
      // Button 3: Software reset (hold for reset)
      software_reset <= pb_sync[3];
      
      // Reset state counter when compression mode is selected (start button rising edge)
      if (start_edge && !software_reset) begin
        button_counter <= 3'b000;
      end
      // Increment counter on button 2 rising edge
      else if (button2_edge && !software_reset) begin
        button_counter <= button_counter + 1;
      end
      // Decrement counter on button 4 rising edge
      else if (button4_edge && !software_reset) begin
        button_counter <= button_counter - 1;
      end
    end
  end
  
  // Edge detection for buttons
  assign button2_edge = pb_sync[2] && !pb_prev[2];
  assign button3_edge = pb_sync[3] && !pb_prev[3];
  assign button4_edge = pb_sync[4] && !pb_prev[4];
  assign start_edge = pb_sync[1] && !start_selected_prev;
  
  // Connect button counter to system state and controls
  assign system_state = button_counter;        // 3-bit counter drives system state
  assign select_compression = pb_sync[0];      // Button 0 controls compression selection
  assign start_selected = pb_sync[1];          // Button 1 controls start selection
  
  // Button-driven controller (runs on VGA clock domain)
  // always_ff @(posedge clk_25mhz, posedge reset) begin
  //   if (reset) begin
  //     demo_counter <= 0;
  //     system_state <= 3'b000;
  //     select_compression <= 1'b0;
  //     start_selected <= 1'b0;
  //   end else begin
  //     // Always increment counter for timing reference
  //     demo_counter <= demo_counter + 1;
      
  //     // Direct button control
  //     select_compression <= pb_sync[0];  // pb[0] controls compression selection
  //     start_selected <= pb_sync[1];      // pb[1] controls start
      
  //     // pb[2] cycles through system states for demo
  //     if (pb_sync[2]) begin
  //       // Cycle through states when button 2 is pressed
  //       case (demo_counter[22:20]) // Change every ~0.17 seconds at 25MHz
  //         3'b000: system_state <= 3'b000; // IDLE
  //         3'b001: system_state <= 3'b001; // COMPRESS
  //         3'b010: system_state <= 3'b010; // DECOMPRESS  
  //         3'b011: system_state <= 3'b011; // State 3
  //         3'b100: system_state <= 3'b100; // State 4
  //         3'b101: system_state <= 3'b101; // State 5
  //         default: system_state <= 3'b000;
  //       endcase
  //     end
  //     // If no button pressed, stay in idle state
  //     else if (!pb_sync[1] && !pb_sync[0]) begin
  //       system_state <= 3'b000;
  //     end
  //   end
  // end
  
  // VGA Driver instantiation
  t05_VGA_Driver_param vga_driver (
    .clk(clk_25mhz),
    .nrst(~combined_reset),  // Use combined reset (hardware + software)
    .enable(1'b1),
    
    // RGB inputs from VGA control
    .Rin(red_in),
    .Gin(green_in),
    .Bin(blue_in),
    
    // VGA outputs
    .hsync(hsync),
    .vsync(vsync),
    .Rout(vga_red),
    .Gout(vga_green),
    .Bout(vga_blue),
    
    // Position outputs for VGA control
    .hpos(hpos_full),
    .vpos(vpos_full)
  );
  
  
  // VGA Control instantiation
  t05_VGA_Control vga_control (
    .clk_25mhz(clk_25mhz),
    .rst(combined_reset),  // Use combined reset (hardware + software)
    
    // Controller interface
    .system_state(system_state),
    .select_compression(select_compression),
    .start_selected(start_selected),
    
    // VGA driver interface
    .hpos(hpos_full),
    .vpos(vpos_full),
    .red_out(red_in),
    .green_out(green_in),
    .blue_out(blue_in),
    
    // Debug output
    .current_screen(current_screen)
  );
  
  // Output assignments - VGA signals to right port bits
  assign right[0] = vga_red;    // VGA red to right[0]
  assign right[1] = vga_green;  // VGA green to right[1]
  assign right[2] = vga_blue;   // VGA blue to right[2]
  assign right[3] = hsync;      // VGA HS to right[3]
  assign right[4] = vsync;      // VGA VS to right[4]
  assign right[7:5] = system_state; // Debug: show system state
  
  // Use left display for debug info
  assign left[2:0] = current_screen;  // Show current screen
  assign left[5:3] = system_state;    // Show system state
  assign left[6] = select_compression; // Show compression selection
  assign left[7] = start_selected;     // Show start status

  // Main RGB outputs (same as VGA outputs)
  assign red = vga_red;
  assign green = vga_green;
  assign blue = vga_blue;
  
  // // Assign 7-segment displays to show VGA timing
  // assign ss7 = hpos[7:0];        // Show horizontal position
  // assign ss6 = {6'b0, hpos[9:8]}; // Show upper bits of hpos
  // assign ss5 = vpos[7:0];        // Show vertical position  
  // assign ss4 = {6'b0, vpos[9:8]}; // Show upper bits of vpos
  // assign ss3 = {5'b0, hsync, vsync, clk_25mhz}; // Show sync signals
  // assign ss2 = {5'b0, current_screen}; // Show current screen
  // assign ss1 = {5'b0, system_state}; // Show state
  // assign ss0 = demo_counter[31:24]; // Show demo counter
  
  // // UART passthrough (not used for VGA)
  // assign txdata = 8'h00;
  // assign txclk = 1'b0;
  // assign rxclk = 1'b0;



//   logic [3:0] state, state_n;
  
//   // Backpack interface signals
//   logic [5:0] count; 
//   logic [319:0] data;
//   logic [9:0] single_chunk;
//   logic backpack_busy;
//   logic backpack_done;
//   logic backpack_ready;
  
//   // ← ADD: Standardized delay signals
//   logic start_delay_n,start_delay_n2;
//   logic delay_done,delay_done2;
  
//   // LCD signals from backpack
//   logic lcd_rs, lcd_rw, lcd_en;
//   logic [7:0] lcd_data;
//   logic bf;

// always_comb begin
//   state_n = state;
//   if (edge_detected) begin
//     case(pb[8:0])
//         9'b000000001: state_n = 4'b0001; // State 1
//         9'b000000010: state_n = 4'b0010; // State 2
//         9'b000000100: state_n = 4'b0011; // State 3
//         9'b000001000: state_n = 4'b0100; // State 4
//         9'b000010000: state_n = 4'b0101; // State 5
//         9'b000100000: state_n = 4'b0110; // State 6
//         9'b001000000: state_n = 4'b0111; // State 7
//         9'b010000000: state_n = 4'b1000; // State 8
//         9'b100000000: state_n = 4'b1001; // State 9
//         default:      state_n = 4'b0000; // Default state
//     endcase
//   end
// end

// logic strobe_mid, strobe_sync, strobe_prev;
// logic edge_detected;
// always_ff @(posedge hz100, posedge reset) begin
//   if (reset) begin
//     strobe_mid <= 0;
//     strobe_sync <= 0;
//     strobe_prev <= 0;
//     state <= 0;
//   end else begin
//     strobe_mid <= |pb[8:0];
//     strobe_sync <= strobe_mid;
//     strobe_prev <= strobe_sync;
//     state <= state_n;
//   end
// end

// assign edge_detected = strobe_sync && !strobe_prev;

//   // Display Control Module
//   t05_displayControl display_ctrl(
//     .clk(hz100),
//     .rst(reset),
//     .compDecomp(pb[18]),
//     .isFinished(pb[17]),
//     .contState_n(state),
    
//     // Backpack interface
//     .backpack_busy(backpack_busy),
//     .backpack_done(backpack_done),
//     .data_reg(data),
//     .count(count),
//     .mode_o(right[2:0]),
//     .start_delay_n(start_delay_n),      // ← Display Control OUTPUTS this
//     .delay_done(delay_done)             // ← Display Control INPUTS this
//   );
  
//   // LCD Backpack Module
//   t05_backpack lcd_backpack(
//     .clk(hz100),
//     .rst(reset),
//     .data(data),
//     .count_n(count),
//     .lcd_data({right[6:5],left[7:0]}),
//     .lcd_en(right[7]),
//     .backpack_busy(backpack_busy),
//     .backpack_done(backpack_done),
//     .start_delay_n(start_delay_n2),  // Backpack doesn't need this
//     .delay_done(delay_done2)         // Backpack doesn't output this
//   );

//   t05_delayClk delayClk_dispCont (
//       .clk(hz100),
//       .rst(reset),
//       .delay_start(start_delay_n),        // ← FIX: DelayClk uses delay_start, not delay_start_n
//       .delay_done(delay_done)             // ← DelayClk OUTPUTS this
//   );

//   t05_delayClk delayClk_backpack (
//       .clk(hz100),
//       .rst(reset),
//       .delay_start(start_delay_n2),        // ← FIX: DelayClk uses delay_start, not delay_start_n
//       .delay_done(delay_done2)             // ← DelayClk OUTPUTS this
//   );
//   assign red = backpack_busy;
//   assign green = backpack_done;
//   assign blue = 1'b0;
  
//   // Assign 7-segment displays to avoid warnings
//   assign ss7 = 8'b0;
//   assign ss6 = 8'b0;
//   assign ss5 = 8'b0;
//   assign ss4 = 8'b0;
//   assign ss3 = 8'b0;
//   assign ss2 = 8'b0;
//   assign ss1 = 8'b0;
//   assign ss0 = 8'b0;

endmodule

