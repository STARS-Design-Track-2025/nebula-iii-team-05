`default_nettype none
// Huffman Tree Construction Module
// This module builds Huffman tree nodes by combining least frequent nodes
// and handles SRAM operations for sum node null value lookups
module t05_hTree (
  // Clock and reset
  input logic clk, rst_n,

  // Input data from FLV module
  input logic [8:0] least1, least2,                     // From FLV - two least frequent nodes to combine
  input logic [63:0] sum,                               // From FLV - combined frequency sum for new node
  
  // SRAM interface
  input logic [63:0] nulls,                             // sum node to null sum from SRAM - null values for sum nodes
  input logic SRAM_finished,                            // from SRAM - indicates SRAM read operation complete
  
  // Control signals
  input logic [3:0] HT_en,                              // Enable signal for HTREE operation from controller

  input logic write_HT_fin,
  input logic sram_complete,
  input logic read_complete,
  
  // Output data to other modules
  output logic [70:0] node_reg,                         // nodes to be written to SRAM
  output logic [6:0] clkCount, nullSumIndex,            // to Sram (nullSumIndex for addressing), To Codebook (clkCount for indexing)
  
  //output logic [3:0] op_fin,                          // to controller - operation completion status
  output logic HT_fin_reg, HT_Finished,
  
  //TEMPORARY
  output logic WriteorRead,                             // to SRAM - Write or Read control signal (1=Read, 0=Write)
  output logic pulse,
  output logic [3:0] state
);

    // State machine type definition
    
 typedef enum logic [3:0] {
        FIN=0,                                          // Finished state - operation complete, waiting for disable
        NEWNODE=1,                                      // Create new tree node from input least1, least2
        L1SRAM=2,                                       // Read SRAM to get null values for least1 (sum node)
        NULLSUM1=3,                                     // Process null sum data for least1
        L2SRAM=4,                                       // Read SRAM to get null values for least2 (sum node)
        NULLSUM2=5,                                     // Process null sum data for least2
        RESET=6,                                        // Reset state for special cases
        IDLE=7,
        L2SRAM_WAIT = 8,
        L2SRAM_RUN = 9,
        L1SRAM_WAIT = 10,
        L1SRAM_RUN = 11
    } state_t;

    // Internal register declarations
    state_t /* state, */ next_state;                                      // Current state register
    logic [70:0] node;
    logic [6:0] clkCount_reg, nullSumIndex_reg;                     // Clock counter and SRAM address index
    logic [8:0] least1_reg, least2_reg;                             // Registered input node values
    logic [63:0] sum_reg;                                           // Registered sum value
    logic [70:0] null1, null2, null1_reg, null2_reg;                // Null node structures for sum nodes
    logic [70:0] tree, tree_reg;                                    // Current tree node being constructed
    logic HT_fin;                                                   // Huffman tree operation finished flag
    logic HT_finished;                                              // Huffman tree completely finished (both inputs null)
    logic [2:0] nullsum_delay_counter, nullsum_delay_counter_reg;   // Counter for NULLSUM state delays
    logic WorR;
    logic wait_cnt, wait_cnt_n;
    logic closing, closing_n;
    // ASSUMING LEAST, SUM VALUES, SRAM_FINISHED ARE REGISTERD VALUES
    logic pre_fin, pre_fin_n;
// Sequential logic block - handles state and register updates
always_ff @(posedge clk, posedge rst_n) begin
    if (rst_n) begin
        state <= NEWNODE;
        nullSumIndex <= 0;
        HT_fin_reg <= 0;
        null1_reg <= 71'b0;
        null2_reg <= 71'b0;
        tree_reg <= 71'b0;
        clkCount <= 0;
        HT_Finished <= 1'b0;   
        nullsum_delay_counter_reg <= 3'b0;   
        WriteorRead <= '0;
        wait_cnt <= 0;
        closing <= 0;
        pre_fin <= 0;
    end else if (HT_en == 4'b0011) begin
        state <= next_state;
        clkCount <= clkCount_reg;
        least1_reg <= least1;
        least2_reg <= least2;
        sum_reg <= sum;
        tree_reg <= tree;
        null1_reg <= null1;
        null2_reg <= null2;
        nullSumIndex <= nullSumIndex_reg;
        HT_fin_reg <= HT_fin;
        HT_Finished <= HT_finished;
        node_reg <= node;
        nullsum_delay_counter_reg <= nullsum_delay_counter;
        WriteorRead <= WorR; // Write or Read control signal
        wait_cnt <= wait_cnt_n;
        closing <= closing_n;
        pre_fin <= pre_fin_n;
    end
end

// SRAM access in order to get nulls to be reset
    // Main combinational logic block - handles Huffman tree construction algorithm
    always @(*) begin
        tree = tree_reg;
        null1 = null1_reg;
        null2 = null2_reg;
        clkCount_reg = clkCount;                            // Output current count value
        nullSumIndex_reg = nullSumIndex;
        next_state = state_t'(state);
        HT_fin = HT_fin_reg;
        HT_finished = 1'b0;
        WorR = 1'b0;                                        // Default write operation
        pulse = 0;
        node = node_reg;                                    // Default to current node value
        nullsum_delay_counter = nullsum_delay_counter_reg;  // Default to current counter value
        wait_cnt_n = wait_cnt;
        closing_n = closing;
        pre_fin_n = pre_fin;

        // Main state machine logic based on HT enable signal
        if (HT_en == 4'b0011) begin
            pre_fin_n = (least1 == 9'b110000000 && least2 == 9'b110000000);
            // Special case: single character file (one node with null)
            if (((least1[8] && least2 == 9'b110000000) || (least2[8] && least1 == 9'b110000000)) && least1 != least2) begin
                if((least1[8] && least2 == 9'b110000000) && least1 != 9'b110000000) begin
                    tree = {clkCount, least1, 9'b110000000, sum[45:0]};
                    closing_n = 1;
                    //next_state = NEWNODE;
                end else if((least2[8] && least1 == 9'b110000000) && least2 != 9'b110000000) begin
                    tree = {clkCount, 9'b110000000, least2, sum[45:0]};
                    closing_n = 1;
                    //next_state = NEWNODE;
                end else begin
                    tree = {clkCount, 9'b110000000, 9'b110000000, sum[45:0]};
                    closing_n = 1;
                    //next_state = NEWNODE;
                end
            // Special case: both nodes are null (NULL + NULL case)
            end 

            if (least1 == 9'b110000000 && least2 == 9'b110000000 && !write_HT_fin) begin
                HT_finished = 1'b1;
                tree = {clkCount, 9'b11000000, 9'b110000000, sum[45:0]};
            end else begin
                // Regular Huffman tree construction state machine
                case(state)
                    NEWNODE: begin
                        WorR = 1'b0; 
                        // Create new internal node from two least frequent nodes
                        // Tree format: {clkCount, least1, least2, sum}
                        if(!write_HT_fin && !closing) begin
                            tree = {clkCount, least1, least2, sum[45:0]};                   // Uses clkCount_reg, not clkCount
                            pulse = 1;
                        end else if (!write_HT_fin) begin
                            pulse = 1;
                        end
                        else if (write_HT_fin) begin
                            // Check if least1 is a sum node (not null) and needs SRAM access
                            if (least1[8] && least1 != 9'b110000000) begin
                                next_state = L1SRAM;
                            // Check if least2 also needs SRAM access
                            end else if (least2[8] && least2 != 9'b110000000) begin
                                next_state = L2SRAM;
                            // Neither node needs SRAM access, go to finish
                            end else if (sram_complete) begin
                                clkCount_reg = clkCount + 2;                                        // Output current count (will be incremented next cycle)
                                next_state = FIN;
                            end
                        end
                        HT_finished = 1'b0;
                        node = tree;                                                        // tree was most recently updated
                    end
                    L1SRAM: begin
                        // Access SRAM for least2 node data
                        WorR = 1'b1;
                        nullSumIndex_reg = least1[6:0];
                        next_state = L1SRAM_WAIT;
                        node = node_reg;                    // no update, keep previous value
                        wait_cnt_n = 0;
                    end
                    L1SRAM_WAIT: begin
                        WorR = 1;
                        if(wait_cnt) begin
                            next_state = L1SRAM_RUN;
                        end
                        else begin
                            next_state = L1SRAM_WAIT;
                            wait_cnt_n = wait_cnt + 1;
                        end
                    end
                    L1SRAM_RUN: begin
                        WorR = 0;
                        nullSumIndex_reg = least1[6:0];
                        if (read_complete) begin
                            next_state = NULLSUM1;
                        end else begin
                            next_state = L1SRAM_RUN;
                        end
                        node = node_reg;                    // no update, keep previous value
                    end
                    NULLSUM1: begin
                        // Process SRAM data for least1 and prepare null1
                        WorR = 1'b0;
                        null1 = {least1[6:0], nulls[63:46], 46'b0};
                        //nullSumIndex_reg = 7'b0;
                        
                        // // Multi-cycle delay within NULLSUM1 state
                        // if (nullsum_delay_counter_reg < 3'd3) begin
                        //     // Still counting delay cycles
                        //     nullsum_delay_counter = nullsum_delay_counter_reg + 1;
                        //     next_state = NULLSUM1; // Stay in this state
                        // end else begin
                        //     // Delay complete, reset counter and move to next state
                        //     nullsum_delay_counter = 3'b0;
                            // Check if least2 also needs SRAM access
                        if (least2[8] && least2 != 9'b110000000) begin
                            next_state = L2SRAM;
                        end else if (sram_complete) begin
                            clkCount_reg = clkCount + 2;
                            next_state = FIN;
                        end
                        // end
                        node = null1;                                                   // null1 was most recently updated
                    end
                    L2SRAM: begin
                        // Access SRAM for least2 node data
                        WorR = 1'b1;
                        nullSumIndex_reg = least2[6:0];
                        next_state = L2SRAM_WAIT;
                        node = node_reg;                    // no update, keep previous value
                        wait_cnt_n = 0;
                    end
                    L2SRAM_WAIT: begin
                        WorR = 1;
                        if(wait_cnt) begin
                            next_state = L2SRAM_RUN;
                        end
                        else begin
                            next_state = L2SRAM_WAIT;
                            wait_cnt_n = wait_cnt + 1;
                        end
                    end
                    L2SRAM_RUN: begin
                        WorR = 0;
                        nullSumIndex_reg = least2[6:0];
                        if (read_complete) begin
                            next_state = NULLSUM2;
                        end else begin
                            next_state = L2SRAM_RUN;
                        end
                        node = node_reg;                    // no update, keep previous value
                    end
                    NULLSUM2: begin
                        // Process SRAM data for least2 and prepare null2
                        WorR = 1'b0;
                        null2 = {least2[6:0], nulls[63:46], 46'b0};
                        //nullSumIndex_reg = 7'b0;
                        
                        // Multi-cycle delay within NULLSUM2 state
                        // if (nullsum_delay_counter_reg < 3'd3) begin
                        //     // Still counting delay cycles
                        //     nullsum_delay_counter = nullsum_delay_counter_reg + 1;
                        //     next_state = NULLSUM2;                                      // Stay in this state
                        if (sram_complete) begin
                            // Delay complete, reset counter and move to next state
                            nullsum_delay_counter = 3'b0;
                            clkCount_reg = clkCount + 2;
                            next_state = FIN;
                        end
                        node = null2;                                                   // null2 was most recently updated
                    end
                    FIN: begin
                        // Final state - signal completion
                        HT_fin = 1'b1;
                        // Stay in FIN state while HT_en is high
                        // Module is ready for next operation when HT_en goes low
                        next_state = IDLE;
                        node = node_reg;                    // no update, keep previous value
                    end
                    IDLE: begin
                        HT_fin = 1'b0;
                        node = node_reg;
                        if(HT_en == 3) begin
                            next_state = NEWNODE;
                        end
                    end
                    default: begin
                        // Error handling - return to initial state
                        next_state = NEWNODE;
                        node = node_reg;                    // no update, keep previous value
                    end
                endcase
            end
        end else begin
            if(HT_en == 0) begin
                // When HT_en is low, reset to NEWNODE for next operation
                next_state = NEWNODE;
                // Don't clear tree, null1, null2 - preserve the results
                nullSumIndex_reg = 7'b0;
                HT_fin = 1'b0;
                WorR = 1'b0;
                node = 71'b0;                           // no update, keep previous value
                nullsum_delay_counter = 3'b0;           // Reset delay counter when disabled
            end
        end
    end
endmodule