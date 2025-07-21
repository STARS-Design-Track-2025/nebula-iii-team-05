// module update(
//     input  logic clk, rst,
//     input  logic busy_o, trn_nxt_char,
//     input  logic [31:0] histogram,
//     input  logic [7:0] histgram_addr,
//     input  logic [7:0] find_least,
//     input  logic [70:0] new_node,
//     input  logic [6:0] htreeindex,
//     input  logic [7:0] codebook,
//     input  logic [127:0] codebook_path,
//     input  logic [7:0] translation,
//     input  logic [2:0] state,

//     output logic wr_en, r_en,
//     output logic [3:0] select,
//     output logic [31:0] old_char,
//     output logic [63:0] comp_val,
//     output logic [70:0] h_element,
//     output logic [128:0] char_code,
//     //output logic [31:0] sram_out [0:63] // Exposed for simulation
// );

//     logic [31:0] sram [0:255]; // internal SRAM
//     assign sram_out = sram;   // copy internal SRAM to output for simulation

//     typedef enum logic [2:0] {
//         A_IDLE = 3'b000,
//         HIST   = 3'b001,
//         FLV    = 3'b010,
//         CODEBOOK = 3'b101,
//         TRANSLATION = 3'b110
//     } state_e;

//     logic in_ready, ready_flv, ready_trn, ready_cb;
//     logic [11:0] base_addr;

//     always_comb begin
//         wr_en = 0;
//         r_en = 0;
//         in_ready = 0;
//         ready_flv = 0;
//         ready_trn = 0;
//         ready_cb = 0;
//         select = 4'b1111;

//         case (state)
//             A_IDLE: begin end
//             HIST: begin wr_en = 1; r_en = 1; in_ready = 1; base_addr = 12'd0; end
//             FLV:  begin r_en = 1; ready_flv = 1; base_addr = 12'd0; end
//             CODEBOOK: begin wr_en = 1; ready_cb = 1; base_addr = 12'd512; end
//             TRANSLATION: begin r_en = 1; ready_trn = 1; base_addr = 12'd0; end
//         endcase
//     end

//     always_ff @(posedge clk or posedge rst) begin
//         if (rst) begin
//             old_char <= 32'b0;
//             comp_val <= 64'b0;
//             h_element <= 71'b0;
//             char_code <= 129'b0;
//         end else begin
//             if (in_ready && r_en) begin
//                 old_char <= sram[histgram_addr]; // Simulated word index
//             end
//             if (ready_flv && (find_least < 64)) begin
//                 comp_val <= {32'b0, sram[find_least]};
//             end
//             if (ready_trn && trn_nxt_char) begin
//                 char_code <= {97'b0, sram[translation]};
//             end
//             if (ready_cb) begin
//                 h_element <= {39'b0, sram[codebook]};
//             end
//             if (in_ready && wr_en) begin
//                 sram[histgram_addr] <= histogram;
//             end
//         end
//     end
// endmodule