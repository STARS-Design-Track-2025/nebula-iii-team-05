`timescale 1ms/10ps

typedef enum logic [3:0] {
    INIT, // initial (set if enable for the hd_decode module isn't high)
    READ_NUM_LEFTS, // reads the 9 bit chunk of the number of lefts after moving right for the left char stored in the header
    READ_LEADING_BIT, // read leading bit checks if there is a backtrack (0) or if another char was found (1)
    READ_CHAR, // read 8 bits of the char from data_in after reading the leading bit(s)
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
    logic [1599:0] SPI_data_arr; // enough for 256 characters and an average of 2 zeroes per char
    logic [31:0] tot_chars;
    logic finished;

    always #5 clk = ~clk;
    t05_hd_decode hd1 (.clk(clk), .rst(reset), .finished(finished), .tot_chars(tot_chars), .hd_enable(1'b1), .SPI_data_in(SPI_data_in), .SPI_read_en(read_en_SPI), .SRAM_data_out(SRAM_data_out), .SRAM_write_en(SRAM_write_en));
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

    task automatic feed_spi_stream(input logic [191:0] spi_data, input int num_bytes);
    //SPI_data_in = spi_data[263-: 8];
    //int i = 0;
      //while (!finished) begin
      for (int i = 0; i < 24; i++) begin
        @(posedge clk);
        while (!read_en_SPI) begin
          if (SRAM_write_en) begin 
            $display("%b", SRAM_data_out);
          end
          @(posedge clk);

        end

        SPI_data_in = spi_data[191 - 8*i -: 8];
        //i++;
        @(posedge clk);
    end
endtask

    initial begin
      $dumpfile("t05_hd_decode.vcd"); //change the vcd vile name to your source file name
      $dumpvars(0, t05_hd_decode_tb);
      
      clk = 0;
      reset = 0;
      //SPI_data_arr[263:0] = 264'b0;
      //SPI_data_arr[263:0] = {{1'b1, 8'd67, 9'b100000100}, {1'b1, 8'd66, 1'b0}, + {1'b1, 8'd65, 1'b0}, {1'b1, 8'd70, 9'b100000001}, {1'b1, 8'd71, 2'b0}, {1'b1, 8'd74, 9'b100000001}, {1'b1, 8'd68, 9'b100000011},{1'b1, 8'd69, 1'b0}, {1'b1, 8'd75, 1'b0}, {1'b1, 8'd72, 9'b100000001}, {1'b1, 8'd73, 4'b0}, {1'b1, 8'b00001010}, {32'd11}, {69'b0}};
      
      // TEST 1
      SPI_data_arr[191:0] = {145'b101000011100000100101000010010100000101010001101000000011010001110010100101010000000110100010010000001010100010101010010001000000011010010010000
      ,9'b100001010
      ,32'd50
      ,6'b100000};

      reset_fsm();
      feed_spi_stream(SPI_data_arr, 24);

      //LONG HTREE

      // SPI_data_arr[639:0] = {599'b1010111101000000011010111011000000011010111001000000011010110111000000011010110101000000011010110011000000011010110001000000011010101111000000011010101101000000011010101011000000011010101001000000011010100111000000011010100101000000011010100011000000011010100001000000011010011111000000011010011101000000011010011011000000011010011001000000011010010111000000011010010101000000011010010011000000011010010001000000011010001111000000011010001101000000011010001011000000011010001001000000011010000111000000011010000101000000011010000011000000011000000001000000011000000010000000000000000000000000000000, 9'b100001010, 32'd50};
      // reset_fsm();
      // feed_spi_stream(SPI_data_arr, 114);

      // TEST 4

      // SPI_data_arr[935:0] = {895'b1011011111000001011001011100101110000100000001100101111001011100011000000101001100000101110010100000001100110001000101110011100000011100110010010111010010000000110011001100101110101100000010100110100010110111110000010110010111001011100001000000011001011110010111000110000001010011000001011100101000000011001100010001011100111000000111001100100101110100100000001100110011001011101011000000101001101000101110110100000001100110101000010101111110000010110001111001011000001000000011000111110010110000110000001010010000001011000101000000011001000010001011000111000000111001000100101100100100000001100100011001011001011000000101001001000101100110100000001100100101000010110011110000010010010011001011010001000000011001001110010110100110000001010010100001011010101000000011001010010001011010111000000111001010100101101100100000001100101011001011011011000000101001011000101101110100000001100101101000000
      //   ,9'b100001010
      //   ,32'd50};
      
      // reset_fsm();
      // feed_spi_stream(SPI_data_arr, 117);
    
    
      #100;

      #1 $finish;

    end
  
endmodule
