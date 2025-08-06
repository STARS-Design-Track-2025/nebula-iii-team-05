module t05_lcd(
 input logic compDecomp,
 input logic [4:0] enstate,
 output logic [127:0] row_1, row_2
);
    typedef enum logic [4:0] { 
        SELECT = 5'd9,
        IDLE = 5'b0,
        HISTOGRAM = 5'b1,
        FLV = 5'd2,
        HUFFMAN = 5'd3,
        CODEBOOK = 5'd4,
        TRANSLATION = 5'd5,
        SPI = 5'd6,
        ERROR = 5'd7,
        COMPLETE = 5'd8
    } state_t;

   typedef enum logic [7:0] {
        A = 8'h41, 
        B = 8'h42, 
        C = 8'h43, 
        D = 8'h44, 
        E = 8'h45,
        F = 8'h46, 
        G = 8'h47, 
        H = 8'h48, 
        I = 8'h49, 
        J = 8'h4A,
        K = 8'h4B, 
        L = 8'h4C, 
        M = 8'h4D, 
        N = 8'h4E, 
        O = 8'h4F,
        P = 8'h50, 
        Q = 8'h51, 
        R = 8'h52, 
        S = 8'h53, 
        T = 8'h54,
        U = 8'h55, 
        V = 8'h56, 
        W = 8'h57, 
        X = 8'h58, 
        Y = 8'h59,
        Z = 8'h5A, 
        DOT = 8'h2E,
        SPACE = 8'h20, 
        FILL = 8'hFF,
        ARROW = 8'h3E, 
        MONEY = 8'h24,
        AND = 8'h26,
        RAND1 = 8'h17,
        RAND2 = 8'h11,
        RAND3 = 8'h12,
        RAND4 = 8'h13,
        RAND5 = 8'h14,
        RAND6 = 8'h15,
        RAND7 = 8'h16, 
        RAND8 = 8'h3F,
        RAND9 = 8'h23,
        RAND10 = 8'h21,
        RAND11 = 8'h10,
        RAND12 = 8'hA1
   } letters_t;

   always_comb begin
        case (enstate)
        SELECT: begin
           if (compDecomp) begin
            row_1 = {ARROW, SPACE, C, O, M, P, R, E, S, S, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE};
            row_2 = {SPACE, SPACE, D, E, C, O, M, P, R, E, S, S, SPACE, SPACE, SPACE, SPACE};
           end else begin
            row_1 = {SPACE, SPACE, C, O, M, P, R, E, S, S, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE};
            row_2 = {ARROW, SPACE, D, E, C, O, M, P, R, E, S, S, SPACE, SPACE, SPACE, SPACE};
           end
        end
        IDLE: begin
            row_1 = {SPACE,  B, I, G, G, I, E, SPACE, SPACE, S, M, A, L, L, S, SPACE};
            row_2 = {SPACE, SPACE, SPACE, C, O, M, P, R, E, S, S, I, O, N, SPACE, SPACE};
        end
        HISTOGRAM: begin
            row_1 = {C, O, U, N, T, I, N, G, DOT, DOT, DOT, SPACE, SPACE, SPACE, SPACE, SPACE};
            row_2 = {FILL, FILL, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE};
        end
        FLV: begin
            row_1 = {C, R, E, A, T, I, N, G, SPACE, T, R, E, E, DOT, DOT, DOT};
            row_2 = {FILL, FILL, FILL, FILL, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE};
        end
        HUFFMAN: begin
            row_1 = {C, R, E, A, T, I, N, G, SPACE, T, R, E, E, DOT, DOT, DOT};
            row_2 = {FILL, FILL, FILL, FILL, FILL, FILL, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE};
        end
        CODEBOOK: begin
            row_1 = {E, N, C, O, D, I, N, G, DOT, DOT, DOT, SPACE, SPACE, SPACE, SPACE, SPACE};
            row_2 = {FILL, FILL, FILL, FILL, FILL, FILL, FILL, FILL, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE};
        end
        TRANSLATION: begin
            row_1 = {T, R, A, N, S, L, A, T, I, N, G, DOT, DOT, DOT, SPACE, SPACE};
            row_2 = {FILL, FILL, FILL, FILL, FILL, FILL, FILL, FILL, FILL, FILL, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE};
        end
        SPI: begin
            row_1 = {S, D, SPACE, U, P, L, O, A, D, I, N, G, DOT, DOT, DOT, SPACE};
            row_2 = {FILL, FILL, FILL, FILL, FILL, FILL, FILL, FILL, FILL, FILL, FILL, SPACE, SPACE, SPACE, SPACE, SPACE};
        end
        ERROR: begin
            row_1 = {SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, E, R, R, O, R, SPACE, SPACE, SPACE, SPACE, SPACE};
            row_2 = {MONEY, AND, RAND1, RAND2, RAND3, RAND4, RAND5, RAND6, RAND7, RAND8, RAND9, RAND10, RAND11, RAND12, AND, MONEY};
        end
        COMPLETE: begin
            row_1 = {SPACE, SPACE, SPACE, C, O, M, P, R, E, S, S, I, O, N, SPACE, SPACE};
            row_2 = {SPACE, SPACE, SPACE, SPACE, C, O, M, P, L, E, T, E, SPACE, SPACE, SPACE, SPACE};
        end
        default: begin
          row_1 = 128'h20_20_20_20_20_20_20_20_20_20_20_20_20_20_20_20;
          row_2 = 128'h20_20_20_20_20_20_20_20_20_20_20_20_20_20_20_20;
        end
   endcase

   end
   endmodule