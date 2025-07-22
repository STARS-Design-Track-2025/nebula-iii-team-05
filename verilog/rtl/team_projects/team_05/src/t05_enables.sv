module t05_enables (
    input logic histo_en, flv_en, htree_to_flv_en, htree_to_cb_en, cb_en, trans_en, spi_en,
    output [3:0] op_fin,
);
always_comb begin
    if (histo_en) begin
        op_fin = HFIN;
    end
    else if (flv_en) begin
        op_fin = FLV_FIN;
    end
    else if (htree_to_flv_en) begin
        op_fin = HTREE_FIN;
    end
    else if (htree_to_)

end

endmodule;