module t05_histogram(
    input logic clk, rst,
    input logic [7:0] addr_i, //sram_addr_in,// SPI and sram address input
    input logic [31:0] sram_in, //character index from the sram
    output logic eof,  //end of file enable going to the controller
    output logic complete,  //end of byte going to the controller (might not need)
    output logic [31:0] total, sram_out, //total number of 8 bit inputs that have came through and the sram output with the new "+ 1" value to the sram_in
    output logic [7:0] hist_addr // the address given to the sram

);

//should be giving an addr to sram then sram will give back the index to that coresponding address then the hist will add 1 to it then give it back to the sram to be stored
logic clear;
logic [7:0] shift; //assign end_file to what the end of the file would be
logic [7:0] end_file = 8'b00011010;



always_ff @( posedge clk, posedge rst) begin : blockName
    if (rst || eof) begin
        sram_out <= 0;
        hist_addr <= 0;
        shift <= shift;
        total <= total;
        complete <= 0;
    end else begin
        sram_out <= sram_in + 1;  //the old index will have 1 added to it and by used as sram_out
        hist_addr <= addr_i;  // the data_i will be used as the addr
        shift <= addr_i; // the shift will be replaced with the data_in and the eof will trigger if it matches the endfile byte
        total <= total +1;  // the total characters will be added onto each other
    end

    if (end_file == shift) begin
        eof <= 1;
    end else begin
        eof <= 0;
    end

    if (eof && !rst) begin
        complete <= 1;
    end
end

endmodule