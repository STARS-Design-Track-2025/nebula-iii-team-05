`timescale 1ms/10ps

module t05_top_decompression_tb;
    logic clk, reset;
    // SPI
    logic [7:0] SPI_data_in; // byte sent by SPI
    logic SPI_data_out; // bit sent to SPI
  logic [1079:0] SPI_data_arr;
  	logic read_en_SPI;
  logic [1:0] controller_state;
  logic SRAM_read_en;
  logic [127:0] SRAM_data_in;
  logic SRAM_wr_en;
  logic [7:0] char_index_tr;

    // CONTROLLER SIGNALS
    // input logic hd_finished,
    // input logic tr_finished,
    // output logic hd_enable,
    // output logic tr_enable,
    // output logic [1:0] controller_state


    // SPI
    // logic mosi;
    // logic miso;
    // logic [7:0] read_out;


    // //WRAPPER
//     logic wbs_stb_o;
//     logic wbs_cyc_o;
//     logic wbs_we_o;
//     logic [3:0] wbs_sel_o;
//     logic [31:0] wbs_dat_o;
//     logic [31:0] wbs_adr_o;
//     logic spi_confirm_out;
//     logic nextChar;
//     logic init;
//     logic wbs_ack_i;
//     logic [31:0] wbs_dat_i;
//     logic pulse_in;

//   sram_WB_Wrapper sramwb1 (
//     .wb_clk_i(clk),
//     .wb_rst_i(reset),
//     .wbs_stb_i(wbs_stb_i),
//     .wbs_cyc_i(wbs_cyc_i),
//     .wbs_we_i(wbs_we_i),
//     .wbs_sel_i(wbs_sel_i),
//     .wbs_dat_i(wbs_dat_i),
//     .wbs_adr_i(wbs_adr_i),
//     .wbs_ack_o(wbs_ack_o),
//     .wbs_dat_o(wbs_dat_o)
//   );

    t05_top_decompression topd1 (
      .SRAM_r_en(SRAM_read_en), .tr_SRAM_data_in(SRAM_data_in), .SRAM_wr_en(SRAM_wr_en), .char_index_tr(char_index_tr), .curr_state(controller_state),
      .clk(clk), .reset(reset), .SPI_data_in(SPI_data_in), .SPI_data_out(SPI_data_out), .SPI_read_en(read_en_SPI)
//       .wbs_stb_i(wbs_stb_i),
//       .wbs_cyc_i(wbs_cyc_i),
//       .wbs_we_i(wbs_we_i),
//       .wbs_sel_i(wbs_sel_i),
//       .wbs_dat_i(wbs_dat_i),
//       .wbs_adr_i(wbs_adr_i),
//       .wbs_ack_o(wbs_ack_o),
//       .wbs_dat_o(wbs_dat_o)
      );

    always #5 clk = ~clk;
    
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
        if (SPI_enable) begin
            SPI_data_in = SPI_data;
            @(posedge clk);
        end
      end
    endtask

  task feed_spi_stream(input logic [1079:0] spi_data, input int num_bytes);
    //SPI_data_in = spi_data[263-: 8];
    //int i = 0;
      //while (!finished) begin
    for (int i = 0; i < 117; i++) begin
        @(posedge clk);
        while (!read_en_SPI) @(posedge clk);
      if (SRAM_wr_en) begin
        $display("%d", char_index_tr);
      end

      SPI_data_in = spi_data[1079 - 8*i -: 8];
        //i++;
        //@(posedge clk);
    end
    #1000;
endtask

    initial begin
      $dumpfile("t05_top_decompression.vcd"); //change the vcd vile name to your source file name
      $dumpvars(0, t05_top_decompression_tb);
      
      clk = 0;
      reset = 0;
//       wbs_stb_o = 0;
//       wbs_cyc_o = 0;
//       wbs_we_o = 0;
//       wbs_sel_o = 0;
//       wbs_dat_o = 0;
//       wbs_adr_o = 0;
//       spi_confirm_out = 0;
//       nextChar = 0;
//       init = 0;
//       wbs_ack_i = 0;
//       wbs_dat_i = 0;
//       pulse_in = 0;
      

      //SPI_data_arr[263:0] = 264'b0;
      //SPI_data_arr[263:0] = {{1'b1, 8'd67, 9'b100000100}, {1'b1, 8'd66, 1'b0}, + {1'b1, 8'd65, 1'b0}, {1'b1, 8'd70, 9'b100000001}, {1'b1, 8'd71, 2'b0}, {1'b1, 8'd74, 9'b100000001}, {1'b1, 8'd68, 9'b100000011},{1'b1, 8'd69, 1'b0}, {1'b1, 8'd75, 1'b0}, {1'b1, 8'd72, 9'b100000001}, {1'b1, 8'd73, 4'b0}, {1'b1, 8'b00001010}, {32'd11}, {69'b0}};
      
      //LONG HTREE
      // SPI_data_arr[911:0] = {880'b101011110100000001101011101100000001101011100100000001101011011100000001101011010100000001101011001100000001101011000100000001101010111100000001101010110100000001101010101100000001101010100100000001101010011100000001101010010100000001101010001100000001101010000100000001101011110100000001101011101100000001101011100100000001101011011100000001101011010100000001101011001100000001101011000100000001101010111100000001101010110100000001101010101100000001101010100100000001101010011100000001101010010100000001101010001100000001101010000100000001101001111100000001101001110100000001101001101100000001101001100100000001101001011100000001101001010100000001101001001100000001101001000100000001101000111100000001101000110100000001101000101100000001101000100100000001101000011100000001101000010100000001101000001100000001100000000100000001100000001000000000000000000000000000100001010, 32'd666};
      // reset_fsm();
      // feed_spi_stream(SPI_data_arr, 114);
      // htree[0] = {{7'd8}, {1'b0, 8'd95}, {1'b0, 8'd30}, {46'b0}};
      // htree[1] = {{7'd8}, {1'b0, 8'd96}, {1'b0, 8'd31}, {46'b0}};
      // htree[2] = {{7'd8}, {1'b0, 8'd97}, {1'b0, 8'd32}, {46'b0}};
      // htree[3] = {{7'd8}, {1'b0, 8'd98}, {1'b0, 8'd33}, {46'b0}};
      // htree[4] = {{7'd8}, {1'b0, 8'd99}, {1'b0, 8'd34}, {46'b0}};
      // htree[5] = {{7'd8}, {1'b0, 8'd100}, {1'b0, 8'd35}, {46'b0}};
      // htree[6] = {{7'd8}, {1'b0, 8'd101}, {1'b0, 8'd36}, {46'b0}};
      // htree[7] = {{7'd8}, {1'b0, 8'd102}, {1'b0, 8'd37}, {46'b0}};
      // htree[8] = {{7'd8}, {1'b0, 8'd103}, {1'b0, 8'd38}, {46'b0}};
      // htree[9] = {{7'd8}, {1'b0, 8'd104}, {1'b0, 8'd39}, {46'b0}};
      // htree[10] = {{7'd8}, {1'b0, 8'd105}, {1'b0, 8'd40}, {46'b0}};
      // htree[11] = {{7'd8}, {1'b0, 8'd106}, {1'b0, 8'd41}, {46'b0}};
      // htree[12] = {{7'd8}, {1'b0, 8'd107}, {1'b0, 8'd42}, {46'b0}};
      // htree[13] = {{7'd8}, {1'b0, 8'd108}, {1'b0, 8'd43}, {46'b0}};
      // htree[14] = {{7'd8}, {1'b0, 8'd109}, {1'b0, 8'd44}, {46'b0}};
      // htree[15] = {{7'd8}, {1'b0, 8'd110}, {1'b0, 8'd45}, {46'b0}};
      // htree[16] = {{7'd8}, {1'b0, 8'd111}, {1'b0, 8'd46}, {46'b0}};
      // htree[17] = {{7'd8}, {1'b0, 8'd112}, {1'b0, 8'd47}, {46'b0}};
      // htree[18] = {{7'd8}, {1'b0, 8'd113}, {1'b0, 8'd48}, {46'b0}};
      // htree[19] = {{7'd8}, {1'b0, 8'd114}, {1'b0, 8'd49}, {46'b0}};
      // htree[20] = {{7'd8}, {1'b0, 8'd115}, {1'b0, 8'd50}, {46'b0}};
      // htree[21] = {{7'd8}, {1'b0, 8'd116}, {1'b0, 8'd51}, {46'b0}};
      // htree[22] = {{7'd8}, {1'b0, 8'd117}, {1'b0, 8'd52}, {46'b0}};
      // htree[23] = {{7'd8}, {1'b0, 8'd118}, {1'b0, 8'd53}, {46'b0}};
      
      // FILE TEST
      SPI_data_arr[1079:0] = {895'b1011011111000001011001011100101110000100000001100101111001011100011000000101001100000101110010100000001100110001000101110011100000011100110010010111010010000000110011001100101110101100000010100110100010110111110000010110010111001011100001000000011001011110010111000110000001010011000001011100101000000011001100010001011100111000000111001100100101110100100000001100110011001011101011000000101001101000101110110100000001100110101000010101111110000010110001111001011000001000000011000111110010110000110000001010010000001011000101000000011001000010001011000111000000111001000100101100100100000001100100011001011001011000000101001001000101100110100000001100100101000010110011110000010010010011001011010001000000011001001110010110100110000001010010100001011010101000000011001010010001011010111000000111001010100101101100100000001100101011001011011011000000101001011000101101110100000001100101101000000
        ,9'b100001010
        ,32'd50
        //,9'b100001010
        ,6'b100000
        ,6'b100010
        ,6'b100001
        ,6'b100011
        ,6'b100010
        ,6'b100010
        ,6'b100101
        ,6'b100100
        ,6'b100110
        ,6'b100111
        ,6'b101001
        ,6'b101000
        ,6'b100100
        ,6'b100110
        ,6'b101010
        ,6'b101011
        ,6'b101101
        ,6'b101100
        ,6'b101110
        ,6'b101111
        ,7'b1100000
        ,9'b100000000
        ,8'b1000000                      };

    
       reset_fsm();
      feed_spi_stream(SPI_data_arr, 36);
      // SPI_data_arr[263:0] = {128'b10000, {1'b1, 8'd67}, {1'b1, 8'd66, 1'b0}, + {1'b1, 8'd65, 1'b0}, {1'b1, 8'd70}, {1'b1, 8'd71, 2'b0}, {1'b1, 8'd74}, {1'b1, 8'd68}, {1'b1, 8'd75}, {1'b1, 8'd69, 1'b0}, {1'b1, 8'd72}, {1'b1, 8'd73, 4'b0}, {32'd10}, {12'b0}};
//       set_inputs(SPI_data_arr[263:256], read_en_SPI);
//       while (!read_en_SPI) begin
//         set_inputs(SPI_data_arr[263:256], read_en_SPI);
//       end
//       set_inputs(SPI_data_arr[255:248], read_en_SPI);
//       while (!read_en_SPI) begin
//         set_inputs(SPI_data_arr[255:248], read_en_SPI);
//       end
//        set_inputs(SPI_data_arr[247:240], read_en_SPI);
//       while (!read_en_SPI) begin
//         set_inputs(SPI_data_arr[247:240], read_en_SPI);
//       end
//       set_inputs(SPI_data_arr[239:232], read_en_SPI);
//       while (!read_en_SPI) begin
//         set_inputs(SPI_data_arr[239:232], read_en_SPI);
//       end
//       set_inputs(SPI_data_arr[231:224], read_en_SPI);
//       while (!read_en_SPI) begin
//         set_inputs(SPI_data_arr[231:224], read_en_SPI);
//       end
//       set_inputs(SPI_data_arr[223:216], read_en_SPI);
//       while (!read_en_SPI) begin
//         set_inputs(SPI_data_arr[223:216], read_en_SPI);
//       end
//       set_inputs(SPI_data_arr[215:208], read_en_SPI);
//       while (!read_en_SPI) begin
//       set_inputs(SPI_data_arr[215:208], read_en_SPI);
//       end

//       set_inputs(SPI_data_arr[207:200], read_en_SPI);
//     while (!read_en_SPI) begin
//       set_inputs(SPI_data_arr[207:200], read_en_SPI);
//     end

    
//       set_inputs(SPI_data_arr[199:192], read_en_SPI);
//     while (!read_en_SPI) begin
//       set_inputs(SPI_data_arr[199:192], read_en_SPI);
//     end

//       set_inputs(SPI_data_arr[191:184], read_en_SPI);
//     while (!read_en_SPI) begin
//       set_inputs(SPI_data_arr[191:184], read_en_SPI);
//     end

//       set_inputs(SPI_data_arr[183:176], read_en_SPI);
//     while (!read_en_SPI) begin
//       set_inputs(SPI_data_arr[183:176], read_en_SPI);
//     end

//       set_inputs(SPI_data_arr[175:168], read_en_SPI);
//     while (!read_en_SPI) begin
//       set_inputs(SPI_data_arr[175:168], read_en_SPI);
//     end

//       set_inputs(SPI_data_arr[167:160], read_en_SPI);
//     while (!read_en_SPI) begin
//       set_inputs(SPI_data_arr[167:160], read_en_SPI);
//     end

//       set_inputs(SPI_data_arr[159:152], read_en_SPI);
//     while (!read_en_SPI) begin
//       set_inputs(SPI_data_arr[159:152], read_en_SPI);
//     end

//       set_inputs(SPI_data_arr[151:144], read_en_SPI);
//     while (!read_en_SPI) begin
//       set_inputs(SPI_data_arr[151:144], read_en_SPI);
//     end

//       set_inputs(SPI_data_arr[143:136], read_en_SPI);
//     while (!read_en_SPI) begin
//       set_inputs(SPI_data_arr[143:136], read_en_SPI);
//     end

//       set_inputs(SPI_data_arr[135:128], read_en_SPI);
//     while (!read_en_SPI) begin
//       set_inputs(SPI_data_arr[135:128], read_en_SPI);
//     end

//       set_inputs(SPI_data_arr[127:120], read_en_SPI);
//     while (!read_en_SPI) begin
//       set_inputs(SPI_data_arr[127:120], read_en_SPI);
//     end

//       set_inputs(SPI_data_arr[119:112], read_en_SPI);
//     while (!read_en_SPI) begin
//       set_inputs(SPI_data_arr[119:112], read_en_SPI);
//     end

//       set_inputs(SPI_data_arr[111:104], read_en_SPI);
//     while (!read_en_SPI) begin
//       set_inputs(SPI_data_arr[111:104], read_en_SPI);
//     end
      
//       set_inputs(SPI_data_arr[103:96], read_en_SPI);
//     while (!read_en_SPI) begin
//       set_inputs(SPI_data_arr[103:96], read_en_SPI);
//     end

//       set_inputs(SPI_data_arr[95:88], read_en_SPI);
//     while (!read_en_SPI) begin
//       set_inputs(SPI_data_arr[95:88], read_en_SPI);
//     end

//       set_inputs(SPI_data_arr[87:80], read_en_SPI);
//     while (!read_en_SPI) begin
//       set_inputs(SPI_data_arr[87:80], read_en_SPI);
//     end

//       set_inputs(SPI_data_arr[79:72], read_en_SPI);
//     while (!read_en_SPI) begin
//       set_inputs(SPI_data_arr[79:72], read_en_SPI);
//     end

//       set_inputs(SPI_data_arr[71:64], read_en_SPI);
//     while (!read_en_SPI) begin
//       set_inputs(SPI_data_arr[71:64], read_en_SPI);
//     end

//       set_inputs(SPI_data_arr[63:56], read_en_SPI);
//     while (!read_en_SPI) begin
//       set_inputs(SPI_data_arr[63:56], read_en_SPI);
//     end

//       set_inputs(SPI_data_arr[55:48], read_en_SPI);
//     while (!read_en_SPI) begin
//       set_inputs(SPI_data_arr[55:48], read_en_SPI);
//     end

//       set_inputs(SPI_data_arr[47:40], read_en_SPI);
//     while (!read_en_SPI) begin
//       set_inputs(SPI_data_arr[47:40], read_en_SPI);
//     end
      
//       set_inputs(SPI_data_arr[39:32], read_en_SPI);
//      // #500
//     while (!read_en_SPI) begin
//       set_inputs(SPI_data_arr[39:32], read_en_SPI);
//     end

//       set_inputs(SPI_data_arr[31:24], read_en_SPI);
//     while (!read_en_SPI) begin
//       set_inputs(SPI_data_arr[31:24], read_en_SPI);
//     end
 
//       set_inputs(SPI_data_arr[23:16], read_en_SPI);
//     while (!read_en_SPI) begin
//       set_inputs(SPI_data_arr[23:16], read_en_SPI);
//     end

//       set_inputs(SPI_data_arr[15:8], read_en_SPI);
//     while (!read_en_SPI) begin
//       set_inputs(SPI_data_arr[15:8], read_en_SPI);
//     end

//       set_inputs(SPI_data_arr[7:0], read_en_SPI);
    // while (!read_en_SPI) begin
    //   set_inputs(SPI_data_arr[7:0], read_en_SPI);
    // end
    
      #100;

      #1 $finish;

    end
//    always @(posedge clk) begin
//      if ((SRAM_read_en) && (controller_state == 2)) begin
//         SRAM_data_in <= SRAM_data_arr[char_index];
//     end
// end
  
endmodule