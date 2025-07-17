`default_nettype none
module t05_controller (
 input logic clk, rst_n, cont_en,
 input logic [3:0] finState,op_fin, // assumed to be registered
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
        ERROR=7,
        DONE=8
    } state_t;

    typedef enum logic [3:0] {
        IDLE_FIN=0,
        HFIN=1,
        FLV_FIN=2,
        HTREE_FIN=3,
        HTREE_FINISHED=4,
        CBS_FIN=5,
        TRN_FIN=6,
        SPI_FIN=7,
        ERROR_FIN=8
    } finState_t;
    
    typedef enum logic [3:0] {
        IDLE_S = 0,
        HIST_S = 1,
        FLV_S = 2,
        HTREE_S = 3,
        CBS_S = 4,
        TRN_S = 5,
        SPI_S = 6,
        ERROR_S = 7
    } op_fin_t;

    logic finished;
    logic en_reg;
    logic [3:0] fin_reg;
    logic [3:0] finState_next;// signal modules send when they are done
    state_t next_state;
    state_t state;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
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
            
            // Track enable signal
            if (cont_en) begin
                en_reg <= 1'b1;
            end
        end
    end
   
    always_comb begin
            finState_next = fin_reg;
            next_state = state;
            finished = 1'b0;
            case (state)
                IDLE: begin
                    if (cont_en) begin
                        next_state = HISTO;
                    end else begin
                        next_state = IDLE;
                    end
                end
                HISTO: begin
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
                    if (fin_reg == ERROR_FIN || op_fin == ERROR_S) begin
                        next_state = ERROR;
                        finState_next = IDLE_FIN;
                    end else if (fin_reg == HTREE_FINISHED) begin
                        next_state = CBS;
                        finState_next = IDLE_FIN;
                    end else if (fin_reg == HTREE_FIN && op_fin == HTREE_S) begin
                        next_state = FLV;
                        finState_next = IDLE_FIN;
                    end else begin
                        next_state = HTREE;
                    end
                end
                CBS: begin
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
                    if (fin_reg == ERROR_FIN || op_fin == ERROR_S) begin
                        next_state = ERROR;
                        finState_next = IDLE_FIN;
                    end else if (fin_reg == SPI_FIN && op_fin == SPI_S) begin
                        next_state = DONE;
                        finState_next = IDLE_FIN;
                    end else begin
                        next_state = SPI;
                    end
                end
                DONE: begin
                    finished = 1'b1;
                    next_state = IDLE; // Reset to IDLE after completion
                end
                default: begin
                    next_state = ERROR; // Handle unexpected states
                end
            endcase
    end          
endmodule