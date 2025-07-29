module t05_histogram(
    input logic clk, rst,
    input logic [3:0] en_state,
    input logic [7:0] spi_in,        // input byte from SPI
    input logic [31:0] sram_in,       // value from SRAM
    input logic busy_i, init,
    input logic read_i, write_i,
    output logic eof,
    output logic complete, // eof = end of file; complete = done with byte
    output logic [31:0] total, sram_out,  //total number of characters within the file,  the updated data going to the sram 
    output logic [7:0]  hist_addr,     // address to SRAM
    output logic [1:0] wr_r_en        // enable going to sram to tell it to read or write
);
//send a controller enable to controller
//accept an enable from sram to know when to procccess new data
logic [3:0] next_state;
logic [7:0] new_spi;
logic [3:0] state;

logic init_edge;

typedef enum logic [3:0] {
    IDLE  = 4'd0,
    READ  = 4'd1,
    WAITREAD  = 4'd2,
    WRITE = 4'd3,
    HALT  = 4'd4,
    DONE = 4'd5,
    WAITWRITE = 4'd6,
    READ3 = 4'd7
} state_t;

// assign sram_out = sram_in + 1;

logic [1:0] wait_cnt, wait_cnt_n;
logic [7:0] end_file = 8'h1A;

logic [31:0] total_n;
logic [1:0] wr_r_en_n;
logic [7:0] hist_addr_n;
logic eof_n, complete_n;

logic [3:0] timer_n, timer;

logic [31:0] sram_out_n;


always_ff @( posedge clk, posedge rst ) begin
    if (rst) begin
        state <= IDLE;
        wait_cnt   <= 0;
        wr_r_en    <= 0;
        total      <= 0;
        hist_addr  <= 0;
        eof        <= 0;
        complete   <= 0;
        total <= 0;
        wait_cnt <= 0;
        timer <= '0;
        sram_out <= '0;
        init_edge <= 0;
        //new_spi <= 0;
        //new_spi <= spi_in;
    end else if (en_state == 1) begin
        state <= next_state;
        wait_cnt   <= wait_cnt_n;
        wr_r_en    <= wr_r_en_n;
        total      <= total_n;
        hist_addr  <= hist_addr_n;
        eof        <= eof_n;
        complete   <= complete_n;
        total <= total_n;
        wait_cnt <= wait_cnt_n;
        timer <= timer_n;
        sram_out <= sram_out_n;
        init_edge <= init;
    end 
end

// Next state logic
always_comb begin
    next_state = state;
    wr_r_en_n = wr_r_en;
    complete_n = complete;
    eof_n = eof;
    hist_addr_n = hist_addr;
    complete_n = complete;
    total_n = total;
    wait_cnt_n = wait_cnt;
    timer_n = timer;
    sram_out_n = sram_out;

    case (state)
        IDLE:  begin //beginning of the histogram
            next_state = READ;
            wr_r_en_n   = 2'd3;
            complete_n  = 0;
            eof_n       = 0;
            hist_addr_n = 0;
        end
        READ:  begin  //giving the sram the character that it wants to pull
            next_state = WAITREAD;
            wr_r_en_n  = 2'd0;
            hist_addr_n = spi_in;
            total_n = total + 1;
        end
        WAITREAD: begin
            wr_r_en_n = 2'd3;
            if(!busy_i) begin
                next_state = WRITE;
                wr_r_en_n = 2'd3;
                sram_out_n = sram_in + 1;
            end
        end
        WAITWRITE: begin
            wr_r_en_n = 2'd3;
            if(!busy_i) begin
                next_state = READ;
                // wr_r_en_n = 2'd0;
            end
        end
        // READ2: begin  //giving the updated data to the sram for storage
        //     if(timer < 10) begin
        //         next_state = READ2;
        //         timer_n = timer + 1;
        //     end else begin  
        //         next_state = WAIT;
        //     end
        //     wr_r_en_n = 2'd0;
        // end        
        // WAIT:  begin  //wait cycle between input and output from sram
        //     wr_r_en_n = 2'd1;
        //     if (wait_cnt == 2) begin
        //         wait_cnt_n = 0;
        //         next_state = WRITE;
        //     end else begin
        //         wait_cnt_n = wait_cnt + 1;
        //         next_state = WAIT;
        //     end
        // end
        WRITE: begin  //pulling the data from the sram and adding 1
            if (spi_in == end_file) begin
                next_state = HALT;
                eof_n = 1;
                wr_r_en_n = 2'd3;
            end else begin
                next_state = WAITWRITE;
            end
        end
        DONE: begin  //done with that 1 cycle
            next_state = DONE;
            complete_n = 1;
            wr_r_en_n = 2'd3;
        end
        HALT:   begin  //the end of file has been enabled and histogram will stop
            next_state = DONE;
            total_n = total + 1;
            wr_r_en_n = 2'd3;
        end
        default: next_state = IDLE;
    endcase

    if(init) begin
        next_state = WRITE;
        wr_r_en_n = 2'd1;
    end else if (init_edge && !init) begin
        next_state = READ;
        wr_r_en_n = 2'd0;
    end
    end
endmodule