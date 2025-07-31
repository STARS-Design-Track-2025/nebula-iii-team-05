`timescale 10ms/1ns
module t05_sram_interface_tb;
    logic clk;
    logic rst;
    //histogram inputs
    logic [31:0] histogram;
    logic [7:0] histgram_addr;
    logic [1:0] hist_r_wr;
    //flv inputs
    logic [8:0] find_least;
    logic [7:0] charwipe1; 
    logic [7:0] charwipe2;
    logic flv_r_wr;
    //htree inputs
    logic [70:0] new_node;
    logic [6:0] htreeindex;
    logic htree_r_wr;
    //codebook inputs
    logic [6:0] curr_index; //addr of data wanting to be pulled from the htree
    logic [7:0] char_index; //addr for writing data in
    logic [127:0] codebook_path; //store this data 
    logic cb_r_wr;
    //translation input
    logic [7:0] translation;
    //controller input
    logic [3:0] state;
    //wishbone connects
    logic wr_en;
    logic r_en;
    logic busy_o;  
    logic [3:0] select;
    logic [31:0] addr;
    logic [31:0] data_i;
    logic [31:0] data_o;
    //htree outputs
    logic [63:0] nulls; //data going to htree
    logic ht_done;
    // histogram output
    logic [31:0] old_char; //data going to histogram
    //flv outputs
    logic [63:0] comp_val; //going to find least value
    //codebook outputs
    logic [70:0] h_element; //from the htree going to codebook
    logic cb_done;
    //translation outputs
    logic [127:0] path;
    //controller output
    logic [5:0] ctrl_done;

  // Instantiate the DUT
  t05_sram_interface test (
    .clk(clk),
    .rst(rst),
    
    .histogram(histogram),
    .histgram_addr(histgram_addr),
    .hist_r_wr(hist_r_wr),
    
    .find_least(find_least),
    .charwipe1(charwipe1),
    .charwipe2(charwipe2),
    .flv_r_wr(flv_r_wr),
    
    .new_node(new_node),
    .htreeindex(htreeindex),
    .htree_r_wr(htree_r_wr),

    .curr_index(curr_index),
    .char_index(char_index),
    .codebook_path(codebook_path),
    .cb_r_wr(cb_r_wr),

    .translation(translation),

    .state(state),

    .wr_en(wr_en),
    .r_en(r_en),
    .busy_o(busy_o),
    .select(select),
    .addr(addr),
    .data_i(data_i),
    .data_o(data_o),
    .nulls(nulls),
    .ht_done(ht_done),
    .old_char(old_char),
    .comp_val(comp_val),
    .h_element(h_element),
    .cb_done(cb_done),
    .path(path),
    .ctrl_done(ctrl_done)
  );

    always begin
        #1
        clk = ~clk;
    end

    initial begin
        $dumpfile("t05_sram_interface.vcd");
        $dumpvars(0, t05_sram_interface_tb);
        clk = 0;
        rst = 0;

        histogram = '0;
        histgram_addr = '0;
        hist_r_wr = 0;

        find_least = '0;
        charwipe1 = '0;
        charwipe2 = '0;
        flv_r_wr = 0;

        new_node = '0;
        htreeindex = '0;
        htree_r_wr = 0;

        curr_index = '0;
        char_index = '0;
        codebook_path = '0;
        cb_r_wr = 0;

        translation = '0;

        state = '0;

        busy_o = 0;
        data_o = '0;

        #10
        rst = 1;
        #20
        rst = 0;

        #100

        state = 1;
        histogram = 20;
        histgram_addr = 3;
        hist_r_wr = 1;

        #2

        histogram = 25;
        histgram_addr = 4;
        hist_r_wr = 0;
        
        #2

        #1 $finish;
    end

endmodule