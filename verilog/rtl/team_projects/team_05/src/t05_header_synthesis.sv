module t05_header_synthesis (
    input logic clk,
    input logic rst,
    input logic [7:0] char_index,
    input logic char_found,
    input logic [8:0] least1,
    input logic [8:0] least2,
    input logic [127:0] char_path,
    output logic [9:0] header
);
logic char_added;
logic [9:0] next_header;
always_ff @(posedge clk, posedge rst) begin
    if (rst) begin
        header <= 10'b0;
    end
    else begin
        header <= next_header;
    end
end

always_comb begin
    next_header = header;
    if (char_found == 1'b1) begin
        next_header = {2'b11, char_index}; // add control bit, beginning 1, and character index for header
        char_added = 1;
    end
    else if (char_added == 1'b1) begin
        if (least1[8] == 1'b0 && least2[8] == 1'b0 && header[7:0] == least2[7:0]) begin // if both least1 and least2 are characters and state is backtrack (both chars have been found)
            next_header = {7'b0, 3'b100}; // add two ending 0's plus control bit (for two characters)
        end
        else if ((least1[8] == 1'b1 && least2[8] == 1'b0) || (least2[8] == 1'b1 && least1[8] == 1'b0)) begin  // if only either least 1 or least 2 is a sum and the other is a character
            next_header = {8'b0, 2'b10}; // add one ending 0 for one character
        end
        char_added = 1'b0;
    end
    else begin
        char_added = 1'b0;
    end
end
endmodule