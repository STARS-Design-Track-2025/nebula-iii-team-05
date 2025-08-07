module t05_translation (
    input logic clk, rst,
    input logic [3:0] en_state,                     //Enable State
    input logic [31:0] totChar,                     //Total number of characters in file
    input logic [7:0] charIn,                       //Character coming in from the SPI
    input logic [127:0] path,                       //Path obtained from SRAM
    input logic sram_complete,                      //SRAM reading path is complete
    input logic [3:0] word_cnt,                     //SRAM State
    input logic ser_pulse,                          //Coming from sd_spi_tx 
    input logic head_bit,                           //Write bit from header
    input logic head_write_en,                      //Header write enable
    input logic write_complete_HS,                  //Header Synthesis has either completed writing or not
    output logic writeBin, nextCharEn, writeEn,     //writeBin == bit being written into file, nextCharEn calls for the next character, writeEn means to write to file 
    output logic pulse,                             //Goes to SRAM interface
    output logic input_valid,                       //Going to sd_spi_tx
    output logic [7:0] char_index,                  //Goes to SRAM
    output logic fin_state                          //Finish State
);
    logic [6:0] index, index_n;
    logic resEn, resEn_n;
    logic writeEn_n, nextCharEn_n, totalEn, totalEn_n;

    logic start, start_n;
    logic write_fin, write_fin_n;

    assign char_index = charIn;

    always_ff @(posedge clk, posedge rst) begin
        if(rst) begin
            index <= 7'd31;
            writeEn <= '0;
            nextCharEn <= '0;
            totalEn <= 1;
            resEn <= '0;
            start <= 1;
            write_fin <= 0;
        end else if (en_state == 5) begin
            writeEn <= writeEn_n;
            nextCharEn <= nextCharEn_n;
            index <= index_n;
            totalEn <= totalEn_n;
            resEn <= resEn_n;
            start <= start_n;
            write_fin <= write_fin_n;
        end
    end

    always @(*) begin
        index_n = index;
        nextCharEn_n = nextCharEn;
        writeEn_n = writeEn;
        resEn_n = resEn;
        totalEn_n = totalEn;
        start_n = start;
        write_fin_n = write_fin;
        writeBin = 0;
        fin_state = 0;
        pulse = 0;
        input_valid = 0;

        if(ser_pulse) begin
            if (en_state == 4) begin
                if(head_write_en) begin
                    writeBin = head_bit;
                    input_valid = 1;
                    writeEn_n = 0;
                end
                else if(write_complete_HS) begin
                    input_valid = 0;
                    writeBin = 0;
                end
            end else if(resEn == 1) begin 
                totalEn_n = 0;
                index_n = 7'd127;
                nextCharEn_n = 1;
                writeEn_n = 0;
                resEn_n = 0;
            end else if(totalEn == 1) begin
                writeEn_n = 1;
                writeBin = totChar[index[4:0]];
                input_valid = 1;
                index_n = index - 1;  
                if(index == 0 && index_n == 127) begin
                    resEn_n = 1;
                    pulse = 1;
                end
            end else if(totalEn == 0) begin
                nextCharEn_n = 0;
                if(charIn == 8'b00011010 && !sram_complete) begin
                    fin_state = 1;
                    writeEn_n = 0;
                end else begin
                    if(sram_complete && write_fin) begin
                        pulse = 1;
                        start_n = 0;
                        write_fin_n = 0;
                    end
                    else if (sram_complete) begin
                        index_n = index - 1;
                        if(path[index] == 1) begin
                            writeEn_n = 1;
                            write_fin_n = 0;
                        end
                        if(writeEn == 1) begin
                            writeBin = path[index];
                            input_valid = 1;
                        end
                        if(index == 0 && index_n == 127) begin
                            writeEn_n = 0;
                            write_fin_n = 1;
                            resEn_n = 1;
                        end
                    end
                end
            end
        end
    end
endmodule