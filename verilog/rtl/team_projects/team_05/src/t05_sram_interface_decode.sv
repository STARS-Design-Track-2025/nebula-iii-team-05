module sram_interface_decode (
    input logic clk, rst,

    // CONTROLLER state
    input logic [2:0] controller_state,

    // header decode write to SRAM
    input logic [7:0] char_index, // write path at char index
    input logic SRAM_write_en,
    input logic [127:0] SRAM_data_out,

    // translation read from SRAM
    input logic SRAM_read_en,
    output logic [127:0] SRAM_data_in,

    // wishbone connects
    output logic wr_en, // write enable
    output logic r_en, // read enable
    input logic busy_o, // input from wishbone connect (SRAM is bus when high)
    output logic [3:0] select, // select all 4 bytes (32 bytes) of write_data to be written
    output logic [31:0] addr, // address of write location
    output logic [31:0] data_i, // data to write to SRAM
    input logic [31:0] data_o // data written from SRAM
);
localparam BASE_ADDR = 32'h33000000; // base SRAM address

// for intializing SRAM
logic init, next_init; 
// count to 2048 and initialize 2048 words (for now, could be 1024)
logic [11:0] init_count, next_init_count;
logic init_finished, next_init_finished;

// count # of words written/ read
logic [2:0] word_count, next_word_count;

// keep track of SRAM busy state
logic prev_busy_o;

// hd_decode
logic hd_decode_count, next_hd_decode_count;

// translation
logic [127:0] next_SRAM_data_in;

always_ff @(posedge clk, posedge rst) begin
    if (rst) begin
      SRAM_data_in <= 128'b0;
      init <= 1; // initialize SRAM
      init_count <= 0;
      init_finished <= 0;
      prev_busy_o <= 0;
      hd_decode_count <= 0;
      word_count <= 0;
    end
    else begin
      SRAM_data_in <= next_SRAM_data_in;
      hd_decode_count <= next_hd_decode_count;
      init <= next_init;
      init_count <= next_init_count;
      init_finished <= next_init_finished;
      prev_busy_o <= busy_o; // keep track of prev state/edge of busy_o
      word_count <= next_word_count;
    end
end


always_comb begin
  select = 4'b1111; // select the full word 
  addr = BASE_ADDR; // set rw address to base address
  wr_en = 0; // write enable to 0
  r_en = 0; //read enable to 0
  data_i = 32'b0; // write data (to WB) to 0
  
  next_init = init;
  next_init_count = init_count;
  next_hd_decode_count = hd_decode_count;
  next_SRAM_data_in = SRAM_data_in;
  next_word_count = word_count;

  case (controller_state)
    1: begin // HD_DECODE
      // INITIALIZATION OF MEMORY
      if (init) begin 
        if (init_count < 2048) begin // intialize 2048 words
          addr = BASE_ADDR + (init_count * 4); // intialize word stored at next address to 0
        end
        else begin
          addr = 32'h33001FFC; // set address to 2048th word for counter values >= 2048 (no overflow)
        end
        data_i = 0;
        wr_en = 1; 

        // initialize last word and set init_finished to 1
        if (init_count == 2048 && !init_finished && prev_busy_o && !busy_o) begin // SRAM just finished being busy (initializing words)
          next_init_finished = 1;
        end
        else if (init_count <= 2047) begin // still initializing bits
          next_init_count = init_count + 1;
        end
        else if (init_finished) begin// all words initialized
          next_init = 0;
        end
    end

      // WRITE PATH
      else begin // start writing codebook paths to SRAM
        case (word_count) // 4 words (128 bit path)
            0: begin 
              r_en = 0;
              wr_en = 0;
              if (SRAM_read_en && !busy_o) begin // write the 128 bit path
                  next_word_count = 1;
              end
            end
            1: begin 
              if (!busy_o && !prev_busy_o) begin // previous operation completely finished
                wr_en = 1; 
                addr = BASE_ADDR + (hd_decode_count * 16);
                data_i = SRAM_data_in[127:96]; 
              end
              else if (!busy_o && prev_busy_o) begin // write first word is complete
                next_word_count = 2;
              end
            end
            2: begin
              if (!busy_o && !prev_busy_o) begin
                addr = BASE_ADDR + (hd_decode_count * 16 + 4);
                data_i = SRAM_data_in[95:64];
              end
              else if (!busy_o && prev_busy_o) begin
                next_word_count = 3;
              end
            end
            3: begin
              if (!busy_o && !prev_busy_o) begin
                addr = BASE_ADDR + (hd_decode_count * 16 + 8);
                data_i = SRAM_data_in[63:32];
              end
              else if (!busy_o && prev_busy_o) begin
                next_word_count = 4;
              end
            end
            4: begin 
              if (!busy_o && !prev_busy_o) begin
                addr = BASE_ADDR + (hd_decode_count * 16 + 12);
                data_i = SRAM_data_in[31:0];
              end
              else if (!busy_o && prev_busy_o) begin
                next_word_count = 0;
                next_hd_decode_count = hd_decode_count + 1; // add one to write count
              end
            end
        endcase
      end
    end

    2: begin
          case (word_count) // 4 words (128 bit path)
            0: begin 
              r_en = 0;
              wr_en = 0;
              if (SRAM_write_en && !busy_o) begin // write the 128 bit path
                  next_word_count = 1;
              end
            end
            1: begin 
              if (!busy_o && !prev_busy_o) begin // previous operation completely finished
                r_en = 1; 
                addr = BASE_ADDR + (char_index * 16);
                next_SRAM_data_in[127:96] = data_o; 
              end
              else if (!busy_o && prev_busy_o) begin // read first word is complete
                next_word_count = 2;
              end
            end
            2: begin
              if (!busy_o && !prev_busy_o) begin
                addr = BASE_ADDR + (char_index * 16 + 4);
                next_SRAM_data_in[95:64] = data_o;
              end
              else if (!busy_o && prev_busy_o) begin
                next_word_count = 3;
              end
            end
            3: begin
              if (!busy_o && !prev_busy_o) begin
                addr =  BASE_ADDR + (char_index * 16 + 8);
                next_SRAM_data_in[63:32] = data_o;
              end
              else if (!busy_o && prev_busy_o) begin
                next_word_count = 4;
              end
            end
            4: begin 
              if (!busy_o && !prev_busy_o) begin
                addr = BASE_ADDR + (char_index * 16 + 12);
                next_SRAM_data_in[31:0] = data_o;
              end
              else if (!busy_o && prev_busy_o) begin
                next_word_count = 0;
              end
            end
        endcase
      end      
  endcase
end

endmodule
