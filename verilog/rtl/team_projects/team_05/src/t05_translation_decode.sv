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
    output logic finished,
    output logic [8:0] SRAM_count
); 
state_tr curr_state, next_state;
logic [3:0] SPI_count, next_SPI_count; // count to 7 and room incase of overflow
logic [8:0] next_SRAM_count; // count to 256 (for code paths for each char from SRAM)
logic [7:0] next_char_index;
logic [127:0] SPI_path, next_SPI_path; // store 7 bytes from SPI in a path
logic [7:0] path_bit_count, next_path_bit_count; // counter to 128
logic match, next_match;
logic curr_chars_found, next_chars_found;
logic next_finished;
logic next_SPI_data_out;

always_ff @(posedge clk, posedge rst) begin
    if (rst) begin
        SPI_count <= 0;
        SRAM_count <= 0;
        curr_state <= INIT;
        char_index <= next_char_index;
        path_bit_count <= 0;
        SPI_path <= 0;
        match <= 0;
        curr_chars_found <= 0;
        finished <= 0;
        SPI_data_out <= 0;
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

    SPI_read_en = 0;
    SPI_write_en = 0;
    SRAM_read_en = 0;

    case (curr_state)
        INIT:begin
             if (translation_enable) begin
                next_state = READ_SRAM_PATH;
                SPI_read_en = 1;
             end
             else begin
                next_state = INIT;
             end
        end
        READ_SRAM_PATH: begin
            if (SRAM_count > 255) begin
                next_SRAM_count = 0;
            end
            else begin
                SRAM_read_en = 1;
                next_char_index = SRAM_count[7:0];
                next_SRAM_count = SRAM_count + 1;
                next_state = READ_SPI_PATH;
            end
        end
        READ_SPI_PATH: begin
            if (path_bit_count >= 128 && match) begin
                next_path_bit_count = 0;
                if (curr_chars_found != tot_chars) begin
                    next_state = COMPARE_PATHS;
                end
                else begin
                    next_state = FINISH;
                end
            end
            else if (path_bit_count < 128 && !match) begin
                if (SPI_count < 8) begin
                    next_SPI_path[127 - path_bit_count[6:0]] = SPI_data_in[7 - SPI_count[2:0]];
                    next_SPI_count = SPI_count + 1;
                    next_path_bit_count = path_bit_count + 1;
                end
                else begin
                    SPI_read_en = 1;
                    next_SPI_count = 0;
                end
            end
        end
        COMPARE_PATHS: begin
            if (path_bit_count < 128) begin
                    if (SPI_path[path_bit_count[6:0]] != SRAM_data_in[path_bit_count[6:0]]) begin
                        next_state = READ_SRAM_PATH; // if a nonmatching bit is found, read another SRAM path and compare it with
                        next_match = 0; // no match found, read another SRAM path and compare it to this SPI path
                    end
                    next_path_bit_count = path_bit_count + 1;
            end
            else begin // if all 128 bits of the two paths are the same, write the SRAM char index bit by bit
                next_path_bit_count = 0;
                next_state = WRITE_PATH;
                next_match = 1; // a match was found, write the char index of the curr SRAM path, and then read the next SRAM then SPI path
            end
        end
        WRITE_PATH: begin
            SPI_write_en = 1;
            if (SPI_count < 8) begin
                next_SPI_data_out = char_index[7-SPI_count]; 
                next_SPI_count = SPI_count + 1;
            end
            else begin
                next_SPI_count = 0;
                next_SPI_path = 128'b0;
                next_state = READ_SRAM_PATH;
                next_chars_found = curr_chars_found + 1;
            end
        end
        FINISH: begin
            next_finished = 1;
        end
        default: begin
            next_state = curr_state;
        end
    endcase

end

endmodule;