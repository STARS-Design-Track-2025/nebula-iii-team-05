// typedef enum logic [3:0] {
//     INIT, // initial (set if enable for the hd_decode module isn't high)
//     SET_PATH, // set path of the first char found all the way left in the tree (first 128 bits of the header)
//     READ_LEADING_BIT, // read leading bit checks if there is a backtrack (0) or if another char was found (1)
//     READ_CHAR, // read 8 bits of the char from data_in after reading the leading bit(s)
//     CHECK_NEXT_CHAR, // will check how many lefts are needed for current char when previous char was also left
//     UPDATE_PATH, // after getting the character, use the # of backtrack and the bit after the char to update the path
//     WRITE_PATH, // once a full path is found, (after a char was found and corresponding path was updated with correct digits), send the path to SRAM with the curr char index
//     FINISH // finished writing all char codes from header
// } state_hd;


module t05_hd_decode (
    input logic clk, rst,
    input logic hd_enable,
    input logic [7:0] data_in_SPI, // read byte of header from SPI
    output logic read_en_SPI,
    output logic [127:0] data_out_SRAM, // write a char path to SRAM
    output logic write_en_SRAM
);
state_hd curr_state, next_state; 
logic [127:0] curr_path, next_path; 
logic [3:0] offset, next_offset; // marker to keep track of which bit in byte of data_in to read next
//logic next_read_en_SPI, next_write_en_SRAM;
logic [7:0] count, next_count;
logic [3:0] char_bit_count, next_char_bit_count;
logic [1:0] leading_bit, next_leading_bit;
logic [7:0] backtracks, next_backtracks;
logic [7:0] curr_char, next_char;
logic [7:0] char_check, next_char_check;
logic [7:0] first_char_path_len, next_first_char_path_len;

always_ff @(posedge clk, posedge rst) begin
    if (rst) begin
        curr_state <= INIT;
        curr_path <= 128'b0;
        offset <= 0;
        count <= 0;
        leading_bit <= 2'b0;
        char_bit_count <= 0;
        curr_char <= 0;
        char_check <= 0;
        first_char_path_len <= 0;
    end
    else if (hd_enable) begin
        curr_state <= next_state;
        curr_path <= next_path;
        offset <= next_offset;
        count <= next_count;
        leading_bit <= next_leading_bit;
        char_bit_count <= next_char_bit_count;
        curr_char <= next_char;
        char_check <= next_char_check;
        first_char_path_len <= next_first_char_path_len;
    end
end

always_comb begin
    next_count = count;
    next_state = curr_state;
    next_path = curr_path;
    next_offset = offset;
    next_char_bit_count = char_bit_count;
    next_char = curr_char;
    next_first_char_path_len = first_char_path_len;
    next_char_check = char_check;
    next_backtracks = backtracks;
    next_leading_bit = leading_bit;

    read_en_SPI = 0;
    write_en_SRAM = 0;

    case (curr_state)
        INIT: begin // if the controller's enable is set high for hd_decode to start or not
            if (hd_enable) begin 
                next_state = SET_PATH;
            end
            else begin
                next_state = INIT;
            end
        end
        SET_PATH: begin // set first 128 bits of header to the first char path to write to SRAM
            if (count < 8'd128) begin
                if (offset < 8) begin
                    next_path[count[6:0]] = data_in_SPI[offset[2:0]]; // transfer 128 bits of first char path to the curr_path
                    if (data_in_SPI[offset[2:0]] == 1'b1) begin // shows the actual beginning of the first char's path
                        next_first_char_path_len = 127-count;
                    end
                    next_count = count + 1;
                    next_offset = offset + 1;
                end
                else begin
                    read_en_SPI = 1;
                    next_offset = offset - 8;
                end
            end
            else begin
                next_state = READ_LEADING_BIT; // read leading bit of first char found to then parse the 8 char bits after it
                next_count = 0;
            end
        end
        READ_LEADING_BIT: begin // parses leading bit(s) of a char (1 if no backtrack), (0 if backtrack)
        if (backtracks == first_char_path_len) begin
                if (offset < 8) begin
                    next_leading_bit = {1'b1, data_in_SPI[offset[2:0]]}; // add 1 to beginning to leading bit to show a leading bit was read (not none)
                    next_offset = offset + 1;
                end
                else begin
                    read_en_SPI = 1;
                    next_offset = offset - 8;
                end
                if (leading_bit != 2'b0) begin
                    if (leading_bit[0] == 0) begin
                        next_state = READ_LEADING_BIT; // read the leading bit until a leading 1 is found
                        next_backtracks = backtracks + 1; // keep track of the number of backtracks for next char's path
                    end
                    else begin
                        next_state = READ_CHAR;
                        next_offset = offset + 1;
                    end
                end
            end
        end
        READ_CHAR: begin
            if (offset < 8) begin
                if (char_bit_count < 8) begin // read 8 bits of the data into the char index
                    next_char[next_char_bit_count[2:0]] = data_in_SPI[offset[2:0]];
                    next_char_bit_count = char_bit_count + 1;
                end
                else begin
                    next_state = UPDATE_PATH; // after fetching the char, update the current path
                    next_char_bit_count = 0;
                end
            end
            else begin // once 8 bits of SPI data is read, get a new chunk
                read_en_SPI = 1;
                next_offset = offset - 8;
            end
        end
        CHECK_NEXT_CHAR: begin
             if (offset < 8) begin
                if (char_bit_count < 8) begin // read 8 bits of the data into the char index
                    next_char_check[next_char_bit_count[2:0]] = data_in_SPI[offset[2:0]];
                    next_char_bit_count = char_bit_count + 1;
                end
                else begin
                    if (data_in_SPI[offset[2:0]] == 0) begin // the next and curr char are two leaf nodes of the current node
                        next_path = {curr_path[126:0], 1'b0}; // add another left the curr char path
                        next_state = WRITE_PATH;
                    end
                    next_char_bit_count = 0;
                end
            end
            else begin // once 8 bits of SPI data is read, get a new chunk
                read_en_SPI = 1;
                next_offset = offset - 8;
            end
        end
        UPDATE_PATH: begin
            if (offset < 8) begin
                if (backtracks == 1) begin
                    next_path = {curr_path[127:1], 1'b1}; // if on the last backtrack, shift out last move and move right
                    next_backtracks = backtracks - 1;
                end
                else if (backtracks > 0) begin
                    next_path = {1'b0, curr_path[127:1]}; // backtrack by shifting out last move
                    next_backtracks = backtracks - 1; // remove one from backtracks
                end
                else if (data_in_SPI[offset[2:0]] == 1) begin // if next char is a left
                    if (backtracks == 0) begin
                        next_path = {curr_path[125:0], 2'b10}; // if there were no backtracks (last char was a left), and next move is a left, move right and then left
                        next_state = CHECK_NEXT_CHAR; // check if the next char is the right to the current char to decide to add another left
                    end
                    else begin
                        next_path = {curr_path[126:0], 1'b0}; // add left to end of path
                    end
                end
                else if (data_in_SPI[offset[2:0]] == 0) begin // if a 0 follows the char, add last move as right
                    next_path = {curr_path[126:0], 1'b1};
                end
            end
        end
        WRITE_PATH: begin
            if (count < 1) begin
                write_en_SRAM = 1;
            end
            else begin
                next_path = {1'b0, curr_path[127:1]}; // shift out last move
                if (char_check == 8'b0) begin
                    next_state = READ_LEADING_BIT;
                end 
                else begin
                    next_state = UPDATE_PATH;
                    next_char = next_char_check;
                    next_char_check = 8'b0;
                end
            end
        end
        default: begin next_state = curr_state; end
    endcase
end

endmodule;