// module t05_backpack (
//     input logic clk, rst,
    
//     // Control interface
//     input logic send_data,              // Trigger to start sending data
//     input logic send_mode,              // 0=send 10 bits, 1=send all 320 bits
//     input logic init_mode,              // 1=initialization mode (adds 5ms delays)
//     input logic [319:0] full_display,   // Complete 320-bit display data
//     input logic [9:0] single_chunk,     // Single 10-bit chunk
    
//     // LCD physical interface (8-bit mode)
//     output logic rs, rw, en,            // LCD control signals
//     output logic [7:0] lcd_data,        // 8-bit data bus to LCD
    
//     // Status outputs
//     output logic busy,                  // Module is transmitting
//     output logic done,                  // Transmission complete
//     output logic ready                  // Ready for next operation
// );

//     // Timing parameters (adjust for your clock frequency)
//     parameter SETUP_TIME = 16'd100;     // Setup time before enable pulse (increased)
//     parameter ENABLE_TIME = 16'd200;    // Enable pulse width (increased)
//     parameter HOLD_TIME = 16'd100;      // Hold time after enable (increased)
//     parameter INIT_DELAY = 32'd5000;  // 5ms delay for initialization commands (assuming 100MHz clock)

//     // State machine for LCD timing
//     typedef enum logic [3:0] {
//         IDLE,
//         LOAD_DATA,
//         SETUP_CHAR,
//         ENABLE_HIGH,
//         ENABLE_LOW,
//         INIT_DELAY_STATE,   // New state for 5ms delay between init commands
//         NEXT_CHAR,
//         COMPLETE
//     } lcd_state_t;
    
//     lcd_state_t state, next_state;
    
//     // Internal registers
//     logic [319:0] display_buffer;       // Buffer for display data
//     logic [5:0] char_count;             // Character counter (0-31)
//     logic [31:0] timing_counter;        // Timing counter (expanded to 32-bit for 5ms delay)
//     logic [9:0] current_chunk;          // Current 10-bit chunk being processed
//     logic [7:0] current_data;           // Current 8-bit data
//     logic current_rs, current_rw;       // Current control signals
//     logic send_mode_reg;                // Registered send mode
//     logic [5:0] total_chars;            // Total characters to send
//     logic is_init_mode;                 // Flag to indicate if we're in initialization mode
    
//     // Sequential logic
//     always_ff @(posedge clk or posedge rst) begin
//         if (rst) begin
//             state <= IDLE;
//             char_count <= 0;
//             timing_counter <= 0;
//             display_buffer <= 320'b0;
//             send_mode_reg <= 0;
//             total_chars <= 0;
//             is_init_mode <= 0;
//         end else begin
//             state <= next_state;
            
//             case (state)
//                 IDLE: begin
//                     if (send_data) begin
//                         // Load data based on mode
//                         if (send_mode) begin
//                             display_buffer <= full_display;
//                             send_mode_reg <= 1;
//                             total_chars <= 32;  // All 32 characters
//                         end else begin
//                             display_buffer[9:0] <= single_chunk;
//                             send_mode_reg <= 0;
//                             total_chars <= 1;   // Just 1 character
//                         end
//                         char_count <= 0;
//                         timing_counter <= 0;
//                         is_init_mode <= init_mode;  // Capture initialization mode
//                     end
//                 end
                
//                 LOAD_DATA: begin
//                     // Extract current 10-bit chunk
//                     current_chunk <= display_buffer[char_count*10 +: 10];
//                     timing_counter <= 0;
//                 end
                
//                 SETUP_CHAR, ENABLE_HIGH, ENABLE_LOW: begin
//                     timing_counter <= timing_counter + 1;
//                 end
                
//                 INIT_DELAY_STATE: begin
//                     timing_counter <= timing_counter + 1;
//                 end
                
//                 NEXT_CHAR: begin
//                     char_count <= char_count + 1;
//                     timing_counter <= 0;
//                 end
                
//                 COMPLETE: begin
//                     char_count <= 0;
//                     timing_counter <= 0;
//                 end
                
//                 default: begin
//                     char_count <= 0;
//                     timing_counter <= 0;
//                 end
//             endcase
//         end
//     end
    
//     // Combinational logic for state transitions and outputs
//     always_comb begin
//         next_state = state;
//         rs = 1'b0;              // Default values
//         rw = 1'b0;
//         en = 1'b0;
//         lcd_data = 8'h20;       // Default space character
//         busy = 1'b0;
//         done = 1'b0;
//         ready = 1'b0;
//         current_data = 8'h20;   // Default space character
//         current_rs = 1'b0;      // Default to command mode
//         current_rw = 1'b0;      // Default to write mode
        
//         // Extract control and data bits from current chunk
//         // 10-bit format: {RS, RW, D7, D6, D5, D4, D3, D2, D1, D0}
//         if (state != IDLE) begin
//             current_rs = current_chunk[9];      // RS bit
//             current_rw = current_chunk[8];      // RW bit  
//             current_data = current_chunk[7:0];  // 8-bit data (D7-D0)
//         end
        
//         case (state)
//             IDLE: begin
//                 ready = 1'b1;
//                 if (send_data) begin
//                     next_state = LOAD_DATA;
//                 end
//             end
            
//             LOAD_DATA: begin
//                 busy = 1'b1;
//                 next_state = SETUP_CHAR;
//             end
            
//             SETUP_CHAR: begin
//                 busy = 1'b1;
//                 lcd_data = current_data;    // Put data on bus
//                 rs = current_rs;            // Set register select
//                 rw = current_rw;            // Set read/write
//                 en = 1'b1;                  // Start with enable HIGH
                
//                 if (timing_counter >= SETUP_TIME) begin
//                     next_state = ENABLE_HIGH;
//                 end
//             end
            
//             ENABLE_HIGH: begin
//                 busy = 1'b1;
//                 lcd_data = current_data;    // Maintain data
//                 rs = current_rs;            // Maintain RS
//                 rw = current_rw;            // Maintain RW
//                 en = 1'b1;                  // Keep enable high during setup
                
//                 if (timing_counter >= ENABLE_TIME) begin
//                     next_state = ENABLE_LOW;
//                 end
//             end
            
//             ENABLE_LOW: begin
//                 busy = 1'b1;
//                 lcd_data = current_data;    // Maintain data
//                 rs = current_rs;            // Maintain RS
//                 rw = current_rw;            // Maintain RW
//                 en = 1'b0;                  // Enable pulse LOW - LCD latches on falling edge
                
//                 if (timing_counter >= HOLD_TIME) begin
//                     if (char_count < (total_chars - 1)) begin
//                         // Check if we need initialization delay
//                         if (is_init_mode) begin
//                             next_state = INIT_DELAY_STATE;
//                         end else begin
//                             next_state = NEXT_CHAR;
//                         end
//                     end else begin
//                         next_state = COMPLETE;
//                     end
//                 end
//             end
            
//             INIT_DELAY_STATE: begin
//                 busy = 1'b1;
//                 // 5ms delay between initialization commands
//                 if (timing_counter >= INIT_DELAY) begin
//                     next_state = NEXT_CHAR;
//                 end
//             end
            
//             NEXT_CHAR: begin
//                 busy = 1'b1;
//                 next_state = LOAD_DATA;
//             end
            
//             COMPLETE: begin
//                 done = 1'b1;
//                 next_state = IDLE;
//             end
            
//             default: begin
//                 ready = 1'b0;
//                 busy = 1'b0;
//                 done = 1'b0;
//                 next_state = IDLE;
//             end
//         endcase
//     end

// endmodule