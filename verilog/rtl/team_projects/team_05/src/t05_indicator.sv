module t05_indicator (
    input logic clk, rst_n, cont_en, // Clock, reset, continue enable
    input logic [3:0] finState, state_en,         // Module completion signals (assumed to be registered)
    input logic [2:0] op_fin,
    output logic [7:0] left, right, ss7, ss6, ss5, ss4, ss3, ss2, ss1, ss0,
    output logic red, green, blue
);
    logic [3:0] fin_state_reg, state_en_reg; // Current state output for other modules
    logic [2:0] op_fin_reg;
    logic [7:0] left_reg, right_reg, ss7_reg, ss6_reg, ss5_reg, ss4_reg, ss3_reg, ss2_reg, ss1_reg, ss0_reg; // Indicator outputs
    logic red_reg, green_reg, blue_reg; // Color indicator outputs

    // Register the input signals on the rising edge of the clock
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            fin_state_reg <= 4'b0;
            op_fin_reg <= 3'b0;
            state_en_reg <= 4'b0;
            left <= 8'b0;
            right <= 8'b0;
            ss7 <= 8'b0;
            ss6 <= 8'b0;
            ss5 <= 8'b0;
            ss4 <= 8'b0;
            ss3 <= 8'b0;
            ss2 <= 8'b0;
            ss1 <= 8'b0;
            ss0 <= 8'b0;
            red <= 1'b0;
            green <= 1'b0;
            blue <= 1'b0;
        end else begin
            fin_state_reg <= finState;
            op_fin_reg <= op_fin;
            state_en_reg <= state_en;
            left <= left_reg;
            right <= right_reg;
            ss7 <= ss7_reg;
            ss6 <= ss6_reg;
            ss5 <= ss5_reg;
            ss4 <= ss4_reg;
            ss3 <= ss3_reg;
            ss2 <= ss2_reg;
            ss1 <= ss1_reg;
            ss0 <= ss0_reg;
            red <= red_reg;
            green <= green_reg;
            blue <= blue_reg;
        end
    end


    always_comb begin
        // Default values for the indicator outputs
        left_reg = 8'b0;
        right_reg = 8'b0;
        ss7_reg = 8'b0;
        ss6_reg = 8'b0;
        ss5_reg = 8'b0;
        ss4_reg = 8'b0;
        ss3_reg = 8'b0;
        ss2_reg = 8'b0;
        ss1_reg = 8'b0;
        ss0_reg = 8'b0;
        red_reg = 1'b0;
        green_reg = 1'b0;
        blue_reg = 1'b0;

        // Update the indicators based on the current state
        case (state_en_reg) 
            4'b0000: begin
                ss7_reg = 8'b00000000;
                ss6_reg = 8'b00000000;
                ss5_reg = 8'b00000110; // I
                ss4_reg = 8'b01011110; // D
                ss3_reg = 8'b00111000; // L
                ss2_reg = 8'b01111001; // E
                ss1_reg = 8'b00000000;
                ss0_reg = 8'b00000000;
            end
            4'b0001: begin
                ss7_reg = 8'b00000001;
                ss6_reg = 8'b00000000;
                ss5_reg = 8'b01110110; // H
                ss4_reg = 8'b00000110; // I
                ss3_reg = 8'b01101101; // S
                ss2_reg = 8'b01111000; // T
                ss1_reg = 8'b00000000;
                ss0_reg = 8'b00000000;
            end
            4'b0010: begin
                ss7_reg = 8'b00000001;
                ss6_reg = 8'b00000000;
                ss5_reg = 8'b00000000;
                ss4_reg = 8'b01110001; // F
                ss3_reg = 8'b00111000; // L
                ss2_reg = 8'b00111110; // V
                ss1_reg = 8'b00000000;
                ss0_reg = 8'b00000000;
            end
            4'b0011: begin
                ss7_reg = 8'b00000001;
                ss6_reg = 8'b00000000;
                ss5_reg = 8'b01110110; // H
                ss4_reg = 8'b01111000; // T
                ss3_reg = 8'b01010000; // R
                ss2_reg = 8'b01111001; // E
                ss1_reg = 8'b01111001; // E
                ss0_reg = 8'b00000000;
            end
            4'b0100: begin
                ss7_reg = 8'b00000001;
                ss6_reg = 8'b00000000;
                ss5_reg = 8'b00000000;
                ss4_reg = 8'b00111001; // C
                ss3_reg = 8'b01111100; // B
                ss2_reg = 8'b01101101; // S
                ss1_reg = 8'b00000000;
                ss0_reg = 8'b00000000;
            end
            4'b0101: begin
                ss7_reg = 8'b00000001;
                ss6_reg = 8'b00000000;
                ss5_reg = 8'b00000000;
                ss4_reg = 8'b01111000; // T
                ss3_reg = 8'b01010000; // R
                ss2_reg = 8'b01010100; // N
                ss1_reg = 8'b00000000;
                ss0_reg = 8'b00000000;
            end
            4'b0110: begin
                ss7_reg = 8'b00000001;
                ss6_reg = 8'b00000000;
                ss5_reg = 8'b00000000;
                ss4_reg = 8'b01101101; // S
                ss3_reg = 8'b01110011; // P
                ss2_reg = 8'b00000110; // I
                ss1_reg = 8'b00000000;
                ss0_reg = 8'b00000000;
            end
            4'b0111: begin
                ss7_reg = 8'b00000001;
                ss6_reg = 8'b01111001; // E
                ss5_reg = 8'b01010000; // R
                ss4_reg = 8'b01010000; // R
                ss3_reg = 8'b00111111; // O
                ss2_reg = 8'b01010000; // R
                ss1_reg = 8'b00000000;
                ss0_reg = 8'b00000000;
            end
            4'b1000: begin
                ss7_reg = 8'b00000001;
                ss6_reg = 8'b00000000;
                ss5_reg = 8'b01011110; // D
                ss4_reg = 8'b00111111; // O
                ss3_reg = 8'b01010100; // N
                ss2_reg = 8'b01111001; // E
                ss1_reg = 8'b00000000;
                ss0_reg = 8'b00000000;
            end
            default: begin
                ss7_reg = 8'b01000000;
                ss6_reg = 8'b01000000;
                ss5_reg = 8'b01000000;
                ss4_reg = 8'b01000000;
                ss3_reg = 8'b01000000;
                ss2_reg = 8'b01000000;
                ss1_reg = 8'b01000000;
                ss0_reg = 8'b01000000;
            end
        endcase

        case (op_fin_reg) 
            3'b000: begin
                left_reg = 8'b10000000;
            end
            3'b001: begin
                left_reg = 8'b01000000; 
            end
            3'b010: begin
                left_reg = 8'b00100000;
            end
            3'b011: begin
                left_reg = 8'b00010000;
            end
            3'b100: begin
                left_reg = 8'b00001000;
            end
            3'b101: begin
                left_reg = 8'b00000100;
            end
            3'b110: begin
                left_reg = 8'b00000010;
            end
            3'b111: begin
                left_reg = 8'b11111111; // Error state
            end
            default: begin
                left_reg = left_reg; // Default case
            end
        endcase

        case (fin_state_reg) 
            4'b0000: begin
                right_reg = 8'b10000000;
            end
            4'b0001: begin
                right_reg = 8'b01000000; 
            end
            4'b0010: begin
                right_reg = 8'b00100000;
            end
            4'b0011: begin
                right_reg = 8'b00010000;
            end
            4'b0100: begin
                right_reg = 8'b00001000;
            end
            4'b0101: begin
                right_reg = 8'b00000100;
            end
            4'b0110: begin
                right_reg = 8'b00000010;
            end
            4'b0111: begin
                right_reg = 8'b00000001;
            end
            default: begin
                right_reg = right_reg; // Default case
            end
        endcase

        if (fin_state_reg == 4'b1000 || op_fin_reg == 3'b111 || state_en_reg == 4'b0111) begin
            // Error state
            red_reg = 1'b1;
            green_reg = 1'b0;
            blue_reg = 1'b0;
        end else if (state_en_reg == 4'b1000) begin
            // finished state
            red_reg = 1'b0;
            green_reg = 1'b1;
            blue_reg = 1'b0;
        end else begin
            // Normal operation state
            red_reg = 1'b0;
            green_reg = 1'b0;
            blue_reg = 1'b1;
        end

    end

endmodule