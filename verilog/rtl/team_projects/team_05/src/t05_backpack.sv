// module t05_backpack (
//     input logic clk, rst,                    // Clock, reset, busy flag
//     input logic [319:0] data,                   // Input data
//     input logic [5:0] count_n,                  // number of digits in the input
//     output logic [9:0] lcd_data,                // LCD data output
//     output logic  lcd_en,                       // LCD enable signal
//     output logic backpack_busy, backpack_done,   // Backpack busy and done signals
//     output logic start_delay_n,
//     input logic delay_done
// );

//     logic en, done;
//     logic [5:0] count,digit, digit_n;
//     logic [9:0] chunk;
    

//     // Delay task signals
//     // logic delay_start_n, delay_done;
//     // logic [17:0] index;

//     typedef enum logic [1:0] {
//         PARSE,
//         UPLOAD,
//         ENABLE,
//         BUSY
//     } state_t;

//     state_t state, next_state;

//     always_ff @(posedge clk or posedge rst) begin
//         if (rst) begin
//             state <= PARSE;
//             lcd_data <= 0; // Default space character
//             lcd_en <= 1'b0;    // Enable signal
//             backpack_busy <= 1'b0;
//             backpack_done <= 1'b0;  
//             count <= 0;
//             digit <= 0;
//             // index <= 0;
//             // delay_done <= 1'b0;
//         end else begin
//             state <= next_state;
//             count <= count_n;
//             lcd_en <= en;
//             backpack_busy <= (state != PARSE);
//             backpack_done <= done;
//             lcd_data <= chunk;
//             digit <= digit_n;
            
//         end
//     end

   
    

//     always_comb begin
//         next_state = state;
//         en = 1'b0;
//         chunk = lcd_data; // Default space character
//         done = 1'b0;
//         digit_n = digit; // Default to current digit
//         start_delay_n = 1'b0; // Default to no delay start

//         case (state)
//             PARSE: begin
//                 if (digit < count) begin
//                     chunk = data[319-(digit*10) -: 10]; // Extract 10 bits starting from 319-(digit*10) down
//                     // chunk = data[data[319-(digit*10):310-(digit*10)]];
//                     next_state = UPLOAD;
//                 end else begin
//                     // done = 1'b1;  // Set done when all digits processed
//                     next_state = PARSE;  // Stay in PARSE when done
//                 end
//             end
            
//             UPLOAD: begin
//                 en = 1'b1; // Enable signal
//                 next_state = ENABLE;
//             end
            
//             ENABLE: begin
//                 en = 1'b0; // Disable after upload
//                 next_state = BUSY;
//             end
            
//             BUSY: begin
//                 // Wait for external delay to complete
//                 start_delay_n = 1'b1; // Trigger delay start
//                 if (delay_done) begin
//                     if (digit < count - 1) begin
//                         next_state = PARSE;
//                         digit_n = digit + 1;
//                     end else begin
//                         done = 1'b1;
//                         digit_n = 0;
//                         next_state = PARSE;
//                     end
//                 end
//                 // Stay in BUSY until delay_done
//             end
            
//             default: begin
//                 next_state = PARSE; // Default to parsing state
//                 digit_n = 0; // Reset digit
//             end
//         endcase
//     end
// endmodule 