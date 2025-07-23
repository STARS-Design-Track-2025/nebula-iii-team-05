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
  // Output data to other modules
  output logic [70:0] node_reg,   // nodes to be written to SRAM
  output logic [6:0] clkCount, nullSumIndex,            // to Sram (nullSumIndex for addressing), To Codebook (clkCount for indexing)
  output logic [3:0] op_fin,                            // to controller - operation completion status
  //TEMPORARY
    //  output logic [3:0] state_reg,//for testing
  output logic WriteorRead                                     // to SRAM - Write or Read control signal (1=Read, 0=Write)
);
    // Internal register declarations
    // logic [70:0] tree_reg, null1_reg, null2_reg;
    logic [70:0] node;
    logic [6:0] clkCount_reg, nullSumIndex_reg;         // Clock counter and SRAM address index
    logic [8:0] least1_reg, least2_reg;                 // Registered input node values
    logic [63:0] sum_reg;                               // Registered sum value
    logic [70:0] null1, null2, null1_reg, null2_reg;                          // Null node structures for sum nodes
    logic [70:0] tree, tree_reg;                                  // Current tree node being constructed
    logic SRAM_fin;                                     // Registered SRAM finished signal
    logic HT_fin;                                       // Huffman tree operation finished flag
    logic HT_finished;                                  // Huffman tree completely finished (both inputs null)
    logic err;                                          // Error detection flag
    logic HT_Finished,HT_fin_reg,ERROR;                 // Status and control flags
    logic [2:0] nullsum_delay_counter, nullsum_delay_counter_reg; // Counter for NULLSUM state delays
    logic WorR;
    // logic [3:0] state_reg;                              // State register for debugging

    // logic [6:0] scounter;
    // logic [6:0] clkCount;
    
    // ASSUMING LEAST, SUM VALUES, SRAM_FINISHED ARE REGISTERD VALUES

    // State machine type definition
    logic [3:0] next_state; // Next state combinational logic
    
 typedef enum logic [3:0] {
        FIN=0,                                          // Finished state - operation complete, waiting for disable
        NEWNODE=1,                                      // Create new tree node from input least1, least2
        L1SRAM=2,                                       // Read SRAM to get null values for least1 (sum node)
        NULLSUM1=3,                                     // Process null sum data for least1
        L2SRAM=4,                                       // Read SRAM to get null values for least2 (sum node)
        NULLSUM2=5,                                     // Process null sum data for least2
        RESET=6                                         // Reset state for special cases
    } state_t;
    state_t state;                                      // Current state register
// Sequential logic block - handles state and register updates
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        // Reset all state machine and registers to initial values
        state <= NEWNODE;
        //reset all registers
        nullSumIndex <= 0;
        HT_fin_reg <= 0;
        null1_reg <= 71'b0;
        null2_reg <= 71'b0;
        tree_reg <= 71'b0;
        clkCount_reg <= 0;
        HT_Finished <= 1'b0;   
        nullsum_delay_counter_reg <= 3'b0;   
    end else begin
        // Clock all signals on positive edge
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
        HT_Finished <= HT_finished;
        ERROR <= err;
        node_reg <= node;
        nullsum_delay_counter_reg <= nullsum_delay_counter;
        WriteorRead <= WorR; // Write or Read control signal

    end
end

// SRAM access in order to get nulls to be reset
    // Main combinational logic block - handles Huffman tree construction algorithm
    always_comb begin

        // Default assignments to prevent latches and maintain current values
        tree = tree_reg;
        null1 = null1_reg;
        null2 = null2_reg;
        clkCount = clkCount_reg;            // Output current count value
        nullSumIndex_reg = nullSumIndex;
        next_state = state;
        HT_fin = HT_fin_reg;
        HT_finished = 1'b0;
        WorR = 1'b0;                        // Default write operation
        op_fin = 4'b0000; 
        node = node_reg;                    // Default to current node value
        nullsum_delay_counter = nullsum_delay_counter_reg; // Default to current counter value
        // Default operation finish signal

        // Main state machine logic based on HT enable signal
        if (HT_en == 4'b0011) begin
            // Special case: single character file (one node with null)
            if (((least1[8] && least2 == 9'b110000000) || (least2[8] && least1 == 9'b110000000)) && least1 != least2) begin
                if((least1[8] && least2 == 9'b110000000) && least1 != 9'b110000000) begin
                    // Create tree node with least1 and null2
                    tree = {clkCount_reg, least1, 9'b110000000, sum[45:0]};
                end else if((least2[8] && least1 == 9'b110000000) && least2 != 9'b110000000) begin
                    // Create tree node with least2 and null1
                    tree = {clkCount_reg, 9'b110000000, least2, sum[45:0]};
                end else begin
                    // Both are null nodes, create a special case tree node
                    tree = {clkCount_reg, 9'b110000000, 9'b110000000, sum[45:0]};
                end
                clkCount = clkCount_reg + 1;
                HT_finished = 1'b0;                     // If both least are null nodes, finish immediately
                next_state = RESET;                     // Go to reset state
            // Special case: both nodes are null (NULL + NULL case)
            end else if (least1 == 9'b110000000 && least2 == 9'b110000000) begin
                HT_finished = 1'b1;
                op_fin = 4'b0100; // Signal completion with op_fin
            end else begin
                // Regular Huffman tree construction state machine
                case(state)
                    NEWNODE: begin //1
                        WorR = 1'b0; 
                        // Create new internal node from two least frequent nodes
                        // Tree format: {clkCount, least1, least2, sum}
                        tree = {clkCount_reg, least1, least2, sum[45:0]};             // Uses clkCount_reg, not clkCount
                        clkCount = clkCount_reg + 1;                            // Output current count (will be incremented next cycle)
                        // Check if least1 is a sum node (not null) and needs SRAM access
                        if (least1[8] && least1 != 9'b110000000) begin
                            next_state = L1SRAM;
                        // Check if least2 also needs SRAM access
                        end else if (least2[8] && least2 != 9'b110000000) begin
                            next_state = L2SRAM;
                        // Neither node needs SRAM access, go to finish
                        end else begin
                            next_state = FIN;
                        end
                        HT_finished = 1'b0;
                        node = tree; // tree was most recently updated
                    end
                    L1SRAM: begin // 2
                        // Access SRAM for least1 node data
                        WorR = 1'b1;
                        nullSumIndex_reg = least1[6:0]; 
                        if (SRAM_finished) begin 
                            next_state = NULLSUM1;

                        end else begin
                            next_state = L1SRAM;
                        end
                        node = node_reg; // no update, keep previous value
                    end
                    NULLSUM1: begin // 3
                        // Process SRAM data for least1 and prepare null1
                        WorR = 1'b0;
                        null1 = {least1[6:0], nulls[63:46], 46'b0};
                        nullSumIndex_reg = 7'b0;
                        
                        // Multi-cycle delay within NULLSUM1 state
                        if (nullsum_delay_counter_reg < 3'd3) begin
                            // Still counting delay cycles
                            nullsum_delay_counter = nullsum_delay_counter_reg + 1;
                            next_state = NULLSUM1; // Stay in this state
                        end else begin
                            // Delay complete, reset counter and move to next state
                            nullsum_delay_counter = 3'b0;
                            // Check if least2 also needs SRAM access
                            if (least2[8]) begin
                                next_state = L2SRAM;
                            end else begin
                                next_state = FIN;
                            end
                        end
                        node = null1; // null1 was most recently updated
                    end
                    L2SRAM: begin // need internal delay // 4
                        // Access SRAM for least2 node data
                        WorR = 1'b1;
                        nullSumIndex_reg = least2[6:0];
                        if (SRAM_finished) begin
                            next_state = NULLSUM2;
                        end else begin
                            next_state = L2SRAM;
                        end
                        node = node_reg; // no update, keep previous value
                        
                    end
                    NULLSUM2: begin // 5
                        // Process SRAM data for least2 and prepare null2
                        WorR = 1'b0;
                        null2 = {least2[6:0], nulls[63:46], 46'b0};
                        nullSumIndex_reg = 7'b0;
                        
                        // Multi-cycle delay within NULLSUM2 state
                        if (nullsum_delay_counter_reg < 3'd3) begin
                            // Still counting delay cycles
                            nullsum_delay_counter = nullsum_delay_counter_reg + 1;
                            next_state = NULLSUM2; // Stay in this state
                        end else begin
                            // Delay complete, reset counter and move to next state
                            nullsum_delay_counter = 3'b0;
                            next_state = FIN;
                        end
                        node = null2; // null2 was most recently updated
                    end
                    FIN: begin // 6
                        // Final state - signal completion
                        HT_fin = 1'b1;
                        // Stay in FIN state while HT_en is high
                        // Module is ready for next operation when HT_en goes low
                        next_state = FIN;
                        node = node_reg; // no update, keep previous value
                    end
                    default: begin
                        // Error handling - return to initial state
                        next_state = NEWNODE;
                        node = node_reg; // no update, keep previous value
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
            node = 71'b0; // no update, keep previous value
            nullsum_delay_counter = 3'b0; // Reset delay counter when disabled
        end

        // Error detection logic
        if(clkCount == 7'd0 && clkCount_reg == 7'd127) begin
            err = 1'b1;
        end else begin
            err = 1'b0;
        end

        // op fin sent to controller
        if (ERROR) begin
            op_fin = 4'b1000; // Indicate error operation finish
        end else if (HT_Finished) begin
            op_fin = 4'b0100;
        end else if (HT_fin_reg) begin
            op_fin = 4'b0011;
        end else begin
            op_fin = 4'b0000; // Default operation finish signal
        end
    end

endmodule