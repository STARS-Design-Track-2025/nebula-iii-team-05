module t05_sram_interface (
    input  logic clk,
    input  logic rst,
    //histogram inputs
    input  logic [31:0] histogram,
    input  logic [7:0] histgram_addr,
    input  logic [1:0] hist_r_wr,
    input  logic hist_read_latch,
    //flv inputs
    input  logic [8:0] find_least,
    input logic [7:0] charwipe1, charwipe2,
    input logic flv_r_wr,
    input logic pulse_FLV,
    input logic wipe_the_char,
    //htree inputs
    input  logic [70:0] new_node,
    input  logic [6:0] htreeindex,
    input logic [6:0] htree_write,
    input logic pulse_HTREE,
    input  logic htree_r_wr,
    input logic [3:0] HT_state,
    //codebook inputs
    input logic [7:0] curr_index, //addr of data wanting to be pulled from the htree
    input  logic [7:0] char_index, //addr for writing data in
    input  logic [127:0] codebook_path, //store this data 
    input logic cb_r_wr,
    //translation input
    input  logic [7:0] translation,
    //controller input
    input  logic [3:0] state,
    //wishbone connects
    output logic wr_en,
    output logic r_en,
    input logic busy_o,  
    output logic [3:0] select,
    output logic [31:0] addr,
    output logic [31:0] data_i,
    input logic [31:0] data_o,
    //htree outputs
    output logic [63:0] nulls, //data going to htree
    output logic ht_done,
    output logic write_HT_fin,
    output logic HTREE_complete,
    output logic HT_read_complete,
    // histogram output
    output logic [31:0] old_char, //data going to histogram
    output logic init,
    output logic nextChar,
    //flv outputs
    output logic [63:0] comp_val, //going to find least value
    output logic nextChar_FLV,
    output logic [3:0] word_cnt,
    output logic FLV_done,
    //codebook outputs
    output logic [70:0] h_element, //from the htree going to codebook
    output logic cb_done,
    //translation outputs
    output logic [127:0] path,
    //controller output
    output logic [5:0] ctrl_done
);

    logic [5:0] done;

    logic [31:0] index;
    assign index = {25'd0, (new_node[6:0] + 1'b1)};

    logic [31:0] hindex;
    assign hindex = {25'd0, htreeindex + 1'b1};

    logic [31:0] charindex1, charindex2, charindex3;
    assign charindex1 = {24'd0, char_index + 1'b1};
    assign charindex2 = {24'd0, char_index + 8'd2};
    assign charindex3 = {24'd0, char_index + 8'd3};

    logic [31:0] currindex;
    assign currindex = {24'd0, curr_index + 1'b1};

    logic [31:0] lindex1, lindex2, lindex3;
    assign lindex1 = {24'd0, translation + 1'b1};
    assign lindex2 = {24'd0, translation + 8'd2};
    assign lindex3 = {24'd0, translation + 8'd3};

    logic [31:0] FLV_HTREE_counter, FLV_HTREE_counter_n;

    logic [3:0] /*word_cnt,*/ word_cnt_n;

    logic [63:0] comp_val_n, nulls_n;
    logic [70:0] h_element_n;
    logic [127:0] path_n;
    logic init_n;
    logic [23:0] init_counter, init_counter_n;

    logic busy_o_last;

    logic [31:0] old_char_n;
    logic check, check_n;

    logic [31:0] HTREE_log;

    assign ctrl_done = '0;
    assign cb_done = 0;
    assign ht_done = 0;

    assign HTREE_log = {22'd0, find_least} - 32'd256;

    logic [31:0] ht_write_1;
    assign ht_write_1 = {24'd0, htree_write} + 32'd1;

    logic [31:0] ht_index_1;
    assign ht_index_1 = {24'd0, htreeindex} + 32'd1;


    logic [2:0] zero_cnt, zero_cnt_n;

    logic FLV_done_n;

    logic [2:0] write_counter_FLV, write_counter_FLV_n;

    logic write_HT_fin_n;
    logic [3:0] counter_HTREE, counter_HTREE_n;

always_ff @( posedge clk, posedge rst) begin
    if (rst) begin
        word_cnt <= 6;
        comp_val <= '0;
        nulls <= '0;
        h_element <= '0;
        path <= '0;
        init <= 1;
        init_counter <= '0;
        busy_o_last <= 0;
        old_char <= '0;
        check <= 0;
        zero_cnt <= 0;
        FLV_done <= '0;
        write_counter_FLV <= 0;
        write_HT_fin <= 0;
        counter_HTREE <= 0;
        FLV_HTREE_counter <= 0;
    end else begin
        word_cnt <= word_cnt_n;
        comp_val <= comp_val_n;
        nulls <= nulls_n;
        h_element <= h_element_n;
        path <= path_n;
        init <= init_n;
        init_counter <= init_counter_n;
        busy_o_last <= busy_o;
        old_char <= old_char_n;
        check <= check_n;
        write_counter_FLV <= write_counter_FLV_n;
        busy_o_last <= busy_o;
        zero_cnt <= zero_cnt_n;
        FLV_done <= FLV_done_n;
        write_HT_fin <= write_HT_fin_n;
        counter_HTREE <= counter_HTREE_n;
        FLV_HTREE_counter <= FLV_HTREE_counter_n;
    end
end

always_comb begin
    select   = 4'b1111;
    addr = 32'h33000000;
    wr_en = 0;
    r_en = 0;
    nextChar = 0;
    nextChar_FLV = 0;
    data_i = 0;
    HTREE_complete = 0;
    HT_read_complete = 0;

    old_char_n = old_char;
    check_n = check;
    write_HT_fin_n = write_HT_fin;
    comp_val_n = comp_val;
    word_cnt_n = word_cnt;
    nulls_n = nulls;
    h_element_n = h_element;
    path_n = path;
    init_n = init;
    init_counter_n = init_counter;
    zero_cnt_n = zero_cnt;
    FLV_done_n = FLV_done;
    write_counter_FLV_n = write_counter_FLV;
    FLV_HTREE_counter_n = FLV_HTREE_counter;

    counter_HTREE_n = counter_HTREE;

    case(state) 
        1: begin //HISTOGRAM
            if(init) begin
                addr = (init_counter < 2048) ? 32'h33000000 + (init_counter * 4) : 32'h33001FFC;
                data_i = '0;
                wr_en = (~check);
                r_en = 0;
                if (init_counter == 2048 && !check && (busy_o_last == 1 && busy_o == 0)) begin
                    check_n = 1;
                end
                else if(init_counter <= 2047 && (busy_o_last == 1 && busy_o == 0)) begin
                    init_counter_n = init_counter + 1;
                end
                else if (check) begin
                    init_n = 0;
                end
            end else begin
                data_i = histogram;
                addr = 32'h33000000 + (histgram_addr * 4);
                if(hist_r_wr == 1 && busy_o == 0) begin //(busy_o_last == 1 && busy_o == 0)) begin
                    wr_en = 1;
                    r_en = 0;
                    nextChar = 1; 
                    // addr = 32'h33000000 + (histgram_addr * 4);
                end else if (hist_r_wr == 0 && busy_o == 0) begin // (busy_o_last == 1 && busy_o == 0)) begin
                    wr_en = 0;
                    r_en = 1;
                    // addr = 32'h33000000 + (histgram_addr * 4);
                end
            end
            if (hist_read_latch) old_char_n = data_o;
        end
        2: begin //FLV
            write_HT_fin_n = 0;
            case(word_cnt)
                0: begin //IDLE
                    addr = '0;
                    if(find_least == 384 && write_counter_FLV == 4) begin
                        FLV_done_n = 1;
                        word_cnt_n = 0;
                        write_counter_FLV_n = 0;
                    end
                    else if(pulse_FLV && !busy_o) begin
                        FLV_done_n = 0;
                        word_cnt_n = 1;
                        comp_val_n = '0;
                    end else if (pulse_FLV && find_least == 0) begin
                        FLV_done_n = 0;
                        word_cnt_n = 1;
                        comp_val_n = '0;
                    end
                end
                1: begin //Determining histogram or htree
                    if(find_least == 384 && wipe_the_char) begin
                        addr = 32'h33000000 + (charwipe1 * 4);
                        data_i = '0;
                        write_counter_FLV_n = write_counter_FLV + 1;
                        wr_en = 1;
                        word_cnt_n = 9;
                        
                    end else if (find_least < 256) begin
                        addr = 32'h33000000 + (find_least * 4);
                        if(!flv_r_wr) begin
                            r_en = 1;
                        end
                        word_cnt_n = 2;
                        nextChar_FLV = 1;
                    end else if (find_least > 255) begin
                        FLV_HTREE_counter_n = HTREE_log * 2;
                        addr = 32'h33001024 + (FLV_HTREE_counter * 4);
                        if(!flv_r_wr) begin
                            r_en = 1;
                        end
                        word_cnt_n = 7;
                        nextChar_FLV = 1;
                    end
                end
                2: begin //Read in histogram state
                    if(!busy_o) begin
                            comp_val_n [31:0] = data_o;
                            comp_val_n [63:32] = '0;
                            nextChar_FLV = 1;
                            word_cnt_n = 0; //Back to idle
                    end
                    else if (find_least == 0 && zero_cnt == 3) begin
                        word_cnt_n = 0;
                    end

                    if(zero_cnt != 3) begin
                        zero_cnt_n = zero_cnt + 1;
                    end
                end
                3: begin //First HTREE read state
                    if(!busy_o) begin
                        addr = 32'h33001024 + ((FLV_HTREE_counter + 1) * 4);
                        if(!flv_r_wr) begin
                            r_en = 1;
                        end
                        word_cnt_n = 4;
                    end
                end
                7: begin
                    if(!busy_o) begin
                        word_cnt_n = 8;
                    end
                end
                8: begin
                    comp_val_n [63:32] = {18'd0, data_o[13:0]};
                    word_cnt_n = 3;
                end
                4: begin //Second HTREE read state
                    if(!busy_o) begin
                        comp_val_n [31:0] = data_o;
                        nextChar_FLV = 1;
                        word_cnt_n = 0;
                    end
                end
                5: begin //Finish overwriting histogram state
                    if(!busy_o) begin
                        addr = 32'h33000000 + (charwipe2 * 4);
                        data_i = '0;
                        wr_en = 1;
                        write_counter_FLV_n = write_counter_FLV + 1;
                        nextChar_FLV = 1;
                        word_cnt_n = 11; 
                    end
                end
                9: begin
                    if(!busy_o) begin
                        word_cnt_n = 10;
                    end
                end
                10: begin
                    if(!busy_o) begin
                        word_cnt_n = 5;
                    end
                end
                6: begin
                    word_cnt_n = 1;
                end
                11: begin
                    word_cnt_n = 12;
                end
                12: begin
                    word_cnt_n = 13;
                end
                13: begin
                    word_cnt_n = 14;
                end
                14: begin
                    if(write_counter_FLV != 4) begin
                        word_cnt_n = 1;
                    end else if (write_counter_FLV == 4) begin
                        word_cnt_n = 0;
                    end
                end
            endcase
        end
        3: begin //HTREE
            case(word_cnt)
                0: begin //IDLE
                    if (htree_write == '0 && counter_HTREE == 2 && !busy_o) begin
                        HTREE_complete = 1;
                    end
                    else if(pulse_HTREE && !busy_o) begin
                        word_cnt_n = 8;
                        counter_HTREE_n = 0;
                    end
                    else if(htree_r_wr) begin
                        word_cnt_n = 8;
                        counter_HTREE_n = 0;
                    end else if(HT_state == 9 && !busy_o && counter_HTREE == 2) begin
                        nulls_n[31:0] = data_o;
                        word_cnt_n = 8;
                        HT_read_complete = 1;
                    end
                end
                1: begin //DETERMINE
                    if(!htree_r_wr) begin
                        addr = 32'h33001024 + (htree_write * 4);
                        wr_en = 1;
                        word_cnt_n = 6;
                        data_i = new_node[63:32];
                        counter_HTREE_n = counter_HTREE + 1;
                    end
                    else if(htree_r_wr) begin
                        addr = 32'h33001024 + (htreeindex * 4);
                        r_en = 1;
                        word_cnt_n = 4;
                        counter_HTREE_n = counter_HTREE + 1;
                    end
                end
                2: begin //WRITE
                    addr = 32'h33001024 + (ht_write_1 * 4);
                    wr_en = 1;
                    word_cnt_n = 0;
                    data_i = new_node[31:0];
                    write_HT_fin_n = 1;
                    counter_HTREE_n = counter_HTREE + 1;
                end
                3: begin //READ
                    addr = 32'h33001024 + (ht_index_1 * 4);
                    r_en = 1;
                    word_cnt_n = 0;
                    counter_HTREE_n = counter_HTREE + 1;
                end
                //4 & 5 are reading waits
                4: begin
                    if(!busy_o) begin
                        word_cnt_n = 5;
                    end
                end
                5: begin
                    nulls_n[63:32] = data_o;
                    word_cnt_n = 3;
                end
                //6 & 7 are writing waits
                6: begin
                    if(!busy_o) begin
                        word_cnt_n = 7;
                    end
                end
                7: begin
                    word_cnt_n = 2;
                end
                8: begin
                    word_cnt_n = 1;
                end
            endcase
        end
        4: begin //CBS
            if (cb_r_wr == 1) begin
                wr_en = 1;
                r_en = 0;
                case (word_cnt) 
                        0: begin
                            addr = '0;
                            word_cnt_n = 1;
                        end
                        1: begin
                            addr = 32'h33003072 + char_index * 4;
                            data_i = codebook_path[127:96];
                            word_cnt_n = 2;
                        end
                        2: begin
                            addr = 32'h33001024 + (charindex1 * 4);
                            data_i = codebook_path[95:64];
                            word_cnt_n = 3;
                        end
                        3: begin
                            addr = 32'h33001024 + (charindex2 * 4);
                            data_i = codebook_path[63:32];
                            word_cnt_n = 4;
                        end
                        4: begin
                            addr = 32'h33001024 + (charindex3 * 4);
                            data_i = codebook_path[31:0];
                            word_cnt_n = 0;
                        end
                endcase
            end
            else if (cb_r_wr == 0) begin
                wr_en = 0;
                r_en = 1;
                case (word_cnt) 
                        0: begin
                            addr = '0;
                            word_cnt_n = 1;
                        end
                        1: begin
                            addr = 32'h33003072 + curr_index * 4;
                            h_element_n[63:32] = data_o;
                            word_cnt_n = 2;
                        end
                        2: begin
                            addr = 32'h33001024 + (currindex * 4);
                            h_element_n[31:0] = data_o;
                            word_cnt_n = 3;
                        end
                        3: begin
                            h_element_n[70:64] = curr_index[6:0];
                            word_cnt_n = 0;
                        end
                endcase
            end
        end
        5: begin //Translation
            wr_en = 0;
            r_en = 1;
            case(word_cnt)
                0: begin
                    addr = '0;
                    word_cnt_n = 1;
                end
                1: begin
                    addr = 32'h33003072 + (translation * 4);
                    path_n[127:96] = data_o;
                    word_cnt_n = 2;
                end
                2: begin
                    addr = 32'h33003072 + (lindex1 * 4);
                    path_n[95:64] = data_o;
                    word_cnt_n = 3;                    
                end
                3: begin
                    addr = 32'h33003072 + (lindex2 * 4);
                    path_n[63:32] = data_o;
                    word_cnt_n = 4;
                end
                4: begin
                    addr = 32'h33003072 + (lindex3 * 4);
                    path_n[31:0] = data_o;
                    word_cnt_n = 0;
                end
            endcase
        end
        default: begin
            addr = '0;
        end
    endcase

end

endmodule