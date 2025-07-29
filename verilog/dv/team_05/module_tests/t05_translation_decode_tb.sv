typedef enum logic [2:0] {
    INIT, // initial (set if enable for the translation_decode module isn't high)
    READ_SRAM_PATH, // read a codebook path for a char from the SRAM
    READ_SPI_PATH, // read a char path from the compressed file
    COMPARE_PATHS, // compare path read from SPI with path read from SRAM
    WRITE_PATH, // writes the char index of the matching path from SRAM to SPI decompressed file, increment chars found and compare tot chars
    FINISH
} state_tr;
module translation_decode_tb;
    logic clk, reset;
    logic translation_enable;
    logic [31:0] tot_chars; // total characters read in the hd_decode
    logic [7:0] SPI_data_in; // read in char bytes from the SPI
    logic [127:0] SRAM_data_in; // read in path from the SRAM
    logic read_en_SPI;
    logic SRAM_read_en;
    logic [7:0] char_index; // char index for char path to get in SRAM
    logic SPI_data_out; // given an char index from SRAM, write the char (bit by bit) based on the corresponding code
    logic SPI_write_en;
    logic finished;
    logic [255:0] SPI_data_arr; // store 2 char paths (each path has 7 bytes)
    logic [127:0] SRAM_data_arr [255:0]; // store paths of all the ASCII chars
    logic [8:0] SRAM_count;

    always #5 clk = ~clk;
    t05_translation_decode tr1 (.clk(clk), .rst(reset), .SRAM_count(SRAM_count), .finished(finished), .tot_chars(tot_chars), .translation_enable(1'b1), .char_index(char_index), .SPI_data_in(SPI_data_in), .SPI_read_en(read_en_SPI), .SRAM_data_in(SRAM_data_in), .SRAM_read_en(SRAM_read_en), .SPI_data_out(SPI_data_out), .SPI_write_en(SPI_write_en));
    task reset_fsm();
      begin
        reset = 1;
        @(posedge clk);
        reset = 0;
        @(posedge clk);
      end
    endtask

    task set_inputs(logic [7:0] SPI_data, logic SPI_enable, logic [127:0] SRAM_data, logic SRAM_enable, logic [31:0] tot_chars);
      begin
        //if (SPI_enable) begin // set byte of SPI data
          SPI_data_in = SPI_data;
        //end
        //if (SRAM_enable) begin // set 128 bit char path from SRAM
          SRAM_data_in = SRAM_data;
          @(posedge clk);
        //end
      end
    endtask

    initial begin
      $dumpfile("t05_translation_decode.vcd"); //change the vcd vile name to your source file name
      $dumpvars(0, t05_translation_decode_tb);
      
      clk = 0;
      reset = 0;

      SPI_data_arr = {128'b10101, {123'b0, 5'b11111}};
      SRAM_data_arr[0] = 128'b10101;
      SRAM_data_arr[1] = 128'b11111;
      tot_chars = 2;

      reset_fsm();
      set_inputs(SPI_data_arr[255:248], read_en_SPI, SRAM_data_arr[char_index], SRAM_read_en, tot_chars);
      while (!read_en_SPI) begin
        set_inputs(SPI_data_arr[255:248], read_en_SPI, SRAM_data_arr[char_index], SRAM_read_en, tot_chars);
      end
       set_inputs(SPI_data_arr[247:240], read_en_SPI, SRAM_data_arr[char_index], SRAM_read_en, tot_chars);
      while (!read_en_SPI) begin
        set_inputs(SPI_data_arr[247:240], read_en_SPI, SRAM_data_arr[char_index], SRAM_read_en, tot_chars);
      end
      set_inputs(SPI_data_arr[239:232], read_en_SPI, SRAM_data_arr[char_index], SRAM_read_en, tot_chars);
      while (!read_en_SPI) begin
        set_inputs(SPI_data_arr[239:232], read_en_SPI, SRAM_data_arr[char_index], SRAM_read_en, tot_chars);
      end
      set_inputs(SPI_data_arr[231:224], read_en_SPI, SRAM_data_arr[char_index], SRAM_read_en, tot_chars);
      while (!read_en_SPI) begin
        set_inputs(SPI_data_arr[231:224], read_en_SPI, SRAM_data_arr[char_index], SRAM_read_en, tot_chars);
      end
      set_inputs(SPI_data_arr[223:216], read_en_SPI, SRAM_data_arr[char_index], SRAM_read_en, tot_chars);
      while (!read_en_SPI) begin
        set_inputs(SPI_data_arr[223:216], read_en_SPI, SRAM_data_arr[char_index], SRAM_read_en, tot_chars);
      end
      set_inputs(SPI_data_arr[215:208], read_en_SPI, SRAM_data_arr[char_index], SRAM_read_en, tot_chars);
      while (!read_en_SPI) begin
      set_inputs(SPI_data_arr[215:208], read_en_SPI, SRAM_data_arr[char_index], SRAM_read_en, tot_chars);
      end

      set_inputs(SPI_data_arr[207:200], read_en_SPI, SRAM_data_arr[char_index], SRAM_read_en, tot_chars);
    while (!read_en_SPI) begin
      set_inputs(SPI_data_arr[207:200], read_en_SPI, SRAM_data_arr[char_index], SRAM_read_en, tot_chars);
    end

    
      set_inputs(SPI_data_arr[199:192], read_en_SPI, SRAM_data_arr[char_index], SRAM_read_en, tot_chars);
    while (!read_en_SPI) begin
      set_inputs(SPI_data_arr[199:192], read_en_SPI, SRAM_data_arr[char_index], SRAM_read_en, tot_chars);
    end

      set_inputs(SPI_data_arr[191:184], read_en_SPI, SRAM_data_arr[char_index], SRAM_read_en, tot_chars);
    while (!read_en_SPI) begin
      set_inputs(SPI_data_arr[191:184], read_en_SPI, SRAM_data_arr[char_index], SRAM_read_en, tot_chars);
    end

      set_inputs(SPI_data_arr[183:176], read_en_SPI, SRAM_data_arr[char_index], SRAM_read_en, tot_chars);
    while (!read_en_SPI) begin
      set_inputs(SPI_data_arr[183:176], read_en_SPI, SRAM_data_arr[char_index], SRAM_read_en, tot_chars);
    end

      set_inputs(SPI_data_arr[175:168], read_en_SPI, SRAM_data_arr[char_index], SRAM_read_en, tot_chars);
    while (!read_en_SPI) begin
      set_inputs(SPI_data_arr[175:168], read_en_SPI, SRAM_data_arr[char_index], SRAM_read_en, tot_chars);
    end

      set_inputs(SPI_data_arr[167:160], read_en_SPI, SRAM_data_arr[char_index], SRAM_read_en, tot_chars);
    while (!read_en_SPI) begin
      set_inputs(SPI_data_arr[167:160], read_en_SPI, SRAM_data_arr[char_index], SRAM_read_en, tot_chars);
    end

      set_inputs(SPI_data_arr[159:152], read_en_SPI, SRAM_data_arr[char_index], SRAM_read_en, tot_chars);
    while (!read_en_SPI) begin
      set_inputs(SPI_data_arr[159:152], read_en_SPI, SRAM_data_arr[char_index], SRAM_read_en, tot_chars);
    end

      set_inputs(SPI_data_arr[151:144], read_en_SPI, SRAM_data_arr[char_index], SRAM_read_en, tot_chars);
    while (!read_en_SPI) begin
      set_inputs(SPI_data_arr[151:144], read_en_SPI, SRAM_data_arr[char_index], SRAM_read_en, tot_chars);
    end

      set_inputs(SPI_data_arr[143:136], read_en_SPI, SRAM_data_arr[char_index], SRAM_read_en, tot_chars);
    while (!read_en_SPI) begin
      set_inputs(SPI_data_arr[143:136], read_en_SPI, SRAM_data_arr[char_index], SRAM_read_en, tot_chars);
    end

      set_inputs(SPI_data_arr[135:128], read_en_SPI, SRAM_data_arr[char_index], SRAM_read_en, tot_chars);
    while (!read_en_SPI) begin
      set_inputs(SPI_data_arr[135:128], read_en_SPI, SRAM_data_arr[char_index], SRAM_read_en, tot_chars);
    end

      set_inputs(SPI_data_arr[127:120], read_en_SPI, SRAM_data_arr[char_index], SRAM_read_en, tot_chars);
    while (!read_en_SPI) begin
      set_inputs(SPI_data_arr[127:120], read_en_SPI, SRAM_data_arr[char_index], SRAM_read_en, tot_chars);
    end

      set_inputs(SPI_data_arr[119:112], read_en_SPI, SRAM_data_arr[char_index], SRAM_read_en, tot_chars);
    while (!read_en_SPI) begin
      set_inputs(SPI_data_arr[119:112], read_en_SPI, SRAM_data_arr[char_index], SRAM_read_en, tot_chars);
    end

      set_inputs(SPI_data_arr[111:104], read_en_SPI, SRAM_data_arr[char_index], SRAM_read_en, tot_chars);
    while (!read_en_SPI) begin
      set_inputs(SPI_data_arr[111:104], read_en_SPI, SRAM_data_arr[char_index], SRAM_read_en, tot_chars);
    end
      
      set_inputs(SPI_data_arr[103:96], read_en_SPI, SRAM_data_arr[char_index], SRAM_read_en, tot_chars);
    while (!read_en_SPI) begin
      set_inputs(SPI_data_arr[103:96], read_en_SPI, SRAM_data_arr[char_index], SRAM_read_en, tot_chars);
    end

      set_inputs(SPI_data_arr[95:88], read_en_SPI, SRAM_data_arr[char_index], SRAM_read_en, tot_chars);
    while (!read_en_SPI) begin
      set_inputs(SPI_data_arr[95:88], read_en_SPI, SRAM_data_arr[char_index], SRAM_read_en, tot_chars);
    end

      set_inputs(SPI_data_arr[87:80], read_en_SPI, SRAM_data_arr[char_index], SRAM_read_en, tot_chars);
    while (!read_en_SPI) begin
      set_inputs(SPI_data_arr[87:80], read_en_SPI, SRAM_data_arr[char_index], SRAM_read_en, tot_chars);
    end

      set_inputs(SPI_data_arr[79:72], read_en_SPI, SRAM_data_arr[char_index], SRAM_read_en, tot_chars);
    while (!read_en_SPI) begin
      set_inputs(SPI_data_arr[79:72], read_en_SPI, SRAM_data_arr[char_index], SRAM_read_en, tot_chars);
    end

      set_inputs(SPI_data_arr[71:64], read_en_SPI, SRAM_data_arr[char_index], SRAM_read_en, tot_chars);
    while (!read_en_SPI) begin
      set_inputs(SPI_data_arr[71:64], read_en_SPI, SRAM_data_arr[char_index], SRAM_read_en, tot_chars);
    end

      set_inputs(SPI_data_arr[63:56], read_en_SPI, SRAM_data_arr[char_index], SRAM_read_en, tot_chars);
    while (!read_en_SPI) begin
      set_inputs(SPI_data_arr[63:56], read_en_SPI, SRAM_data_arr[char_index], SRAM_read_en, tot_chars);
    end

      set_inputs(SPI_data_arr[55:48], read_en_SPI, SRAM_data_arr[char_index], SRAM_read_en, tot_chars);
    while (!read_en_SPI) begin
      set_inputs(SPI_data_arr[55:48], read_en_SPI, SRAM_data_arr[char_index], SRAM_read_en, tot_chars);
    end

      set_inputs(SPI_data_arr[47:40], read_en_SPI, SRAM_data_arr[char_index], SRAM_read_en, tot_chars);
    while (!read_en_SPI) begin
      set_inputs(SPI_data_arr[47:40], read_en_SPI, SRAM_data_arr[char_index], SRAM_read_en, tot_chars);
    end
      
      set_inputs(SPI_data_arr[39:32], read_en_SPI, SRAM_data_arr[char_index], SRAM_read_en, tot_chars);
    while (!read_en_SPI) begin
      set_inputs(SPI_data_arr[39:32], read_en_SPI, SRAM_data_arr[char_index], SRAM_read_en, tot_chars);
    end

      set_inputs(SPI_data_arr[31:24], read_en_SPI, SRAM_data_arr[char_index], SRAM_read_en, tot_chars);
    while (!read_en_SPI) begin
      set_inputs(SPI_data_arr[31:24], read_en_SPI, SRAM_data_arr[char_index], SRAM_read_en, tot_chars);
    end
 
      set_inputs(SPI_data_arr[23:16], read_en_SPI, SRAM_data_arr[char_index], SRAM_read_en, tot_chars);
    while (!read_en_SPI) begin
      set_inputs(SPI_data_arr[23:16], read_en_SPI, SRAM_data_arr[char_index], SRAM_read_en, tot_chars);
    end

      set_inputs(SPI_data_arr[15:8], read_en_SPI, SRAM_data_arr[char_index], SRAM_read_en, tot_chars);
    while (!read_en_SPI) begin
      set_inputs(SPI_data_arr[15:8], read_en_SPI, SRAM_data_arr[char_index], SRAM_read_en, tot_chars);
    end

      set_inputs(SPI_data_arr[7:0], read_en_SPI, SRAM_data_arr[char_index], SRAM_read_en, tot_chars);
    
      #1000;

      #1 $finish;

    end
  
endmodule