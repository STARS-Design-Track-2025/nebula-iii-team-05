module t05_displayControl
(
    input logic clk, rst,
    input logic bf,compDecomp,isFinished,
    input logic [3:0] contState_n,
    output logic rs,rw,d7, d6, d5, d4, d3, d2, d1, d0, en
);

    logic rs_n, rw_n, d7_n, d6_n, d5_n, d4_n, d3_n, d2_n, d1_n, d0_n, en_n, en_n2;
    logic [319:0] data, data_reg;
    logic [2:0] mode_n;

   
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

    state_t contState;
    assign contState = state_t'(contState_n);

    typedef enum logic [2:0] {
        INIT,
        TITLE,
        SELECT,
        COMP,
        DECOMP,
        FINISH,
        ERROR_STATE
    } mode_t;
    mode_t mode;

    typedef enum logic [9:0] {
        A = 10'b0001000001,
        B = 10'b0001000010,
        C = 10'b0001000011,
        D = 10'b0001000100,
        E = 10'b0001000101,
        F = 10'b0001000110,
        G = 10'b0001000111,
        H = 10'b0001001000,
        I = 10'b0001001001,
        K = 10'b0001001011,
        L = 10'b0001001100,
        M = 10'b0001001101,
        N = 10'b0001001110,
        O = 10'b0001001111,
        P = 10'b0001010000,
        R = 10'b0001010010,
        S = 10'b0001010011,
        T = 10'b0001010100,
        U = 10'b0001010101,
        V = 10'b0001010110,
        SPACE = 10'b1000100000,
        BLOCK = 10'b001111111111,
        CLEAR = 10'b0000000001,
        HOME = 10'b0000000010
        // NEWLINE =
    } data_t;
    data_t keys;
   
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            rs <= 1'b0;
            rw <= 1'b0;
            d7 <= 1'b0;
            d6 <= 1'b0;
            d5 <= 1'b0;
            d4 <= 1'b0;
            d3 <= 1'b0;
            d2 <= 1'b0;
            d1 <= 1'b0;
            d0 <= 1'b0;
            en <= 1'b0;
        end else begin
            rs <= rs_n;
            rw <= rw_n;
            d7 <= d7_n;
            d6 <= d6_n;
            d5 <= d5_n;  
            d4 <= d4_n;
            d3 <= d3_n;
            d2 <= d2_n;
            d1 <= d1_n;
            d0 <= d0_n;
            en <= en_n;
            en_n <= en_n2;
            mode <= mode_t'(mode_n);
            data_reg <= data;
        end
    end


    always_comb begin
        mode_n = mode;
        data = '0; // Initialize data to zero
        // en_n = en_n2;
        en_n2 = 1'b0;
        rs_n = 1'b0; 
        rw_n = 1'b0;
        d7_n = 1'b0;
        d6_n = 1'b0;
        d5_n = 1'b0; 
        d4_n = 1'b0; 
        d3_n = 1'b0;
        d2_n = 1'b0;
        d1_n = 1'b0;
        d0_n = 1'b0;
        
        // Default assignments
        case (mode)
            INIT: begin
                data = '0;
                data = {CLEAR, HOME, 300'b0}; // Clear display and set home position
                repeat (2) begin
                    rs_n = data[319];
                    rw_n = data[318];
                    d7_n = data[317];
                    d6_n = data[316];
                    d5_n = data[315];
                    d4_n = data[314];
                    d3_n = data[313];
                    d2_n = data[312];
                    d1_n = data[311];
                    d0_n = data[310];
                    en_n2 = 1'b0;
                    data = data << 10; // Shift the data to the right by 10 bits for the next cycle
                    en_n2 = 1'b1; // Enable signal is set to high
                end
                data = '0;
                data = {10'b0000111000,10'b0000001100,10'b0000000110,290'b0};
                repeat (3) begin
                    rs_n = data[319];
                    rw_n = data[318];
                    d7_n = data[317];
                    d6_n = data[316];
                    d5_n = data[315];
                    d4_n = data[314];
                    d3_n = data[313];
                    d2_n = data[312];
                    d1_n = data[311];
                    d0_n = data[310];
                    // en_n2 = 1'b0;
                    data = data << 10; // Shift the data to the right by 10 bits for the next cycle
                    // en_n2 = 1'b1; // Enable signal is set to high
                end
                mode_n = TITLE;
            end
            TITLE: begin
                data = '0;
                data = {CLEAR, HOME, 300'b0}; // Clear display and set home position
                repeat (2) begin
                    rs_n = data[319];
                    rw_n = data[318];
                    d7_n = data[317];
                    d6_n = data[316];
                    d5_n = data[315];
                    d4_n = data[314];
                    d3_n = data[313];
                    d2_n = data[312];
                    d1_n = data[311];
                    d0_n = data[310];
                    en_n2 = 1'b0;
                    data = data << 10; // Shift the data to the right by 10 bits for the next cycle
                    en_n2 = 1'b1; // Enable signal is set to high
                end
                data = '0;
                data = {SPACE, B, I, G, G, I, E, SPACE, SPACE, S, M, A, L, L, S, SPACE,/*NEWLINE*/ H, U, F, F, M, A, N, SPACE, E, N, C, O, D, I, N, G};
                repeat (32) begin
                    rs_n = data[319];
                    rw_n = data[318];
                    d7_n = data[317];
                    d6_n = data[316];
                    d5_n = data[315];
                    d4_n = data[314];
                    d3_n = data[313];
                    d2_n = data[312];
                    d1_n = data[311];
                    d0_n = data[310];
                    en_n2 = 1'b0;
                    data = data << 10; // Shift the data to the right by 10 bits for the next cycle
                    en_n2 = 1'b1; // Enable signal is set to high
                end
                mode_n = SELECT;
            end
            SELECT: begin
                data = '0;
                data = {CLEAR, HOME, 300'b0}; // Clear display and set home position
                repeat (2) begin
                    rs_n = data[319];
                    rw_n = data[318];
                    d7_n = data[317];
                    d6_n = data[316];
                    d5_n = data[315];
                    d4_n = data[314];
                    d3_n = data[313];
                    d2_n = data[312];
                    d1_n = data[311];
                    d0_n = data[310];
                    en_n2 = 1'b0;
                    data = data << 10; // Shift the data to the right by 10 bits for the next cycle
                    en_n2 = 1'b1; // Enable signal is set to high
                end
                data = '0;
                data = {SPACE, SPACE, C, O, M, P, R, E, S, S, I, O, N, SPACE, SPACE, SPACE, SPACE, D, E, C, O, M, P, R, E, S, S, I, O, N, SPACE, SPACE};
                repeat (32) begin
                    rs_n = data[319];
                    rw_n = data[318];
                    d7_n = data[317];
                    d6_n = data[316];
                    d5_n = data[315];
                    d4_n = data[314];
                    d3_n = data[313];
                    d2_n = data[312];
                    d1_n = data[311];
                    d0_n = data[310];
                    en_n2 = 1'b0;
                    data = data << 10; // Shift the data to the right by 10 bits for the next cycle
                    en_n2 = 1'b1; // Enable signal is set to high
                end
                if (compDecomp) begin
                    mode_n = COMP;
                end else begin
                    mode_n = DECOMP;
                end
            end
            COMP: begin
                data = '0;
                data = {CLEAR, HOME, 300'b0}; // Clear display and set home position
                repeat (2) begin
                    rs_n = data[319];
                    rw_n = data[318];
                    d7_n = data[317];
                    d6_n = data[316];
                    d5_n = data[315];
                    d4_n = data[314];
                    d3_n = data[313];
                    d2_n = data[312];
                    d1_n = data[311];
                    d0_n = data[310];
                    en_n2 = 1'b0;
                    data = data << 10; // Shift the data to the right by 10 bits for the next cycle
                    en_n2 = 1'b1; // Enable signal is set to high
                end
                case (contState)
                    IDLE: begin
                        data = {SPACE, SPACE, C, O, M, P, R, E, S, S, I, O, N, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE};
                    end
                    HISTO: begin
                        data = {SPACE, SPACE, C, O, M, P, R, E, S, S, I, O, N, SPACE, BLOCK, BLOCK, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE};
                    end
                    FLV: begin
                        data = {SPACE, SPACE, C, O, M, P, R, E, S, S, I, O, N, SPACE, BLOCK, BLOCK, BLOCK, BLOCK, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE};
                    end
                    HTREE: begin
                        data = {SPACE, SPACE, C, O, M, P, R, E, S, S, I, O, N, SPACE, BLOCK, BLOCK, BLOCK, BLOCK, BLOCK, BLOCK, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE};
                    end
                    CBS: begin
                        data = {SPACE, SPACE, C, O, M, P, R, E, S, S, I, O, N, SPACE, BLOCK, BLOCK, BLOCK, BLOCK, BLOCK, BLOCK, BLOCK, BLOCK, BLOCK, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE};
                    end
                    TRN: begin
                        data = {SPACE, SPACE, C, O, M, P, R, E, S, S, I, O, N, SPACE, BLOCK, BLOCK, BLOCK, BLOCK, BLOCK, BLOCK, BLOCK, BLOCK, BLOCK, BLOCK, BLOCK, BLOCK, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE};
                    end
                    SPI: begin
                        data = {SPACE, SPACE, C, O, M, P, R, E, S, S, I, O, N, SPACE, BLOCK, BLOCK, BLOCK, BLOCK, BLOCK, BLOCK, BLOCK, BLOCK, BLOCK, BLOCK, BLOCK, BLOCK, BLOCK, BLOCK, BLOCK, SPACE, SPACE, SPACE};
                    end
                    ERROR: begin
                        data = {SPACE, SPACE, C, O, M, P, R, E, S, S, I, O, N, SPACE, SPACE, BLOCK, SPACE, BLOCK, SPACE, BLOCK, SPACE, BLOCK, SPACE, BLOCK, SPACE, BLOCK, SPACE, BLOCK, SPACE, BLOCK, SPACE, BLOCK};
                    end
                    DONE: begin
                        data = {SPACE, SPACE, C, O, M, P, R, E, S, S, I, O, N, SPACE, BLOCK, BLOCK, BLOCK, BLOCK, BLOCK, BLOCK, BLOCK, BLOCK, BLOCK, BLOCK, BLOCK, BLOCK, BLOCK, BLOCK, BLOCK, BLOCK, BLOCK, BLOCK};
                    end
                    default: begin
                        // Default case to handle unexpected states
                        data = '0;
                    end
                endcase
                repeat (32) begin
                    rs_n = data[319];
                    rw_n = data[318];
                    d7_n = data[317];
                    d6_n = data[316];
                    d5_n = data[315];
                    d4_n = data[314];
                    d3_n = data[313];
                    d2_n = data[312];
                    d1_n = data[311];
                    d0_n = data[310];
                    en_n2 = 1'b0;
                    data = data << 10; // Shift the data to the right by 10 bits for the next cycle
                    en_n2 = 1'b1; // Enable signal is set to high
                end
                if (isFinished) begin
                    mode_n = FINISH;
                end else begin
                    mode_n = COMP;
                end

                if (contState == ERROR) begin
                    mode_n = ERROR_STATE;
                end
            end
            DECOMP: begin
                data = '0;data = {CLEAR, HOME, 300'b0}; // Clear display and set home position
                repeat (2) begin
                    rs_n = data[319];
                    rw_n = data[318];
                    d7_n = data[317];
                    d6_n = data[316];
                    d5_n = data[315];
                    d4_n = data[314];
                    d3_n = data[313];
                    d2_n = data[312];
                    d1_n = data[311];
                    d0_n = data[310];
                    en_n2 = 1'b0;
                    data = data << 10; // Shift the data to the right by 10 bits for the next cycle
                    en_n2 = 1'b1; // Enable signal is set to high
                end
                data = '0;

            end
            FINISH: begin
                data = '0;
                data = {CLEAR, HOME, 300'b0}; // Clear display and set home position
                repeat (2) begin
                    rs_n = data[319];
                    rw_n = data[318];
                    d7_n = data[317];
                    d6_n = data[316];
                    d5_n = data[315];
                    d4_n = data[314];
                    d3_n = data[313];
                    d2_n = data[312];
                    d1_n = data[311];
                    d0_n = data[310];
                    en_n2 = 1'b0;
                    data = data << 10; // Shift the data to the right by 10 bits for the next cycle
                    en_n2 = 1'b1; // Enable signal is set to high
                end
                data = '0;

                data = { F, I, N, I, S, H, 260'b0};
                repeat (6) begin
                    rs_n = data[319];
                    rw_n = data[318];
                    d7_n = data[317];
                    d6_n = data[316];
                    d5_n = data[315];
                    d4_n = data[314];
                    d3_n = data[313];
                    d2_n = data[312];
                    d1_n = data[311];
                    d0_n = data[310];
                    en_n2 = 1'b0;
                    data = data << 10; // Shift the data to the right by 10 bits for the next cycle
                    en_n2 = 1'b1; // Enable signal is set to high
                end
            end
            ERROR_STATE: begin
                data = '0;
                data = {CLEAR, HOME, 300'b0}; // Clear display and set home position
                repeat (2) begin
                    rs_n = data[319];
                    rw_n = data[318];
                    d7_n = data[317];
                    d6_n = data[316];
                    d5_n = data[315];
                    d4_n = data[314];
                    d3_n = data[313];
                    d2_n = data[312];
                    d1_n = data[311];
                    d0_n = data[310];
                    en_n2 = 1'b0;
                    data = data << 10; // Shift the data to the right by 10 bits for the next cycle
                    en_n2 = 1'b1; // Enable signal is set to high
                end
                data = '0;

                data = { E, R, R, O, R, 270'b0};
                repeat (5) begin
                    rs_n = data[319];
                    rw_n = data[318];
                    d7_n = data[317];
                    d6_n = data[316];
                    d5_n = data[315];
                    d4_n = data[314];
                    d3_n = data[313];
                    d2_n = data[312];
                    d1_n = data[311];
                    d0_n = data[310];
                    en_n2 = 1'b0;
                    data = data << 10; // Shift the data to the right by 10 bits for the next cycle
                    en_n2 = 1'b1; // Enable signal is set to high
                end
            end
            default: begin
                // Default case to handle unexpected modes
                data = '0;
            end
        endcase
    end
endmodule