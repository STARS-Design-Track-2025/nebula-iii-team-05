// $Id: $
// File name:   t00_ssdec.sv
// Created:     5/23/2024
// Author:      Miguel Isrrael Teran
// Description: Seven-Segment Decoder

module t00_ssdec (
    input logic [3:0] in,
    input logic enable,
    output logic [7:0] out
);
    always_comb begin
        out = '0;
        if (enable) begin
            case (in)
                4'h0: out = 8'b0111111;
                4'h1: out = 8'b0000110;
                4'h2: out = 8'b1011011;
                4'h3: out = 8'b1001111;
                4'h4: out = 8'b1100110;
                4'h5: out = 8'b1101101;
                4'h6: out = 8'b1111101;
                4'h7: out = 8'b0000111;
                4'h8: out = 8'b1111111;
                4'h9: out = 8'b1100111;
                4'ha: out = 8'b1110111;
                4'hb: out = 8'b1111100;
                4'hc: out = 8'b0111001;
                4'hd: out = 8'b1011110;
                4'he: out = 8'b1111001;
                4'hf: out = 8'b1110001;
            endcase
        end
    end
endmodule
