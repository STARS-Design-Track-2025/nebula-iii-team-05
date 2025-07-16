module t05_sram(
    input logic clk, rst, wr_en,
    input logic [3:0] word_i, 
    input logic[31:0] data_i, addr,
    output logic busy_o,
    output logic [31:0] data_o
);
    
endmodule