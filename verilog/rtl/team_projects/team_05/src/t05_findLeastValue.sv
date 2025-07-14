module t05_findLeastValue (
    input logic clk, rst,
    input logic [63:0] compVal,
    input logic state,
    output logic [63:0] sum,
    output logic [7:0] charWipe1, charWipe2,
    output logic [8:0] least1, least2, count,
    output logic fin
);
logic [8:0] least1_n, least2_n, count_n, sumCount;
logic [63:0] val1, val2, val1_n, val2_n, sum_n;
logic [7:0] charWipe1_n, charWipe2_n;

always_ff @(posedge clk, posedge rst) begin
    if(rst) begin
        least1 <= 0;
        least2 <= 0;
        count <= 0;
        charWipe1 <= 0;
        charWipe2 <= 0;
        sum <= 0;
        val1 <= 64'hFFFFFFFFFFFFFFFF;
        val2 <= 64'hFFFFFFFFFFFFFFFF;
    end else if (state) begin
        least1 <= least1_n;
        least2 <= least2_n;
        count <= count_n;
        charWipe1 <= charWipe1_n;
        charWipe2 <= charWipe2_n;
        sum <= sum_n;
        val1 <= val1_n;
        val2 <= val2_n;
    end
end

always_comb begin
    if(count < 385) begin
        count_n = count + 1;
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
    sumCount = count - 256;
    sum_n = sum;

    if(compVal != 0 && count < 384) begin
        if(val1 > compVal && count < 256) begin
            least2_n = least1;
            charWipe2_n = charWipe1;
            val2_n = val1;
            least1_n = {1'b0, count [7:0]};
            charWipe1_n = count[7:0];
            val1_n = compVal;
        end else if (val2 > compVal && count < 256) begin
            least2_n = {1'b0, count[7:0]};
            charWipe2_n = count[7:0];
            val2_n = compVal;
        end else if (val1 > compVal && count > 255) begin
            least2_n = least1;
            charWipe2_n = charWipe1;
            val2_n = val1;
            least1_n = {1'b1, sumCount[7:0]};
            charWipe1_n = '0;
            val1_n = compVal;
        end else if (val2 > compVal && count > 255) begin
            least2_n = {1'b1, sumCount[7:0]};
            charWipe2_n = '0;
            val2_n = compVal;
        end
        if(val1 != 64'hFFFFFFFFFFFFFFFF && val2 != 64'hFFFFFFFFFFFFFFFF) begin
            sum_n = val1 + val2;
        end
    end
    if(count == 384) begin
        fin = 1;
    end else begin
        fin = 0;
    end
end
endmodule