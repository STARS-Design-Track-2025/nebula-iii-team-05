module t05_translation (
    input logic clk, rst,
    input logic [3:0] en_state,                     //Enable State
    input logic [31:0] totChar,                     //Total number of characters in file
    input logic [7:0] charIn,                       //Character coming in from the SPI
    input logic [127:0] path,                       //Path obtained from SRAM
    output logic writeBin, nextCharEn, writeEn,     //writeBin == bit being written into file, nextCharEn calls for the next character, writeEn means to write to file 
    output logic fin_state                          //Finish State
);
    logic [6:0] index, index_n;
    logic resEn, resEn_n;
    logic writeEn_n, nextCharEn_n, totalEn, totalEn_n;

    always_ff @(posedge clk, posedge rst) begin
        if(rst) begin
            index <= 7'd31;
            writeEn <= '0;
            nextCharEn <= '0;
            totalEn <= 1;
            resEn <= '0;
        end else if (en_state == 5) begin
            writeEn <= writeEn_n;
            nextCharEn <= nextCharEn_n;
            index <= index_n;
            totalEn <= totalEn_n;
            resEn <= resEn_n;
        end
    end

    always @(*) begin
        index_n = index;
        nextCharEn_n = nextCharEn;
        writeEn_n = writeEn;
        resEn_n = resEn;
        totalEn_n = totalEn;
        writeBin = 0;
        fin_state = 0;

        if(resEn == 1) begin 
            totalEn_n = 0;
            index_n = 7'd127;
            nextCharEn_n = 1;
            writeEn_n = 0;
            resEn_n = 0;
        end else if(totalEn == 1) begin
            writeEn_n = 1;
            writeBin = totChar[index[4:0]];
            index_n = index - 1;  
            if(index == 0 && index_n == 127) begin
                resEn_n = 1;
            end
        end else if(totalEn == 0) begin
            nextCharEn_n = 0;
            index_n = index - 1;
            if(charIn == 8'b00011010) begin
                fin_state = 1;
                writeEn_n = 0;
            end else begin
                if(path[index] == 1) begin
                    writeEn_n = 1;
                end
                if(writeEn == 1) begin
                    writeBin = path[index];
                end
                if(index == 0 && index_n == 127) begin
                    writeEn_n = 0;
                    resEn_n = 1;
                end
            end
        end
    end
endmodule