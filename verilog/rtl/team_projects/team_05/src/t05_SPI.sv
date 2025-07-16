typedef enum logic [1:0] {
    INIT = 0,
    READ = 1,
    WRITE = 2,
    DONE = 3
}state_t;

module t05_SPI (
    output logic mosi, // Write
    input logic miso, // Read
    input logic rst, // Reset
    input logic serial_clk, clk,
    input logic slave_select,
    output logic [7:0] read_output,
    input logic writebit,
    input logic read_en, write_en
);

localparam
    CMD0 = 48'b010000000000000000000000000000000000000010010101, // To go into IDLE STATE
    CMD58 = 48'b011110100000000000000000000000000000000001110101, // OCR Conditions
    CMD55 = 48'b011101110000000000000000000000000000000001100101, // Prepares the SD Card for the next command
    ACMD41 = 48'b011010010100000000000000000000000000000000000001, // Exits initialization mode and begn the data transfer
    CMD12 = 48'b010011000000000000000000000000000000000000000001, // Stop reading multiple blocks
    CMD8 =  48'b010010000000000000000000000000011010101010000111; // Check the voltage range and if the card is compatible

logic [47:0] cmd18 = {8'b01010010, read_address, 8'b00000001}, // Read multiple blocks until termination code
cmd24 = 48'b01011000; /* ARGUMENT ADDRESS */ //00000001 // Write single 

// Logic declarations
logic [47:0] cmd_line, cmd_line_n; 
state_t state, state_n;
logic idle_enable, idle_enable_n, warmup_enable, warmup_enable_n, response_enable, response_enable_n; // Used to enable the first bit of the command
logic enable_0, enable_0_n, enable_8, enable_8_n, enable_55, enable_55_n, enable_41, enable_41_n; 
logic [7:0] read_byte, read_byte_n; 
logic [39:0] response_holder, response_holder_n; // Used to hold the response byte
logic [6:0] warmup_counter, warmup_counter_n; // Used to stabilize the SD before data transfer begin
logic [5:0] index_counter, index_counter_n; // Used to count the number of bits received
logic [5:0] timer_50, timer_50_n; 
logic [5:0] read_in_timer, read_in_timer_n;
logic read_in_40, read_in_40_n;
logic [31:0] read_address, read_address_n; 
logic read_cmd_en, read_cmd_en_n; // Used to enable the read command
logic read_stop, read_stop_n; // Used to stop reading data
logic cmd_en, cmd_en_n; // Used to enable the command

// typedef enum logic [47:0] { 
//     CMD0 = 48'b010000000000000000000000000000000000000010010101, // To go into IDLE STATE
//     CMD58 = 48'b011110100000000000000000000000000000000001110101, // OCR Conditions
//     CMD55 = 48'b011101110000000000000000000000000000000001100101, // Prepares the SD Card for the next command
//     ACMD41 = 48'b011010010100000000000000000000000000000000000001, // Exits initialization mode and begn the data transfer
//     CMD18 = {01010010, read_address, 00000001}, // Read multiple blocks until termination code
//     CMD12 = 48'b010011000000000000000000000000000000000000000001, // Stop reading multiple blocks
//     CMD24 = 48'b01011000, /* ARGUMENT ADDRESS */ //00000001 // Write single 
//     CMD8 =  48'b010010000000000000000000000000011010101010000111 // Check the voltage range and if the card is compatible
// }command_t;

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            cmd_line <= CMD0; // Reset with CMD0
            state <= INIT;
            read_byte <= '0;
        end else if (serial_clk) begin
            cmd_line <= cmd_line_n;
            state <= state_n;
            read_byte <= read_byte_n;
        end
    end

// INIT Logic Block
always_comb begin
    cmd_line_n = cmd_line;
    state_n = state;
    read_byte_n = read_byte;
    warmup_counter_n = warmup_counter;
    warmup_enable_n = warmup_enable;
    response_holder_n = response_holder;
    response_enable_n = response_enable;
    enable_0_n = enable_0;
    enable_8_n = enable_8;
    enable_55_n = enable_55;
    enable_41_n = enable_41;
    read_in_40_n = read_in_40;
    read_in_timer_n = read_in_timer;
    index_counter_n = index_counter;
    timer_50_n = timer_50;
    read_cmd_en_n = read_cmd_en;
    read_stop_n = read_stop;
    mosi = 0;
    read_output = '0;
    cmd_en_n = cmd_en;
    idle_enable_n = idle_enable;

    case (state)
        INIT: begin
            if (slave_select == 0) begin
                if(warmup_enable) begin 
                    if (warmup_counter < 74) begin
                        warmup_counter_n = warmup_counter + 1; // Warmup counter to stabilize the SD
                    end 
                    else if (warmup_counter == 74) begin
                        enable_0_n = 1; // Enable the first bit of the command
                        warmup_enable_n = 0;
                    end
                end

                if(read_in_40) begin
                    response_holder_n = {response_holder[38:0], miso}; // Shift in data on MISO
                    if(read_in_timer < 40) begin
                        read_in_timer_n = read_in_timer + 1;
                    end else begin
                        read_in_timer_n = 0;
                        read_in_40_n = 0;
                        response_enable_n = 1;
                    end
                end

                    // Response for CMD0 
                if (response_enable) begin
                    response_enable_n = 0; 
                    if (response_holder[39:32] == 8'b00000001 && idle_enable) begin
                        enable_8_n = 1;
                        idle_enable_n = 0;
                    end 
                    // Response for CMD8
                    if (response_holder == 40'b000000100000000000000000000000110101010) begin
                        enable_55_n = 1;
                    end
                    // Response for ACMD41
                    if (response_holder[39:32] == 8'b00000000) begin
                        state_n = READ;
                    end
                    if (response_holder[39:32] == 8'b00000001) begin
                        enable_41_n = 0;
                        enable_55_n = 1; 
                    end
                end 
                
                else if (cmd_en) begin
                    if (index_counter == 6'd48) begin
                        index_counter_n = 0; // Reset the index counter after sending the command
                        cmd_en_n = 0;
                    end
                    if (index_counter < 48) begin
                        index_counter_n = index_counter + 1; // Increment the index counter for each bit
                    end
                    mosi = cmd_line[47 - index_counter]; // Shift out the command bit
                end 

                else if(enable_0) begin
                    cmd_line_n = CMD0; 
                    cmd_en_n = 1;
                    if (timer_50 < 50) begin
                        timer_50_n = timer_50 + 1; // Increment the timer for 50 clock cycles
                    end else begin
                        timer_50_n = 0; 
                        read_in_40_n = 1; 
                        enable_0_n = 0;
                        idle_enable_n = 1;
                    end
                end
                
                else if (enable_8) begin
                    cmd_line_n = CMD8; 
                    cmd_en_n = 1;
                    if (timer_50 < 50) begin
                        timer_50_n = timer_50 + 1; // Increment the timer for 50 clock cycles
                    end else begin
                        timer_50_n = 0; 
                        read_in_40_n = 1; 
                        enable_8_n = 0;
                    end
                end 
                
                else if (enable_55) begin
                    cmd_line_n = CMD55; 
                    cmd_en_n = 1;
                    if (timer_50 < 50) begin
                        timer_50_n = timer_50 + 1; // Increment the timer for 50 clock cycles
                    end else begin
                        enable_41_n = 1; // Enable the ACMD41 command after 50 clock cycles
                        enable_55_n = 0;
                        timer_50_n = 0;  
                    end
                end 
                
                else if (enable_41) begin 
                    cmd_line_n = ACMD41; 
                    cmd_en_n = 1; 
                    if (timer_50 < 50) begin
                        timer_50_n = timer_50 + 1; // Increment the timer for 50 clock cycles
                    end else begin
                        read_in_40_n = 1;
                        enable_41_n = 0; 
                        timer_50_n = 0;
                    end
                end
            end 
        end

        READ: begin  // Logic for reading data from MISO
            if(read_en) begin
                if(read_cmd_en) begin
                    cmd_line_n = cmd18;
                    cmd_en_n = 1;
                    if(cmd_en) begin
                        if (index_counter == 48) begin
                            index_counter_n = 0; // Reset the index counter after sending the command
                            cmd_en_n = 0;
                            read_cmd_en_n = 0;
                        end
                        if (index_counter < 48) begin
                            index_counter_n = index_counter + 1; // Increment the index counter for each bit
                        end
                        mosi = cmd_line[47 - index_counter]; // Shift out the command bit
                    end
                end
            end
            else if (read_stop) begin
                cmd_line_n = CMD12;    
                cmd_en_n = 1;
                if(cmd_en) begin
                    if (index_counter == 48) begin
                        index_counter_n = 0; // Reset the index counter after sending the command
                        cmd_en_n = 0;
                        read_cmd_en_n = 0;
                    end
                    if (index_counter < 48) begin
                        index_counter_n = index_counter + 1; // Increment the index counter for each bit
                    end
                    mosi = cmd_line[47 - index_counter]; // Shift out the command bit
                end
            end
            else if (read_stop == 0 && read_en == 0) begin
                if (read_in_timer < 8) begin
                    read_in_timer_n = read_in_timer + 1; // Increment the read-in timer for each bit
                    read_byte_n = {read_byte[6:0], miso}; // Shift in data on MISO
                end else begin
                    read_output = read_byte; 
                    read_in_timer_n = 0; 
                end
            end
        end
        WRITE: begin // Logic for writing data to MISO can be added here
            if(write_en) begin
                cmd_line_n = CMD12;    
                cmd_en_n = 1;
                if(cmd_en) begin
                    if (index_counter == 48) begin
                        index_counter_n = 0; // Reset the index counter after sending the command
                        cmd_en_n = 0;
                        read_cmd_en_n = 0;
                    end
                    if (index_counter < 48) begin
                        index_counter_n = index_counter + 1; // Increment the index counter for each bit
                    end
                    mosi = cmd_line[47 - index_counter]; // Shift out the command bit
                end
            end
            mosi = writebit;
        end

        DONE: begin
            // Logic for finalizing the operation can be added here
        end

        default: state_n = INIT; // Reset to INIT on unexpected state
    endcase
end
endmodule