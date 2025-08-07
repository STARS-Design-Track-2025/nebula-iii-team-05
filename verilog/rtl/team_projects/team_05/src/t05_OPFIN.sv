 `default_nettype none
module opfin (
 input logic clk, rst, cont_en,restart_en,compDecomp,
 input logic [3:0] comp_state, 
 input logic [1:0]decomp_state, // assumed to be registered
 output logic [3:0] opFin,
 output logic finished_signal, compEN_reg, decompEN_reg
);


    logic compDecomp_reg;

    typedef enum logic [3:0]{
        IDLE=0,
        SELECT=1,
        COMP=2,
        HISTO=3,
        FLV=4,
        HTREE=5,
        CBS=6,
        TRN=7,
        SPI=8,
        DECOMP=9,
        STATE0=10,
        STATE1=11,
        STATE2=12,
        STATE3=13,
        DONE=14,
        ERROR=15
    } state_t;

    state_t state, next_state;
    logic finished;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            compDecomp_reg <= 0;
            compEN_reg <= 1'b0;
            decompEN_reg <= 1'b0;
        end else begin
            state <= next_state;
            compDecomp_reg <= compDecomp;
            // Only set enable signals when transitioning to enabled state
            if (state == COMP && cont_en) begin
                compEN_reg <= 1'b1;
            end
            if (state == DECOMP && cont_en) begin
                decompEN_reg <= 1'b1;
            end
            finished_signal <= finished;
        end
    end
    // idle -> select -> comp -> Hist -> FLV <-> HTREE -> CBS -> TRN -> SPI -> done
    //                -> decomp -> state0 -> state 1 -> state 2 -> state 3 -> done
    always_comb begin
        // Default values to avoid latches
        opFin = state;
        finished = 1'b0;
        next_state = state; // Default: stay in current state
        
        if (compEN_reg) begin 
            case(comp_state)
                0: begin
                    next_state = IDLE;
                end
                1: begin
                    next_state = HISTO;
                end
                2: begin
                    next_state = FLV;
                end
                3: begin
                    next_state = HTREE;
                end
                4: begin
                    next_state = CBS;
                end
                5: begin
                    next_state = TRN;
                end
                6: begin
                    next_state = SPI;
                end
                7: begin
                    next_state = ERROR;
                end
                8: begin
                    next_state = DONE;
                end
                default: begin
                    next_state = IDLE;
                end
            endcase
        end else if (decompEN_reg) begin
            case(decomp_state)
                2'd0: begin
                    next_state = STATE0;
                end
                2'd1: begin
                    next_state = STATE1;
                end
                2'd2: begin
                    next_state = STATE2;
                end
                2'd3: begin
                    next_state = STATE3;
                end
                default: begin
                    next_state = STATE0;
                end
            endcase
        end else begin
            // Handle normal state machine transitions when not enabled
            case (state)
                IDLE: begin
                    finished = 1'b0;
                    if (cont_en) begin
                        next_state = SELECT;
                    end
                end

                SELECT: begin
                    if (compDecomp_reg) begin
                        next_state = COMP;
                    end else begin
                        next_state = DECOMP;
                    end
                end

                COMP: begin
                    if (!compDecomp_reg) begin
                        next_state = DECOMP;
                    end
                    // compEN_reg will be set in the clocked block when cont_en is high
                end

                DECOMP: begin
                    if (compDecomp_reg) begin
                        next_state = COMP;
                    end
                    // decompEN_reg will be set in the clocked block when cont_en is high
                end

                DONE: begin
                    finished = 1'b1; // Indicate operation is done
                    if (restart_en) begin
                        next_state = IDLE; // Go back to IDLE on restart
                    end
                end

                default: begin
                    next_state = IDLE;
                end
            endcase
        end
    end
endmodule