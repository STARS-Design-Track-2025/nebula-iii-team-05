`timescale 1ms/10ps
// typedef enum logic [2:0] {
//     INIT,
//     HEADER_DECODE,
//     TRANSLATE,
//     FINISH
// } state_t;

module t05_controller_decode (
    input logic controller_enable,
    input logic clk, rst,
    input logic hd_finished,
    input logic tr_finished,
    input logic SRAM_r_en,
    input logic SRAM_wr_en,
    input logic init,
    input logic SRAM_finished,
    output logic hd_enable,
    output logic tr_enable,
    output logic [1:0] curr_state,
    output logic finished,
  	output logic SPI_read_en,
  	input logic SPI_read_en_hd,
  	input logic SPI_read_en_tr,
    output logic SRAM_controller_en
); 
logic [1:0] next_state;
logic next_finished;

always_ff @(posedge clk, posedge rst) begin
    if (rst) begin
        curr_state <= 2'b0;
      	finished <= 0;
    end
    else begin
        curr_state <= next_state;
      	finished <= next_finished;
    end
end

always_comb begin
    next_finished = finished;
    next_state = curr_state;

    case (curr_state)
        2'b0: begin // INIT
            hd_enable = 0;
            tr_enable = 0;
            SPI_read_en = 0;
            if (controller_enable) begin
              SRAM_controller_en = 1;
              if (!init) begin
                next_state = 1;
              end
            end
            else begin
              SRAM_controller_en = 0;
            end
        end
        2'b1: begin // HEADER DECODE
            // SRAM is currently writing data for hd_decode
            //hd_enable = 1;
            SRAM_controller_en = 1;
          	hd_enable = (SRAM_wr_en && !SRAM_finished) ? 0 : 1;
            //hd_enable = (SPI_r_en && !SPI_finished) ? 0 : 1; // wait for SPI to finish reading
            tr_enable = 0;
          	SPI_read_en = SPI_read_en_hd;
            if (hd_finished) begin
                next_state = 2'b10;
            end
        end
        2'b10: begin // TRANSLATION
          	//tr_enable = 1;
            SRAM_controller_en = 1;
            tr_enable = (SRAM_r_en && !SRAM_finished)  ? 0 : 1;
            //tr_enable = (SPI_r_en && !SPI_finished) ? 0 : 1; // wait for SPI to finish writing
            hd_enable = 0;
          	SPI_read_en = SPI_read_en_tr;
            if (tr_finished) begin
                next_state = 2'b11;
            end
        end
        2'b11: begin // FINISH
            SRAM_controller_en = 0;
            SPI_read_en = 0;
            hd_enable = 0;
            tr_enable = 0;
            next_finished = 1;
        end
        default: begin 
          SPI_read_en = 0;
          next_state = curr_state; 
          hd_enable = 0;
          tr_enable = 0;
          next_finished = 0;
          if (controller_enable) begin
            SRAM_controller_en = 1;
          end
          else begin
            SRAM_controller_en = 0;
          end
          end
    endcase

end


endmodule