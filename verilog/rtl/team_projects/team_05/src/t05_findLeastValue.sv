module t05_findLeastValue (
    input logic clk, rst,
    input logic [63:0] compVal,                         //Value being compared to least1 and least2, either a histogram value or sum
    input logic [3:0] en_state,                         //Enable state
    output logic [63:0] sum,                            //Sum of two values
    output logic [7:0] charWipe1, charWipe2,            //Characters to be wiped from SRAM
    output logic [8:0] least1, least2, histo_index,     //Least values and the index for the next value from SRAM
    output logic fin_state,                              //Finish Enable
    output logic flv_r_wr,
    output logic pulse_FLV,
    output logic wipe_the_char,
    input logic nextChar,
    input logic [3:0] word_cnt,
    input logic FLV_done
);
logic [8:0] least1_n, least2_n, count_n, sumCount;
logic [63:0] val1, val2, val1_n, val2_n, sum_n;
logic [7:0] charWipe1_n, charWipe2_n;
logic fin_state_n;
logic startup, startup_n;
logic alt;
logic [3:0] alternator_timer, alternator_timer_n;

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
        startup <= 1;
        alternator_timer <= 0;
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
        startup <= startup_n;
        alternator_timer <= alternator_timer_n;
    end
end

always @(*) begin
    count_n = histo_index;
    pulse_FLV = 0;
    startup_n = startup;
    alternator_timer_n = alternator_timer;
    alt = 0;

    if(histo_index == 0) begin
        if(alternator_timer < 5) begin
            alternator_timer_n = alternator_timer + 1;
        end else begin
            alt = 1;
            alternator_timer_n = 0;
        end
    end else if (histo_index > 255) begin
        if(alternator_timer < 9) begin
            alternator_timer_n = alternator_timer + 1;
        end else begin
            alt = 1;
            alternator_timer_n = 0;
        end
    end
    else begin
        if(alternator_timer < 4) begin
            alternator_timer_n = alternator_timer + 1;
        end else begin
            alt = 1;
            alternator_timer_n = 0;
        end
    end
    if(((histo_index < 384 && alt) || startup ) && en_state == 2) begin
        if(startup) begin
            count_n = 0;
            //pulse_FLV = 1;
        end
        else begin
            count_n = histo_index + 1;
        end
        pulse_FLV = 1;
        startup_n = 0;
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
    flv_r_wr = 0;
    wipe_the_char = 1;

    if(compVal != 0 && histo_index < 384 && histo_index != 26 && fin_state != 1) begin //&& histo_index != 0) begin
        if(val1 > compVal && histo_index < 256) begin
            least2_n = least1;
            charWipe2_n = charWipe1;
            val2_n = val1;
            least1_n = {1'b0, histo_index[7:0]};
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
            wipe_the_char = 0;
        end else if (val2 > compVal && histo_index > 255) begin
            least2_n = {1'b1, sumCount[7:0]};
            charWipe2_n = '0;
            val2_n = compVal;
            wipe_the_char = 0;
        end
    end

    if(val1 != '1 && val2 != '1) begin
        sum_n = val1 + val2;
    end
    if(histo_index == 384 && FLV_done) begin
        fin_state_n = 1;
        flv_r_wr = 1;
    end
end
endmodule