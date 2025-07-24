module t05_histogram(
<<<<<<< HEAD
    input  logic       clk, rst,
    input  logic [7:0] spi_in,        // input byte from SPI
    input  logic [31:0] sram_in,       // value from SRAM
    output logic       eof, complete, // eof = end of file; complete = done with byte
=======
    input logic clk, rst,
    input logic [3:0] en_state,
    input logic [7:0] spi_in,        // input byte from SPI
    input logic [31:0] sram_in,       // value from SRAM
    output logic eof,
    output logic complete, // eof = end of file; complete = done with byte
>>>>>>> 93c89207a86f7d90771c1bfd8e81072026bccc93
    output logic [31:0] total, sram_out,  //total number of characters within the file,  the updated data going to the sram 
    output logic [7:0]  hist_addr,     // address to SRAM
    output logic [1:0] wr_r_en        // enable going to sram to tell it to read or write
);
//send a controller enable to controller
//accept an enable from sram to know when to procccess new data
logic [31:0] char_total;
logic [3:0] state, next_state;
logic [7:0] new_spi;

typedef enum logic [3:0] {
    IDLE  = 4'd0,
    READ  = 4'd1,
    WAIT  = 4'd2,
    WRITE = 4'd3,
    HALT  = 4'd4,
    DONE = 4'd5,
    READ2 = 4'd6
} state_t;

logic [1:0] wait_cnt;
logic [7:0] end_file = 8'h1A;

always_ff @( posedge clk, posedge rst ) begin
    if (rst) begin
        state <= IDLE;
<<<<<<< HEAD
    end else begin
=======
    end else if (en_state == 1) begin
>>>>>>> 93c89207a86f7d90771c1bfd8e81072026bccc93
        state <= next_state;
    end 
end

always_ff @(posedge clk, posedge rst) begin
    if (rst) begin
        wait_cnt <= 0;
    end else if (state == WAIT) begin
        wait_cnt <= wait_cnt + 1;
    end
end

always_ff @( posedge clk, posedge rst ) begin : blockName
    if (rst) begin
        new_spi <= 0;
<<<<<<< HEAD
    end else begin
=======
    end else if (en_state == 1) begin
>>>>>>> 93c89207a86f7d90771c1bfd8e81072026bccc93
        new_spi <= spi_in;
    end
end

// Next state logic
always_ff @( posedge clk, posedge rst ) begin
    if (rst) begin
        state      <= IDLE;
        wait_cnt   <= 0;
        wr_r_en    <= 0;
        total      <= 0;
        sram_out   <= 0;
        hist_addr  <= 0;
        eof        <= 0;
        complete   <= 0;
        char_total <= 0;
    end else if (en_state == 1) begin
        case (state)
            IDLE:  begin //beginning of the histogram
                next_state <= READ;
                wr_r_en   <= 2'd3;
                complete  <= 0;
                eof       <= 0;
                hist_addr <= 00;
                sram_out <= 0;
            end
            READ:  begin  //giving the sram the character that it wants to pull
                next_state <= READ2;
                wr_r_en   <= 2'd0;
                hist_addr <= new_spi;
                char_total <= char_total + 1;
            end
            READ2: begin  //giving the updated data to the sram for storage
                next_state <= WAIT;
                wr_r_en <= 2'd0;
            end
            WAIT:  begin  //wait cycle between input and output from sram
                wr_r_en <= 2'd3;
                if (wait_cnt == 2) begin
                    wait_cnt <= 0;
                    next_state <= WRITE;
                end else begin
                    next_state <= WAIT;
                end
            end
            WRITE: begin  //pulling the data from the sram and adding 1
                wr_r_en <= 2'd1;
                sram_out <= sram_in + 1;
                if (spi_in == end_file) begin
                    next_state <= HALT;
                    eof <= 1;
                    wr_r_en <= 2'd3;
                end else begin
                    next_state <= READ;
                end
            end
            DONE: begin  //done with that 1 cycle
                next_state <= DONE;
                complete <= 1;
                wr_r_en <= 2'd3;
            end
            HALT:   begin  //the end of file has been enabled and histogram will stop
                next_state <= DONE;
                //eof <= 1;
                total <= char_total + 1;
                wr_r_en <= 2'd3;
            end
            default: next_state <= IDLE;
        endcase
        end
        // else if (en_state != 1) begin
        //     eof <= 0;
        // end
    end
endmodule