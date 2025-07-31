`default_nettype none

module t05_controller (
 input logic clk, rst, cont_en,restart_en,
 input logic [7:0] finState,
 input logic [5:0] op_fin, // assumed to be registered - from SRAM
 input logic fin_idle, fin_HG, fin_FLV, fin_HT, fin_FINISHED, fin_CBS, fin_TRN, fin_SPI,
 output logic [3:0] state_reg,
 output logic finished_signal
);

    typedef enum logic [3:0] {
        IDLE=0,
        HISTO=1,
        FLV=2,
        HTREE=3,
        CBS=4,
        TRN=5,
        SPI=6,
        DONE=8
    } state_t;

    typedef enum logic [7:0] {
        IDLE_FIN=       8'b10000000,
        HFIN=           8'b11000000,
        FLV_FIN=        8'b11100000,
        HTREE_FIN=      8'b11110000,
        HTREE_FINISHED= 8'b11101000,
        CBS_FIN=        8'b11101100,
        TRN_FIN=        8'b11101110,
        SPI_FIN=        8'b11101111
    } fin_State_t;
    
    typedef enum logic [5:0] {
        IDLE_S = 0,
        HIST_S = 1,
        FLV_S = 2,
        HTREE_S = 3,
        CBS_S = 4,
        TRN_S = 5,
        SPI_S = 6
    } op_fin_t;

    logic finished;
    logic en_reg;
    logic [7:0] fin_reg;
    logic [7:0] finState_next;// signal modules send when they are done
    state_t next_state;
    logic [7:0] fin_signal;
    assign fin_signal = {fin_idle, fin_HG, fin_FLV, fin_HT, fin_FINISHED, fin_CBS, fin_TRN, fin_SPI};

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            state_reg <= IDLE;
            en_reg <= 1'b0;
            fin_reg <= '0;
            finished_signal <= 1'b0;
        end else begin
            // Always update state machine - not conditional on cont_en
            fin_reg <= finState;
            state_reg <= next_state;
            finished_signal <= finished;
            
            // Track enable signal
            if (cont_en) begin
                en_reg <= 1'b1;
            end
        end
    end
   
    always_comb begin
        finished = finished_signal;
        
            //finState_next = fin_reg;
            case (fin_reg)
                IDLE_FIN: begin
                    next_state = HISTO;
                end
                HFIN: begin
                    next_state = FLV;
                end
                FLV_FIN: begin
                    next_state = HTREE;
                end
                HTREE_FIN: begin
                    next_state = FLV;
                end
                HTREE_FINISHED: begin
                    next_state = CBS;
                end
                CBS_FIN: begin
                    next_state = TRN;
                end
                TRN_FIN: begin
                    next_state = SPI;
                end
                SPI_FIN: begin
                    next_state = DONE;
                end
                default: begin
                    next_state = IDLE;
                end
            endcase
            // case (state_reg)
            //     IDLE: begin
            //         if (cont_en) begin
            //             next_state = HISTO;
            //         end else begin
            //             next_state = IDLE;
            //         end
            //     end
            //     HISTO: begin
            //         if ((fin_reg == ERROR_FIN) || op_fin == ERROR_S) begin
            //             next_state = ERROR;
            //             finState_next = IDLE_FIN;
            //         end else if (fin_reg == HFIN && op_fin == HIST_S) begin
            //             next_state = FLV;
            //             finState_next = IDLE_FIN;
            //         end else begin
            //             next_state = HISTO;
            //         end
            //     end
            //     FLV: begin
            //         if (fin_reg == ERROR_FIN || op_fin == ERROR_S) begin
            //             next_state = ERROR;
            //             finState_next = IDLE_FIN;
            //         end else if (fin_reg == FLV_FIN && op_fin == FLV_S) begin
            //             next_state = HTREE;
            //             finState_next = IDLE_FIN;
            //         end else begin
            //             next_state = FLV;
            //         end
            //     end
            //     HTREE: begin
            //         if (fin_reg == ERROR_FIN || op_fin == ERROR_S) begin
            //             next_state = ERROR;
            //             finState_next = IDLE_FIN;
            //         end else if (fin_reg == HTREE_FINISHED) begin
            //             next_state = CBS;
            //             finState_next = IDLE_FIN;
            //         end else if (fin_reg == HTREE_FIN && op_fin == HTREE_S) begin
            //             next_state = FLV;
            //             finState_next = IDLE_FIN;
            //         end else begin
            //             next_state = HTREE;
            //         end
            //     end
            //     CBS: begin
            //         if (fin_reg == ERROR_FIN || op_fin == ERROR_S) begin
            //             next_state = ERROR;
            //             finState_next = IDLE_FIN;
            //         end else if (fin_reg == CBS_FIN && op_fin == CBS_S) begin
            //             next_state = TRN;
            //             finState_next = IDLE_FIN;
            //         end else begin
            //             next_state = CBS;
            //         end
            //     end
            //     TRN: begin
            //         if (fin_reg == ERROR_FIN || op_fin == ERROR_S) begin
            //             next_state = ERROR;
            //             finState_next = IDLE_FIN;
            //         end else if (fin_reg == TRN_FIN && op_fin == TRN_S) begin
            //             next_state = SPI;
            //             finState_next = IDLE_FIN;
            //         end else begin
            //             next_state = TRN;
            //         end
            //     end
            //     SPI: begin
            //         if (fin_reg == ERROR_FIN || op_fin == ERROR_S) begin
            //             next_state = ERROR;
            //             finState_next = IDLE_FIN;
            //         end else if (fin_reg == SPI_FIN && op_fin == SPI_S) begin
            //             next_state = DONE;
            //             finState_next = IDLE_FIN; // might be a problem idk
            //         end else begin
            //             next_state = SPI;
            //         end
            //     end
            //     DONE: begin
            //         finished = 1'b1;
            //         if (restart_en) begin
            //             next_state = IDLE; // Reset to IDLE after completion
            //         end else begin
            //             next_state = DONE; // Stay in DONE
            //             // Add a counter or flag to transition to IDLE after 1 cycle
            //         end
            //         //next_state = IDLE; // Reset to IDLE after completion
            //     end
            //     default: begin
            //         next_state = ERROR; // Handle unexpected states
            //     end
            // endcase
    end          
endmodule