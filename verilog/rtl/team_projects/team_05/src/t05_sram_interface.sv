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
//inputs from sram
    input  logic [31:0] sram_data_out_his,
    input  logic [63:0] sram_data_out_flv,
    input  logic [127:0] sram_data_out_trn,
    input  logic [70:0] sram_data_out_cb,
    input  logic [70:0] sram_data_out_ht,

    output logic wr_en,
    output logic r_en,
    output logic busy_o,  //this should be an input
    output logic [3:0] select,

    output logic [31:0] addr,
    //htree outputs
    output logic [63:0] sram_data_in_ht,  //stored to sram
    output logic [63:0] nulls, //data going to htree
    // histogram output
    output logic [31:0] sram_data_in_hist, //stored to sram
    output logic [31:0] old_char, //data going to histogram
//flv outputs
    output logic [63:0] comp_val, //going to find least value
    output logic [63:0] sram_data_in_flv, //stored to sram
    //codebook outputs
    output logic [70:0] h_element, //from the htree going to codebook
    output logic [127:0] cb_path_sram, //going to sram
//translation outputs
    output logic [127:0] path
);


    module_state_t curr_module;
    ctrl_state_t ctrl_state, next_ctrl;

    logic do_read, do_write;
    logic [31:0] base_addr;

    // FSM to manage r_en, wr_en, and busy_o
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            ctrl_state <= S_IDLE;
            r_en <= 0;
            wr_en <= 0;
            busy_o <= 0;
        end else begin
            ctrl_state <= next_ctrl;
            case (ctrl_state)
                S_IDLE: begin
                    if (do_read) begin
                        r_en <= 1;
                        busy_o <= 1;
                        next_ctrl <= S_WAIT1;
                    end else if (do_write) begin
                        wr_en <= 1;
                        busy_o <= 1;
                        next_ctrl <= S_WAIT1;
                    end
                end
                S_WAIT1: begin
                    next_ctrl <= S_WAIT2;
                end
                S_WAIT2: begin
                    r_en <= 0;
                    wr_en <= 0;
                    busy_o <= 0;
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
                do_write = 1;
                do_read = 1;  //still need to find an enable for this
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
            sram_data_in_hist <= 0;
            sram_data_in_flv <= 0;
            sram_data_in_ht <= 0;
            old_char <= 0;
            comp_val <= 0;
            path <= 0;
            h_element <= 0;
        end else begin
            case (state)
                HIST: begin
                    addr <= base_addr + (4 * histgram_addr);
                    if (do_write) begin
                        sram_data_in_hist <= histogram;
                    end else if (do_read)  begin 
                        old_char <= sram_data_out_his;
                    end
                end
                FLV: begin
                    if (wr_en && !r_en) begin
                        addr <= base_addr + (4 * charwipe1);
                        sram_data_in_flv <= 0; //replacing the date that is at that addr to 0


                        addr <= base_addr + (4 * charwipe2);
                        sram_data_in_flv <= 0;  //replacing this data that is at chrwipe 2 to 0
                    end else if (r_en && !wr_en) begin

                        if (find_least <= 255) begin
                            addr <= base_addr + (4 * find_least); //data coming from the histogram so make the base addr the same
                            comp_val <= sram_data_out_flv;
                        end else begin
                            addr <= base_addr + (4 * find_least);  //same base addr as the htree
                            comp_val <= sram_data_out_flv; //64 bits of data back 46 coming from the htree 
                        end
                    end
                end

                HTREE: begin
                    if (wr_en && !r_en) begin
                        addr <= base_addr + (4 * new_node[6:0]);
                        sram_data_in_ht <= new_node[70:7];
                    end else if (r_en && !wr_en) begin
                        addr <= base_addr + (4 * htreeindex);
                        h_element <= sram_data_out_ht; //the htree will be getiing data from itself at the htreeindex
                    end 
                    end
                CODEBOOK: begin
                    if (wr_en && !r_en) begin
                    addr <= base_addr + (4 * char_index);
                    cb_path_sram <= codebook_path;
                    end else if (r_en && !wr_en) begin
                        addr <= base_addr + (4 * curr_index);  //data comming from the htree so make the base addr the same as htree written data
                        h_element <= sram_data_out_cb;
                    end 
                end
                TRANSLATION: begin
                        addr <= base_addr + (4 * translation);
                        path <= sram_data_out_trn;
                end
            endcase
        end
    end

endmodule