`timescale 1ms/10ps

// typedef enum logic [2:0] {
//     INIT,
//     HEADER_DECODE,
//     TRANSLATE,
//     FINISH
// } state_t;

module t05_controller_decode (
    input logic clk, rst,
    input logic hd_finished,
    input logic tr_finished,
    input logic SRAM_r_en,
    input logic SRAM_wr_en,
    output logic hd_enable,
    output logic tr_enable,
    output logic [1:0] curr_state,
    output logic finished
); 
logic [1:0] next_state;
logic next_finished;

always_ff @(posedge clk, posedge rst) begin
    if (rst) begin
        curr_state <= 2'b0;
    end
    else begin
        curr_state <= next_state;
    end
end

always_comb begin
    next_finished = finished;
    next_state = curr_state;

    case (curr_state)
        2'b0: begin // INIT
            hd_enable = 0;
            tr_enable = 0;
            next_state = 0;
        end
        2'b1: begin // HEADER DECODE
            // SRAM is currently writing data for hd_decode
            hd_enable = (SRAM_wr_en || SRAM_r_en) ? 0 : 1;
            tr_enable = 0;
            if (hd_finished) begin
                next_state = 2'b10;
            end
        end
        2'b10: begin // TRANSLATION
            tr_enable = (SRAM_wr_en || SRAM_r_en)  ? 0 : 1;
            hd_enable = 0;
            if (tr_finished) begin
                next_state = 2'b11;
            end
        end
        2'b11: begin // FINISH
            hd_enable = 0;
            tr_enable = 0;
            next_finished = 1;
        end
        default: begin 
          next_state = curr_state; 
          hd_enable = 0;
          tr_enable = 0;
          next_finished = 0;
          end
    endcase

end


endmodule
