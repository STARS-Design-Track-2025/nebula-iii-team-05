module clkdiv(
    input logic clk_in, rst,
    output logic five_ms_clk, fifty_ms_clk, hundred_ns_clk
);
logic [17:0] five_counter, fifty_counter, hundred_couter;
    always_ff @(posedge clk_in, posedge rst) begin
        if (rst) begin
            five_counter <= 18'b0;
            fifty_counter <= '0;
            hundred_couter <= '0;
            five_ms_clk <= 0;
            hundred_ns_clk <= 0;
            fifty_ms_clk <= 0;
        end else begin 
            if (five_counter >= 4999) begin
                five_ms_clk <= 1;
                five_counter <= 18'b0;
            end 
            if (fifty_counter >= 49999) begin
                fifty_ms_clk <= 1;
                fifty_counter <= '0;
            end if (hundred_couter >= 0.099) begin
                hundred_ns_clk <= 1;
                hundred_couter <= 18'b0;
            end else begin
                    five_counter <= five_counter + 18'd1;
                    fifty_counter <= fifty_counter + '1;
                    hundred_couter <= hundred_couter + 18'd1;
                    five_ms_clk <= 0;
                    hundred_ns_clk <= 0;
                    fifty_counter <= 0;
            end
        end
    end



endmodule