module t05_histogram(
    input logic clk, rst, clear,
    input logic [7:0] data, // SPI input
    output logic eof,
    output logic [31:0] total,
    output logic [31:0] hist [0:255]

);
logic [7:0] shift; //assign end_file to what the end of the file would be
logic [7:0] end_file = 8'b00011010;

always_ff @( posedge clk, posedge rst ) begin 
    if (rst) begin
        for (int i = 0; i<= 255; i++) begin
            hist[i] = '0;
        end
    end else if (!eof) begin
        hist[data] <= hist[data] + 1;
    end    
end

always_ff @(posedge clk, posedge rst) begin
	if (rst) begin
        shift <= 8'b0;
        eof <= 0;
	end else begin
        shift <= data;
	end 

	if (end_file == shift) begin
		eof <= 1;
    end else begin
        eof <= 0;
	end
end

always_ff @( posedge clk, posedge rst ) begin 
        if (rst || clear) begin
            total <= 32'b0;
        end else begin
            total <= total + 1;
        end
        
end
endmodule