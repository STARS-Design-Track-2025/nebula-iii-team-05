module lcd(
input logic clk, rst, 
 input logic comp,
 input logic decomp, //button for compression or decompression
 input logic select, //button to select compression or decompression
 input logic [3:0] enstate,
 output logic [127:0] row_1, row_2
);

    typedef enum logic [3:0] { 
        IDLE=0,
        SELECT=1,
        COMP=2,
        HISTOGRAM=3,
        FLV=4,
        HUFFMAN=5,
        CODEBOOK=6,
        TRANSLATION=7,
        SPI=8,
        DECOMP=9,
        DEIDLE=10,
        HEADER=11,
        DETRANSLATION=12,
        DECOMPLETE=13,
        COMPLETE=14,
        ERROR=15
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
            // row_1 = {O, N, E, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE};
            // row_2 = {SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE};
            //  case(enstate)
            //  SELECT: begin
            //      row_1 = {T, W, O, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE};
            //             row_2 = {SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE};
            //  end
            //  COMP: begin
            // row_1 = {T, H, R, E, E, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE};
            // row_2 = {SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE};
            //  end
            //  DECOMP: begin
            // row_1 = {F, O, U, R, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE};
            //             row_2 = {SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE};
            //  end
            //     IDLE: begin
            //         row_1 = {F, I, V, E, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE};
            //             row_2 = {SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE};
            //     end
            //     HISTOGRAM: begin
            //         row_1 = {S, I, X, SPACE, SPACE, SPACE, SPACE, SPACE, 64'b0};
            //             row_2 = {SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE};
            //     end
            //     FLV: begin
            //         row_1 = {S, E, V, E, N, SPACE, SPACE, 72'b0};
            //             row_2 = {SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE};
            //     end
            //     HUFFMAN: begin
            //         row_1 = {E, I, G,H, T, SPACE, 80'b0};
            //             row_2 = {SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE};
            //     end
            //     CODEBOOK: begin
            //         row_1 = {N, I, N, E, SPACE, SPACE, SPACE, SPACE, SPACE, 56'b0};
            //             row_2 = {SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE};
            //     end
            //     TRANSLATION: begin
            //         row_1 = {T, E, N, SPACE, SPACE, 88'b0};
            //             row_2 = {SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE};
            //     end
            //     SPI: begin
            //         row_1 = {E, L, E, V, E, N, SPACE, 72'b0};
            //         row_2 = {FILL, FILL, FILL, FILL, FILL, FILL, FILL, FILL, FILL, FILL, FILL, SPACE, SPACE, SPACE, SPACE, SPACE};
            //     end
            //     ERROR: begin
            //         row_1 = {T, W, E, L, V, E, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE};
            //             row_2 = {SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE};
            //     end
            //     COMPLETE: begin
            //         row_1 = {O, N, E, T, H, R, E, E, SPACE, SPACE, SPACE, SPACE, SPACE, 24'b0};
            //             row_2 = {SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE};
            //     end                 
            //     DEIDLE: begin
            //         row_1 = {O, N, E, F, O, U, R, SPACE, 64'b0};
            //             row_2 = {SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE};
            //          end
            //         HEADER: begin
            //             row_1 = {O, N, E, F, I, V, E, SPACE, SPACE, SPACE, SPACE, SPACE, 32'b0};
            //             row_2 = {SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE};
            //         end
            //         DETRANSLATION: begin
            //             row_1 = {O, N, E, S, I, X, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, 32'b0};
            //             row_2 = {SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE};
            //         end
            //         DECOMPLETE: begin
            //             row_1 = {O, N, E, S, E, V, E, N, SPACE, SPACE, SPACE, SPACE, 32'b0};
            //             row_2 = {SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE};
            //         end 
            //         default: begin
            //             row_1 = {O, N, E, E, I, G, H, T, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE};
            //             row_2 = {SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE};
            //         end
            //  endcase

                         row_1 = {SPACE,  B, I, G, G, I, E, SPACE, SPACE, S, M, A, L, L, S, SPACE};
            row_2 = {SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE};
             case(enstate)
             SELECT: begin
                 row_1 = {SPACE,  B, I, G, G, I, E, SPACE, SPACE, S, M, A, L, L, S, SPACE};
                 row_2 = {SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE};
             end
             COMP: begin
            row_1 = {ARROW, SPACE, C, O, M, P, R, E, S, S, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE};
            row_2 = {SPACE, SPACE, D, E, C, O, M, P, R, E, S, S, SPACE, SPACE, SPACE, SPACE};
             end
             DECOMP: begin
            row_1 = {SPACE, SPACE, C, O, M, P, R, E, S, S, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE};
            row_2 = {ARROW, SPACE, D, E, C, O, M, P, R, E, S, S, SPACE, SPACE, SPACE, SPACE};
             end
                IDLE: begin
                    row_1 = {SPACE,  B, I, G, G, I, E, SPACE, SPACE, S, M, A, L, L, S, SPACE};
                    row_2 = {SPACE, SPACE, C, O, M, P, R, E, S, S, I, O, N, SPACE, SPACE, SPACE};
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
                DEIDLE: begin
                    row_1 = {SPACE,  B, I, G, G, I, E, SPACE, SPACE, S, M, A, L, L, S, SPACE};
                    row_2 = {SPACE, D, E, C, O, M, P, R, E, S, S, I, O, N, SPACE, SPACE};                   
                     end
                    HEADER: begin
                        row_1 = {D, E, C, O, D, I, N, G, DOT, DOT, DOT, SPACE, SPACE, SPACE, SPACE, SPACE};
                        row_2 = {FILL, FILL, FILL,SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE};
                    end
                    DETRANSLATION: begin
                        row_1 = {D, E, T, R, A, N, S, L, A, T, I, N, G, DOT, DOT, DOT};
                        row_2 = {FILL, FILL, FILL, FILL, FILL, FILL, FILL, FILL, FILL, FILL, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE};
                    end
                    DECOMPLETE: begin
                        row_1 = {SPACE, D, E, C, O, M, P, R, E, S, S, I, O, N, SPACE, SPACE                                                                                                                                                                                             };
                        row_2 = {SPACE, SPACE, SPACE, SPACE, C, O, M, P, L, E, T, E, SPACE, SPACE, SPACE, SPACE};
                    end 
                    default: begin
                        row_1 = {SPACE,  B, I, G, G, I, E, SPACE, SPACE, S, M, A, L, L, S, SPACE};
                        row_2 = {SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE, SPACE};
                    end
             endcase
    end 
   endmodule 