module t05_top_tb;
    logic clk, rst;
    // histogram
    logic [7:0] spi_in;        // input byte from SPI
    logic [31:0] sram_in;       // value from SRAM
    logic       eof, complete; // eof = end of file; complete = done with byte
    logic [31:0] total, sram_out;  //total number of characters within the file,  the updated data going to the sram 
    logic [7:0]  hist_addr;     // address to SRAM
    logic [1:0] wr_r_en;       // enable going to sram to tell it to read or write
    
    // FLV
    logic [63:0] compVal; // previous least value to compare with current one
    logic [3:0] en_state; // enable state (from controller)
    logic [63:0] sum; // amount of occurrences of current char (current element)
    logic [7:0] charWipe1, charWipe2; // charWipe1 & charWipe2 for setting least1's and least2's occurrences to 0 after found if they are chars (not sums)
    logic [8:0] least1, least2, histo_index; //output least1 and least2 and the histo index (either from histogram if chars of htree if sums)
    logic [2:0] fin_state; // finish state (sent to controller)

    task reset_fsm();
      begin
        reset = 1;
        @(posedge clk);
        reset = 0;
        @(posedge clk);
      end
    endtask

    task set_inputs(logic [6:0] max_index1, logic [70:0] h_element1);
      begin
        max_index = max_index1;
        h_element = h_element1;
        @(posedge clk);
      end
    endtask

    initial begin
      $dumpfile("t05_cb_synthesis.vcd"); //change the vcd vile name to your source file name
      $dumpvars(0, t05_cb_synthesis_tb);

    end

endmodule;