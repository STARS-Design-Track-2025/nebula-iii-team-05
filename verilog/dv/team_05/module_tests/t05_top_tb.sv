module t05_top_tb;
    logic clk, rst;
    // Histogram
    logic [7:0] spi_in;        // input byte (FILE CHAR) from SPI
    logic [31:0] sram_in;       // value from SRAM (CURRENT OCCURRENCES)
    logic       eof, complete; // eof = end of file; complete = done with byte (checked if byte was equal to eof and if not added 1 to sram_in)
    logic [31:0] total, sram_out;  //total number of characters within the file,  the updated data going to the sram  (sram_out = sram_in + 1 if spi_in not eof)
    logic [7:0]  hist_addr;     // address to SRAM (FILE CHAR as and index (from SPI))
    logic [1:0] wr_r_en;       // enable going to sram to tell it to read (Low) or write (High)
    
    // FLV
    logic [63:0] compVal; // previous least value to compare with current one
    logic [3:0] en_state; // enable state (from controller)
    logic [63:0] sum; // amount of occurrences of current char (current element)
    logic [7:0] charWipe1, charWipe2; // charWipe1 & charWipe2 for setting least1's and least2's occurrences to 0 after found if they are chars (not sums)
    logic [8:0] least1, least2, histo_index; //output least1 and least2 and the histo index (either from histogram if chars of htree if sums)
    logic [2:0] fin_state; // finish state (sent to controller)

    // H Tree
    

    // Cb Synthesis
    logic [6:0] max_index; // max index (index of the last/top element of the htree)
    logic [70:0] h_element; // htree element (FROM SRAM)
    logic write_finish; // sent from header synthesis to indicate it finished writing the header potion to SPI
    logic [2:0] curr_process; // EN state from controller
    logic char_found; // enable for header synthesis to update it's header potion and start writing to SPI
    logic [127:0] char_path; // updated when a new char was found with that char's tree path (sent to SRAM with char_index)
    logic [7:0] char_index; // updated when a new char was found in the tree (sent to SRAM as an index to store the char path)
    logic [6:0] curr_index; // curr_index, goes to SRAM to get a new htree element (h_element) to traverse to
    logic [8:0] least1; // least2, parse from h_element, goes to header synthesis
    logic [8:0] least2; // least1, parse from h_element, goes to header synthesis
    logic [3:0] finished; // finished, goes to controller op_fin
    logic [6:0] track_length; //path length, goes to header synthesis

    // Header Synthesis

    // Translation
    logic [3:0] en_state,                     //Enable State (From controller)
    logic [31:0] totChar,                     //Total number of characters in file (from )
    logic [7:0] charIn,                       //Character coming in from the SPI
    logic [127:0] path,                       //Path obtained from SRAM
    logic writeBin, nextCharEn, writeEn,     //writeBin == bit being written into file, nextCharEn calls for the next character, writeEn means to write to file 
    logic [2:0] fin_state                    //Finish State


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