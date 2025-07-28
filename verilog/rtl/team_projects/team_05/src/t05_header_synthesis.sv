module t05_header_synthesis (
    input logic clk,
    input logic rst,
    input logic [7:0] char_index,
    input logic char_found,
    input logic [8:0] least1,
    input logic [8:0] least2,
    input logic [127:0] char_path,
    input logic [127:0] curr_path,
    input logic [6:0] track_length,
    input state_cb state,
    input logic first_char,
    output logic [8:0] header,
    output logic enable,
    output logic bit1,
    output logic write_finish
);
logic char_added;
logic [8:0] next_header;
logic [7:0] zeroes;
logic [7:0] next_zeroes;
logic next_enable;
logic [7:0] count;
logic [7:0] next_count;
logic [8:0] path_count;
logic [8:0] next_path_count;
logic next_bit1;
logic next_char_added;
logic next_write_finish;
logic start;
logic next_write_zeroes;
logic write_zeroes;
logic next_start;
logic zero_sent;
logic next_zero_sent;
logic write_char_path;
logic next_write_char_path;
logic next_first_char;
logic [127:0] first_char_path, next_first_char_path;

always_ff @(posedge clk, posedge rst) begin
    if (rst) begin
        header <= 9'b0;
        zeroes <= 0;
        enable <= 0;
        count <= 0;
        bit1 <= 0;
        char_added <= 0;
        write_finish <= 0;
        write_zeroes <= 0;
        start <= 0;
      zero_sent <= 0;
      write_char_path <= 0;
      path_count <= 0;
      first_char_path <= 0;
    end
    else begin
        header <= next_header;
        zeroes <= next_zeroes;
        enable <= next_enable;
        count <= next_count;
        bit1 <= next_bit1;
        char_added <= next_char_added;
        write_finish <= next_write_finish;
        write_zeroes <= next_write_zeroes;
        start <= next_start;
      zero_sent <= next_zero_sent; 
      write_char_path <= next_write_char_path;
      path_count <= next_path_count;
      first_char_path <= next_first_char_path;
    end
end

always_comb begin
    next_header = header;
    next_zeroes = zeroes;
    next_enable = enable;
    next_count = count;
    next_bit1 = bit1;
    next_char_added = char_added;
    next_write_finish = write_finish;
    next_write_zeroes = write_zeroes;
    next_start = start;
    next_write_char_path = write_char_path;
    next_path_count = path_count;
    
    if ((char_found == 1'b1)) begin
        next_header = {1'b1, char_index}; // add control bit, beginning 1, and character index for header
        next_char_added = 1;
        next_enable = 0;
        next_start = 1;
        next_write_finish = 0;
        next_first_char_path = char_path;
    end
  if ((state == BACKTRACK && !char_added && !char_found && curr_path[0] == 1 && track_length > 0)) begin // send one zero for each backtrack (not while char is being added)
        next_write_zeroes = 1;
        next_enable = 1;
        next_write_finish = 0;
        next_bit1 = 0;
        zeroes = next_zeroes + 1;
    end
  else if (write_zeroes) begin // reset variables when state is no longer backtrack
    next_write_finish = 1;
    next_write_zeroes = 0;
    next_enable = 0;
    next_zeroes = 0;
  end

    if ((!write_char_path && first_char)) begin
        if (path_count < 9'd127) begin
            next_enable = 1;
            next_write_char_path = 0;
            next_bit1 = next_first_char_path[127-path_count];
            next_path_count = path_count + 1;
        end
        else begin
            next_bit1 = 0;
            next_write_char_path = 1;
            next_path_count = 0;
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
                next_write_finish = 1;
                next_bit1 = 0;
                next_count = 0;
                next_char_added = 0;
                next_zero_sent = 0;
            end
        end
        else begin
            next_bit1 = 1'b0;
            next_count = 0;
        end
    end
end
endmodule