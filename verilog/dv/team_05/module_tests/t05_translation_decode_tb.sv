`timescale 1ms/10ps
//`include "typedefs.sv"
typedef enum logic [2:0] {
    INIT, // initial (set if enable for the translation_decode module isn't high)
    READ_SRAM_PATH, // read a codebook path for a char from the SRAM
    READ_SPI_PATH, // read a char path from the compressed file
    COMPARE_PATHS, // compare path read from SPI with path read from SRAM
    WRITE_PATH, // writes the char index of the matching path from SRAM to SPI decompressed file, increment chars found and compare tot chars
    FINISH
} state_tr;

module t05_translation_decode_tb;
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
  logic [1023:0] SPI_data_arr; // store 2 char paths (each path has 7 bytes)
    logic [127:0] SRAM_data_arr [255:0]; // store paths of all the ASCII chars
    logic [8:0] SRAM_count;

    always #5 clk = ~clk;
    t05_translation_decode tr1 (.clk(clk), .rst(reset), .finished(finished), .tot_chars(tot_chars), .translation_enable(1'b1), .char_index(char_index), .SPI_data_in(SPI_data_in), .SPI_read_en(read_en_SPI), .SRAM_data_in(SRAM_data_in), .SRAM_read_en(SRAM_read_en), .SPI_data_out(SPI_data_out), .SPI_write_en(SPI_write_en));
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
          SPI_data_in = SPI_data;
          SRAM_data_in = SRAM_data;
          @(posedge clk);
      end
    endtask

  task automatic feed_spi_stream(input logic [1023:0] spi_data, input int num_bytes);
    //SPI_data_in = spi_data[255 -: 8];
    for (int i = 0; i < num_bytes; i++) begin
        @(posedge clk);
        while (!read_en_SPI) @(posedge clk);

        SPI_data_in = spi_data[1023 - 8*i -: 8];
    end
endtask

    initial begin
      $dumpfile("t05_translation_decode.vcd"); //change the vcd vile name to your source file name
      $dumpvars(0, t05_translation_decode_tb);
      
      clk = 0;
      reset = 0;

      SPI_data_arr = {128'b10101, 128'b11111, 128'b10101, 128'b101011111111, 128'b00000001111111, 128'b10000000000000000001, 128'b011111111111110, 128'b101011111111};//, 128'b011111111111110, 128'b10000000000000000001};
      SRAM_data_arr[0] = 128'b10101;
      SRAM_data_arr[1] = 128'b11111;
      SRAM_data_arr[2] = 128'b101011111111;
      SRAM_data_arr[3] = 128'b00000001111111;
      SRAM_data_arr[4] = 128'b011111111111110;
      SRAM_data_arr[5] = 128'b10000000000000000001;
      for (integer i = 6; i < 255; i++) begin
        SRAM_data_arr[i] = 0;
      end
      tot_chars = 8;

      reset_fsm();
      feed_spi_stream(SPI_data_arr, 128);
    
        #500;

      #1 $finish;

    end
   always @(posedge clk) begin
    if (SRAM_read_en) begin
        SRAM_data_in <= SRAM_data_arr[char_index];
    end
end
endmodule