module t05_findLeastValue (
    input logic clk, rst,
    input logic [63:0] compVal,                         //Value being compared to least1 and least2, either a histogram value or sum
    input logic [3:0] en_state,                         //Enable state
    output logic [63:0] sum,                            //Sum of two values
    output logic [7:0] charWipe1, charWipe2,            //Characters to be wiped from SRAM
    output logic [8:0] least1, least2, histo_index,     //Least values and the index for the next value from SRAM
    output logic fin_state                              //Finish Enable
);
logic [8:0] least1_n, least2_n, count_n, sumCount;
logic [63:0] val1, val2, val1_n, val2_n, sum_n;
logic [7:0] charWipe1_n, charWipe2_n;
logic fin_state_n;

always_ff @(posedge clk, posedge rst) begin
    if(rst) begin
        least1 <= 9'b110000000;
        least2 <= 9'b110000000;
        histo_index <= 0;
        charWipe1 <= 0;
        charWipe2 <= 0;
        sum <= 0;
        val1 <= '1;
        val2 <= '1;
        fin_state <= 0;
    end else if (en_state == 2) begin
        least1 <= least1_n;
        least2 <= least2_n;
        histo_index <= count_n;
        charWipe1 <= charWipe1_n;
        charWipe2 <= charWipe2_n;
        sum <= sum_n;
        val1 <= val1_n;
        val2 <= val2_n;
        fin_state <= fin_state_n;
    end
end

always @(*) begin
    if(histo_index < 385) begin
        count_n = histo_index + 1;
    end else begin
        count_n = 0;
    end
end

always @(*) begin
    val1_n = val1;
    val2_n = val2;
    charWipe1_n = charWipe1;
    charWipe2_n = charWipe2;
    least1_n = least1;
    least2_n = least2;
    sumCount = histo_index - 256;
    sum_n = sum;
    fin_state_n = fin_state;

    // if(histo_index == 0) begin
    //     fin_state_n = 0;
    // end

    if(compVal != 0 && histo_index < 384 && histo_index != 0) begin
        if(val1 > compVal && histo_index < 256) begin
            least2_n = least1;
            charWipe2_n = charWipe1;
            val2_n = val1;
            least1_n = {1'b0, histo_index [7:0]};
            charWipe1_n = histo_index[7:0];
            val1_n = compVal;
        end else if (val2 > compVal && histo_index < 256) begin
            least2_n = {1'b0, histo_index[7:0]};
            charWipe2_n = histo_index[7:0];
            val2_n = compVal;
        end else if (val1 > compVal && histo_index > 255) begin
            least2_n = least1;
            charWipe2_n = charWipe1;
            val2_n = val1;
            least1_n = {1'b1, sumCount[7:0]};
            charWipe1_n = '0;
            val1_n = compVal;
        end else if (val2 > compVal && histo_index > 255) begin
            least2_n = {1'b1, sumCount[7:0]};
            charWipe2_n = '0;
            val2_n = compVal;
        end
    end

    if(val1 == '1 && val2 == '1) begin
        least1_n = 384;
        least2_n = 384;
    end

    if(val1 != '1 && val2 != '1) begin
        sum_n = val1 + val2;
    end
    if(histo_index == 384) begin
        fin_state_n = 1;
    end
end
endmodule