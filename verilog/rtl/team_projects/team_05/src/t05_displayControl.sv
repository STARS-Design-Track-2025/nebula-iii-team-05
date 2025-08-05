// module t05_displayControl
// (
//     input logic clk, rst,
//     input logic  compDecomp, isFinished,    // from controller
//     input logic [3:0] contState_n,          // from controlelr

//     // Interface to backpack module
 
//     input logic backpack_busy,           // Backpack is transmitting
//     input logic backpack_done,           // Backpack full transmission complete
//     output logic [319:0] data_reg,
//     output logic [5:0] count,
//     output logic [2:0] mode_o,
//     output logic start_delay_n,
//     input logic delay_done
// );
//     logic [319:0] data;
//     logic [2:0] mode_n,nextMode,nextMode_n;
//     logic [1:0]clr,clr_r,c_reg;
//     logic [5:0]  count_n;
//     logic backpack_done_reg; 

//     // logic start_delay_n, delay_done;
//     logic [17:0] index;

   
//    typedef enum logic [3:0] {
//         IDLE=0,     // Waiting for start signal
//         HISTO=1,    // Histogram generation state
//         FLV=2,      // Frequency/Length/Value processing state  
//         HTREE=3,    // Huffman tree construction state
//         CBS=4,      // Code book generation state
//         TRN=5,      // Data transmission/encoding state
//         SPI=6,      // SPI communication state
//         ERROR=7,    // Error handling state
//         DONE=8      // Completion state
//     } state_t;

//     state_t contState;
//     assign contState = state_t'(contState_n);

//     typedef enum logic [2:0] {
//         INIT,
//         TITLE,
//         SELECT,
//         COMP,
//         DECOMP,
//         FINISH,
//         ERROR_STATE,
//         RESET
//     } mode_t;
//     mode_t mode;

//     typedef enum logic [9:0] {
//         A = 10'b0001000001,
//         B = 10'b0001000010,
//         C = 10'b0001000011,
//         D = 10'b0001000100,
//         E = 10'b0001000101,
//         F = 10'b0001000110,
//         G = 10'b0001000111,
//         H = 10'b0001001000,
//         I = 10'b0001001001,
//         K = 10'b0001001011,
//         L = 10'b0001001100,
//         M = 10'b0001001101,
//         N = 10'b0001001110,
//         O = 10'b0001001111,
//         P = 10'b0001010000,
//         R = 10'b0001010010,
//         S = 10'b0001010011,
//         T = 10'b0001010100,
//         U = 10'b0001010101,
//         V = 10'b0001010110,
//         SPACE = 10'b1000100000,
//         BLOCK = 10'b001111111111,
//         CLEAR = 10'b0000000001,
//         HOME = 10'b0000000010
//         // NEWLINE =
//     } data_t;
//     data_t keys;
   
//     always_ff @(posedge clk or posedge rst) begin
//         if (rst) begin
//             nextMode <= INIT;
//             mode <= INIT;
//             count <= 6'd0;
//             data_reg <= '0;
//             backpack_done_reg <= 1'b0;
//             c_reg <= 2'b0;

//         end else begin
//             mode <= mode_t'(mode_n);
//             data_reg <= data;
//             count <= count_n;
//             nextMode <= nextMode_n; 
//             if (~backpack_done_reg && backpack_done) begin
//                 backpack_done_reg <= backpack_done;
//             end else if (backpack_done_reg && c_reg == 3) begin
//                 backpack_done_reg <= 1'b0; 
//                 c_reg <= 2'b0;
//             end else if (backpack_done_reg)begin
//                 c_reg = c_reg + 1;
//                 backpack_done_reg <= 1'b1;
//             end else begin
//                 backpack_done_reg <= 1'b0;
//             end
            
//         end
//     end

    


//     always_comb begin
//         mode_n = mode;
//         data = '0;
//         nextMode_n = nextMode; 
//         count_n = 6'd0;
//         mode_o = mode; 
//         start_delay_n = 1'b0;
//         // Default assignments
//         case (mode)
//             INIT: begin
//                 data = {10'b0000111000,10'b0000001100,10'b0000000110,290'b0};
//                 count_n = 6'd2;
//                 // start_delay_n = 1'b1; // Start delay for initialization
//                 // if (delay_done) begin
//                     // start_delay_n = 1'b0; // Stop delay after done
//                     if (backpack_done || backpack_done_reg) begin
//                         mode_n = RESET;
//                         nextMode_n = TITLE;
//                     end 
//                 // end else begin
//                 //     mode_n = INIT;
//                 //     // start_delay_n = 1'b0;
//                 // end
//             end
//             TITLE: begin
//                 data = {SPACE, B, I, G, G, I, E, SPACE, SPACE, S, M, A, L, L, S, SPACE,/*NEWLINE*/ H, U, F, F, M, A, N, SPACE, E, N, C, O, D, I, N, G};
//                 count_n = 6'd31;
//                 start_delay_n = 1'b1; // Start delay for initialization
//                 if (delay_done) begin
//                     if (backpack_done || backpack_done_reg) begin
//                         mode_n = RESET;
//                         nextMode_n = SELECT;
//                     end else begin
//                         mode_n = TITLE;
//                     end
//                 end
//             end
//             SELECT: begin
//                 data = {SPACE, SPACE, C, O, M, P, R, E, S, S, I, O, N, SPACE, SPACE, SPACE, SPACE, D, E, C, O, M, P, R, E, S, S, I, O, N, SPACE, SPACE};
//                 count_n = 6'd31;
//                 start_delay_n = 1'b1; // Start delay for initialization
//                 if (delay_done) begin
//                     if (compDecomp && (backpack_done || backpack_done_reg)) begin
//                         mode_n = COMP;
//                     end else if (~compDecomp && (backpack_done || backpack_done_reg)) begin
//                         mode_n = DECOMP;
//                     end else begin
//                         mode_n = SELECT;
//                     end
//                 end
//             end
//             COMP: begin

//                 case (contState)
//                     IDLE: begin
//                         data = {SPACE, SPACE, C, O, M, P, R, E, S, S, I, O, N, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE};
//                         count_n = 6'd31;
//                     end
//                     HISTO: begin
//                         data = {SPACE, SPACE, C, O, M, P, R, E, S, S, I, O, N, SPACE, BLOCK, BLOCK, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE};
//                         count_n = 6'd31;
//                     end
//                     FLV: begin
//                         data = {SPACE, SPACE, C, O, M, P, R, E, S, S, I, O, N, SPACE, BLOCK, BLOCK, BLOCK, BLOCK, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE};
//                         count_n = 6'd31;
//                     end
//                     HTREE: begin
//                         data = {SPACE, SPACE, C, O, M, P, R, E, S, S, I, O, N, SPACE, BLOCK, BLOCK, BLOCK, BLOCK, BLOCK, BLOCK, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE};
//                         count_n = 6'd31;
//                     end
//                     CBS: begin
//                         data = {SPACE, SPACE, C, O, M, P, R, E, S, S, I, O, N, SPACE, BLOCK, BLOCK, BLOCK, BLOCK, BLOCK, BLOCK, BLOCK, BLOCK, BLOCK, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE};
//                         count_n = 6'd31;
//                     end
//                     TRN: begin
//                         data = {SPACE, SPACE, C, O, M, P, R, E, S, S, I, O, N, SPACE, BLOCK, BLOCK, BLOCK, BLOCK, BLOCK, BLOCK, BLOCK, BLOCK, BLOCK, BLOCK, BLOCK, BLOCK, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE};
//                         count_n = 6'd31;
//                     end
//                     SPI: begin
//                         data = {SPACE, SPACE, C, O, M, P, R, E, S, S, I, O, N, SPACE, BLOCK, BLOCK, BLOCK, BLOCK, BLOCK, BLOCK, BLOCK, BLOCK, BLOCK, BLOCK, BLOCK, BLOCK, BLOCK, BLOCK, BLOCK, SPACE, SPACE, SPACE};
//                         count_n = 6'd31;
//                     end
//                     ERROR: begin
//                         data = {SPACE, SPACE, C, O, M, P, R, E, S, S, I, O, N, SPACE, SPACE, BLOCK, SPACE, BLOCK, SPACE, BLOCK, SPACE, BLOCK, SPACE, BLOCK, SPACE, BLOCK, SPACE, BLOCK, SPACE, BLOCK, SPACE, BLOCK};
//                         count_n = 6'd31;
//                     end
//                     DONE: begin
//                         data = {SPACE, SPACE, C, O, M, P, R, E, S, S, I, O, N, SPACE, BLOCK, BLOCK, BLOCK, BLOCK, BLOCK, BLOCK, BLOCK, BLOCK, BLOCK, BLOCK, BLOCK, BLOCK, BLOCK, BLOCK, BLOCK, BLOCK, BLOCK, BLOCK};
//                         count_n = 6'd31;
//                     end
//                     default: begin
//                         // Default case to handle unexpected states
//                         data = '0;
//                         count_n = 6'd0;
//                     end
//                 endcase
//                 start_delay_n = 1'b1; // Start delay for initialization
//                 if (delay_done) begin
//                     if (backpack_done || backpack_done_reg) begin
//                         mode_n = RESET;
//                         nextMode_n = FINISH; 
//                     end else begin
//                         mode_n = COMP;
//                     end
//                 end
//             end
//             DECOMP: begin
//                 // Add proper decompression display
//                 data = {D, E, C, O, M, P, R, E, S, S, I, O, N, SPACE, SPACE, SPACE,
//                         SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, 
//                         SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE};
//                 count_n = 6'd31;  // ← FIX: Change from 6'd0 to 6'd32
//                 if (backpack_done || backpack_done_reg) begin
//                     mode_n = RESET;
//                     nextMode_n = FINISH;
//                 end else begin
//                     mode_n = DECOMP;
//                 end
//             end
//             FINISH: begin

//                 data = { F, I, N, I, S, H, 260'b0};
//                 count_n = 6'd5;

//             end
//             ERROR_STATE: begin

//                 data = { E, R, R, O, R, 270'b0};
//                 count_n = 6'd4;
                
//             end
//             RESET: begin
//                 data = {CLEAR, HOME, 300'b0}; // Clear display and set home position
//                 count_n = 6'd2;
//                 start_delay_n = 1'b1; // Start delay for initialization
//                 if (delay_done) begin
//                     if (backpack_done || backpack_done_reg) begin
//                         mode_n = nextMode;
//                     end else begin
//                         mode_n = RESET;
//                     end
//                 end
//             end
//             default: begin
//                 // Default case to handle unexpected modes
//                 mode_n = INIT;
//                 data = '0; // Initialize data to zero
//                 count_n = 6'd0;
//             end
//         endcase
//     end
// endmodule