module t05_header_synthesis (
    input logic clk,
    input logic rst,
    input logic [7:0] char_index,
    input logic char_found,
    input logic curr_path,            /*[127:0]*/ 
    input logic [6:0] cb_length,
    input logic state8, // WRITE zeroes
    input logic state6, // WRITE char path and a 0 if it is a right char
    input logic left,                 //if the char found is a left char
    input logic [7:0] zeroes,
    input logic [7:0] num_lefts,      //num of lefts from htree
    input logic ser_pulse,            //Pulse from sd_spi_tx
    output logic write_complete,      //Going out to translation
    output logic enable,              //Going to translation
    output logic bit1,                //Going to translation
    output logic [7:0] zero_count
    //output logic new_zeroes,
    // output logic write_finish
);
logic char_added;
logic [8:0] next_header, header;
//logic [7:0] zeroes;
logic [7:0] next_zeroes;
logic next_enable;
logic [7:0] count;
logic [7:0] next_count;
logic next_bit1;
logic next_char_added;
logic start;
logic next_write_zeroes;
logic write_zeroes;
logic next_start;
logic write_char_path;
logic next_write_char_path;
logic write_num_lefts, next_write_num_lefts;
logic next_write_complete;
logic [7:0] next_zero_count;

always_ff @(posedge clk, posedge rst) begin
    if (rst) begin
      header <= 9'b0;
      //zeroes <= 0;
      enable <= 0;
      count <= 0;
      bit1 <= 0;
      char_added <= 0;
      write_zeroes <= 0;
      start <= 0;
      write_char_path <= 0;
      write_num_lefts <= 0;
      write_complete <= 0;
      zero_count <= 0;
    end
    else begin
      header <= next_header;
      //zeroes <= next_zeroes;
      enable <= next_enable;
      count <= next_count;
      bit1 <= next_bit1;
      char_added <= next_char_added;
      write_zeroes <= next_write_zeroes;
      start <= next_start;
      write_char_path <= next_write_char_path;
      write_num_lefts <= next_write_num_lefts;
      write_complete <= next_write_complete;
      zero_count <= next_zero_count;
    end
end

always_comb begin
    next_header = header;
    //next_zeroes = zeroes;
    next_enable = enable;
    next_count = count;
    next_bit1 = bit1;
    next_char_added = char_added;
    next_write_zeroes = write_zeroes;
    next_start = start;
    next_write_char_path = write_char_path;
    next_write_num_lefts = write_num_lefts;
    next_write_complete = write_complete;
    next_zero_count = zero_count;

    
    if ((char_found == 1'b1)) begin
      next_header = {1'b1, char_index}; // add control bit, beginning 1, and character index for header
      next_char_added = 1;
      next_enable = 0;
      next_start = 1;
      next_write_char_path = 1;
      next_write_complete = 0;
      next_zero_count = 0;
    end
    if (zeroes != 0 && state8) begin // send one zero for each backtrack (not while char is being added)
      next_write_zeroes = 1;
      next_enable = 1;
      next_bit1 = 0;
      //next_zeroes = zeroes + 1;
      next_write_complete = 0;
    end
    else if (write_zeroes) begin // reset variables when state is no longer backtrack
      if (zero_count < zeroes) begin
        next_zero_count = zero_count + 1;
      end
      else begin
        next_write_zeroes = 0;
        next_enable = 0;
        //next_zeroes = 0;
        next_write_complete = 1;
        next_zero_count = 0;
      end
    end

    if (write_char_path) begin
        if (start) begin
            next_enable = 1;
            next_start = 0;
            next_bit1 = header[8];
            next_header = {header[7:0], 1'b0}; // shift out msb to write (first occurrence)
            next_count = count + 1;
            next_char_added = 1;
        end
        else if (enable && char_added) begin // if {1'b1, char} is now in the header, send the 9 bits to the SPI bit by bit
            if (count < 9) begin
                next_bit1 = header[8];
                next_header = {header[7:0], 1'b0};
                next_count = count + 1;
            end
            else begin // once all bits are sent, reset all intermediate variables and set write_finish to 1
                next_count = 0;
                next_enable = 0;
                next_bit1 = 0;
                next_char_added = 0;
              	next_write_char_path = 0;
              if (num_lefts != 0 && left) begin
                next_write_num_lefts = 1;
                end
              if (num_lefts == 0) begin
                next_write_complete = 1;
              end
              // if (zeroes != 0 && curr_path) begin
              //   next_write_complete = 0;
              //   next_write_zeroes = 1;
              //   next_enable = 1;
              //   next_bit1 = 0;
              // end
            end
        end
        else begin
            next_bit1 = 1'b0;
            next_count = 0;
        end
    end
  if (write_num_lefts) begin // write the number of lefts after going right in the tree for left chars after their header portion
    if(count == 0) begin // add 1 as first bit
        next_bit1 = 1'b1;
        next_count = count + 1;
        next_write_char_path = 0;
        next_enable = 1;
        next_write_complete = 0;
      end
    else if (count < 9) begin // write 8 bit # of lefts and a leading 1
      next_enable = 1;
      next_bit1 = num_lefts[8-count];
      next_count = count + 1;
    end
    else begin
      next_count = 0;
      next_enable = 0;
      next_bit1 = 0;
      next_write_num_lefts = 0;
      next_write_complete = 1;
    end
  end
end
endmodule