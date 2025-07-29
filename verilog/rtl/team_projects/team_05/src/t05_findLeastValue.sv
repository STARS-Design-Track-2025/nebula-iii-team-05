module t05_findLeastValue (
    input logic clk, rst,
    input logic [63:0] compVal,
    input logic [3:0] en_state,
    output logic [63:0] sum,
    output logic [7:0] charWipe1, charWipe2,
    output logic [8:0] least1, least2, histo_index,
    output logic [2:0] fin_state
);
logic [8:0] least1_n, least2_n, count_n, sumCount;
logic [63:0] val1, val2, val1_n, val2_n, sum_n;
logic [7:0] charWipe1_n, charWipe2_n;
logic nextCharEn; // Missing declaration

always_ff @(posedge clk, posedge rst) begin
    if(rst) begin
        least1 <= 0;
        least2 <= 0;
        histo_index <= 0;
        charWipe1 <= 0;
        charWipe2 <= 0;
        sum <= 0;
        val1 <= 64'hFFFFFFFFFFFFFFFF;
        val2 <= 64'hFFFFFFFFFFFFFFFF;
    end else if (en_state == 2) begin
        least1 <= least1_n;
        least2 <= least2_n;
        histo_index <= count_n;
        charWipe1 <= charWipe1_n;
        charWipe2 <= charWipe2_n;
        sum <= sum_n;
        val1 <= val1_n;
        val2 <= val2_n;
    end
end

always_comb begin
    if(histo_index < 385) begin
        count_n = histo_index + 1;
    end else begin
        count_n = 0;
    end
end

always_comb begin
    val1_n = val1;
    val2_n = val2;
    charWipe1_n = charWipe1;
    charWipe2_n = charWipe2;
    least1_n = least1;
    least2_n = least2;
    sumCount = histo_index - 256;
    sum_n = sum;
    nextCharEn = 0;

    if(compVal != 0 && histo_index < 384) begin
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
            nextCharEn = 1;
        end
        if(val1 != 64'hFFFFFFFFFFFFFFFF && val2 != 64'hFFFFFFFFFFFFFFFF) begin
            sum_n = val1 + val2;
        end
    end
    if(histo_index == 384) begin
        fin_state = 2;
    end else begin
        fin_state = 0;
    end
end
endmodule