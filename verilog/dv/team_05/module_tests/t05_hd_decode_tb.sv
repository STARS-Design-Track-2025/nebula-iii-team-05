`timescale 1ms/10ps

typedef enum logic [3:0] {
    INIT, // initial (set if enable for the hd_decode module isn't high)
    SET_PATH, // set path of the first char found all the way left in the tree (first 128 bits of the header)
    READ_LEADING_BIT, // read leading bit checks if there is a backtrack (0) or if another char was found (1)
    READ_CHAR, // read 8 bits of the char from data_in after reading the leading bit(s)
    CHECK_NEXT_CHAR, // will check how many lefts are needed for current char when previous char was also left
    UPDATE_PATH, // after getting the character, use the # of backtrack and the bit after the char to update the path
    WRITE_PATH, // once a full path is found, (after a char was found and corresponding path was updated with correct digits), send the path to SRAM with the curr char index
    READ_TOT_CHAR, // read the total number chars in the file after the whole binary tree was turned into a codebook  
    FINISH // finished writing all char codes from header
} state_hd;

module t05_hd_decode_tb;
    logic clk, reset;
    logic hd_enable;
    logic [7:0] SPI_data_in; // read byte of header from SPI
    logic read_en_SPI;
    logic [127:0] SRAM_data_out; // write a char path to SRAM
    logic SRAM_write_en;
    logic [3071:0] SPI_data_arr; // enough for 256 characters and an average of 2 zeroes per char
    logic [7:0] tot_chars;
    logic finished;

    always #5 clk = ~clk;
    t05_hd_decode hd1 (.clk(clk), .rst(reset), .finished(finished), .tot_chars(tot_chars), .hd_enable(1'b1), .SPI_data_in(SPI_data_in), .read_en_SPI(SPI_read_en), .data_out_SRAM(SRAM_data_out), .write_en_SRAM(SRAM_write_en));
    task reset_fsm();
      begin
        reset = 1;
        @(posedge clk);
        reset = 0;
        @(posedge clk);
      end
    endtask

    task set_inputs(logic [7:0] SPI_data, logic SPI_enable);
      begin
        //if (SPI_enable) begin
            SPI_data_in = SPI_data;
            @(posedge clk);
        //end
      end
    endtask

    initial begin
      $dumpfile("t05_hd_decode.vcd"); //change the vcd vile name to your source file name
      $dumpvars(0, t05_hd_decode_tb);
      
      clk = 0;
      reset = 0;
      SPI_data_arr[3071:0] = 3072'b0;
      SPI_data_arr[263:0] = {128'b10000, {1'b1, 8'd67}, {1'b1, 8'd66, 1'b0}, + {1'b1, 8'd65, 1'b0}, {1'b1, 8'd70}, {1'b1, 8'd71, 2'b0}, {1'b1, 8'd74}, {1'b1, 8'd68}, {1'b1, 8'd69, 1'b0}, {1'b1, 8'd72}, {1'b1, 8'd73, 4'b0}, {32'd10}, {5'b0}};
      reset_fsm();
       set_inputs(SPI_data_arr[263:256], read_en_SPI);
      while (!read_en_SPI) begin
        set_inputs(SPI_data_arr[263:256], read_en_SPI);
      end
      set_inputs(SPI_data_arr[255:248], read_en_SPI);
      while (!read_en_SPI) begin
        set_inputs(SPI_data_arr[255:248], read_en_SPI);
      end
       set_inputs(SPI_data_arr[247:240], read_en_SPI);
      while (!read_en_SPI) begin
        set_inputs(SPI_data_arr[247:240], read_en_SPI);
      end
      set_inputs(SPI_data_arr[239:232], read_en_SPI);
      while (!read_en_SPI) begin
        set_inputs(SPI_data_arr[239:232], read_en_SPI);
      end
      set_inputs(SPI_data_arr[231:224], read_en_SPI);
      while (!read_en_SPI) begin
        set_inputs(SPI_data_arr[231:224], read_en_SPI);
      end
      set_inputs(SPI_data_arr[223:216], read_en_SPI);
      while (!read_en_SPI) begin
        set_inputs(SPI_data_arr[223:216], read_en_SPI);
      end
      set_inputs(SPI_data_arr[215:208], read_en_SPI);
      while (!read_en_SPI) begin
      set_inputs(SPI_data_arr[215:208], read_en_SPI);
      end

      set_inputs(SPI_data_arr[207:200], read_en_SPI);
    while (!read_en_SPI) begin
      set_inputs(SPI_data_arr[207:200], read_en_SPI);
    end

    
      set_inputs(SPI_data_arr[199:192], read_en_SPI);
    while (!read_en_SPI) begin
      set_inputs(SPI_data_arr[199:192], read_en_SPI);
    end

      set_inputs(SPI_data_arr[191:184], read_en_SPI);
    while (!read_en_SPI) begin
      set_inputs(SPI_data_arr[191:184], read_en_SPI);
    end

      set_inputs(SPI_data_arr[183:176], read_en_SPI);
    while (!read_en_SPI) begin
      set_inputs(SPI_data_arr[183:176], read_en_SPI);
    end

      set_inputs(SPI_data_arr[175:168], read_en_SPI);
    while (!read_en_SPI) begin
      set_inputs(SPI_data_arr[175:168], read_en_SPI);
    end

      set_inputs(SPI_data_arr[167:160], read_en_SPI);
    while (!read_en_SPI) begin
      set_inputs(SPI_data_arr[167:160], read_en_SPI);
    end

      set_inputs(SPI_data_arr[159:152], read_en_SPI);
    while (!read_en_SPI) begin
      set_inputs(SPI_data_arr[159:152], read_en_SPI);
    end

      set_inputs(SPI_data_arr[151:144], read_en_SPI);
    while (!read_en_SPI) begin
      set_inputs(SPI_data_arr[151:144], read_en_SPI);
    end

      set_inputs(SPI_data_arr[143:136], read_en_SPI);
    while (!read_en_SPI) begin
      set_inputs(SPI_data_arr[143:136], read_en_SPI);
    end

      set_inputs(SPI_data_arr[135:128], read_en_SPI);
    while (!read_en_SPI) begin
      set_inputs(SPI_data_arr[135:128], read_en_SPI);
    end

      set_inputs(SPI_data_arr[127:120], read_en_SPI);
    while (!read_en_SPI) begin
      set_inputs(SPI_data_arr[127:120], read_en_SPI);
    end

      set_inputs(SPI_data_arr[119:112], read_en_SPI);
    while (!read_en_SPI) begin
      set_inputs(SPI_data_arr[119:112], read_en_SPI);
    end

      set_inputs(SPI_data_arr[111:104], read_en_SPI);
    while (!read_en_SPI) begin
      set_inputs(SPI_data_arr[111:104], read_en_SPI);
    end
      
      set_inputs(SPI_data_arr[103:96], read_en_SPI);
    while (!read_en_SPI) begin
      set_inputs(SPI_data_arr[103:96], read_en_SPI);
    end

      set_inputs(SPI_data_arr[95:88], read_en_SPI);
    while (!read_en_SPI) begin
      set_inputs(SPI_data_arr[95:88], read_en_SPI);
    end

      set_inputs(SPI_data_arr[87:80], read_en_SPI);
    while (!read_en_SPI) begin
      set_inputs(SPI_data_arr[87:80], read_en_SPI);
    end

      set_inputs(SPI_data_arr[79:72], read_en_SPI);
    while (!read_en_SPI) begin
      set_inputs(SPI_data_arr[79:72], read_en_SPI);
    end

      set_inputs(SPI_data_arr[71:64], read_en_SPI);
    while (!read_en_SPI) begin
      set_inputs(SPI_data_arr[71:64], read_en_SPI);
    end

      set_inputs(SPI_data_arr[63:56], read_en_SPI);
    while (!read_en_SPI) begin
      set_inputs(SPI_data_arr[63:56], read_en_SPI);
    end

      set_inputs(SPI_data_arr[55:48], read_en_SPI);
    while (!read_en_SPI) begin
      set_inputs(SPI_data_arr[55:48], read_en_SPI);
    end

      set_inputs(SPI_data_arr[47:40], read_en_SPI);
    while (!read_en_SPI) begin
      set_inputs(SPI_data_arr[47:40], read_en_SPI);
    end
      
      set_inputs(SPI_data_arr[39:32], read_en_SPI);
     // #500
    while (!read_en_SPI) begin
      set_inputs(SPI_data_arr[39:32], read_en_SPI);
    end

      set_inputs(SPI_data_arr[31:24], read_en_SPI);
    while (!read_en_SPI) begin
      set_inputs(SPI_data_arr[31:24], read_en_SPI);
    end
 
      set_inputs(SPI_data_arr[23:16], read_en_SPI);
    while (!read_en_SPI) begin
      set_inputs(SPI_data_arr[23:16], read_en_SPI);
    end

      set_inputs(SPI_data_arr[15:8], read_en_SPI);
    while (!read_en_SPI) begin
      set_inputs(SPI_data_arr[15:8], read_en_SPI);
    end

      set_inputs(SPI_data_arr[7:0], read_en_SPI);
    // while (!read_en_SPI) begin
    //   set_inputs(SPI_data_arr[7:0], read_en_SPI);
    // end
    
      #100;

      #1 $finish;

    end
  
endmodule