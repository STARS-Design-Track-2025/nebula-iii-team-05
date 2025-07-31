// Team 05 Controller Module
// Main state machine controller for Huffman encoding compression pipeline
// Manages sequential execution of: HISTO -> FLV -> HTREE -> CBS -> TRN -> SPI -> DONE
`default_nettype none
module t05_controller (
 input logic clk, rst, cont_en,restart_en,        // Clock, reset, continue enable, restart enable
 input logic [3:0] finState,op_fin,                 // Module completion signals (assumed to be registered)
 output logic [3:0] state_reg,                      // Current state output for other modules
 output logic finished_signal                       // Signal indicating entire compression pipeline is complete
);
//FINSTATE NEEDS TO ALWAYS BE MOST RECENTLY CHANGED STATE FROM MODULES
    // State machine enumeration for main compression pipeline states
    typedef enum logic [3:0] {
        IDLE=0,     // Waiting for start signal
        HISTO=1,    // Histogram generation state
        FLV=2,      // Frequency/Length/Value processing state  
        HTREE=3,    // Huffman tree construction state
        CBS=4,      // Code book generation state
        TRN=5,      // Data transmission/encoding state
        SPI=6,      // SPI communication state
        ERROR=7,    // Error handling state
        DONE=8      // Completion state
    } state_t;

    // Finish state enumeration for module completion signaling
    typedef enum logic [3:0] {
        IDLE_FIN=0,         // No finished
        HFIN=1,             // Histogram finished
        FLV_FIN=2,          // FLV finished
        HTREE_FIN=3,        // Huffman tree finished (normal completion)
        HTREE_FINISHED=4,   // Huffman tree  finished (special completion - NULL+NULL case)
        CBS_FIN=5,          // Code book  finished
        TRN_FIN=6,          // Transmission finished
        SPI_FIN=7,          // SPI  finished
        ERROR_FIN=8         // Error condition detected
    } finState_t;
    
    // Operation finish signal enumeration for inter-module communication
    typedef enum logic [3:0] {
        IDLE_S = 0,     // Idle/no operation
        HIST_S = 1,     // Histogram operation complete
        FLV_S = 2,      // FLV operation complete
        HTREE_S = 3,    // Huffman tree operation complete
        CBS_S = 4,      // Code book operation complete
        TRN_S = 5,      // Transmission operation complete
        SPI_S = 6,      // SPI operation complete
        ERROR_S = 7     // Error operation signal
    } op_fin_t;

    // Internal signal declarations
    logic finished;                 // Internal finished flag
    logic en_reg;                   // Registered enable signal
    logic [3:0] fin_reg;           // Registered finish state from modules
    logic [3:0] finState_next;     // Next finish state value
    state_t next_state;            // Next state machine state
    state_t state;                 // Current state machine state

    // Sequential logic block - handles state and register updates
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            // Reset all state machine and control registers to initial values
            state <= IDLE;
            state_reg <= IDLE;
            en_reg <= 1'b0;
            fin_reg <= IDLE_FIN;
            finished_signal <= 1'b0;
        end else begin
            // Always update state machine - not conditional on cont_en
            state <= next_state;
            fin_reg <= finState_next;
            state_reg <= next_state;
            finished_signal <= finished;
            
            // Track enable signal for debugging/monitoring
            if (cont_en) begin
                en_reg <= 1'b1;
            end
        end
    end
   
    // Main state machine combinational logic
    // Controls the sequential flow of the Huffman compression pipeline
    always_comb begin
            // Default assignments to prevent latches
            finState_next = finState;
            next_state = state;
            finished = 1'b0;
            
            // State machine logic for compression pipeline control
            case (state)
                IDLE: begin
                    // Wait for continue signal to start compression pipeline
                    if (cont_en) begin
                        next_state = HISTO;
                    end else begin
                        next_state = IDLE;
                    end
                end
                HISTO: begin
                    // Histogram generation state - wait for completion or error
                    if (fin_reg == ERROR_FIN || op_fin == ERROR_S) begin
                        next_state = ERROR;
                        finState_next = IDLE_FIN;
                    end else if (fin_reg == HFIN && op_fin == HIST_S) begin
                        next_state = FLV;
                        finState_next = IDLE_FIN;
                    end else begin
                        next_state = HISTO;
                    end
                end
                FLV: begin
                    // Frequency/Length/Value processing state
                    if (fin_reg == ERROR_FIN || op_fin == ERROR_S) begin
                        next_state = ERROR;
                        finState_next = IDLE_FIN;
                    end else if (fin_reg == FLV_FIN && op_fin == FLV_S) begin
                        next_state = HTREE;
                        finState_next = IDLE_FIN;
                    end else begin
                        next_state = FLV;
                    end
                end
                HTREE: begin
                    // Huffman tree construction state with special completion handling
                    if (fin_reg == ERROR_FIN || op_fin == ERROR_S) begin
                        next_state = ERROR;
                        finState_next = IDLE_FIN;
                    end else if (fin_reg == HTREE_FINISHED) begin
                        // Special completion case (e.g., NULL+NULL nodes)
                        next_state = CBS;
                        finState_next = IDLE_FIN;
                    end else if (fin_reg == HTREE_FIN && op_fin == HTREE_S) begin
                        // Normal completion - may need to return to FLV for additional processing
                        next_state = FLV;
                        finState_next = IDLE_FIN;
                    end else begin
                        next_state = HTREE;
                    end
                end
                CBS: begin
                    // Code book generation state - create Huffman codes from tree
                    if (fin_reg == ERROR_FIN || op_fin == ERROR_S) begin
                        next_state = ERROR;
                        finState_next = IDLE_FIN;
                    end else if (fin_reg == CBS_FIN && op_fin == CBS_S) begin
                        next_state = TRN;
                        finState_next = IDLE_FIN;
                    end else begin
                        next_state = CBS;
                    end
                end
                TRN: begin
                    // Data transmission/encoding state - encode input data using Huffman codes
                    if (fin_reg == ERROR_FIN || op_fin == ERROR_S) begin
                        next_state = ERROR;
                        finState_next = IDLE_FIN;
                    end else if (fin_reg == TRN_FIN && op_fin == TRN_S) begin
                        next_state = SPI;
                        finState_next = IDLE_FIN;
                    end else begin
                        next_state = TRN;
                    end
                end
                SPI: begin
                    // SPI communication state - transmit compressed data
                    if (fin_reg == ERROR_FIN || op_fin == ERROR_S) begin
                        next_state = ERROR;
                        finState_next = IDLE_FIN;
                    end else if (fin_reg == SPI_FIN && op_fin == SPI_S) begin
                        next_state = DONE;
                        finState_next = IDLE_FIN; // might be a problem idk
                    end else begin
                        next_state = SPI;
                    end
                end
                DONE: begin
                    // Completion state - signal finished and wait for restart
                    finished = 1'b1;
                    if (restart_en) begin
                        next_state = IDLE; // Reset to IDLE after completion
                    end else begin
                        next_state = DONE; // Stay in DONE
                        // Add a counter or flag to transition to IDLE after 1 cycle
                    end
                    //next_state = IDLE; // Reset to IDLE after completion
                end
                default: begin
                    // Error handling for undefined states
                    next_state = ERROR; // Handle unexpected states
                end
            endcase
    end          
endmodule