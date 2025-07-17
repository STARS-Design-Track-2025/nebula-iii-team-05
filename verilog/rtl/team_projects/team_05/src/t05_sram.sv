module t05_sram(
    input logic clk, rst, ready, //enable for when the data has been read
    input logic [31:0] histogram, //new histogram value to write
    input logic [7:0] histgram_addr, //address from the histogram
    input logic [8:0] find_least,
    input logic [70:0] htreewrite,
    input logic [6:0] htreeread,
    input logic [7:0] codebook, 
    input logic [127:0] codebook_path, 
    input logic [7:0] translation, 
    input logic [2:0] word_i, state,  // might not need the word, the state bit of which module the data is from
    input logic[31:0] sram_in, //data coimng into the sram interface to be stored
    output logic busy_o, ready_h,
    output logic [31:0] old_char, //output value to read from sram
    output logic [70:0] h_element, 
    output logic [128:0] char_code,
    output logic [31:0] trn_histo_element,
    output logic [31:0] flv_histo_element,
    output logic [63:0] comp_val, //find least value
    output logic [3:0] ctrl,
    output logic [31:0] data_o, addr //output data going from the wishbone and sram as well as the address associated with it going to the staemachine for the controller
);
//the goal of the sram is to input data from different addresses and either store the data that is given to it or output the data that the address pulls
    logic [31:0] sram [255:0];
    logic in_ready;
    
    logic do_wr, do_r,  wr_en, r_en; //enables for reading and writing should be given from the controller because the sram will not be able to determine what data to read/write on its own
    // logic [31:0] read_addr_reg;
    logic [31:0] base_addr; //the addresses will already be created within the sram interface

//HISTOGRAM
    // pulls the 32 bit value for the histogram and give it to it then takes in the new 32 bit number from the histogram and stores it
        //examine the ready input, it may need to be moved to an output in the future
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            old_char <= 0;
            ready_h  <= 0;
        end else if (in_ready) begin
            if (r_en) begin //include that if the histogram enable from the controller is on too
                old_char <= sram[histgram_addr]; // Read 32-bit value at 8-bit address
                ready_h  <= 1;
            end else if (wr_en) begin
                sram[histgram_addr] <= histogram; // Write new 32-bit value
                ready_h <= 0;
                // the histogram done enable from the sram going to the controller will be high
            end else if (!r_en && !wr_en) begin
                old_char <= '0;
            end else begin
                ready_h <= 0;
            end
        end
    end


//FIND LEAST VALUE
    //gives the sram a address and the sram gives back a64 bit value
    always_ff @( posedge clk, posedge rst) begin : blockName
        if (rst) begin

        end else begin

        end
    end


//TRANSLATION
    //inputs an address and outputs 128 bits and 32 bits
    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin

        end else begin

        end 
    end

//CODEBOOK
    //inputs an address and 128 bit path and outputs 71 bits
        always_ff @(posedge clk, posedge rst) begin
        if (rst) begin

        end else begin

        end 
    end

//HTREE
    //inputs 71 and 7 bits and a read/write enable and stores it


//CONTROLLER
    // enable signals to and from sram for each module
    typedef enum logic [2:0] { 
        A_IDLE = 3'b000,
        HIST = 3'b001,
        FLV = 3'b010,
        HTREE = 3'b011,
        CODEBOOK = 3'b101,
        TRANSLATION = 3'b110
    } name;

    always_comb begin : blockName  //example only for the idle and histogram right now
        if (A_IDLE) begin
            wr_en = 0;
            r_en = 0;
            //any other enables would be 0
        end if (HIST) begin
            wr_en = 1;
            //or "must get clarification from controller"
            r_en =1;
            in_ready = 1;
        end
        
    end















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