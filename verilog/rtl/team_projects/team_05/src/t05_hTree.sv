`default_nettype none
module t05_hTree (
  input logic clk, rst_n,
  input logic [8:0] least1, least2,
  input logic [45:0] sum,
  input logic [63:0] nulls,//sum node to null sum
  input logic HT_en,
  input logic cont_en,SRAM_finished,
  output logic [70:0] tree, null1, null2,// nodes to be written to SRAM
  output logic [6:0] clkCount,nullSumIndex,
  output logic HT_Finished,HT_fin_reg
);
    logic [6:0] clkCount_reg, nullSumIndex_reg;
    logic [8:0] least1_reg, least2_reg;
    logic [45:0] sum_reg;
    logic [70:0] null1_reg, null2_reg;
    logic [70:0] tree_reg;
    logic SRAM_fin;
    logic HT_fin;

    // logic [6:0] scounter;
    // logic [6:0] clkCount;
    
    // ASSUMING LEAST, SUM VALUES, SRAM_FINISHED ARE REGISTERD VALUES

    // state machine
    logic [3:0] next_state;
    logic [3:0] state_reg;
    
 typedef enum logic [3:0] {
        FIN=0,
        NEWNODE=1,
        L1SRAM=2,
        NULLSUM1=3,
        L2SRAM=4,
        NULLSUM2=5
    } state_t;
    state_t state;
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state <= NEWNODE;
        //reset all registers
        nullSumIndex <= 0;
        HT_fin_reg <= 0;
    end else begin
        state <= state_t'(next_state);
        clkCount_reg <= clkCount;

        // least1_reg <= least1;
        // least2_reg <= least2;
        // sum_reg <= sum;
        tree_reg <= tree;
        null1_reg <= null1;
        null2_reg <= null2;
        nullSumIndex <= nullSumIndex_reg;
        SRAM_fin <= SRAM_finished;
        HT_fin_reg <= HT_fin;

    end
end

// SRAM access in order to get nulls to be reset
    always_comb begin

        tree = 71'b0;
        null1 = 71'b0;
        null2 = 71'b0;
        clkCount = 7'b0;
        nullSumIndex_reg = 7'b0;
        next_state = state_reg;
        HT_fin = 1'b0;
        HT_Finished = 1'b0;

    if (HT_en) begin
        if (sum == 46'b0) begin
            HT_Finished = 1'b1;
        end else begin
            case(state_reg)
                NEWNODE: begin
                    tree = {clkCount_reg,least1, least2, sum};
                    clkCount = clkCount_reg + 1;
                    if (least1_reg[8]) begin
                        next_state = L1SRAM;
                    end else if (least2_reg[8]) begin
                        next_state = L2SRAM;
                    end else begin
                        next_state = FIN;
                    end
                end
                L1SRAM: begin
                    nullSumIndex_reg = least1[6:0]; 
                    if (SRAM_finished) begin 
                        next_state = NULLSUM1;

                    end else begin
                        next_state = L1SRAM;
                    end
                end
                NULLSUM1: begin
                    null1 = {least1[6:0], nulls[63:46], 46'b0};
                    nullSumIndex_reg = 7'b0;
                    if (least1_reg[8]) begin
                        next_state = L2SRAM;
                    end else begin
                        next_state = FIN;
                    end
                end
                L2SRAM: begin
                    nullSumIndex_reg = least2[6:0];
                    if (SRAM_finished) begin
                        next_state = NULLSUM2;
                    end else begin
                        next_state = L2SRAM;
                    end
                end
                NULLSUM2: begin
                    null2 = {least2[6:0], nulls[63:46], 46'b0};
                    nullSumIndex_reg = 7'b0;
                    next_state = FIN;
                end
                FIN: begin
                    HT_fin = 1'b1;
                    if (!HT_en) begin
                        next_state = NEWNODE;
                    end else begin
                        next_state = FIN;
                    end
                end
                default: begin
                    next_state = NEWNODE;
                end
            endcase
        end
        end
    end
endmodule
