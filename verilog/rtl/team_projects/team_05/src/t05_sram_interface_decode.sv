`timescale 1ms/10ps
module t05_sram_interface_decode (
    input logic clk, rst,

    // CONTROLLER state
    input logic [1:0] controller_state,
    input logic SRAM_controller_en,

    // header decode write to SRAM
    input logic [7:0] char_index_hd, // write path at char index
    input logic SRAM_write_en,
    input logic [127:0] SRAM_data_out,

    // translation read from SRAM
    input logic [7:0] char_index_tr, // read path at char index
    input logic SRAM_read_en,
    output logic [127:0] SRAM_data_in,
    output logic SRAM_finished,

    //output logic SRAM_finished,

    // wishbone connects
    output logic wr_en, // write enable
    output logic r_en, // read enable
    input logic busy_o, // input from wishbone connect (SRAM is bus when high)
    output logic [3:0] select, // select all 4 bytes (32 bytes) of write_data to be written
    output logic [31:0] addr, // address of write location
    output logic [31:0] data_i, // data to write to SRAM
    output logic init,
    input logic [31:0] data_o // data written from SRAM
);
localparam BASE_ADDR = 32'h33000000; // base SRAM address

// for intializing SRAM
logic next_init; 
// count to 2048 and initialize 2048 words (for now, could be 1024)
logic [11:0] init_count, next_init_count;
logic init_finished, next_init_finished;

// count # of words written/ read
logic [2:0] word_count, next_word_count;

// keep track of SRAM busy state
logic prev_busy_o;

// hd_decode
logic [7:0] hd_decode_count, next_hd_decode_count;

// translation
logic [127:0] next_SRAM_data_in;

logic next_SRAM_finished;

logic test;
logic [2:0] next_wait_count, wait_count;

always_ff @(posedge clk, posedge rst) begin
    if (rst) begin
      SRAM_data_in <= 128'b0;
      init <= 1; // initialize SRAM
      init_count <= 0;
      init_finished <= 0;
      prev_busy_o <= 0;
      hd_decode_count <= 0;
      word_count <= 0;
      SRAM_finished <= 0;
      test <= 0;
      wait_count <= 0;
    end
    else if (SRAM_controller_en) begin
      SRAM_data_in <= next_SRAM_data_in;
      hd_decode_count <= next_hd_decode_count;
      init <= next_init;
      init_count <= next_init_count;
      init_finished <= next_init_finished;
      prev_busy_o <= busy_o; // keep track of prev state/edge of busy_o
      word_count <= next_word_count;
      SRAM_finished <= next_SRAM_finished;
      wait_count <= next_wait_count;
    end
end


always @(*) begin
  select = 4'b1111; // select the full word 
  //addr = 32'h33000000; // set rw address to base address
  wr_en = 0; // write enable to 0
  r_en = 0; //read enable to 0
  data_i = 32'b0; // write data (to WB) to 0
  //test = 0;
  
  next_init = init;
  next_init_count = init_count;
  next_hd_decode_count = hd_decode_count;
  next_SRAM_data_in = SRAM_data_in;
  next_word_count = word_count;
  next_SRAM_finished = SRAM_finished;
  next_init_finished = init_finished;
  next_wait_count = wait_count;

  if (SRAM_controller_en) begin
  case (controller_state)
    0: begin // HD_DECODE
      // INITIALIZATION OF MEMORY
      //test = 1;
      //if (wait_count == 0) begin
      if (init) begin 
        if ((prev_busy_o && !busy_o || !prev_busy_o && !busy_o)) begin
          next_wait_count = wait_count + 1;
        end
        else if (init_count < 1024) begin // intialize 2048 words
          addr = BASE_ADDR + (init_count * 4); // intialize word stored at next address to 0
          next_wait_count = 0;
        end
        else begin
          addr = 32'h33001FFC; // set address to 2048th word for counter values >= 2048 (no overflow)
          next_wait_count = 0;
        end
        data_i = 0;
        wr_en = 1; 

        // initialize last word and set init_finished to 1
        // if (wait_count < 3) begin
        //   next_wait_count = wait_count + 1;
        // end
        if (init_count == 1024 && !init_finished && (prev_busy_o && !busy_o)) begin // SRAM just finished being busy (initializing words)
          next_init_finished = 1;
          next_wait_count =  0;
        end
        else if (init_count <= 1023 && !init_finished && (prev_busy_o && !busy_o)) begin // still initializing bits
          next_init_count = init_count + 1;
          next_wait_count = 0;
        end
        else if (init_finished) begin// all words initialized
          next_init = 0;
          next_wait_count = 0;
        end
    end
      // end
      // else begin
      //   next_wait_count = 1;
      // end
  end
      // WRITE PATH
    1: begin // start writing codebook paths to SRAM
        case (word_count) // 4 words (128 bit path)
            0: begin 
              r_en = 0;
              wr_en = 0;
              next_SRAM_finished = 0;
              if (SRAM_write_en && !busy_o && wait_count < 3) begin // write the 128 bit path
                  next_wait_count = wait_count + 1;
              end
              else if (SRAM_write_en && !busy_o) begin // write the 128 bit path
                  next_word_count = 1;
                  next_wait_count = 0;
              end
            end
            1: begin 
              if (!busy_o && !prev_busy_o) begin // previous operation completely finished
                wr_en = 1; 
                addr = BASE_ADDR + (char_index_hd * 16);
                data_i = SRAM_data_out[127:96]; 
              end
              else if (wait_count < 2) begin
                next_wait_count = wait_count+ 1;
              end
              else if (!busy_o && prev_busy_o) begin // write first word is complete
                next_wait_count = 0;
                next_word_count = 2;
              end
            end
            2: begin
              if (!busy_o && !prev_busy_o) begin
                wr_en = 1; 
                addr = BASE_ADDR + (char_index_hd * 16 + 4);
                data_i = SRAM_data_out[95:64];
              end
              else if (wait_count < 2) begin
                next_wait_count = wait_count + 1;
              end
              else if (!busy_o && prev_busy_o) begin
                next_wait_count = 0;
                next_word_count = 3;
              end
            end
            3: begin
              if (!busy_o && !prev_busy_o) begin
                wr_en = 1; 
                addr = BASE_ADDR + (char_index_hd * 16 + 8);
                data_i = SRAM_data_out[63:32];
              end
              else if (wait_count < 2) begin
                next_wait_count = wait_count + 1;
              end
              else if (!busy_o && prev_busy_o) begin
                next_wait_count = 0;
                next_word_count = 4;
              end
            end
            4: begin 
              if (!busy_o && !prev_busy_o) begin
                wr_en = 1; 
                addr = BASE_ADDR + (char_index_hd * 16 + 12);
                data_i = SRAM_data_out[31:0];
              end
              // else if (wait_count < 3) begin
              //   next_wait_count = wait_count + 1;
              // end
              else if (!busy_o && prev_busy_o) begin
                next_word_count = 0;
                next_SRAM_finished = 1;
                next_wait_count = 0;
              end
            end
        endcase
      end

    2: begin
          case (word_count) // 4 words (128 bit path)
            0: begin 
              r_en = 0;
              wr_en = 0;
              next_SRAM_finished = 0;
              if (!busy_o && wait_count < 3) begin // write the 128 bit path
                  next_wait_count = wait_count + 1;
              end
              else if (SRAM_read_en && !busy_o) begin // write the 128 bit path
                  next_wait_count = 0;
                  next_word_count = 1;
              end
            end
            1: begin 
              if (!busy_o && !prev_busy_o) begin // previous operation completely finished
                r_en = 1; 
                addr = BASE_ADDR + (char_index_tr * 16);
              end
              else if (wait_count < 2) begin
                next_wait_count = wait_count + 1;
              end
              else if (!busy_o && prev_busy_o) begin // read first word is complete
                next_wait_count = 0;
                next_word_count = 2;
                next_SRAM_data_in[127:96] = data_o; 
              end
            end
            2: begin
              if (!busy_o && !prev_busy_o) begin
                r_en = 1; 
                addr = BASE_ADDR + (char_index_tr * 16 + 4);
              end
              else if (wait_count < 2) begin
                next_wait_count = wait_count + 1;
              end
              else if (!busy_o && prev_busy_o) begin
                next_wait_count = 0;
                next_word_count = 3;
                next_SRAM_data_in[95:64] = data_o;
              end
            end
            3: begin
              if (!busy_o && !prev_busy_o) begin
                r_en = 1; 
                addr =  BASE_ADDR + (char_index_tr * 16 + 8);
              end
              else if (wait_count < 2) begin
                next_wait_count = wait_count + 1;
              end
              else if (!busy_o && prev_busy_o) begin
                next_wait_count = 0;
                next_word_count = 4;
                next_SRAM_data_in[63:32] = data_o;
              end
            end
            4: begin 
              if (!busy_o && !prev_busy_o) begin
                r_en = 1; 
                addr = BASE_ADDR + (char_index_tr * 16 + 12);
              end
              else if (wait_count < 3) begin
                next_wait_count = wait_count + 1;
              end
              else if (!busy_o && prev_busy_o) begin
                next_wait_count = 0;
                next_word_count = 0;
                next_SRAM_data_in[31:0] = data_o;
                next_SRAM_finished = 1;
              end
            end
        endcase
      end 
      // 3: begin


      // end     
  endcase
  end
end

endmodule


