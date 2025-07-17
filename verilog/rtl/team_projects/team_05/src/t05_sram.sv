module t05_sram(
    input logic clk, rst, 
    input logic [3:0] word_i, state,  // might not need the word, the state bit of which module the data is from
    input logic[31:0] sram_in, //data coimng into the sram interface to be stored
    output logic busy_o, 
    output logic [31:0] data_o, addr //output data going from the wishbone and sram as well as the address associated with it going to the staemachine for the controller
);
//for the state machine going to the controller should read the input
    logic do_wr, do_r,  wr_en, r_en; //enables for reading and writing
    // logic [31:0] read_addr_reg;
    logic [31:0] base_addr; //created address

    // assign read_addr = read_addr_reg;
//States to write
    typedef enum logic [1:0] {  
        IDLE,
        WRITE_PREP,
        WRITE_COMMIT,
        WRITE_DONE
    } state_t;
//States to read
    typedef enum logic [2:0] {
        R_IDLE,
        R_LATCH_ADDR,
        R_DO_READ,
        R_WAIT_DATA,
        R_DONE
    } read_state_t;
//States for the address assignment
    typedef enum logic [3:0] { 
        A_IDLE = 4'b0000,
        HIST = 4'b0001,
        FLV = 4'b0010,
        HTREE = 4'b0011,
        CODEBOOK = 4'b0101,
        TRANSLATION = 4'b0110,
        ERROR = 4'b0111,
        DONE = 4'b1000
    } name;

    state_t curr_state, next_state;
    read_state_t r_curr, r_next;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            curr_state <= IDLE;
    end else begin
            curr_state <= next_state;
    end 
    end

    always_ff @(posedge clk or posedge rst) begin
        if (rst)
            r_curr <= R_IDLE;
        else
            r_curr <= r_next;
    end

    // State logic
    always_comb begin
        next_state = curr_state;
        do_wr = 0;

        case (curr_state)
            IDLE: begin
                if (wr_en) 
                next_state = WRITE_PREP;
            end

            WRITE_PREP: begin
                next_state = WRITE_COMMIT;
            end

            WRITE_COMMIT: begin //in this state will the data 
                do_wr = 1; // trigger the write
                next_state = WRITE_DONE;
            end

            WRITE_DONE: begin
                if (!wr_en) next_state = IDLE;
            end
        endcase
    end

    always_comb begin
        r_next    = r_curr;
        do_r      = 0;
        busy_o    = 0;

        case (r_curr)
            R_IDLE: begin
                if (r_en)
                    r_next = R_LATCH_ADDR;
            end

            R_LATCH_ADDR: begin
                r_next = R_DO_READ;
                busy_o = 1;
            end

            R_DO_READ: begin
                do_r   = 1;
                r_next = R_WAIT_DATA;
                busy_o = 1;
            end

            R_WAIT_DATA: begin
                r_next = R_DONE;
                busy_o = 1;
            end

            R_DONE: begin
                busy_o = 1;
                if (!r_en)
                    r_next = R_IDLE;
            end
            default : begin
                r_next = R_IDLE;
            end
        endcase
    end

    always_comb begin
        wr_en = 0;
        r_en = 0;

    case (state)
        HIST: begin
            wr_en = 1;
            base_addr = 32'b0000_0000_0000_0000_0000_0000_0000_0000;
        end // HIST
        FLV: base_addr = 32'b0000_0000_0000_0000_0000_0001_0000_0000; // FLV
        HTREE: base_addr = 32'b0000_0000_0000_0000_0000_0010_0000_0000; // HTREE
        CODEBOOK: base_addr = 32'b0000_0000_0000_0000_0000_0011_0000_0000; // CBS
        TRANSLATION: base_addr = 32'b0000_0000_0000_0000_0000_0100_0000_0000; // TRN
        ERROR: base_addr = 32'b0000_0000_0000_0000_0000_1111_0000_0000; // ERROR
        DONE : base_addr = 32'b0000_0000_0000_0000_0000_1111_1111_1111; // DONE / END
        default: base_addr = 32'b1101_1110_1010_1101_1011_1110_1110_1111; // invalid //will change later
    endcase
end

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            r_curr       <= R_IDLE;
            data_o <= 32'd0;
        end else begin
            r_curr <= r_next;

        // Capture SRAM output
        if (r_curr == R_DONE)
            data_o <= sram_in;
        end
    end 

    always_ff @( posedge clk, posedge rst ) begin : blockName
        if (rst) begin
            addr <= 32'b0;
        end else begin
            addr <= base_addr + 1'b1;
        end
    end

endmodule