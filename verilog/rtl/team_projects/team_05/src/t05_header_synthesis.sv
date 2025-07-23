module t05_header_synthesis (
    input logic clk,
    input logic rst,
    input logic [7:0] char_index, // index (character) found from cb synthesis module
    input logic char_found, // from cb synthesis module to indicate a char was found
    input logic [8:0] least1, // least 1 of the htree element of which the character was found from cb synthesis
    input logic [8:0] least2, // least 2 of the htree element of which the character was found from cb synthesis
    output logic [8:0] header, // portion of the header (1 followed by the character) created within this module
    output logic enable, // waits one cycle after character was found to decide how many zeroes to add to the end of the char
    output logic bit1, // bit sent to the SPI
    output logic write_finish // sent to the cb synthesis to indicate all bits of header portion were written
);
logic char_added; // char added will be high once char is found
logic [3:0] zeroes; // number of zeroes to add after character bits are written
logic [3:0] count; // counter used to keep track of the correct number of zeroes sent

// next state logic
logic [8:0] next_header; 
logic [3:0] next_count;
logic next_bit1;
logic next_enable;
logic [3:0] next_zeroes;
logic next_char_added;
logic next_write_finish;
logic start;

always_ff @(posedge clk, posedge rst) begin
    if (rst) begin
        header <= 9'b0;
        zeroes <= 0;
        enable <= 0;
        count <= 0;
        bit1 <= 0;
        char_added <= 0;
        write_finish <= 0;
    end
    else begin
        header <= next_header;
        zeroes <= next_zeroes;
        enable <= next_enable;
        count <= next_count;
        bit1 <= next_bit1;
        char_added <= next_char_added;
        write_finish <= next_write_finish;
    end
end

always_comb begin
    next_header = header;
    next_zeroes = zeroes;
    next_enable = enable;
    next_count = count;
    next_bit1 = bit1;
    next_char_added = char_added;
    next_write_finish = 0;

    if ((char_found == 1'b1)) begin
        next_header = {1'b1, char_index}; // add control bit, beginning 1, and character index for header
        next_char_added = 1;
        next_zeroes = 0;
        start = 0;
    end
    else if (char_added == 1'b1) begin
        if (least1[8] == 1'b0 && least2[8] == 1'b0 && header[7:0] == least2[7:0]) begin // if both least1 and least2 are characters and state is backtrack (both chars have been found)
            next_zeroes = 4'b0010;
        end
        else if ((least1[8] == 1'b1 && least2[8] == 1'b0) || (least2[8] == 1'b1 && least1[8] == 1'b0)) begin  // if only either least 1 or least 2 is a sum and the other is a character
            next_zeroes = 4'b1;
        end
        else begin
            next_zeroes = 4'b0; // otherwise, only the left character was found, and the right char hasn't been found, so don't add zeroes to this char
        end
        next_char_added = 1'b0;
        start = 1; // when start is 1, set enable high
    end
    else begin
        start = 0;
        next_char_added = 1'b0;
    end
    if (start) begin // set enable high
        next_enable = 1;
        start = 0;
    end
    // shift register logic
    if (enable && (count < 9)) begin // while leading 1 and char are being added
        next_bit1 = header[8];
        next_header = {header[7:0], 1'b0}; // shift out msb to write
        next_count = count + 1;
    end
    else if (enable && count >= 9) begin // if count is greater than 9 (leading one and 8 bits of char have been written)
        if (count < (zeroes + 9)) begin // this will add either 0, 1, or 2 zeroes depending on states described above
            next_count = count + 1;
            next_bit1 = 1'b0;
        end
        else begin // once all zeroes have been added, set all enables low and indicate that write has been finished to cb synthesis
            next_bit1 = 1'b0;
            next_enable = 0;
            next_count = 0;
            next_write_finish = 1;
        end
    end

end
endmodule