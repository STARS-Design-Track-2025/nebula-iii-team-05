module t05_sram_interface(
    input logic clk, rst, busy_o, trn_nxt_char,//enable for when the data has been read
    input logic [31:0] histogram, //new histogram value to write
    input logic [7:0] histgram_addr, //address from the histogram
    input logic hist_r_wr,
    input logic [8:0] find_least,  //count 
    input logic [70:0] new_node,
    input logic [6:0] htreeindex,
    input logic htree_r_wr,
    input logic [7:0] codebook, 
    input logic [127:0] codebook_path, 
    input logic [7:0] translation, 
    input logic [2:0] state,  // the state bit of which module the data is from
    input logic [31:0] sram_data_out_his,
    input logic [63:0] sram_data_out_flv,
    input logic [128:0] sram_data_out_trn,
    input logic [70:0] sram_data_out_cb,
    input logic [31:0] sram_data_out_ht,
    output logic wr_en, r_en,
    output logic [3:0] select,
    output logic [31:0] old_char,
    output logic [31:0] addr, sram_data_in,//output value to read from sram
    output logic [63:0] comp_val, //find least value
    output logic [70:0] h_element, 
    output logic [128:0] char_code
);
//the goal of the sraminterface is to input data from different addresses and either store the data that is given to it or output the data that the address pulls
//the goal of the sram interface is to communicate with the sram to wither read of write data using specific addresses assigned by the sram interface.
    logic ready_his;  //histogram ready
    logic ready_flv; //flv ready
    logic ready_trn; //translation
    logic ready_cb;  //codebook
    logic ready_ht;  //htree

    logic [31:0] base_addr;

    typedef enum logic [2:0] { 
        A_IDLE = 3'b000,
        HIST = 3'b001,
        FLV = 3'b010,
        // HTREE = 3'b011,
        CODEBOOK = 3'b101,
        TRANSLATION = 3'b110
    } name;
   

    always_comb begin  
        wr_en = 0;
        r_en = 0;
        ready_his = 0;
        ready_flv = 0;
        ready_trn = 0;
        ready_cb = 0;
        // ready_ht =0;
        select = 4'b1111;
        if (state == A_IDLE) begin
            wr_en = 0;
            r_en = 0;
            ready_his = 0;
            ready_flv = 0;
            ready_trn = 0;
            ready_cb = 0;
            ready_ht =0;
        end else if (state == HIST) begin
            if (hist_r_wr == 0) begin
                wr_en = 0;  //the histogram should write for the histogram
                r_en =1;  //the sram should read for the histogram
                ready_his = 1;  //data from the histogram has been inputted
                base_addr = 32'b0;

                ready_flv = 0;
                ready_trn = 0;
                ready_cb = 0;
                ready_ht =0;
            end
            if (hist_r_wr == 1) begin
                wr_en = 1;  //the histogram should write for the histogram
                r_en =0;  //the sram should read for the histogram
                ready_his = 1;  //data from the histogram has been inputted
                base_addr = 32'b0;

                ready_flv = 0;
                ready_trn = 0;
                ready_cb = 0;
                ready_ht =0;
            end
        end else if (state == HTREE) begin
            if (htree_r_wr == 0) begin
                r_en = 1;
                wr_en = 0;  //the histogram should write for the histogram
                ready_ht = 1;// specific ready input to the htree that the data has been inputted 
                base_addr = 12'b100000000;   
            end 
            if (htree_r_wr == 1) begin
                r_en = 0;
                wr_en = 1;  //the histogram should write for the histogram
                ready_ht = 1;// specific ready input to the htree that the data has been inputted 
                base_addr = 12'b100000000;   
            end
        end else if (state == FLV) begin
            r_en = 1;  //the sram should read for the histogram
            ready_flv = 1; // specific ready input to the flv that the data has been inputted
            base_addr = 32'b0;

            ready_his = 0;
            ready_trn = 0;
            ready_cb = 0;
            ready_ht =0; 

        end else if (state == CODEBOOK) begin
            wr_en = 1;  //the histogram should write for the histogram
            ready_cb = 1; // specific ready input to the flv that the data has been inputted
            base_addr = 32'b1000000000;

            ready_his = 0;
            ready_flv = 0;
            ready_trn = 0;
            ready_ht = 0;
        end else if (state == TRANSLATION) begin
            r_en =1;  //the sram should read for the histogram
            ready_trn = 1;// specific ready input to the flv that the data has been inputted
            base_addr = 32'b0;

            ready_his = 0;
            ready_flv = 0;
            ready_ht = 0;
            ready_cb = 0;
        end               

    end
    //state machine with wr, r and busy o

    //idle > read > readwait > idle
    //idel > write > writewait > idle\
    typedef enum logic[2:0] { 
        IDLE,
        READ,
        WRITE,
        WAITREAD, 
        WAITWRITE,
        DONE_R,
        DONE_WR
     } name;

always_comb begin
    case ()
        IDLE: begin
            if () begin
                next_state = READ;
            end else if () begin 
                next_state = WRITE;
            end
        end
        READ: begin
            next_state = WAITREAD
        end 
        WRITE: begin
            next_state = WAITWRITE
        end
        WAITREAD: begin
            next_state = DONE_R
        end
        WAITWRITE:begin
        next_state = DONE_WR
        end
        DONE_R: begin
            next_state = IDLE
        end
        DONE_WR: begin
            next_state = IDLE
        end
        default: begin 
            next_state = IDLE;
        end
    endcase

end
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            old_char <= 0;
            comp_val <= 0;
            char_code <= 0;
            h_element <= 0;
        end else if (ready_his) begin

            if (r_en && busy_o) begin //include that if the histogram enable from the controller is on too
                old_char <= sram_data_out_his;
                addr <= base_addr + (4 * histgram_addr); // Read 32-bit value at 8-bit address
            end 

            if (wr_en) begin 
                sram_data_in <= histogram;
                addr <= base_addr + (4 * histgram_addr);
            end
        end else if (ready_ht) begin
            if (wr_en) begin
                addr <= base_addr + (4 * htreeindex) 
                sram_data_in_ht <= h_element[31:0]; 
            end else if (r_en) begin
                node_data  <= sram_data_out_ht
                addr <= [base_addr + (4 * node_addr)];

            end
        end else if (ready_flv) begin
            if (find_least <= 255) begin
                comp_val <= sram_data_out_flv;
                addr <= base_addr + (4 * find_least); //the address will only give it a 32 bit value
            end else if (find_least <= 384) begin
            //    comp_val <= sum value from the htree
            end
        end else if (ready_trn && trn_nxt_char) begin
            char_code <= sram_data_out_trn;
            addr <= base_addr + (4 * translation);
        end else if (ready_cb) begin
            h_element <= sram_data_out_cb;
            addr <= base_addr + (4 * codebook);  //71 bit code coming from the sram stored by htree
        end 
    end

endmodule



            // else if (wr_en) begin
            //     sram[base_addr + (4 * histgram_addr)] <= histogram; // Write new 32-bit value
            // end 



        // end else if (ready_ht) begin
        //     if (wr_en) begin
        //         sram[base_addr + (4 * htreeindex)] <= h_element[31:0]; 
        //     end else if (r_en) begin
        //         node_data  <= {32'b0,sram[base_addr + (4* node_addr)]};

        //     end