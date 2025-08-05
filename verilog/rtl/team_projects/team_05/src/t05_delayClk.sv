module t05_delayClk (
    input logic clk, rst,
    input logic delay_start,
    output logic delay_done
);
    logic [17:0] index;
    logic delay_start_reg;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            index <= 18'b0;
            delay_done <= 1'b0;
            delay_start_reg <= 1'b0;
        end else begin
            delay_start_reg <= delay_start;    
            
            if (delay_start_reg) begin         
                if (index < 18'd10) begin
                    index <= index + 1;
                    delay_done <= 1'b0;
                end else begin
                    delay_done <= 1'b1;
                    index <= 18'b0; // Reset index after delay is done
                end
            end else begin
                index <= 18'b0;
                delay_done <= 1'b0;
            end
        end
    end
endmodule