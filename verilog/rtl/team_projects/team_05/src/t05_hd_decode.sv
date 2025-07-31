`timescale 1ms/10ps
// typedef enum logic [3:0] {
//     INIT, // initial (set if enable for the hd_decode module isn't high)
//     READ_NUM_LEFTS, // reads the 9 bit chunk of the number of lefts after moving right for the left char stored in the header
//     READ_LEADING_BIT, // read leading bit checks if there is a backtrack (0) or if another char was found (1)
//     READ_CHAR, // read 8 bits of the char from data_in after reading the leading bit(s)
//     UPDATE_PATH, // after getting the character, use the # of backtrack and the bit after the char to update the path
//     WRITE_PATH, // once a full path is found, (after a char was found and corresponding path was updated with correct digits), send the path to SRAM with the curr char index
//     READ_TOT_CHAR, // read the total number chars in the file after the whole binary tree was turned into a codebook  
//     FINISH // finished writing all char codes from header
// } state_hd;

module t05_hd_decode (
    input logic clk, rst,
    input logic hd_enable,
    input logic [7:0] SPI_data_in, // read byte of header from SPI
    output logic SPI_read_en, // sent to SPI to enable a new byte to be read
    output logic [127:0] SRAM_data_out, // write a char path to SRAM
    output logic [7:0] char_index, // set to SRAM to store address
    output logic SRAM_write_en, // sent to SRAM to enable writing a char path
    output logic finished, // sent to controller
    output logic [31:0] tot_chars // read from compressed file and sent to translation to determine the finish condition
);
  state_hd curr_state, next_state; 
  logic [127:0] curr_path, next_path; 
  logic [3:0] offset, next_offset; // marker to keep track of which bit in byte of data_in to read next
  logic [7:0] count, next_count;
  logic [1:0] leading_bit, next_leading_bit;
  logic [7:0] backtracks, next_backtracks;
  logic [7:0] curr_char, next_char;
  logic next_wait_cycle, wait_cycle;
  logic next_first, first;
  logic next_finished;
  logic [31:0] next_tot_chars;
  logic [127:0] char_path, next_char_path;
  logic [7:0] num_lefts, next_num_lefts;
  
always_ff @(posedge clk, posedge rst) begin
    if (rst) begin
        curr_state <= INIT;
        curr_path <= 128'b1;
        offset <= 0;
        count <= 0;
        leading_bit <= 2'b0;
        curr_char <= 0;
        wait_cycle <= 1;
        backtracks <= 0;
        first <= 1;
        finished <= 0;
        tot_chars <= 0;
        char_path <= 0;
        num_lefts <= 0;
    end
    else if (hd_enable) begin
        curr_state <= next_state;
        curr_path <= next_path;
        offset <= next_offset;
        count <= next_count;
        leading_bit <= next_leading_bit;
        curr_char <= next_char;
        wait_cycle = next_wait_cycle;
        backtracks = next_backtracks;
        first <= next_first;
        finished <= next_finished;
        tot_chars <= next_tot_chars;
        char_path <= next_char_path;
      	num_lefts <= next_num_lefts;
      
    end
end

always_comb begin
    next_count = count;
    next_state = curr_state;
    next_path = curr_path;
    next_offset = offset;
    next_char = curr_char;
    next_backtracks = backtracks;
    next_leading_bit = leading_bit;
    next_wait_cycle = wait_cycle;
    SRAM_data_out = curr_path;
    char_index = curr_char;
    next_first = first;
    next_finished = finished;
    next_tot_chars = tot_chars;
    next_char_path = char_path;
    next_num_lefts = num_lefts;

    SPI_read_en = 0;
    SRAM_write_en = 0;

    case (curr_state)
        INIT: begin // if the controller's enable is set high for hd_decode to start or not
            if (hd_enable) begin
                 if (count < 2) begin
                    next_count = count + 1;
                 end
                 else if (count > 1) begin
                    next_count = 0;
                    SPI_read_en = 1;
                    next_state = READ_LEADING_BIT; // SET_PATH;
                 end
            end
            else begin
                next_state = INIT;
            end
        end

        READ_LEADING_BIT: begin // parses leading bit(s) of a char (1 if no backtrack), (0 if backtrack)
          if (offset < 8) begin
            next_leading_bit = {1'b1, SPI_data_in[7-offset[2:0]]}; // add 1 to beginning to leading bit to show a leading bit was read (not none)
            next_offset = offset + 1;
            if (next_leading_bit[0] == 0) begin
              next_state = READ_LEADING_BIT; // read the leading bit until a leading 1 is found
              next_backtracks = backtracks + 1; // keep track of the number of backtracks for curr char's path
            end
            else begin // first part of left char hasn't been read (num of lefts in path)
              next_state = READ_CHAR; // READ_CHAR;
            end
          end
          else begin // get next SPI byte
            SPI_read_en = 1;
            next_offset = offset - 8;
          end
        end
      
        READ_NUM_LEFTS: begin
          if (offset < 8) begin
            if (count < 8) begin // read 8 bits of the data into the char index
              next_num_lefts[7-count[2:0]] = SPI_data_in[7-offset[2:0]];
              next_count = count + 1;
              next_offset = offset + 1;
            end
            else begin
              next_state = UPDATE_PATH; // after reading num_lefts of curr left char, read curr left char
              next_count = 0;
            end
          end
          else begin // once 8 bits of SPI data is read, get a new chunk
            SPI_read_en = 1;
            next_offset = offset - 8;
          end
        end

        READ_CHAR: begin
          if (offset < 8) begin
            if (count < 8) begin // read 8 bits of the data into the char index
              next_char[7- count[2:0]] = SPI_data_in[7-offset[2:0]];
              next_count = count + 1;
              next_offset = offset + 1;
            end
            else begin
              if (SPI_data_in[7-offset[2:0]] == 1 && curr_char != 8'b00001010) begin // read # lefts of left char first
                next_state = READ_NUM_LEFTS;
                next_offset = offset + 1;
              end
              else if (curr_char == 8'b00001010 && leading_bit[0]) begin // if char is a newline, read total number of chars after it
                next_state = READ_TOT_CHAR;
              end
              else begin
                next_state = UPDATE_PATH; // after fetching the char, update the current path
              end
              next_count = 0;
            end
          end
          else begin // once 8 bits of SPI data is read, get a new chunk
            SPI_read_en = 1;
            next_offset = offset - 8;
          end
        end
       
        UPDATE_PATH: begin
            if (offset < 8) begin
                    if (backtracks == 1) begin
                        next_path = {curr_path[127:1], 1'b1}; // if on the last backtrack, shift out last move and move right
                        next_backtracks = backtracks - 1;
                        if (SPI_data_in[7-offset[2:0]] == 0) begin // if the char is a right then write the path
                            next_state = WRITE_PATH;
                        end
                    end
                    else if (backtracks > 0) begin // continue to backtrack until only one backtrack is left
                                next_path = {1'b0, curr_path[127:1]}; // backtrack by shifting out last move
                                next_backtracks = backtracks - 1; // remove one from backtracks
                    end
                    else begin // if backtracks are 0
                      if (SPI_data_in[7-offset[2:0]] == 1) begin // if curr_char is a left
                        if (char_path[0] == 0 && count == 0 && !first) begin // if prev char was a left
                                next_path = {curr_path[126:0], 1'b1}; // add a right
                                next_count = 1;
                              end
                              if (num_lefts != 0) begin// if the left char hasn't been moved left the right amount of times after moving right once
                                next_path = {next_path[126:0], 1'b0}; // add left to end of the path
                                next_num_lefts = num_lefts - 1; 
                              end
                              else begin // if the curr char is a left and the number of lefts to move is 0
                                next_state = WRITE_PATH;
                                next_count = 0;
                              end
                        end
                        else begin // add right once if the char is a right and there were no backtracks
                            next_path = {curr_path[126:0], 1'b1};
                            next_state = WRITE_PATH;
                        end

                    end
              end
              else begin // if offset was >= 8, reset and get a new SPI byte
                SPI_read_en = 1;
                next_offset = offset - 8;
              end
          end

        WRITE_PATH: begin
          if (first) begin // if first found char path is being written, reset next_first to 0 (finish condition of path being = to 128'b1 won't be false positive)
                next_first = 0;
            end
          if (count < 1) begin // wait one cycle for path to be set 
                SRAM_write_en = 1;
                char_index = curr_char;
                SRAM_data_out = curr_path;
                next_count = count + 1;
                next_char_path = curr_path;
            end
            else begin // then shift out last move
                next_path = {1'b0, curr_path[127:1]}; // shift out last move
                next_state = READ_LEADING_BIT;
                next_count = 0;
            end
        end
        READ_TOT_CHAR: begin
            if (count < 32) begin // read 4 bytes of data from SPI to get 32 bits of data for tot_chars
                if (offset < 8) begin // if curr bit is within valid index of SPI read byte (0-7)
                    next_tot_chars[31-count] = SPI_data_in[7-offset];
                    next_count = count + 1;
                    next_offset = offset + 1;
                end
                else begin // once 8 bits of SPI data is read, get a new chunk
                    SPI_read_en = 1;
                    next_offset = offset - 8;
                end
            end
            else begin
                next_count = 0;
                next_state = FINISH;
            end
        end
        FINISH: begin
            next_finished = 1;
        end
        default: begin next_state = curr_state; end
    endcase
end

endmodule;