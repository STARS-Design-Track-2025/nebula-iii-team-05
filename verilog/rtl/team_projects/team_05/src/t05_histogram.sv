module t05_histogram(
    input  logic       clk, rst,
    input  logic [7:0] spi_in,        // input byte from SPI
    input  logic [31:0] sram_in,       // value from SRAM
    output logic       eof, complete, // eof = end of file; complete = done with byte
    output logic [31:0] total, sram_out,
    output logic [7:0]  hist_addr,     // address to SRAM
    output logic       wr_r_en        // unified enable signal
);
logic [31:0] char_total;
logic [3:0] state, next_state;

typedef enum logic [3:0] {  //states of wither read or write for the histogram to the sram
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
    end else begin
        next_state <= state;
    end 
end

always_ff @(posedge clk, posedge rst) begin
    if (rst) begin
        wait_cnt <= 0;
    end else if (state == WAIT) begin
        wait_cnt <= wait_cnt + 1;
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
    end 
    case (state)
        IDLE:  begin 
            next_state <= READ;
            wr_r_en   <= 0;
            complete  <= 0;
            eof       <= 0;
        end
        READ:  begin
            next_state <= WAIT;
            wr_r_en   <= 0;
            hist_addr <= spi_in;
            char_total <= char_total + 1;
        end
        READ2: begin
            next_state <= WAIT;
            wr_r_en <= 0;
        end
        WAIT:  begin
            if (wait_cnt == 2) begin
                wait_cnt <= 0;
                next_state <= DONE;
            end else begin
                next_state <= WRITE;
            end
        end
        WRITE: begin
            wr_r_en <= 1;
            sram_out <= sram_in + 1;
            if (spi_in == end_file) begin
                next_state <= HALT;
                char_total <= total;
            end else begin
                next_state <= READ2;
            end
        end
        DONE: begin
            next_state <= IDLE;
        end
        HALT:   begin
            next_state <= HALT;
            eof <= 1;
        end
    endcase
    end



// //should be giving an addr to sram then sram will give back the index to that coresponding address then the hist will add 1 to it then give it back to the sram to be stored
// logic clear;
// logic [7:0] shift; //assign end_file to what the end of the file would be
// logic [7:0] end_file = 8'b00011010;



// always_ff @( posedge clk, posedge rst) begin : blockName
//     if (rst || eof) begin
//         sram_out <= 0;
//         hist_addr <= 0;
//         shift <= shift;
//         total <= total;
//         complete <= 0;
//     end else begin
//         sram_out <= sram_in + 1;  //the old index will have 1 added to it and by used as sram_out
//         hist_addr <= addr_i;  // the data_i will be used as the addr
//         shift <= addr_i; // the shift will be replaced with the data_in and the eof will trigger if it matches the endfile byte
//         total <= total +1;  // the total characters will be added onto each other
//     end

//     if (end_file == shift) begin
//         eof <= 1;
//     end else begin
//         eof <= 0;
//     end

//     if (eof && !rst) begin
//         complete <= 1;
//     end
// end

endmodule