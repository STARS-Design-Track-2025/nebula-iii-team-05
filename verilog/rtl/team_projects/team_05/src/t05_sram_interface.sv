    typedef enum logic [2:0] {
        A_IDLE = 3'b000,
        HIST   = 3'b001,
        FLV    = 3'b010,
        HTREE  = 3'b011,
        CODEBOOK = 3'b101,
        TRANSLATION = 3'b110
    } module_state_t;


    typedef enum logic [1:0] {
        S_IDLE,
        S_WAIT1,
        S_WAIT2
    } ctrl_state_t;


module t05_sram_interface(  //send enable to htree and codebook for when it is done with that piece of data
    input  logic clk,
    input  logic rst,
    //histogram inputs
    input  logic [31:0] histogram,
    input  logic [7:0] histgram_addr,
    input  logic hist_r_wr,
//flv inputs
    input  logic [8:0] find_least,
    input logic [7:0] charwipe1, charwipe2,
    input logic flv_r_wr,
//htree inputs
    input  logic [70:0] new_node,
    input  logic [6:0] htreeindex,
    input  logic htree_r_wr,
//codebook inputs
    input logic [6:0] curr_index, //addr of data wanting to be pulled from the htree
    input  logic [7:0] char_index, //addr for writing data in
    input  logic [127:0] codebook_path, //store this data 
//translation input
    input  logic [7:0] translation,
//controller input
    input  logic [2:0] state,
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
    // histogram output
    output logic [31:0] old_char, //data going to histogram
//flv outputs
    output logic [63:0] comp_val, //going to find least value
    //codebook outputs
    output logic [70:0] h_element, //from the htree going to codebook
    output logic cb_done,
//translation outputs
    output logic [127:0] path,
//controller output
    output logic [2:0] ctrl_done
);


    module_state_t curr_module;
    ctrl_state_t ctrl_state, next_ctrl;

    logic do_read, do_write;
    logic [31:0] base_addr;

    logic ht;
    logic cb;
    logic [2:0] done;


    logic [31:0] sram_data_in_hist;
    logic [63:0] sram_data_in_ht;
    logic [31:0] sram_data_out_his;
    logic [63:0] sram_data_out_flv;
    logic [127:0] sram_data_out_trn;
    logic [70:0] sram_data_out_cb;
    logic [70:0] sram_data_out_ht;
    logic [2:0] word_cnt;
    logic [127:0] cb_path_buff;
    logic [63:0] node_buffer;
    logic [127:0] temp_path;
    logic [63:0] find_it;
    logic [70:0] cb_out;
    logic [127:0] cb_path_sram;

always_ff @( posedge clk, posedge rst ) begin : blockName
    if (rst) begin
        word_cnt <= 0;
        cb_path_buff <= 0;
        node_buffer <= 0;
        temp_path <= 0;
        find_it <= 0;
        cb_done <= 0;
        ht_done <= 0;
    end else if (state == CODEBOOK && do_write) begin
        case (word_cnt)
            0: begin //wait state 
            end 
            1: begin
                addr <= base_addr + (char_index * 4);
                data_i <= cb_path_buff[31:0];
            end 
            2: begin
                addr <= base_addr + (char_index * 4) + 4;
                data_i <= cb_path_buff[63:32];
            end
            3: begin
                addr <= base_addr + (char_index * 4) + 8;
                data_i <= cb_path_buff[95:64];
            end
            4: begin
                addr <= base_addr + (char_index * 4) + 12;
                data_i <= cb_path_buff[127:96];
            end
        endcase
        cb_path_buff <= cb_path_sram ;
        word_cnt <= word_cnt + 1;
        if (word_cnt == 5) begin
            cb_done <= 1;
            word_cnt <= 0;
            done <= 3'd5;
        end
    end else if (state == CODEBOOK && do_read) begin
        case (word_cnt)
            0: begin
                addr <= base_addr + (curr_index * 4) ;
                cb_out[31:0] <= data_o;
            end 
            1: begin
                addr <= base_addr + (curr_index * 4) + 4;
                cb_out[63:32] <= data_o;
            end
            2: begin
                addr <= base_addr + (curr_index * 4) + 8;
                cb_out[70:64] <= data_o[6:0];
            end
        endcase
        word_cnt <= word_cnt + 1;
        if (word_cnt == 3) begin
            h_element <= cb_out;
            cb_done <= 1;
            word_cnt <= 0;
        end
    end else if (state == HTREE && do_read) begin
        case (word_cnt)
            0: begin
                addr <= base_addr + (htreeindex * 4);
                node_buffer[31:0] <= data_o;
           end
            1: begin 
                addr <= base_addr + (htreeindex * 4) + 4;
                node_buffer[63:32] <= data_o;
            end
        endcase
        word_cnt <= word_cnt + 1;
        if (word_cnt == 2) begin
            nulls <= node_buffer;
            ht_done <= 1;
            word_cnt <= 0;
        end
    end else if (state == HTREE && do_write) begin
        case (word_cnt)
            0: begin  //wait state for the sram to read
            end
            1: begin
                addr <= base_addr + (new_node[6:0] * 4);
                data_i <= new_node[38:7];
           end
            2: begin 
                addr <= base_addr + (new_node[6:0] * 4) + 4;
                data_i <= new_node[70:39];
            end
        endcase
        word_cnt <= word_cnt + 1;
        if (word_cnt == 3) begin
            ht_done <= 1;
            word_cnt <= 0;
            done <= 3'd3;
        end
    end else if (state == TRANSLATION && do_read) begin
        case (word_cnt)
            0: begin
                addr <= base_addr + (4 * translation) + 0;
                temp_path[31:0]   <= data_o;
            end
            1: begin
                addr <= base_addr + (4 * translation) + 4;
                temp_path[63:32]  <= data_o;
            end
            2: begin
                addr <= base_addr + (4 * translation) + 8;
                temp_path[95:64]  <= data_o;
            end
            3: begin
                addr <= base_addr + (4 * translation) + 12;
                temp_path[127:96] <= data_o;
            end
        endcase
            word_cnt <= word_cnt + 1;
            if (word_cnt == 3) begin
                path <= temp_path;
                word_cnt <= 0;
            end
    end else if (state == FLV && do_read) begin
        case (word_cnt)
            0: begin
                addr <= base_addr + (4 * find_least);
                find_it[31:0] <= data_o;
            end
            1: begin
                addr <= base_addr + (4 * find_least) + 4;
                find_it[63:32] <= data_o;
            end
        endcase
        word_cnt <= word_cnt + 1;
        if (word_cnt == 2) begin
            sram_data_out_flv <= find_it;
            word_cnt <= 0;
        end
    end else if (state == FLV && do_write) begin
        case (word_cnt)
            0: begin
                addr <= base_addr + (4 * charwipe1);
                data_i <= 0;
            end
            1: begin
                addr <= base_addr + (4 * charwipe2);
                data_i <= 0;
            end
        endcase
        word_cnt <= word_cnt + 1;
        if (word_cnt == 1) begin
            word_cnt <= 0;
            done <= 3'd2;
        end
    end 

end

always_ff @( posedge clk, posedge rst ) begin
    if (rst) begin
        ctrl_done <= 3'b0;
    end else begin
        ctrl_done <= 3'b0;
        if (state == HIST) begin
            ctrl_done <= done;
        end else if (state == FLV) begin
            ctrl_done <= done;
        end else if (state == HTREE) begin
            ctrl_done <= done;
        end else if (state == CODEBOOK) begin
            ctrl_done <= done;
        end else if (state == TRANSLATION) begin
            ctrl_done <= done;
        end
    end
end
    always_ff @( posedge clk, posedge rst ) begin
        if (rst) begin
            ht_done <= 0;
            cb_done <= 0;
        end else if (state == HTREE) begin
            ht_done <= !ht;
        end else if (state == CODEBOOK) begin
            cb_done <= !cb;
        end
    end

    // FSM to manage r_en, wr_en, and busy_o
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            ctrl_state <= S_IDLE;
            r_en <= 0;
            wr_en <= 0;
        end else begin
            ctrl_state <= next_ctrl;
            case (ctrl_state)
                S_IDLE: begin
                    if (do_read) begin
                        r_en <= 1;
                        next_ctrl <= S_WAIT1;
                    end else if (do_write) begin
                        wr_en <= 1;
                        next_ctrl <= S_WAIT1;
                    end
                end
                S_WAIT1: begin
                    next_ctrl <= S_WAIT2;
                end
                S_WAIT2: begin
                    r_en <= 0;
                    wr_en <= 0;
                    next_ctrl <= S_IDLE;
                end
            endcase
        end
    end

    // Top-level combinational control for operations
    always_comb begin
        do_read  = 0;
        do_write = 0;
        select   = 4'b1111;
        base_addr = 0;

        case (state)
            HIST: begin
                base_addr = 32'b0;
                if (hist_r_wr == 0) begin 
                    do_read = 1;
                end else if (hist_r_wr == 1) begin
                    do_write = 1;
            end
            end
            FLV: begin
                base_addr = 32'd0;
                if (flv_r_wr == 0) begin
                    do_read = 1;
                end else if (flv_r_wr == 1) begin 
                    do_write =1;
                end
            end
            HTREE: begin
                base_addr = 32'd1024;
                if (htree_r_wr == 0) begin 
                    do_read = 1;
                end else if (htree_r_wr == 1) begin
                    do_write = 1;
                end
            end
            CODEBOOK: begin
                base_addr = 32'd2048;
                if (char_index == 0) begin
                    do_read = 1;
                end else begin
                    do_write = 1;
                end
            end
            TRANSLATION: begin
                base_addr = 32'd0;
                do_read = 1;
            end
            default: begin
                do_read = 0;
                do_write = 0;
            end
        endcase
    end

    // Data path
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            addr <= 0;
            old_char <= 0;
            comp_val <= 0;
            path <= 0;
            h_element <= 0;
            ht <= 0;
            cb <= 1;
        end else begin
            case (state)
                HIST: begin
                    addr <= base_addr + (4 * histgram_addr);
                    if (do_write) begin
                        data_i <= histogram;
                        done <= 3'd1;
                    end else if (do_read)  begin 
                        old_char <= data_o;
                        done <= 3'd1;
                    end
                end
                FLV: begin
                if (do_read && busy_o && word_cnt == 2) begin

                        if (find_least <= 255) begin
                            comp_val <= sram_data_out_flv;
                        end else begin
                            comp_val <= sram_data_out_flv; //64 bits of data back 46 coming from the htree 
                        end
                        done <= 3'd2;
                    end
                end

                HTREE: begin
                    if (do_read && busy_o && word_cnt == 2) begin
                        h_element <= sram_data_out_ht; //the htree will be getiing data from itself at the htreeindex
                        ht <= 1;  //enable going to the htree to let it know that the sram is finished
                        done <= 3'd3;
                    end 
                    end
                CODEBOOK: begin
                    if (do_write) begin
                        cb_path_sram <= codebook_path;
                    end else if (do_read && busy_o && word_cnt == 2) begin
                        h_element <= sram_data_out_cb;
                        cb <= 1;  //enable going to the codebook letting it know that it is finished 
                        done <= 3'd5;
                    end 
                end
               
                TRANSLATION: begin
                    if (do_read && busy_o && word_cnt == 3) begin
                        done <= 3'd6;
                    end
                end
            endcase
        end
    end

endmodule