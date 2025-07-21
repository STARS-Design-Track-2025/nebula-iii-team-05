`default_nettype none
module t05_hTree (
  input logic clk, rst_n,
  input logic [8:0] least1, least2,
  input logic [45:0] sum,
  input logic [63:0] nulls,//sum node to null sum from SRAM
  input logic [3:0] HT_en, // Enable signal for HTREE operation
  input logic SRAM_finished,
  output logic [70:0] tree_reg, null1_reg, null2_reg,// nodes to be written to SRAM
  output logic [6:0] clkCount,nullSumIndex,
  output logic HT_Finished,HT_fin_reg,
  //temp
  output logic [3:0] state_reg,//for testing
  output logic ERROR, WorR
);
    logic [6:0] clkCount_reg, nullSumIndex_reg;
    logic [8:0] least1_reg, least2_reg;
    logic [45:0] sum_reg;
    logic [70:0] null1, null2;
    logic [70:0] tree;
    logic SRAM_fin;
    logic HT_fin;
    logic HT_finished;
    logic err;

    // logic [6:0] scounter;
    // logic [6:0] clkCount;
    
    // ASSUMING LEAST, SUM VALUES, SRAM_FINISHED ARE REGISTERD VALUES

    // state machine
    logic [3:0] next_state;
    // logic [3:0] state_reg;
    
 typedef enum logic [3:0] {
        FIN=0,
        NEWNODE=1,
        L1SRAM=2,
        NULLSUM1=3,
        L2SRAM=4,
        NULLSUM2=5,
        RESET=6
    } state_t;
    state_t state;
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state <= NEWNODE;
        //reset all registers
        nullSumIndex <= 0;
        HT_fin_reg <= 0;
        null1_reg <= 71'b0;
        null2_reg <= 71'b0;
        tree_reg <= 71'b0;
        clkCount_reg <= 0;
        HT_Finished <= 1'b0;   
    end else begin
        state <= state_t'(next_state);
        clkCount_reg <= clkCount;

        least1_reg <= least1;
        least2_reg <= least2;
        sum_reg <= sum;
        tree_reg <= tree;
        null1_reg <= null1;
        null2_reg <= null2;
        nullSumIndex <= nullSumIndex_reg;
        SRAM_fin <= SRAM_finished;
        HT_fin_reg <= HT_fin;
        state_reg <= state;
        HT_Finished <= HT_finished;
        ERROR <= err;

    end
end

// SRAM access in order to get nulls to be reset
    always_comb begin

        tree = tree_reg;
        null1 = null1_reg;
        null2 = null2_reg;
        clkCount = clkCount_reg;  // Output current count value
        nullSumIndex_reg = nullSumIndex;
        next_state = state;
        HT_fin = HT_fin_reg;
        HT_finished = 1'b0;
        WorR = 1'b0; // Default write operation

        if (HT_en == 4'b0011) begin
            if (((least1[8] && least2 == 9'b110000000) || (least2[8] && least1 == 9'b110000000)) && least1 != least2) begin // single character file
                tree = {clkCount_reg, least1, 9'b110000000, sum};
                clkCount = clkCount_reg + 1;
                HT_finished = 1'b0; // If both least are null nodes, finish immediately
                next_state = RESET; // Go to reset state
            end else if (least1 == 9'b110000000 && least2 == 9'b110000000) begin // only activates if both are null
                HT_finished = 1'b1;
            end else begin
                case(state)
                    NEWNODE: begin
                        WorR = 1'b0; 
                        // if only least 1 is valid then l1 will be what it is and l2 is 11 then 0's
                        // no element least values are 11000... null characters are all 0's
                        tree = {clkCount_reg, least1, least2, sum};  // Uses clkCount_reg, not clkCount
                        clkCount = clkCount_reg + 1;  // Output current count (will be incremented next cycle)
                        if (least1[8] && least1 != 9'b110000000) begin // sum node not null node
                            next_state = L1SRAM;
                        end else if (least2[8] && least2 != 9'b110000000) begin
                            next_state = L2SRAM;
                        end else begin
                            next_state = FIN;
                        end
                        HT_finished = 1'b0;
                    end
                    L1SRAM: begin
                        WorR = 1'b1;
                        nullSumIndex_reg = least1[6:0]; 
                        if (SRAM_finished) begin 
                            next_state = NULLSUM1;

                        end else begin
                            next_state = L1SRAM;
                        end
                    end
                    NULLSUM1: begin
                        WorR = 1'b0;
                        null1 = {least1[6:0], nulls[63:46], 46'b0};
                        nullSumIndex_reg = 7'b0;
                        if (least2[8]) begin
                            next_state = L2SRAM;
                        end else begin
                            next_state = FIN;
                        end
                    end
                    L2SRAM: begin
                        WorR = 1'b1;
                        nullSumIndex_reg = least2[6:0];
                        if (SRAM_finished) begin
                            next_state = NULLSUM2;
                        end else begin
                            next_state = L2SRAM;
                        end
                    end
                    NULLSUM2: begin
                        WorR = 1'b0;
                        null2 = {least2[6:0], nulls[63:46], 46'b0};
                        nullSumIndex_reg = 7'b0;
                        next_state = FIN;
                    end
                    FIN: begin
                        HT_fin = 1'b1;
                        // Stay in FIN state while HT_en is high
                        // Module is ready for next operation when HT_en goes low
                        next_state = FIN;
                    end
                    default: begin
                        next_state = NEWNODE;
                    end
                endcase
            end
        end else begin
            // When HT_en is low, reset to NEWNODE for next operation
            next_state = NEWNODE;
            // Don't clear tree, null1, null2 - preserve the results
            nullSumIndex_reg = 7'b0;
            HT_fin = 1'b0;
            WorR = 1'b0;
        end

        // Error detection logic
        if(clkCount == 7'd0 && clkCount_reg == 7'd127) begin
            err = 1'b1;
        end else begin
            err = 1'b0;
        end
    end

endmodule
