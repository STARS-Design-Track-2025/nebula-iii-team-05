`timescale 1ms/10ps
// typedef enum logic [2:0] {
//     INIT, // initial (set if enable for the translation_decode module isn't high)
//     READ_SRAM_PATH, // read a codebook path for a char from the SRAM
//     READ_SPI_PATH, // read a char path from the compressed file
//     COMPARE_PATHS, // compare path read from SPI with path read from SRAM
//     WRITE_PATH, // writes the char index of the matching path from SRAM to SPI decompressed file, increment chars found and compare tot chars
//     FINISH
// } state_tr;

module t05_translation_decode (
    input logic clk, rst,
    input logic translation_enable,
    input logic [31:0] tot_chars, // total characters read in the hd_decode
    input logic [7:0] SPI_data_in, // read in char bytes from the SPI
    input logic [127:0] SRAM_data_in, // read in path from the SRAM
    output logic SPI_read_en,
    output logic SRAM_read_en,
    output logic [7:0] char_index, // char index for char path to get in SRAM
    output logic SPI_data_out, // given an char index from SRAM, write the char (bit by bit) based on the corresponding code
    output logic SPI_write_en,
    output logic finished
); 
logic [2:0] curr_state, next_state;
logic [3:0] SPI_count, next_SPI_count; // count to 7 and room incase of overflow
logic [8:0] SRAM_count, next_SRAM_count; // count to 256 (for code paths for each char from SRAM)
logic [7:0] next_char_index;
logic [127:0] SPI_path, next_SPI_path; // store 7 bytes from SPI in a path
logic [7:0] path_bit_count, next_path_bit_count; // counter to 128
logic match, next_match;
logic [31:0] curr_chars_found, next_chars_found;
logic next_finished;
logic next_SPI_data_out;
logic wait_cycle, next_wait_cycle;
logic next_SRAM_read_en;

always_ff @(posedge clk, posedge rst) begin
    if (rst) begin
        SPI_count <= 0;
        SRAM_count <= 0;
        curr_state <= 0; // INIT
        char_index <= 0;
        path_bit_count <= 0;
        SPI_path <= 0;
        match <= 0;
        curr_chars_found <= 0;
        finished <= 0;
        SPI_data_out <= 0;
      wait_cycle <= 1;
      SRAM_read_en <= 0;
    end
    else if (translation_enable) begin
        SPI_count <= next_SPI_count;
        SRAM_count <= next_SRAM_count;
        curr_state <= next_state;
        char_index <= next_char_index;
        path_bit_count <= next_path_bit_count;
        SPI_path <= next_SPI_path;
        match <= next_match;
        curr_chars_found <= next_chars_found;
        finished <= next_finished;
        SPI_data_out <= next_SPI_data_out;
      wait_cycle <= next_wait_cycle;
      SRAM_read_en <= next_SRAM_read_en;
    end
end

always_comb begin
    next_SPI_count = SPI_count;
    next_SRAM_count = SRAM_count;
    next_state = curr_state;
    next_char_index = char_index;
    next_path_bit_count = path_bit_count;
    next_SPI_path = SPI_path;
    next_match = match;
    next_chars_found = curr_chars_found;
    next_finished = finished;
    next_SPI_data_out = SPI_data_out;
  next_wait_cycle = wait_cycle;
  next_SRAM_read_en = SRAM_read_en;

    SPI_read_en = 0;
    SPI_write_en = 0;

    case (curr_state)
        0:begin // INIT
             if (translation_enable) begin
                  SPI_read_en = 1;
                 next_state = 1; //READ_SRAM_PATH
             end
             else begin
                next_state = 0; // INIT
             end
        end
        1: begin // READ_SRAM_PATH
          if (!wait_cycle) begin
            if (SRAM_count > 255) begin
                next_SRAM_count = 0;
            end
            else begin
                next_char_index = SRAM_count[7:0];
                next_SRAM_count = SRAM_count + 1;
              next_SRAM_read_en = 1;
              next_state = 2; // READ_SPI_PATH
              next_wait_cycle = 1;
                SPI_read_en = 1;
            end
          end
          else begin
            next_SRAM_read_en = 0;
            next_wait_cycle = 0;
          end
        end
        2: begin // READ_SPI_PATH
          if (!wait_cycle) begin
            next_SRAM_read_en = 0;
            if (path_bit_count < 128) begin
                if (SPI_count < 8) begin
                  next_SPI_path = SPI_path;
                  next_SPI_path[127 - path_bit_count[6:0]] = SPI_data_in[7 - SPI_count[2:0]];
                  next_SPI_count = SPI_count + 1;
                  next_path_bit_count = path_bit_count + 1;
                end
                else begin
                  SPI_read_en = 1;
                  next_SPI_count = 0;
                  next_wait_cycle = 1;
                end
              end
              else begin
                next_path_bit_count = 0;
                next_state = 3; // COMPARE_PATHS
                next_wait_cycle = 1;
              end
            end
          else begin
            next_wait_cycle = 0;
          end
        end
        3: begin // COMPARE_PATHS
          if (!wait_cycle) begin
            if (SPI_path != SRAM_data_in) begin
              next_state = 1;// READ_SRAM_PATH // if a nonmatching bit is found, read another SRAM path and compare it with
              next_SPI_count = 0;
              next_wait_cycle = 1;
              next_path_bit_count = 0;
            end
            else begin // if all 128 bits of the two paths are the same, write the SRAM char index bit by bit
              next_path_bit_count = 0;
              next_wait_cycle = 1;
              next_state = 4; // WRITE_PATH
            end
            if (SPI_count >= 8) begin        
              next_SPI_count = 0;
            end
          end
          else begin
            next_wait_cycle = 0;
          end
        end
        4: begin // WRITE_PATH
          if (!wait_cycle) begin
              SPI_write_en = 1;
              if (SPI_count < 8) begin
                  next_SPI_data_out = char_index[7-SPI_count]; 
                  next_SPI_count = SPI_count + 1;
              end
              else begin
                  next_SPI_data_out = 0;
                  next_SPI_count = 0;
                  next_SPI_path = 128'b0;
                  next_wait_cycle = 1;
                  next_state = 1; // READ_SRAM_PATH
                  next_chars_found = curr_chars_found + 1;
                if (next_chars_found == tot_chars) begin
                  next_state = 5; // FINISH
                end
              end
          end
          else begin
            next_wait_cycle = 0;
          end
        end
        5: begin // FINISH
            next_finished = 1;
        end
        default: begin
            next_state = curr_state;
        end
    endcase

end

endmodule;
