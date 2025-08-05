// VGA Control Module for Huffman Compression System
// Displays title screen, selection menu, and progress screens
// Author: Team 05

module t05_VGA_Control (
    input logic clk_25mhz,          // 25MHz pixel clock for VGA
    input logic rst,                // Reset signal
    
    // Controller interface
    input logic [2:0] system_state, // Current system state from main controller
    input logic select_compression, // Selection input (1=compression, 0=decompression)
    input logic start_selected,     // Start button pressed
    
    // VGA Driver interface
    input logic [10:0] hpos,        // Full horizontal position (0-799 for 640x480)
    input logic [9:0] vpos,         // Full vertical position (0-524 for 640x480)
    output logic red_out, green_out, blue_out, // RGB outputs to VGA driver
    
    // Debug outputs
    output logic [2:0] current_screen // Current screen being displayed
);

    // Screen state definitions
    typedef enum logic [2:0] {
        SCREEN_TITLE,
        SCREEN_LOADING,
        SCREEN_SELECT,
        SCREEN_COMPRESS,
        SCREEN_DECOMPRESS,
        SCREEN_COMPLETE
    } screen_t;
    
    screen_t screen_state, next_screen_state;
    
    // System state definitions (matching your description)
    typedef enum logic [2:0] {
        STATE_IDLE,
        STATE_COMPRESS,
        STATE_DECOMPRESS,
        STATE_FINISHED
    } sys_state_t;
    
    // Internal signals
    logic [31:0] timer_counter;
    logic [3:0] loading_progress;
    logic [3:0] operation_progress;  // Internal progress (updates frequently)
    logic [3:0] display_progress;    // Display progress (updates slowly for smooth visual)
    logic [3:0] title_progress;      // Progress for title screen
    logic [2:0] prev_system_state;   // Track state changes
    logic [31:0] finished_timer;     // Timer for finished state delay
    logic in_finished_state;         // Flag to track if we're in finished state
    logic [31:0] display_update_counter; // Counter for display progress updates
    logic pixel_on;
    logic [7:0] char_x;
    logic [5:0] char_y;
    logic [2:0] pixel_x;  // 3 bits for 8-pixel character (0-7)
    logic [3:0] pixel_y;
    logic [7:0] current_char;
    
    // Standard 8x16 character positioning (no gaps)
    // 80 characters × 8 pixels = 640 pixels (perfect fit)
    // 30 characters × 16 pixels = 480 pixels (perfect fit)
    assign char_x = hpos[10:3];                  // Character position (0-79)
    assign char_y = {1'b0, vpos[8:4]};           // Character row (0-29)
    assign pixel_x = hpos[2:0];                  // Pixel within character (0-7)
    assign pixel_y = vpos[3:0];                  // Pixel within character (0-15)
    
    // Screen state machine
    always_ff @(posedge clk_25mhz or posedge rst) begin
        if (rst) begin
            screen_state <= SCREEN_TITLE;
            timer_counter <= 0;
            loading_progress <= 0;
            operation_progress <= 0;
            display_progress <= 0;
            title_progress <= 0;
            prev_system_state <= 3'b000;
            finished_timer <= 0;
            in_finished_state <= 0;
            display_update_counter <= 0;
        end else begin
            screen_state <= next_screen_state;
            prev_system_state <= system_state;
            
            // Timer for title screen (2 seconds at 25MHz)
            if (screen_state == SCREEN_TITLE) begin
                if (timer_counter < 50_000_000) begin // 2 seconds at 25MHz
                    timer_counter <= timer_counter + 1;
                end else begin
                    timer_counter <= 0;
                end
            end
            // Timer for loading screen (10 seconds at 25MHz)
            else if (screen_state == SCREEN_LOADING) begin
                if (timer_counter < 250_000_000) begin // 10 seconds
                    timer_counter <= timer_counter + 1;
                    loading_progress <= timer_counter[27:24]; // Update every ~0.67 seconds
                end else begin
                    timer_counter <= 0;
                    loading_progress <= 15; // Complete
                end
            end
            // Progress management for operation screens
            else if (screen_state == SCREEN_COMPRESS || screen_state == SCREEN_DECOMPRESS) begin
                // Reset progress when state changes or entering operation screen
                if (prev_system_state != system_state || 
                    (screen_state != next_screen_state && next_screen_state == screen_state)) begin
                    operation_progress <= 0;
                    display_progress <= 0;
                    timer_counter <= 0;
                    display_update_counter <= 0;
                end else begin
                    // Always increment display update counter
                    display_update_counter <= display_update_counter + 1;
                    
                    // Update display progress slowly (every ~0.33 seconds at 25MHz)
                    if (display_update_counter[22:0] == 0) begin // Update every 8.4M cycles (~0.33s)
                        if (display_progress < operation_progress) begin
                            display_progress <= display_progress + 1;
                        end else if (display_progress > operation_progress) begin
                            display_progress <= operation_progress; // Catch up immediately if behind
                        end
                    end
                    
                    // Increment internal progress based on current system state timing
                    case (system_state)
                        3'b000: begin // Creating Histogram - 2.5 seconds total (2s progress + 0.5s completion)
                            if (timer_counter < 50_000_000) begin // 2 seconds for progress
                                timer_counter <= timer_counter + 1;
                                // Use higher bits for slower progress updates
                                operation_progress <= (timer_counter[27:24] < 14) ? timer_counter[27:24] : 4'd14;
                            end else if (timer_counter < 62_500_000) begin // Additional 0.5 seconds at 100%
                                timer_counter <= timer_counter + 1;
                                operation_progress <= 15; // Show complete
                            end else begin
                                operation_progress <= 15; // Ready for state change
                            end
                        end
                        3'b001: begin // Finding Least Value - 2 seconds total (1.5s progress + 0.5s completion)
                            if (timer_counter < 37_500_000) begin // 1.5 seconds for progress
                                timer_counter <= timer_counter + 1;
                                operation_progress <= (timer_counter[27:24] < 14) ? timer_counter[27:24] : 4'd14;
                            end else if (timer_counter < 50_000_000) begin // Additional 0.5 seconds at 100%
                                timer_counter <= timer_counter + 1;
                                operation_progress <= 15; // Show complete
                            end else begin
                                operation_progress <= 15; // Ready for state change
                            end
                        end
                        3'b010: begin // Synthesizing Huffman Tree - 3.5 seconds total (3s progress + 0.5s completion)
                            if (timer_counter < 75_000_000) begin // 3 seconds for progress
                                timer_counter <= timer_counter + 1;
                                operation_progress <= (timer_counter[28:25] < 14) ? timer_counter[28:25] : 4'd14;
                            end else if (timer_counter < 87_500_000) begin // Additional 0.5 seconds at 100%
                                timer_counter <= timer_counter + 1;
                                operation_progress <= 15; // Show complete
                            end else begin
                                operation_progress <= 15; // Ready for state change
                            end
                        end
                        3'b011: begin // Synthesizing Codebook - 3 seconds total (2.5s progress + 0.5s completion)
                            if (timer_counter < 62_500_000) begin // 2.5 seconds for progress
                                timer_counter <= timer_counter + 1;
                                operation_progress <= (timer_counter[27:24] < 14) ? timer_counter[27:24] : 4'd14;
                            end else if (timer_counter < 75_000_000) begin // Additional 0.5 seconds at 100%
                                timer_counter <= timer_counter + 1;
                                operation_progress <= 15; // Show complete
                            end else begin
                                operation_progress <= 15; // Ready for state change
                            end
                        end
                        3'b100: begin // Translating - 1.5 seconds total (1s progress + 0.5s completion)
                            if (timer_counter < 25_000_000) begin // 1 second for progress
                                timer_counter <= timer_counter + 1;
                                operation_progress <= (timer_counter[26:23] < 14) ? timer_counter[26:23] : 4'd14;
                            end else if (timer_counter < 37_500_000) begin // Additional 0.5 seconds at 100%
                                timer_counter <= timer_counter + 1;
                                operation_progress <= 15; // Show complete
                            end else begin
                                operation_progress <= 15; // Ready for state change
                            end
                        end
                        3'b101: begin // Uploading to SD - 2 seconds total (1.5s progress + 0.5s completion)
                            if (timer_counter < 37_500_000) begin // 1.5 seconds for progress
                                timer_counter <= timer_counter + 1;
                                operation_progress <= (timer_counter[27:24] < 14) ? timer_counter[27:24] : 4'd14;
                            end else if (timer_counter < 50_000_000) begin // Additional 0.5 seconds at 100%
                                timer_counter <= timer_counter + 1;
                                operation_progress <= 15; // Show complete
                            end else begin
                                operation_progress <= 15; // Ready for state change
                            end
                        end
                        default: begin // Finished or other states
                            operation_progress <= 15; // Complete
                        end
                    endcase
                    
                    // If state advanced beyond what progress shows, jump progress to completion
                    if ((system_state == 3'b001 && operation_progress < 15) || // Moved to FLV
                        (system_state == 3'b010 && operation_progress < 15) || // Moved to HTREE
                        (system_state == 3'b011 && operation_progress < 15) || // Moved to CBS
                        (system_state == 3'b100 && operation_progress < 15) || // Moved to TRN
                        (system_state == 3'b101 && operation_progress < 15) || // Moved to SPI
                        (system_state >= 3'b110)) begin // Moved to DONE or beyond
                        operation_progress <= 15;
                    end
                end
            end
            
            // Track finished state and manage timer for complete screen delay
            if (system_state == STATE_FINISHED && (screen_state == SCREEN_COMPRESS || screen_state == SCREEN_DECOMPRESS)) begin
                if (!in_finished_state) begin
                    // Just entered finished state, start timer
                    in_finished_state <= 1;
                    finished_timer <= 0;
                end else begin
                    // Continue timing in finished state
                    finished_timer <= finished_timer + 1;
                end
            end else if (screen_state == SCREEN_SELECT) begin
                // Reset when returning to select screen
                in_finished_state <= 0;
                finished_timer <= 0;
            end
            
            // Reset timers only for screens that don't use them
            if (screen_state != SCREEN_TITLE && screen_state != SCREEN_LOADING && 
                screen_state != SCREEN_COMPRESS && screen_state != SCREEN_DECOMPRESS) begin
                timer_counter <= 0;
                loading_progress <= 0;
                operation_progress <= 0;
                display_progress <= 0;
                title_progress <= 0;
                display_update_counter <= 0;
            end
        end
    end
    
    // Next state logic
    always_comb begin
        case (screen_state)
            SCREEN_TITLE: begin
                if (timer_counter >= 50_000_000) // Wait for 2 seconds to complete
                    next_screen_state = SCREEN_LOADING;
                else
                    next_screen_state = SCREEN_TITLE;
            end
            
            SCREEN_LOADING: begin
                if (loading_progress >= 15)
                    next_screen_state = SCREEN_SELECT;
                else
                    next_screen_state = SCREEN_LOADING;
            end
            
            SCREEN_SELECT: begin
                if (start_selected) begin
                    if (select_compression)
                        next_screen_state = SCREEN_COMPRESS;
                    else
                        next_screen_state = SCREEN_DECOMPRESS;
                end else begin
                    next_screen_state = SCREEN_SELECT;
                end
            end
            
            SCREEN_COMPRESS: begin
                // Only show complete screen after 5 seconds in finished state
                if (system_state == STATE_FINISHED && finished_timer > 125_000_000) // 5 seconds at 25MHz
                    next_screen_state = SCREEN_COMPLETE;
                else
                    next_screen_state = SCREEN_COMPRESS;
            end
            
            SCREEN_DECOMPRESS: begin
                // Only show complete screen after 5 seconds in finished state
                if (system_state == STATE_FINISHED && finished_timer > 125_000_000) // 5 seconds at 25MHz
                    next_screen_state = SCREEN_COMPLETE;
                else
                    next_screen_state = SCREEN_DECOMPRESS;
            end
            
            SCREEN_COMPLETE: begin
                if (timer_counter > 75_000_000) // Show complete for 3 seconds
                    next_screen_state = SCREEN_SELECT;
                else
                    next_screen_state = SCREEN_COMPLETE;
            end
            
            default: next_screen_state = SCREEN_TITLE;
        endcase
    end
    
    // Character lookup function
    function logic [7:0] get_char_at_pos(input logic [7:0] x, input logic [5:0] y);
        // Only display characters in the active video area (640x480)
        if (x >= 80 || y >= 30) begin
            get_char_at_pos = " ";  // Blank for out-of-range positions
        end else begin
        case (screen_state)
            SCREEN_TITLE: begin
                // "Biggie Smalls, Huffman Compression" - centered around row 10
                if (y == 10) begin
                    case (x)
                        22: get_char_at_pos = "B";
                        23: get_char_at_pos = "i";
                        24: get_char_at_pos = "g";
                        25: get_char_at_pos = "g";
                        26: get_char_at_pos = "i";
                        27: get_char_at_pos = "e";
                        28: get_char_at_pos = " ";
                        29: get_char_at_pos = "S";
                        30: get_char_at_pos = "m";
                        31: get_char_at_pos = "a";
                        32: get_char_at_pos = "l";
                        33: get_char_at_pos = "l";
                        34: get_char_at_pos = "s";
                        35: get_char_at_pos = ",";
                        36: get_char_at_pos = " ";
                        37: get_char_at_pos = "H";
                        38: get_char_at_pos = "u";
                        39: get_char_at_pos = "f";
                        40: get_char_at_pos = "f";
                        41: get_char_at_pos = "m";
                        42: get_char_at_pos = "a";
                        43: get_char_at_pos = "n";
                        44: get_char_at_pos = " ";
                        45: get_char_at_pos = "C";
                        46: get_char_at_pos = "o";
                        47: get_char_at_pos = "m";
                        48: get_char_at_pos = "p";
                        49: get_char_at_pos = "r";
                        50: get_char_at_pos = "e";
                        51: get_char_at_pos = "s";
                        52: get_char_at_pos = "s";
                        53: get_char_at_pos = "i";
                        54: get_char_at_pos = "o";
                        55: get_char_at_pos = "n";
                        default: get_char_at_pos = " ";
                    endcase
                end else begin
                    get_char_at_pos = " ";
                end
            end
            
            SCREEN_LOADING: begin
                // Title + loading bar
                if (y == 8) begin
                    case (x)
                        22: get_char_at_pos = "B";
                        23: get_char_at_pos = "i";
                        24: get_char_at_pos = "g";
                        25: get_char_at_pos = "g";
                        26: get_char_at_pos = "i";
                        27: get_char_at_pos = "e";
                        28: get_char_at_pos = " ";
                        29: get_char_at_pos = "S";
                        30: get_char_at_pos = "m";
                        31: get_char_at_pos = "a";
                        32: get_char_at_pos = "l";
                        33: get_char_at_pos = "l";
                        34: get_char_at_pos = "s";
                        35: get_char_at_pos = ",";
                        36: get_char_at_pos = " ";
                        37: get_char_at_pos = "H";
                        38: get_char_at_pos = "u";
                        39: get_char_at_pos = "f";
                        40: get_char_at_pos = "f";
                        41: get_char_at_pos = "m";
                        42: get_char_at_pos = "a";
                        43: get_char_at_pos = "n";
                        44: get_char_at_pos = " ";
                        45: get_char_at_pos = "C";
                        46: get_char_at_pos = "o";
                        47: get_char_at_pos = "m";
                        48: get_char_at_pos = "p";
                        49: get_char_at_pos = "r";
                        50: get_char_at_pos = "e";
                        51: get_char_at_pos = "s";
                        52: get_char_at_pos = "s";
                        53: get_char_at_pos = "i";
                        54: get_char_at_pos = "o";
                        55: get_char_at_pos = "n";
                        default: get_char_at_pos = " ";
                    endcase
                end else if (y == 12) begin
                    // Loading text
                    case (x)
                        35: get_char_at_pos = "L";
                        36: get_char_at_pos = "o";
                        37: get_char_at_pos = "a";
                        38: get_char_at_pos = "d";
                        39: get_char_at_pos = "i";
                        40: get_char_at_pos = "n";
                        41: get_char_at_pos = "g";
                        42: get_char_at_pos = ".";
                        43: get_char_at_pos = ".";
                        44: get_char_at_pos = ".";
                        default: get_char_at_pos = " ";
                    endcase
                end else if (y == 14) begin
                    // Progress bar - centered (20 chars wide: positions 30-49)
                    if (x >= 30 && x <= 49) begin
                        if (x == 30)
                            get_char_at_pos = 8'h01; // Left end cap
                        else if (x == 49)
                            get_char_at_pos = 8'h02; // Right end cap
                        else if (x <= (30 + {4'b0, loading_progress} + 1)) // +1 to account for left cap
                            get_char_at_pos = 8'h03; // Filled block
                        else
                            get_char_at_pos = 8'h04; // Empty block
                    end else begin
                        get_char_at_pos = " ";
                    end
                end else begin
                    get_char_at_pos = " ";
                end
            end
            
            SCREEN_SELECT: begin
                if (y == 8) begin
                    case (x)
                        30: get_char_at_pos = "S";
                        31: get_char_at_pos = "e";
                        32: get_char_at_pos = "l";
                        33: get_char_at_pos = "e";
                        34: get_char_at_pos = "c";
                        35: get_char_at_pos = "t";
                        36: get_char_at_pos = " ";
                        37: get_char_at_pos = "M";
                        38: get_char_at_pos = "o";
                        39: get_char_at_pos = "d";
                        40: get_char_at_pos = "e";
                        default: get_char_at_pos = " ";
                    endcase
                end else if (y == 12) begin
                    case (x)
                        25: get_char_at_pos = select_compression ? ">" : " ";
                        26: get_char_at_pos = " ";
                        27: get_char_at_pos = "C";
                        28: get_char_at_pos = "o";
                        29: get_char_at_pos = "m";
                        30: get_char_at_pos = "p";
                        31: get_char_at_pos = "r";
                        32: get_char_at_pos = "e";
                        33: get_char_at_pos = "s";
                        34: get_char_at_pos = "s";
                        35: get_char_at_pos = "i";
                        36: get_char_at_pos = "o";
                        37: get_char_at_pos = "n";
                        default: get_char_at_pos = " ";
                    endcase
                end else if (y == 14) begin
                    case (x)
                        25: get_char_at_pos = !select_compression ? ">" : " ";
                        26: get_char_at_pos = " ";
                        27: get_char_at_pos = "D";
                        28: get_char_at_pos = "e";
                        29: get_char_at_pos = "c";
                        30: get_char_at_pos = "o";
                        31: get_char_at_pos = "m";
                        32: get_char_at_pos = "p";
                        33: get_char_at_pos = "r";
                        34: get_char_at_pos = "e";
                        35: get_char_at_pos = "s";
                        36: get_char_at_pos = "s";
                        37: get_char_at_pos = "i";
                        38: get_char_at_pos = "o";
                        39: get_char_at_pos = "n";
                        default: get_char_at_pos = " ";
                    endcase
                end else begin
                    get_char_at_pos = " ";
                end
            end
            
            SCREEN_COMPRESS: begin
                if (y == 6) begin
                    case (x)
                        30: get_char_at_pos = "C";
                        31: get_char_at_pos = "o";
                        32: get_char_at_pos = "m";
                        33: get_char_at_pos = "p";
                        34: get_char_at_pos = "r";
                        35: get_char_at_pos = "e";
                        36: get_char_at_pos = "s";
                        37: get_char_at_pos = "s";
                        38: get_char_at_pos = "i";
                        39: get_char_at_pos = "o";
                        40: get_char_at_pos = "n";
                        default: get_char_at_pos = " ";
                    endcase
                end else if (y == 8) begin
                    // Current operation based on system_state
                    case (system_state)
                        3'b000: begin // Creating Histogram
                            case (x)
                                25: get_char_at_pos = "C";
                                26: get_char_at_pos = "r";
                                27: get_char_at_pos = "e";
                                28: get_char_at_pos = "a";
                                29: get_char_at_pos = "t";
                                30: get_char_at_pos = "i";
                                31: get_char_at_pos = "n";
                                32: get_char_at_pos = "g";
                                33: get_char_at_pos = " ";
                                34: get_char_at_pos = "H";
                                35: get_char_at_pos = "i";
                                36: get_char_at_pos = "s";
                                37: get_char_at_pos = "t";
                                38: get_char_at_pos = "o";
                                39: get_char_at_pos = "g";
                                40: get_char_at_pos = "r";
                                41: get_char_at_pos = "a";
                                42: get_char_at_pos = "m";
                                default: get_char_at_pos = " ";
                            endcase
                        end
                        3'b001: begin // Finding Least Value
                            case (x)
                                25: get_char_at_pos = "F";
                                26: get_char_at_pos = "i";
                                27: get_char_at_pos = "n";
                                28: get_char_at_pos = "d";
                                29: get_char_at_pos = "i";
                                30: get_char_at_pos = "n";
                                31: get_char_at_pos = "g";
                                32: get_char_at_pos = " ";
                                33: get_char_at_pos = "L";
                                34: get_char_at_pos = "e";
                                35: get_char_at_pos = "a";
                                36: get_char_at_pos = "s";
                                37: get_char_at_pos = "t";
                                38: get_char_at_pos = " ";
                                39: get_char_at_pos = "V";
                                40: get_char_at_pos = "a";
                                41: get_char_at_pos = "l";
                                42: get_char_at_pos = "u";
                                43: get_char_at_pos = "e";
                                default: get_char_at_pos = " ";
                            endcase
                        end
                        3'b010: begin // Synthesizing Huffman Tree
                            case (x)
                                20: get_char_at_pos = "S";
                                21: get_char_at_pos = "y";
                                22: get_char_at_pos = "n";
                                23: get_char_at_pos = "t";
                                24: get_char_at_pos = "h";
                                25: get_char_at_pos = "e";
                                26: get_char_at_pos = "s";
                                27: get_char_at_pos = "i";
                                28: get_char_at_pos = "z";
                                29: get_char_at_pos = "i";
                                30: get_char_at_pos = "n";
                                31: get_char_at_pos = "g";
                                32: get_char_at_pos = " ";
                                33: get_char_at_pos = "H";
                                34: get_char_at_pos = "u";
                                35: get_char_at_pos = "f";
                                36: get_char_at_pos = "f";
                                37: get_char_at_pos = "m";
                                38: get_char_at_pos = "a";
                                39: get_char_at_pos = "n";
                                40: get_char_at_pos = " ";
                                41: get_char_at_pos = "T";
                                42: get_char_at_pos = "r";
                                43: get_char_at_pos = "e";
                                44: get_char_at_pos = "e";
                                default: get_char_at_pos = " ";
                            endcase
                        end
                        3'b011: begin // Synthesizing Codebook
                            case (x)
                                20: get_char_at_pos = "S";
                                21: get_char_at_pos = "y";
                                22: get_char_at_pos = "n";
                                23: get_char_at_pos = "t";
                                24: get_char_at_pos = "h";
                                25: get_char_at_pos = "e";
                                26: get_char_at_pos = "s";
                                27: get_char_at_pos = "i";
                                28: get_char_at_pos = "z";
                                29: get_char_at_pos = "i";
                                30: get_char_at_pos = "n";
                                31: get_char_at_pos = "g";
                                32: get_char_at_pos = " ";
                                33: get_char_at_pos = "C";
                                34: get_char_at_pos = "o";
                                35: get_char_at_pos = "d";
                                36: get_char_at_pos = "e";
                                37: get_char_at_pos = "b";
                                38: get_char_at_pos = "o";
                                39: get_char_at_pos = "o";
                                40: get_char_at_pos = "k";
                                default: get_char_at_pos = " ";
                            endcase
                        end
                        3'b100: begin // Translating
                            case (x)
                                32: get_char_at_pos = "T";
                                33: get_char_at_pos = "r";
                                34: get_char_at_pos = "a";
                                35: get_char_at_pos = "n";
                                36: get_char_at_pos = "s";
                                37: get_char_at_pos = "l";
                                38: get_char_at_pos = "a";
                                39: get_char_at_pos = "t";
                                40: get_char_at_pos = "i";
                                41: get_char_at_pos = "n";
                                42: get_char_at_pos = "g";
                                default: get_char_at_pos = " ";
                            endcase
                        end
                        3'b101: begin // Uploading to SD
                            case (x)
                                27: get_char_at_pos = "U";
                                28: get_char_at_pos = "p";
                                29: get_char_at_pos = "l";
                                30: get_char_at_pos = "o";
                                31: get_char_at_pos = "a";
                                32: get_char_at_pos = "d";
                                33: get_char_at_pos = "i";
                                34: get_char_at_pos = "n";
                                35: get_char_at_pos = "g";
                                36: get_char_at_pos = " ";
                                37: get_char_at_pos = "t";
                                38: get_char_at_pos = "o";
                                39: get_char_at_pos = " ";
                                40: get_char_at_pos = "S";
                                41: get_char_at_pos = "D";
                                default: get_char_at_pos = " ";
                            endcase
                        end
                        default: begin // Unknown State
                            if (system_state == 3'b110 || system_state == 3'b111) begin
                                // Display "Unknown State" for states 6 and 7
                                case (x)
                                    30: get_char_at_pos = "U";
                                    31: get_char_at_pos = "n";
                                    32: get_char_at_pos = "k";
                                    33: get_char_at_pos = "n";
                                    34: get_char_at_pos = "o";
                                    35: get_char_at_pos = "w";
                                    36: get_char_at_pos = "n";
                                    37: get_char_at_pos = " ";
                                    38: get_char_at_pos = "S";
                                    39: get_char_at_pos = "t";
                                    40: get_char_at_pos = "a";
                                    41: get_char_at_pos = "t";
                                    42: get_char_at_pos = "e";
                                    default: get_char_at_pos = " ";
                                endcase
                            end else begin
                                // Display "Finished" for STATE_FINISHED (3)
                                case (x)
                                    33: get_char_at_pos = "F";
                                    34: get_char_at_pos = "i";
                                    35: get_char_at_pos = "n";
                                    36: get_char_at_pos = "i";
                                    37: get_char_at_pos = "s";
                                    38: get_char_at_pos = "h";
                                    39: get_char_at_pos = "e";
                                    40: get_char_at_pos = "d";
                                    default: get_char_at_pos = " ";
                                endcase
                            end
                        end
                    endcase
                end else if (y == 12) begin
                    // Progress bar - centered (20 chars wide: positions 30-49)
                    if (x >= 30 && x <= 49) begin
                        if (x == 30)
                            get_char_at_pos = 8'h01; // Left end cap
                        else if (x == 49)
                            get_char_at_pos = 8'h02; // Right end cap
                        else if ((x - 31) <= display_progress) // Subtract 31 to account for left cap
                            get_char_at_pos = 8'h03; // Filled block
                        else
                            get_char_at_pos = 8'h04; // Empty block
                    end else begin
                        get_char_at_pos = " ";
                    end
                end else if (y == 14) begin
                    // Percentage display
                    logic [6:0] percentage;
                    logic [7:0] tens_digit, ones_digit;
                    percentage = get_overall_percentage(system_state, display_progress, 1'b1); // 1 for compression
                    tens_digit = {1'b0, percentage} / 8'd10;
                    ones_digit = {1'b0, percentage} % 8'd10;
                    
                    if (x >= 37 && x <= 42) begin // Centered under progress bar
                        case (x - 37)
                            0: get_char_at_pos = (percentage >= 100) ? "1" : " ";
                            1: get_char_at_pos = (percentage >= 100) ? "0" : 
                                                 (percentage >= 10) ? (tens_digit + 8'd48) : " "; // 48 is ASCII '0'
                            2: get_char_at_pos = (ones_digit + 8'd48); // Convert to ASCII
                            3: get_char_at_pos = "%";
                            default: get_char_at_pos = " ";
                        endcase
                    end else begin
                        get_char_at_pos = " ";
                    end
                end else begin
                    get_char_at_pos = " ";
                end
            end
            
            SCREEN_DECOMPRESS: begin
                if (y == 6) begin
                    case (x)
                        28: get_char_at_pos = "D";
                        29: get_char_at_pos = "e";
                        30: get_char_at_pos = "c";
                        31: get_char_at_pos = "o";
                        32: get_char_at_pos = "m";
                        33: get_char_at_pos = "p";
                        34: get_char_at_pos = "r";
                        35: get_char_at_pos = "e";
                        36: get_char_at_pos = "s";
                        37: get_char_at_pos = "s";
                        38: get_char_at_pos = "i";
                        39: get_char_at_pos = "o";
                        40: get_char_at_pos = "n";
                        default: get_char_at_pos = " ";
                    endcase
                end else if (y == 8) begin
                    // Current operation based on system_state
                    case (system_state)
                        3'b000: begin // Starting
                            case (x)
                                34: get_char_at_pos = "S";
                                35: get_char_at_pos = "t";
                                36: get_char_at_pos = "a";
                                37: get_char_at_pos = "r";
                                38: get_char_at_pos = "t";
                                39: get_char_at_pos = "i";
                                40: get_char_at_pos = "n";
                                41: get_char_at_pos = "g";
                                default: get_char_at_pos = " ";
                            endcase
                        end
                        3'b001: begin // Decoding
                            case (x)
                                33: get_char_at_pos = "D";
                                34: get_char_at_pos = "e";
                                35: get_char_at_pos = "c";
                                36: get_char_at_pos = "o";
                                37: get_char_at_pos = "d";
                                38: get_char_at_pos = "i";
                                39: get_char_at_pos = "n";
                                40: get_char_at_pos = "g";
                                default: get_char_at_pos = " ";
                            endcase
                        end
                        3'b010: begin // Translation
                            case (x)
                                31: get_char_at_pos = "T";
                                32: get_char_at_pos = "r";
                                33: get_char_at_pos = "a";
                                34: get_char_at_pos = "n";
                                35: get_char_at_pos = "s";
                                36: get_char_at_pos = "l";
                                37: get_char_at_pos = "a";
                                38: get_char_at_pos = "t";
                                39: get_char_at_pos = "i";
                                40: get_char_at_pos = "o";
                                41: get_char_at_pos = "n";
                                default: get_char_at_pos = " ";
                            endcase
                        end
                        default: begin // Unknown State
                            if (system_state == 3'b110 || system_state == 3'b111) begin
                                // Display "Unknown State" for states 6 and 7
                                case (x)
                                    30: get_char_at_pos = "U";
                                    31: get_char_at_pos = "n";
                                    32: get_char_at_pos = "k";
                                    33: get_char_at_pos = "n";
                                    34: get_char_at_pos = "o";
                                    35: get_char_at_pos = "w";
                                    36: get_char_at_pos = "n";
                                    37: get_char_at_pos = " ";
                                    38: get_char_at_pos = "S";
                                    39: get_char_at_pos = "t";
                                    40: get_char_at_pos = "a";
                                    41: get_char_at_pos = "t";
                                    42: get_char_at_pos = "e";
                                    default: get_char_at_pos = " ";
                                endcase
                            end else begin
                                // Display "Finish" for STATE_FINISHED (3)
                                case (x)
                                    34: get_char_at_pos = "F";
                                    35: get_char_at_pos = "i";
                                    36: get_char_at_pos = "n";
                                    37: get_char_at_pos = "i";
                                    38: get_char_at_pos = "s";
                                    39: get_char_at_pos = "h";
                                    default: get_char_at_pos = " ";
                                endcase
                            end
                        end
                    endcase
                end else if (y == 12) begin
                    // Progress bar - centered (20 chars wide: positions 30-49)
                    if (x >= 30 && x <= 49) begin
                        if (x == 30)
                            get_char_at_pos = 8'h01; // Left end cap
                        else if (x == 49)
                            get_char_at_pos = 8'h02; // Right end cap
                        else if ((x - 31) <= display_progress) // Subtract 31 to account for left cap
                            get_char_at_pos = 8'h03; // Filled block
                        else
                            get_char_at_pos = 8'h04; // Empty block
                    end else begin
                        get_char_at_pos = " ";
                    end
                end else if (y == 14) begin
                    // Percentage display
                    logic [6:0] percentage;
                    logic [7:0] tens_digit, ones_digit;
                    percentage = get_overall_percentage(system_state, display_progress, 1'b0); // 0 for decompression
                    tens_digit = {1'b0, percentage} / 8'd10;
                    ones_digit = {1'b0, percentage} % 8'd10;
                    
                    if (x >= 37 && x <= 42) begin // Centered under progress bar
                        case (x - 37)
                            0: get_char_at_pos = (percentage >= 100) ? "1" : " ";
                            1: get_char_at_pos = (percentage >= 100) ? "0" : 
                                                 (percentage >= 10) ? (tens_digit + 8'd48) : " "; // 48 is ASCII '0'
                            2: get_char_at_pos = (ones_digit + 8'd48); // Convert to ASCII
                            3: get_char_at_pos = "%";
                            default: get_char_at_pos = " ";
                        endcase
                    end else begin
                        get_char_at_pos = " ";
                    end
                end else begin
                    get_char_at_pos = " ";
                end
            end
            
            SCREEN_COMPLETE: begin
                if (y == 10) begin
                    case (x)
                        28: get_char_at_pos = "O";
                        29: get_char_at_pos = "p";
                        30: get_char_at_pos = "e";
                        31: get_char_at_pos = "r";
                        32: get_char_at_pos = "a";
                        33: get_char_at_pos = "t";
                        34: get_char_at_pos = "i";
                        35: get_char_at_pos = "o";
                        36: get_char_at_pos = "n";
                        37: get_char_at_pos = " ";
                        38: get_char_at_pos = "C";
                        39: get_char_at_pos = "o";
                        40: get_char_at_pos = "m";
                        41: get_char_at_pos = "p";
                        42: get_char_at_pos = "l";
                        43: get_char_at_pos = "e";
                        44: get_char_at_pos = "t";
                        45: get_char_at_pos = "e";
                        default: get_char_at_pos = " ";
                    endcase
                end else begin
                    get_char_at_pos = " ";
                end
            end
            
            default: get_char_at_pos = " ";
        endcase
        end  // Close the if-else block
    endfunction
    
    // Get current character
    assign current_char = get_char_at_pos(char_x, char_y);
    
    // Calculate overall percentage based on state and individual progress
    function logic [6:0] get_overall_percentage(input logic [2:0] state, input logic [3:0] progress, input logic is_compress);
        logic [6:0] base_percentage;
        logic [6:0] progress_within_state;
        
        if (is_compress) begin
            // Compression states: 0=20%, 1=35%, 2=55%, 3=75%, 4=85%, 5=95%, finished=100%
            case (state)
                3'b000: base_percentage = 7'd0;   // Creating Histogram: 0-20%
                3'b001: base_percentage = 7'd20;  // Finding Least Value: 20-35%
                3'b010: base_percentage = 7'd35;  // Huffman Tree: 35-55%
                3'b011: base_percentage = 7'd55;  // Codebook: 55-75%
                3'b100: base_percentage = 7'd75;  // Translating: 75-85%
                3'b101: base_percentage = 7'd85;  // Uploading: 85-95%
                default: base_percentage = 7'd95; // Finished: 95-100%
            endcase
            
            // Calculate progress within current state
            case (state)
                3'b000: progress_within_state = (progress * 20) / 15; // 20% range
                3'b001: progress_within_state = (progress * 15) / 15; // 15% range
                3'b010: progress_within_state = (progress * 20) / 15; // 20% range
                3'b011: progress_within_state = (progress * 20) / 15; // 20% range
                3'b100: progress_within_state = (progress * 10) / 15; // 10% range
                3'b101: progress_within_state = (progress * 10) / 15; // 10% range
                default: progress_within_state = (progress * 5) / 15;  // 5% range
            endcase
        end else begin
            // Decompression states: 0=33%, 1=66%, 2=90%, finished=100%
            case (state)
                3'b000: base_percentage = 7'd0;   // Starting: 0-33%
                3'b001: base_percentage = 7'd33;  // Decoding: 33-66%
                3'b010: base_percentage = 7'd66;  // Translation: 66-90%
                default: base_percentage = 7'd90; // Finished: 90-100%
            endcase
            
            // Calculate progress within current state
            case (state)
                3'b000: progress_within_state = (progress * 33) / 15; // 33% range
                3'b001: progress_within_state = (progress * 33) / 15; // 33% range
                3'b010: progress_within_state = (progress * 24) / 15; // 24% range
                default: progress_within_state = (progress * 10) / 15; // 10% range
            endcase
        end
        
        get_overall_percentage = base_percentage + progress_within_state;
        if (get_overall_percentage > 100) get_overall_percentage = 100;
    endfunction
    
    // Simple 8x8 font ROM lookup (basic characters)
    function logic get_font_pixel(input logic [7:0] char_code, input logic [2:0] row, col);
        logic [7:0] font_data;
        
        case (char_code)
            " ": font_data = 8'b00000000;
            "A": begin
                case (row)
                    0: font_data = 8'b00111000;
                    1: font_data = 8'b01000100;
                    2: font_data = 8'b10000010;
                    3: font_data = 8'b11111110;
                    4: font_data = 8'b10000010;
                    5: font_data = 8'b10000010;
                    6: font_data = 8'b10000010;
                    7: font_data = 8'b00000000;
                endcase
            end
            "B": begin
                case (row)
                    0: font_data = 8'b11111100;
                    1: font_data = 8'b10000010;
                    2: font_data = 8'b10000010;
                    3: font_data = 8'b11111100;
                    4: font_data = 8'b10000010;
                    5: font_data = 8'b10000010;
                    6: font_data = 8'b11111100;
                    7: font_data = 8'b00000000;
                endcase
            end
            "C": begin
                case (row)
                    0: font_data = 8'b01111110;
                    1: font_data = 8'b10000000;
                    2: font_data = 8'b10000000;
                    3: font_data = 8'b10000000;
                    4: font_data = 8'b10000000;
                    5: font_data = 8'b10000000;
                    6: font_data = 8'b01111110;
                    7: font_data = 8'b00000000;
                endcase
            end
            "D": begin
                case (row)
                    0: font_data = 8'b11111000;
                    1: font_data = 8'b10000100;
                    2: font_data = 8'b10000010;
                    3: font_data = 8'b10000010;
                    4: font_data = 8'b10000010;
                    5: font_data = 8'b10000100;
                    6: font_data = 8'b11111000;
                    7: font_data = 8'b00000000;
                endcase
            end
            "E": begin
                case (row)
                    0: font_data = 8'b11111110;
                    1: font_data = 8'b10000000;
                    2: font_data = 8'b10000000;
                    3: font_data = 8'b11111100;
                    4: font_data = 8'b10000000;
                    5: font_data = 8'b10000000;
                    6: font_data = 8'b11111110;
                    7: font_data = 8'b00000000;
                endcase
            end
            "F": begin
                case (row)
                    0: font_data = 8'b11111110;
                    1: font_data = 8'b10000000;
                    2: font_data = 8'b10000000;
                    3: font_data = 8'b11111100;
                    4: font_data = 8'b10000000;
                    5: font_data = 8'b10000000;
                    6: font_data = 8'b10000000;
                    7: font_data = 8'b00000000;
                endcase
            end
            "G": begin
                case (row)
                    0: font_data = 8'b01111110;
                    1: font_data = 8'b10000000;
                    2: font_data = 8'b10000000;
                    3: font_data = 8'b10001110;
                    4: font_data = 8'b10000010;
                    5: font_data = 8'b10000010;
                    6: font_data = 8'b01111110;
                    7: font_data = 8'b00000000;
                endcase
            end
            "H": begin
                case (row)
                    0: font_data = 8'b10000010;
                    1: font_data = 8'b10000010;
                    2: font_data = 8'b10000010;
                    3: font_data = 8'b11111110;
                    4: font_data = 8'b10000010;
                    5: font_data = 8'b10000010;
                    6: font_data = 8'b10000010;
                    7: font_data = 8'b00000000;
                endcase
            end
            "I": begin
                case (row)
                    0: font_data = 8'b01111100;
                    1: font_data = 8'b00010000;
                    2: font_data = 8'b00010000;
                    3: font_data = 8'b00010000;
                    4: font_data = 8'b00010000;
                    5: font_data = 8'b00010000;
                    6: font_data = 8'b01111100;
                    7: font_data = 8'b00000000;
                endcase
            end
            "L": begin
                case (row)
                    0: font_data = 8'b10000000;
                    1: font_data = 8'b10000000;
                    2: font_data = 8'b10000000;
                    3: font_data = 8'b10000000;
                    4: font_data = 8'b10000000;
                    5: font_data = 8'b10000000;
                    6: font_data = 8'b11111110;
                    7: font_data = 8'b00000000;
                endcase
            end
            "M": begin
                case (row)
                    0: font_data = 8'b10000010;
                    1: font_data = 8'b11000110;
                    2: font_data = 8'b10101010;
                    3: font_data = 8'b10010010;
                    4: font_data = 8'b10000010;
                    5: font_data = 8'b10000010;
                    6: font_data = 8'b10000010;
                    7: font_data = 8'b00000000;
                endcase
            end
            "N": begin
                case (row)
                    0: font_data = 8'b10000010;
                    1: font_data = 8'b11000010;
                    2: font_data = 8'b10100010;
                    3: font_data = 8'b10010010;
                    4: font_data = 8'b10001010;
                    5: font_data = 8'b10000110;
                    6: font_data = 8'b10000010;
                    7: font_data = 8'b00000000;
                endcase
            end
            "O": begin
                case (row)
                    0: font_data = 8'b00111110;
                    1: font_data = 8'b01000001;
                    2: font_data = 8'b01000001;
                    3: font_data = 8'b01000001;
                    4: font_data = 8'b01000001;
                    5: font_data = 8'b01000001;
                    6: font_data = 8'b00111110;
                    7: font_data = 8'b00000000;
                endcase
            end
            "P": begin
                case (row)
                    0: font_data = 8'b11111100;
                    1: font_data = 8'b10000010;
                    2: font_data = 8'b10000010;
                    3: font_data = 8'b11111100;
                    4: font_data = 8'b10000000;
                    5: font_data = 8'b10000000;
                    6: font_data = 8'b10000000;
                    7: font_data = 8'b00000000;
                endcase
            end
            "S": begin
                case (row)
                    0: font_data = 8'b01111110;
                    1: font_data = 8'b10000000;
                    2: font_data = 8'b10000000;
                    3: font_data = 8'b01111100;
                    4: font_data = 8'b00000010;
                    5: font_data = 8'b00000010;
                    6: font_data = 8'b11111100;
                    7: font_data = 8'b00000000;
                endcase
            end
            "T": begin
                case (row)
                    0: font_data = 8'b11111110;
                    1: font_data = 8'b00010000;
                    2: font_data = 8'b00010000;
                    3: font_data = 8'b00010000;
                    4: font_data = 8'b00010000;
                    5: font_data = 8'b00010000;
                    6: font_data = 8'b00010000;
                    7: font_data = 8'b00000000;
                endcase
            end
            "U": begin
                case (row)
                    0: font_data = 8'b10000010;
                    1: font_data = 8'b10000010;
                    2: font_data = 8'b10000010;
                    3: font_data = 8'b10000010;
                    4: font_data = 8'b10000010;
                    5: font_data = 8'b10000010;
                    6: font_data = 8'b01111100;
                    7: font_data = 8'b00000000;
                endcase
            end
            "V": begin
                case (row)
                    0: font_data = 8'b10000010;
                    1: font_data = 8'b10000010;
                    2: font_data = 8'b10000010;
                    3: font_data = 8'b10000010;
                    4: font_data = 8'b01000100;
                    5: font_data = 8'b00101000;
                    6: font_data = 8'b00010000;
                    7: font_data = 8'b00000000;
                endcase
            end
            "a": begin
                case (row)
                    0: font_data = 8'b00000000;
                    1: font_data = 8'b00000000;
                    2: font_data = 8'b01111100;
                    3: font_data = 8'b00000010;
                    4: font_data = 8'b01111110;
                    5: font_data = 8'b10000010;
                    6: font_data = 8'b01111110;
                    7: font_data = 8'b00000000;
                endcase
            end
            "b": begin
                case (row)
                    0: font_data = 8'b10000000;
                    1: font_data = 8'b10000000;
                    2: font_data = 8'b11111100;
                    3: font_data = 8'b10000010;
                    4: font_data = 8'b10000010;
                    5: font_data = 8'b10000010;
                    6: font_data = 8'b11111100;
                    7: font_data = 8'b00000000;
                endcase
            end
            "c": begin
                case (row)
                    0: font_data = 8'b00000000;
                    1: font_data = 8'b00000000;
                    2: font_data = 8'b01111110;
                    3: font_data = 8'b10000000;
                    4: font_data = 8'b10000000;
                    5: font_data = 8'b10000000;
                    6: font_data = 8'b01111110;
                    7: font_data = 8'b00000000;
                endcase
            end
            "d": begin
                case (row)
                    0: font_data = 8'b00000010;
                    1: font_data = 8'b00000010;
                    2: font_data = 8'b01111110;
                    3: font_data = 8'b10000010;
                    4: font_data = 8'b10000010;
                    5: font_data = 8'b10000010;
                    6: font_data = 8'b01111110;
                    7: font_data = 8'b00000000;
                endcase
            end
            "e": begin
                case (row)
                    0: font_data = 8'b00000000;
                    1: font_data = 8'b00000000;
                    2: font_data = 8'b01111100;
                    3: font_data = 8'b10000010;
                    4: font_data = 8'b11111110;
                    5: font_data = 8'b10000000;
                    6: font_data = 8'b01111100;
                    7: font_data = 8'b00000000;
                endcase
            end
            "f": begin
                case (row)
                    0: font_data = 8'b00111100;
                    1: font_data = 8'b01000000;
                    2: font_data = 8'b11111100;
                    3: font_data = 8'b01000000;
                    4: font_data = 8'b01000000;
                    5: font_data = 8'b01000000;
                    6: font_data = 8'b01000000;
                    7: font_data = 8'b00000000;
                endcase
            end
            "g": begin
                case (row)
                    0: font_data = 8'b00000000;
                    1: font_data = 8'b00000000;
                    2: font_data = 8'b01111110;
                    3: font_data = 8'b10000010;
                    4: font_data = 8'b01111110;
                    5: font_data = 8'b00000010;
                    6: font_data = 8'b01111100;
                    7: font_data = 8'b00000000;
                endcase
            end
            "h": begin
                case (row)
                    0: font_data = 8'b10000000;
                    1: font_data = 8'b10000000;
                    2: font_data = 8'b11111100;
                    3: font_data = 8'b10000010;
                    4: font_data = 8'b10000010;
                    5: font_data = 8'b10000010;
                    6: font_data = 8'b10000010;
                    7: font_data = 8'b00000000;
                endcase
            end
            "i": begin
                case (row)
                    0: font_data = 8'b00010000;
                    1: font_data = 8'b00000000;
                    2: font_data = 8'b00110000;
                    3: font_data = 8'b00010000;
                    4: font_data = 8'b00010000;
                    5: font_data = 8'b00010000;
                    6: font_data = 8'b00111000;
                    7: font_data = 8'b00000000;
                endcase
            end
            "k": begin
                case (row)
                    0: font_data = 8'b10000000;
                    1: font_data = 8'b10000000;
                    2: font_data = 8'b10001000;
                    3: font_data = 8'b10010000;
                    4: font_data = 8'b11100000;
                    5: font_data = 8'b10010000;
                    6: font_data = 8'b10001000;
                    7: font_data = 8'b00000000;
                endcase
            end
            "l": begin
                case (row)
                    0: font_data = 8'b00110000;
                    1: font_data = 8'b00010000;
                    2: font_data = 8'b00010000;
                    3: font_data = 8'b00010000;
                    4: font_data = 8'b00010000;
                    5: font_data = 8'b00010000;
                    6: font_data = 8'b00111000;
                    7: font_data = 8'b00000000;
                endcase
            end
            "m": begin
                case (row)
                    0: font_data = 8'b00000000;
                    1: font_data = 8'b00000000;
                    2: font_data = 8'b11100110;
                    3: font_data = 8'b10011001;
                    4: font_data = 8'b10011001;
                    5: font_data = 8'b10011001;
                    6: font_data = 8'b10011001;
                    7: font_data = 8'b00000000;
                endcase
            end
            "n": begin
                case (row)
                    0: font_data = 8'b00000000;
                    1: font_data = 8'b00000000;
                    2: font_data = 8'b11111100;
                    3: font_data = 8'b10000010;
                    4: font_data = 8'b10000010;
                    5: font_data = 8'b10000010;
                    6: font_data = 8'b10000010;
                    7: font_data = 8'b00000000;
                endcase
            end
            "o": begin
                case (row)
                    0: font_data = 8'b00000000;
                    1: font_data = 8'b00000000;
                    2: font_data = 8'b01111100;
                    3: font_data = 8'b10000010;
                    4: font_data = 8'b10000010;
                    5: font_data = 8'b10000010;
                    6: font_data = 8'b01111100;
                    7: font_data = 8'b00000000;
                endcase
            end
            "p": begin
                case (row)
                    0: font_data = 8'b00000000;
                    1: font_data = 8'b00000000;
                    2: font_data = 8'b01111110;
                    3: font_data = 8'b01000001;
                    4: font_data = 8'b01111110;
                    5: font_data = 8'b01000000;
                    6: font_data = 8'b01000000;
                    7: font_data = 8'b00000000;
                endcase
            end
            "r": begin
                case (row)
                    0: font_data = 8'b00000000;
                    1: font_data = 8'b00000000;
                    2: font_data = 8'b10111100;
                    3: font_data = 8'b11000000;
                    4: font_data = 8'b10000000;
                    5: font_data = 8'b10000000;
                    6: font_data = 8'b10000000;
                    7: font_data = 8'b00000000;
                endcase
            end
            "s": begin
                case (row)
                    0: font_data = 8'b00000000;
                    1: font_data = 8'b00000000;
                    2: font_data = 8'b01111110;
                    3: font_data = 8'b10000000;
                    4: font_data = 8'b01111100;
                    5: font_data = 8'b00000010;
                    6: font_data = 8'b11111100;
                    7: font_data = 8'b00000000;
                endcase
            end
            "t": begin
                case (row)
                    0: font_data = 8'b01000000;
                    1: font_data = 8'b01000000;
                    2: font_data = 8'b11111100;
                    3: font_data = 8'b01000000;
                    4: font_data = 8'b01000000;
                    5: font_data = 8'b01000000;
                    6: font_data = 8'b00111100;
                    7: font_data = 8'b00000000;
                endcase
            end
            "u": begin
                case (row)
                    0: font_data = 8'b00000000;
                    1: font_data = 8'b00000000;
                    2: font_data = 8'b10000010;
                    3: font_data = 8'b10000010;
                    4: font_data = 8'b10000010;
                    5: font_data = 8'b10000010;
                    6: font_data = 8'b01111110;
                    7: font_data = 8'b00000000;
                endcase
            end
            "v": begin
                case (row)
                    0: font_data = 8'b00000000;
                    1: font_data = 8'b00000000;
                    2: font_data = 8'b10000010;
                    3: font_data = 8'b10000010;
                    4: font_data = 8'b01000100;
                    5: font_data = 8'b00101000;
                    6: font_data = 8'b00010000;
                    7: font_data = 8'b00000000;
                endcase
            end
            "w": begin
                case (row)
                    0: font_data = 8'b00000000;
                    1: font_data = 8'b00000000;
                    2: font_data = 8'b10000010;
                    3: font_data = 8'b10010010;
                    4: font_data = 8'b10010010;
                    5: font_data = 8'b10010010;
                    6: font_data = 8'b01101100;
                    7: font_data = 8'b00000000;
                endcase
            end
            "y": begin
                case (row)
                    0: font_data = 8'b00000000;
                    1: font_data = 8'b00000000;
                    2: font_data = 8'b10000010;
                    3: font_data = 8'b10000010;
                    4: font_data = 8'b01111110;
                    5: font_data = 8'b00000010;
                    6: font_data = 8'b01111100;
                    7: font_data = 8'b00000000;
                endcase
            end
            "z": begin
                case (row)
                    0: font_data = 8'b00000000;
                    1: font_data = 8'b00000000;
                    2: font_data = 8'b11111110;
                    3: font_data = 8'b00000100;
                    4: font_data = 8'b00111000;
                    5: font_data = 8'b01000000;
                    6: font_data = 8'b11111110;
                    7: font_data = 8'b00000000;
                endcase
            end
            ",": begin
                case (row)
                    0: font_data = 8'b00000000;
                    1: font_data = 8'b00000000;
                    2: font_data = 8'b00000000;
                    3: font_data = 8'b00000000;
                    4: font_data = 8'b00000000;
                    5: font_data = 8'b00010000;
                    6: font_data = 8'b00010000;
                    7: font_data = 8'b00100000;
                endcase
            end
            ".": begin
                case (row)
                    0: font_data = 8'b00000000;
                    1: font_data = 8'b00000000;
                    2: font_data = 8'b00000000;
                    3: font_data = 8'b00000000;
                    4: font_data = 8'b00000000;
                    5: font_data = 8'b00000000;
                    6: font_data = 8'b00010000;
                    7: font_data = 8'b00000000;
                endcase
            end
            ">": begin
                case (row)
                    0: font_data = 8'b00000000;
                    1: font_data = 8'b00110000;
                    2: font_data = 8'b00001100;
                    3: font_data = 8'b00000011;
                    4: font_data = 8'b00001100;
                    5: font_data = 8'b00110000;
                    6: font_data = 8'b00000000;
                    7: font_data = 8'b00000000;
                endcase
            end
            "|": begin
                case (row)
                    0: font_data = 8'b00010000;
                    1: font_data = 8'b00010000;
                    2: font_data = 8'b00010000;
                    3: font_data = 8'b00010000;
                    4: font_data = 8'b00010000;
                    5: font_data = 8'b00010000;
                    6: font_data = 8'b00010000;
                    7: font_data = 8'b00010000;
                endcase
            end
            "=": begin
                case (row)
                    0: font_data = 8'b00000000;
                    1: font_data = 8'b00000000;
                    2: font_data = 8'b11111110;
                    3: font_data = 8'b00000000;
                    4: font_data = 8'b11111110;
                    5: font_data = 8'b00000000;
                    6: font_data = 8'b00000000;
                    7: font_data = 8'b00000000;
                endcase
            end
            "-": begin
                case (row)
                    0: font_data = 8'b00000000;
                    1: font_data = 8'b00000000;
                    2: font_data = 8'b00000000;
                    3: font_data = 8'b11111110;
                    4: font_data = 8'b00000000;
                    5: font_data = 8'b00000000;
                    6: font_data = 8'b00000000;
                    7: font_data = 8'b00000000;
                endcase
            end
            "0": begin
                case (row)
                    0: font_data = 8'b00111100;
                    1: font_data = 8'b01000110;
                    2: font_data = 8'b01001010;
                    3: font_data = 8'b01010010;
                    4: font_data = 8'b01100010;
                    5: font_data = 8'b01000010;
                    6: font_data = 8'b00111100;
                    7: font_data = 8'b00000000;
                endcase
            end
            "1": begin
                case (row)
                    0: font_data = 8'b00010000;
                    1: font_data = 8'b00110000;
                    2: font_data = 8'b00010000;
                    3: font_data = 8'b00010000;
                    4: font_data = 8'b00010000;
                    5: font_data = 8'b00010000;
                    6: font_data = 8'b01111100;
                    7: font_data = 8'b00000000;
                endcase
            end
            "2": begin
                case (row)
                    0: font_data = 8'b00111100;
                    1: font_data = 8'b01000010;
                    2: font_data = 8'b00000010;
                    3: font_data = 8'b00001100;
                    4: font_data = 8'b00110000;
                    5: font_data = 8'b01000000;
                    6: font_data = 8'b01111110;
                    7: font_data = 8'b00000000;
                endcase
            end
            "3": begin
                case (row)
                    0: font_data = 8'b00111100;
                    1: font_data = 8'b01000010;
                    2: font_data = 8'b00000010;
                    3: font_data = 8'b00011100;
                    4: font_data = 8'b00000010;
                    5: font_data = 8'b01000010;
                    6: font_data = 8'b00111100;
                    7: font_data = 8'b00000000;
                endcase
            end
            "4": begin
                case (row)
                    0: font_data = 8'b00001100;
                    1: font_data = 8'b00010100;
                    2: font_data = 8'b00100100;
                    3: font_data = 8'b01000100;
                    4: font_data = 8'b01111110;
                    5: font_data = 8'b00000100;
                    6: font_data = 8'b00000100;
                    7: font_data = 8'b00000000;
                endcase
            end
            "5": begin
                case (row)
                    0: font_data = 8'b01111110;
                    1: font_data = 8'b01000000;
                    2: font_data = 8'b01111100;
                    3: font_data = 8'b00000010;
                    4: font_data = 8'b00000010;
                    5: font_data = 8'b01000010;
                    6: font_data = 8'b00111100;
                    7: font_data = 8'b00000000;
                endcase
            end
            "6": begin
                case (row)
                    0: font_data = 8'b00111100;
                    1: font_data = 8'b01000010;
                    2: font_data = 8'b01000000;
                    3: font_data = 8'b01111100;
                    4: font_data = 8'b01000010;
                    5: font_data = 8'b01000010;
                    6: font_data = 8'b00111100;
                    7: font_data = 8'b00000000;
                endcase
            end
            "7": begin
                case (row)
                    0: font_data = 8'b01111110;
                    1: font_data = 8'b00000010;
                    2: font_data = 8'b00000100;
                    3: font_data = 8'b00001000;
                    4: font_data = 8'b00010000;
                    5: font_data = 8'b00010000;
                    6: font_data = 8'b00010000;
                    7: font_data = 8'b00000000;
                endcase
            end
            "8": begin
                case (row)
                    0: font_data = 8'b00111100;
                    1: font_data = 8'b01000010;
                    2: font_data = 8'b01000010;
                    3: font_data = 8'b00111100;
                    4: font_data = 8'b01000010;
                    5: font_data = 8'b01000010;
                    6: font_data = 8'b00111100;
                    7: font_data = 8'b00000000;
                endcase
            end
            "9": begin
                case (row)
                    0: font_data = 8'b00111100;
                    1: font_data = 8'b01000010;
                    2: font_data = 8'b01000010;
                    3: font_data = 8'b00111110;
                    4: font_data = 8'b00000010;
                    5: font_data = 8'b01000010;
                    6: font_data = 8'b00111100;
                    7: font_data = 8'b00000000;
                endcase
            end
            "%": begin
                case (row)
                    0: font_data = 8'b01100010;
                    1: font_data = 8'b10010100;
                    2: font_data = 8'b01101000;
                    3: font_data = 8'b00010000;
                    4: font_data = 8'b00101100;
                    5: font_data = 8'b01001010;
                    6: font_data = 8'b10001100;
                    7: font_data = 8'b00000000;
                endcase
            end
            // Progress bar characters
            8'h01: begin // Left end cap [
                case (row)
                    0: font_data = 8'b11111111;
                    1: font_data = 8'b10101010;
                    2: font_data = 8'b11111010;
                    3: font_data = 8'b10101111;
                    4: font_data = 8'b10101111;
                    5: font_data = 8'b11111010;
                    6: font_data = 8'b10101010;
                    7: font_data = 8'b11111111;
                endcase
            end
            8'h02: begin // Right end cap ]
                case (row)
                    0: font_data = 8'b11111111;
                    1: font_data = 8'b01010101;
                    2: font_data = 8'b01011111;
                    3: font_data = 8'b11110101;
                    4: font_data = 8'b11110101;
                    5: font_data = 8'b01011111;
                    6: font_data = 8'b01010101;
                    7: font_data = 8'b11111111;
                endcase
            end
            8'h03: begin // Filled progress block
                case (row)
                    0: font_data = 8'b11111111;
                    1: font_data = 8'b11111111;
                    2: font_data = 8'b11111111;
                    3: font_data = 8'b11111111;
                    4: font_data = 8'b11111111;
                    5: font_data = 8'b11111111;
                    6: font_data = 8'b11111111;
                    7: font_data = 8'b11111111;
                endcase
            end
            8'h04: begin // Empty progress block
                case (row)
                    0: font_data = 8'b11111111;
                    1: font_data = 8'b10000001;
                    2: font_data = 8'b10000001;
                    3: font_data = 8'b10000001;
                    4: font_data = 8'b10000001;
                    5: font_data = 8'b10000001;
                    6: font_data = 8'b10000001;
                    7: font_data = 8'b11111111;
                endcase
            end
            default: font_data = 8'b11111111; // Solid block for unknown chars
        endcase
        
        get_font_pixel = font_data[7 - col];
    endfunction
    
    // Generate pixel data
    always_comb begin
        // Default values (black background)
        pixel_on = 1'b0;
        red_out = 1'b0;
        green_out = 1'b0;
        blue_out = 1'b0;
        
        if (hpos < 640 && vpos < 480) begin
            // Use 8x8 font patterns, stretched vertically to 8x16 character cells
            pixel_on = get_font_pixel(current_char, pixel_y[3:1], pixel_x);
            
            // Pure white text on black background
            if (pixel_on) begin
                red_out = 1'b1;    // Full brightness red
                green_out = 1'b1;  // Full brightness green
                blue_out = 1'b1;   // Full brightness blue
            end else begin
                red_out = 1'b0;    // Black background
                green_out = 1'b0;
                blue_out = 1'b0;
            end
        end
    end
    
    // Debug output
    assign current_screen = screen_state;

endmodule
