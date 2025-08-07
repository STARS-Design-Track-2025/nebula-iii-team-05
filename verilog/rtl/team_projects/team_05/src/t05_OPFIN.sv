 `default_nettype none
module t05_OPFIN (
 input logic clk, rst, cont_en, restart_en, compDecomp,
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
    // logic [3:0] state_reg, next_state_reg;
    logic finished, next_finished, compEN, decompEN;

    always_ff @(posedge clk or posedge rst) begin
        if (rst || restart_en) begin
            state <= IDLE;
            compDecomp_reg <= 0;
        end else begin
            state <= next_state;
            compDecomp_reg <= compDecomp;
            compEN_reg <= compEN;
            decompEN_reg <= decompEN;
        end
    end
    // idle -> select -> comp -> Hist -> FLV <-> HTREE -> CBS -> TRN -> SPI -> done
    //                -> decomp -> state0 -> state 1 -> state 2 -> state 3 -> done
    always_comb begin
        compEN = compEN_reg;
        decompEN = decompEN_reg;
        next_state = state;

        // Default values to avoid latches
        if (compEN)begin 
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
        end else if (decompEN) begin
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
            next_state = state; // latch signal
        end
        compEN = 1'b0;
        decompEN = 1'b0;

        case (state)
            IDLE: begin
                if (cont_en) begin
                    next_state = SELECT;
                end
            end

            SELECT: begin
                if (compDecomp_reg ) begin
                    next_state = COMP;
                end else begin
                    next_state = DECOMP;
                end
            end

            COMP: begin
                if(!compDecomp_reg) begin
                    next_state = DECOMP;
                end else if (cont_en) begin
                    compEN = 1'b1;
                end else begin 
                    next_state = COMP;
                end
            end

            DECOMP: begin
                if(!compDecomp_reg) begin
                    next_state = COMP;
                end else if (cont_en) begin
                    decompEN = 1'b1;
                end else begin 
                    next_state = DECOMP;
                end
            end

            default: begin
                next_state = IDLE;
            end
        endcase
    end
endmodule