`timescale 1ms/10ps
module t05_translation_decode (
  input logic clk, rst,
  input logic translation_enable, // enables translate_decode
  input logic [127:0] SRAM_read_data, // read 128 bit path
  output logic SRAM_read_en, // enable SRAM to read 4 words
  input logic [7:0] SPI_read_data, // read byte from SPI
  output logic SPI_read_en, // enable SPI to read a byte
  input logic [31:0] tot_chars, // from compressed file header (hd_decode)
  
  output logic SPI_write_en,
  output logic finished, // finished, sent to controller
  output logic SPI_write_data, // 8 bits of char sent to SPI
  output logic [7:0] char_index // keep track of char of SRAM path from codebook being compared to compressed file
);

logic [7:0] eof = 8'd26;
logic [3:0] bit_count, next_bit_count; // current bit of SPI data being compared to SRAM path
logic next_SRAM_read_en, next_SPI_read_en, next_SPI_write_en;
logic [3:0] curr_state, next_state;
logic [7:0] next_char_index;
logic [1:0] wait_count, next_wait_count;
logic [6:0] path_start, next_path_start;
logic [127:0] curr_path_SPI, next_path_SPI;
logic [6:0] curr_path_SPI_start, next_path_SPI_start;
logic [3:0] offset, next_offset;
logic [8:0] SRAM_paths_compared, next_SRAM_paths_compared;
logic next_finished;
logic [2:0] count, next_count;
logic next_SPI_write_data;
logic [31:0] next_chars_found, curr_chars_found;
logic one_found, next_one_found;
logic [3:0] prev_state, prev_state_n;
logic full_bit_read, next_full_bit_read;

always_ff @(posedge clk, posedge rst) begin
  if (rst) begin
    bit_count <= 0;
    wait_count <= 0;
    SRAM_read_en <= 0;
    SPI_read_en <= 0;
    SPI_write_en <= 0;
    path_start <= 0;
    curr_path_SPI <= 0;
    curr_path_SPI_start <= 0;
    offset <= 0;
    SRAM_paths_compared <= 0;
    curr_state <= 0;
    finished <= 0;
    count <= 0;
    SPI_write_data <= 0;
    curr_chars_found <= 0;
    char_index <= 0;
    one_found <= 0;
    prev_state <= 0;
    full_bit_read <= 1;

  end
  else if (translation_enable) begin
    bit_count <= next_bit_count;
    SRAM_read_en <= next_SRAM_read_en;
    SPI_read_en <= next_SPI_read_en;
    SPI_write_en <= next_SPI_write_en;
    wait_count <= next_wait_count;
    path_start <= next_path_start;
    curr_path_SPI <= next_path_SPI;
    curr_path_SPI_start <= next_path_SPI_start;
    offset <= next_offset;
    SRAM_paths_compared <= next_SRAM_paths_compared;
    curr_state <= next_state;
    finished <= next_finished;
    count <= next_count;
    SPI_write_data <= next_SPI_write_data;
    curr_chars_found <= next_chars_found;
    char_index <= next_char_index;
    one_found <= next_one_found;
    prev_state <= prev_state_n;
    full_bit_read <= next_full_bit_read;
  end
end

always_comb begin
  next_bit_count = bit_count;
  next_SRAM_read_en = SRAM_read_en;
  next_SPI_read_en = SPI_read_en;
  next_SPI_write_en = SPI_write_en;
  next_wait_count = wait_count;
  next_path_start = path_start;
  next_path_SPI = curr_path_SPI;
  next_path_SPI_start = curr_path_SPI_start;
  next_offset = offset;
  next_SRAM_paths_compared = SRAM_paths_compared;
  next_finished = finished;
  next_count = count;
  next_SPI_write_data = SPI_write_data;
  next_chars_found = curr_chars_found;
  next_state = curr_state;
  next_char_index = char_index;
  next_one_found = one_found;
  prev_state_n = prev_state;
  next_full_bit_read = full_bit_read;
  
  case (curr_state)
    0: begin // INIT
      if (translation_enable) begin
        next_state = 1;
      end
    end
    1: begin // READ SRAM PATH
      if (char_index >= 255) begin
        next_char_index = 0;
        next_SRAM_paths_compared = 0;
      end
        if (wait_count == 0) begin
          next_wait_count = wait_count + 1;
          next_SRAM_read_en = 1;
        end
        else if (wait_count == 1) begin
          next_SRAM_read_en = 0;
          next_wait_count = wait_count + 1;
        end
      else if (translation_enable) begin
        if ((SRAM_read_data != 128'b0 && SRAM_paths_compared == 0 && full_bit_read)) begin// don't check empty paths
            //next_char_index = 0;
              next_state = 2; // only get a new byte if creating a new SPI path to compare and no bits in current SPI byte haven't been used
              prev_state_n = 3;
          end
        else if (SRAM_read_data != 128'b0) begin
            next_state = 3; // find sram path length
          end
        else begin
          next_char_index = char_index + 1;
        end
          next_wait_count = 0;
        end
      end
      2: begin // READ SPI BYTE
        if (wait_count == 0) begin
          next_wait_count = wait_count + 1;
          next_SPI_read_en = 1;
        end
        else if (wait_count == 1) begin
          next_SPI_read_en = 0;
          next_wait_count = wait_count + 1;
        end
        else if (translation_enable) begin
          next_state = prev_state;
          next_wait_count = 0;
        end
      end
      3: begin // FIND BEGINNING OF SRAM PATH
        if (SRAM_read_data[path_start] == 0) begin
            next_path_start = path_start + 1;
        end
        else begin
          if (SRAM_paths_compared != 0 && SRAM_paths_compared < 256) begin
            next_state = 6; // don't change SPI path until it is compared to all SRAM paths
            //next_char_index = char_index + 1;
          end
          else begin
            next_SRAM_paths_compared = 0; // reset # SRAM paths compared and update the SPI path
            next_state = 4;
           end
         end
       end
    4: begin
      if (offset <= 7) begin
        next_full_bit_read = 0;
        if (SPI_read_data[7-offset] == 0 || (!one_found && SPI_read_data[7-offset] == 1)) begin
          next_offset = offset + 1;
          next_path_SPI = {curr_path_SPI[126:0], SPI_read_data[7-offset]};
          next_path_SPI_start = curr_path_SPI_start + 1;
          next_one_found = 1;
        end
        else if (SPI_read_data[7-offset] == 1 && curr_path_SPI_start > 0) begin
          next_one_found = 0;
          next_state = 6; // finished path, compare
        end
      end 
      else begin
        next_full_bit_read = 1;
        next_offset = 0;
        next_state = 2;
        prev_state_n = 4;
      end
    end
            
        
      6: begin // COMPARE SRAM AND SPI PATHS
            if (curr_path_SPI == SRAM_read_data) begin
              next_state = 7;
              next_count = 0;
              next_path_SPI = 0;
            end
        else if (SRAM_paths_compared < 256) begin // still SRAM paths to search (current paths have same size but not equal)
              //prev_char_index = char_index;
              next_char_index = char_index + 1;
              next_SRAM_paths_compared = SRAM_paths_compared + 1;
              next_state = 1;
              next_count = 0;
            end
      end
      7: begin // WRITE SPI PATH WITH CURRENT SRAM INDEX
              next_SPI_write_en = 1;
              if (bit_count < 8) begin
                  if (count == 0) begin
                    next_SPI_write_data = char_index[7-bit_count]; 
                    next_bit_count = bit_count + 1;
                    next_count = 1;
                  end
                  else if (count >= 1) begin
                    next_SPI_write_en = 0;
                    next_count = 0;
                  end
              end
              else begin
                next_bit_count = 0;
                next_SRAM_paths_compared = 0;
                next_SPI_write_data = 0;
                next_count = 0;
                next_path_SPI = 128'b0;
                next_state = 1; // READ_SRAM_PATH
                next_SPI_write_en = 0;
                next_chars_found = curr_chars_found + 1;
                if (next_chars_found == tot_chars) begin
                  next_state = 8; // ADD EOF
                end
              end
        end
        8: begin
             next_SPI_write_en = 1;
              if (bit_count < 8) begin
                  if (count == 0) begin
                    next_SPI_write_data = eof[7-bit_count]; 
                    next_bit_count = bit_count + 1;
                    next_count = 1;
                  end
                  else if (count >= 1) begin
                    next_SPI_write_en = 0;
                    next_count = 0;
                  end
              end
              else begin
                next_SPI_write_en = 0;
                next_bit_count = 0;
                next_state = 9; // FINISH
              end

        end
    	9: begin
          next_finished = 1;     
        end

  endcase

end
endmodule