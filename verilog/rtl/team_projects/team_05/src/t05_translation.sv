module t05_translation (
    input logic clk, rst,
    input logic [31:0] totChar,
    input logic [7:0] charIn,
    input logic [127:0] path,
    output logic writeBin
);
    logic [7:0] index, index_n;
    logic [3:0] count, count_n;
    logic countEn, countEn_n, nextCharEn, nextCharEn_n, totalEn, totalEn_n, writeBin_n;
    logic [1:0]state, state_n;

    always_ff @(posedge clk, posedge rst) begin
        if(rst) begin
            index <= 8'd31;
            writeBin <= '0;
            countEn <= '0;
            nextCharEn <= '0;
            state <= '0;
            totalEn <= 1;
        end else begin
            writeBin <= writeBin_n;
            countEn <= countEn_n;
            nextCharEn <= nextCharEn_n;
            index <= index_n;
            state <= state_n;
            totalEn <= totalEn_n;
        end
    end

    always_ff @(posedge clk, posedge rst) begin
        if(rst) begin
            count <= '0;
        end else if (countEn) begin
            count <= count_n;
        end
    end



    always_comb begin
        index_n = index;
        nextCharEn_n = nextCharEn;
        countEn_n = countEn;
        writeBin_n = writeBin;
        count_n = count;
        state_n = state;
        totalEn_n = totalEn;

        if(index == 0 && totalEn == 1) begin 
            totalEn_n = 0;
            index_n = 8'd127;
        end

        if(totalEn == 1) begin
            writeBin_n = totChar[index[4:0]];
            if(index != 0) begin
                index_n = index - 1;  
            end
        end else if(totalEn == 0) begin
            

        end
    end
endmodule