`default_nettype none
module t05_SPI (
    input   logic           miso,                       // Read
    input   logic           rst,                        // Reset
    input   logic           clk,                        //Clock
    input   logic           serial_clk,                 //Serial Clock
    input   logic           writebit,                   //Bit that needs to be written
    input   logic           read_en,                    //Determines when to start reading
    input   logic           write_en,                   //Determines when to start writing
    input   logic           read_stop,                  //Determines when to stop reading
    input   logic           write_stop,                 //Determines when to stop writing
    input   logic           nextCharEn,     
    output  logic           slave_select,               //CS
    output  logic           reading,                    //Reading active
    output  logic           read_output,                //Goes to bytecount
    output  logic           finish,                     //Finish Signal
    output  logic           freq_flag,                  //Clock Frequency Flag
    output  logic           mosi                        // Write
);

typedef enum logic [3:0] {
    WARMUP = 1,
    CMD_CHOOSE = 2,
    CMD_INPUT = 3,
    CMD_RESPONSE = 4,
    IDLE = 5,
    READ_PREP = 6,
    READING = 7,
    READ_STOP = 8,
    WRITE_TOKEN = 9,
    WRITING = 10,
    WRITE_CRC = 11
} state_t;

localparam
    CMD0 = 48'b010000000000000000000000000000000000000010010101,                // To go into IDLE STATE
    CMD58 = 48'b011110100000000000000000000000000000000001110101,               // OCR Conditions
    CMD55 = 48'b011101110000000000000000000000000000000001100101,               // Prepares the SD Card for the next command
    ACMD41 = 48'b011010010100000000000000000000000000000000000001,              // Exits initialization mode and begn the data transfer
    CMD12 = 48'b010011000000000000000000000000000000000000000001,               // Stop reading 
    CMD8 =  48'b010010000000000000000000000000011010101010000111;               // Check the voltage range and if the card is compatible

logic [47:0] cmd18;
assign cmd18 = {8'b01010010, address, 8'b00000001};                     // Read multiple blocks until termination code
logic [47:0] cmd24; 
assign cmd24 = {8'b01011000, address, 8'b00000001};                     // Write single 
logic [47:0] cmd25; 
assign cmd25 = {8'b01011001, address, 8'b00000001};                     // Write Multiple

// Logic declarations
state_t         state, state_n;
logic [47:0]    cmd_line, cmd_line_n;                                   //CMD being written
logic           freq_flag_n;
//WARMUP
logic [6:0]     warmup_counter, warmup_counter_n;                       // Used to stabilize the SD before data transfer begin
//CMD_CHOOSE
logic           redo_init, redo_init_n;                                 //Control the repeat in sd initialization
//CMD_INPUT
logic [5:0]     cmd_counter, cmd_counter_n;                             // Used to count the number of bits received
//CMD_RESPONSE 
logic [6:0]     read_48, read_48_n;                                     //Reading in response timer
//IDLE
logic [31:0]    address, address_n;                                     //Address for writing/reading
//WRITE_TOKEN
logic [2:0]     counter_token, counter_token_n;                         //Counter for writing data token to SD
//WRITING
logic [7:0]     data_token, data_token_n;                               //Enable for Data Token writing
logic [12:0]    counter_512, counter_512_n;                             //Counter for 512 blocks;
//WRITE_CRC
logic [5:0]     counter_crc, counter_crc_n;                             //Counter for writing CRC at the end of 512 bytes

always_ff @(posedge clk, posedge rst) begin
    if (rst) begin  
        //GENERAL
        state <= WARMUP;   
        cmd_line <= '0;
        freq_flag <= 0;
        //WARMUP
        warmup_counter <= '0;  
        //CMD_CHOOSE
        redo_init <= 1;
        //CMD_INPUT
        cmd_counter <= '0;
        //CMD_RESPONSE
        read_48 <= '0;
        //IDLE
        address <= '0;
        //WRITE_TOKEN
        counter_token <= 0;
        //WRITING
        data_token <= 8'hFC;
        counter_512 <= '0;
        //WRITE_CRC
        counter_crc <= '0;
    end else if (serial_clk) begin
        //GENERAL
        state <= state_n;
        cmd_line <= cmd_line_n;
        freq_flag <= freq_flag_n;
        //WARMUP
        warmup_counter <= warmup_counter_n; // Counter for the warmup
        //CMD_CHOOSE
        redo_init <= redo_init_n;
        //CMD_INPUT
        cmd_counter <= cmd_counter_n; // Counter for the number of bits received
        //CMD_RESPONSE
        read_48 <= read_48_n;
        //IDLE
        address <= address_n;
        //WRITE_TOKEN
        counter_token <= counter_token_n;
        //WRITING
        data_token <= data_token_n;
        counter_512 <= counter_512_n;
        //WRITE_CRC
        counter_crc <= counter_crc_n;
    end
end

// INIT Logic Block
always_comb begin
    //GENERAL
    state_n = state;
    cmd_line_n = cmd_line;
    freq_flag_n = freq_flag;
    slave_select = 0;
    mosi = 1;
    //WARMUP
    warmup_counter_n = warmup_counter;
    //CMD_CHOOSE
    redo_init_n = redo_init;
    //CMD_INPUT
    cmd_counter_n = cmd_counter;
    //CMD_RESPONSE
    read_48_n = read_48;
    //IDLE
    address_n = address;
    //READING
    reading = 0;
    read_output = 0;
    //WRITE_TOKEN
    counter_token_n = counter_token;
    //WRITING
    data_token_n = data_token;
    counter_512_n = counter_512;
    //WRITE_CRC
    counter_crc_n = counter_crc;

    case (state)
        WARMUP: begin
            slave_select = 1;
            freq_flag_n = 0;
            if (warmup_counter < 75) begin
                warmup_counter_n = warmup_counter + 1; // Warmup counter to stabilize the SD
                mosi = 1;
                //slave_select = 1;
            end 
            else begin
                state_n = CMD_INPUT;
                cmd_line_n = CMD0;
                warmup_counter_n = 0;
                //slave_select = 1; 
            end
        end
        CMD_CHOOSE: begin
            case(cmd_line[45:40])
                '0: begin //CMD_0
                    cmd_line_n= CMD8;
                    state_n = CMD_INPUT;
                end
                8: begin //CMD_8
                    cmd_line_n = CMD55;
                    state_n = CMD_INPUT;
                end
                55: begin //CMD_55
                    cmd_line_n = ACMD41;
                    state_n = CMD_INPUT;
                end
                41: begin //ACMD_41
                    if(redo_init) begin
                        cmd_line_n = CMD8;
                        state_n = CMD_CHOOSE;
                        redo_init_n = 0;
                    end
                    else begin
                        cmd_line_n = CMD58;
                        state_n = CMD_INPUT;
                    end
                end
                58: begin //CMD_58
                    cmd_line_n = '0;
                    state_n = IDLE;
                end
                18: begin //CMD_18
                    cmd_line_n = '0;
                    state_n = READING;
                end
                12: begin //CMD_12
                    cmd_line_n = '0;
                    state_n = IDLE;
                end
                25: begin //CMD_25
                    cmd_line_n = '0;
                    data_token_n = 8'hFC;
                    state_n = WRITE_TOKEN;
                    mosi = 1;
                end
            endcase
        end
        CMD_INPUT: begin
            slave_select = 0;
            if (cmd_counter == 47) begin
                cmd_counter_n = 0;                      // Reset the index counter after sending the command
                state_n = CMD_RESPONSE;
            end
            else if (cmd_counter < 47) begin
                cmd_counter_n = cmd_counter + 1;        // Increment the index counter for each bit
            end
            mosi = cmd_line[47 - cmd_counter];          // Shift out the command bit
        end
        CMD_RESPONSE: begin
            if(read_48 < 48) begin
                read_48_n = read_48 + 1;
            // end else if (write_en) begin
            //     read_48_n = 0;
            //     state_n = CMD_RESPONSE;
            end else begin
                read_48_n = '0;
                state_n = CMD_CHOOSE;
            end
        end
        IDLE: begin
            slave_select = 1;
            freq_flag_n = 0; //Make ONE later
            if(read_en) begin
                cmd_line_n = cmd18;
                address_n = '0;
                state_n = CMD_INPUT;
            end
            else if(write_en) begin
                cmd_line_n = cmd25;
                address_n = '0;
                state_n = CMD_INPUT;
            end
        end
        READING: begin
            slave_select = 1;
            if(read_stop) begin
                cmd_line_n = CMD12;
                state_n = CMD_INPUT;
            end
            else begin
                state_n = READING;
                read_output = miso;
                reading = 1;
            end
        end
        WRITE_TOKEN: begin
            if(counter_token < 7) begin
                if(counter_token < 6) begin
                    counter_token_n = counter_token + 1;
                end
                mosi = data_token[6 - counter_token];
            end 
            if(counter_token == 6) begin
                //mosi = writebit;
                counter_token_n = '0;
                state_n = WRITING;
            end
        end
        WRITING: begin
            slave_select = 1;
            if(counter_512 == 512 * 8) begin
                state_n = WRITE_CRC;
                //mosi = 1;
                counter_512_n = '0;
            end
            if (counter_512 < 512 * 8) begin
                mosi = writebit;
                counter_512_n = counter_512 + 1;
            end
            if(write_stop) begin
                data_token_n = 8'hFD;
            end
        end
        WRITE_CRC: begin
            if(counter_crc <= 7) begin
                counter_crc_n = counter_crc + 1;
                mosi = 1;
            end else if (counter_crc < 30) begin
                counter_crc_n = counter_crc + 1;
            end else if (counter_crc == 30) begin
                state_n = WRITE_TOKEN;
            end
        end
        default: state_n = IDLE;
    endcase
end
endmodule


// `default_nettype none
// module t05_SPI (
//     input logic miso, // Read
//     input logic rst, // Reset
//     input logic serial_clk, clk,
//     input logic writebit,
//     input logic read_en, write_en, read_stop, nextCharEn,
//     input logic [31:0] read_address, write_address,
//     output logic slave_select,
//     output logic [7:0] read_output,
//     output logic [3:0] finish, 
//     output logic freq_flag, cmd_en,
//     output logic mosi // Write
// );

// typedef enum logic [5:0] {
//     INITIAL = 0,
//     READ_SPI = 1,
//     WRITE_SPI = 2,
//     DONE = 3,
//     IDLE_SPI = 4,
//     EN_0 = 5,
//     EN_8 = 6,
//     EN_55 = 7,
//     EN_41 = 8,
//     EN_58 = 9,
//     EN_18 = 10,
//     EN_24 = 11,
//     EN_12 = 12,
//     RESPONSE = 13,
//     C1 = 14,
//     C2 = 15,
//     C3 = 16,
//     C4 = 17,
//     C5 = 18,
//     CIDLE = 19
// }state_t;

// localparam
//     CMD0 = 48'b010000000000000000000000000000000000000010010101, // To go into IDLE STATE
//     CMD58 = 48'b011110100000000000000000000000000000000001110101, // OCR Conditions
//     CMD55 = 48'b011101110000000000000000000000000000000001100101, // Prepares the SD Card for the next command
//     ACMD41 = 48'b011010010100000000000000000000000000000000000001, // Exits initialization mode and begn the data transfer
//     CMD12 = 48'b010011000000000000000000000000000000000000000001, // Stop reading 
//     CMD8 =  48'b010010000000000000000000000000011010101010000111; // Check the voltage range and if the card is compatible

// logic [47:0] cmd18;
// assign cmd18 = {8'b01010010, read_address, 8'b00000001};  // Read multiple blocks until termination code
// logic [47:0] cmd24; 
// assign cmd24 = {8'b01011000, write_address, 8'b00000001}; // Write single 

// // Logic declarations
// state_t state, state_n;
// state_t enables, enables_n;
// state_t command, command_n;
// logic [47:0] cmd_line, cmd_line_n; 
// logic [7:0] read_byte, read_byte_n; 
// logic [6:0] warmup_counter, warmup_counter_n; // Used to stabilize the SD before data transfer begin
// logic [5:0] index_counter, index_counter_n; // Used to count the number of bits received
// logic [5:0] timer_50, timer_50_n; 
// logic [6:0] read_in_timer, read_in_timer_n;
// logic read_in_40, read_in_40_n;
// logic read_cmd_en, read_cmd_en_n, write_cmd_en, write_cmd_en_n, warmup_enable, warmup_enable_n, freq_flag_n; // Used to enable the read command
// logic cmd_en_n; // Used to enable the command
// logic redo, redo_n; // Used to redo the command if the response is not valid
// logic read_stop_en, read_stop_en_n; // Used to enable the read stop

// always_ff @(posedge clk, posedge rst) begin
//     if (rst) begin
//         cmd_line <= CMD0; // Reset with CMD0
//         state <= INITIAL;
//         enables <= IDLE_SPI;
//         command <= CIDLE; // Initialize the command to IDLE
//         read_byte <= '0;
//         warmup_enable <= 1; // Enable warmup to stabilize the SD
//         read_in_40 <= 0; // Enable the read in 40 bits
//         read_in_timer <= 0; // Timer for reading in 40 bits
//         index_counter <= 0; // Counter for the number of bits received
//         timer_50 <= 0; // Timer for 50 clock cycles
//         read_cmd_en <= 1; // Enable the read command
//         cmd_en <= 0; // Enable the command
//         warmup_counter <= 0; // Counter for the warmup
//         write_cmd_en <= 0; // Enable the write command
//         read_cmd_en <= 0; 
//         redo <= 1;
//         read_stop_en <= 1; // Enable the read stop
//         freq_flag <= 0;
//     end else if (serial_clk) begin
//         cmd_line <= cmd_line_n;
//         state <= state_n;
//         enables <= enables_n;
//         command <= command_n;
//         read_byte <= read_byte_n;
//         warmup_enable <= warmup_enable_n; // Enable warmup to stabilize the SD
//         read_in_40 <= read_in_40_n; // Enable the read in 40 bits
//         read_in_timer <= read_in_timer_n; // Timer for reading in 40 bits
//         index_counter <= index_counter_n; // Counter for the number of bits received
//         timer_50 <= timer_50_n; // Timer for 50 clock cycles
//         read_cmd_en <= read_cmd_en_n; // Enable the read command
//         cmd_en <= cmd_en_n; // Enable the command
//         warmup_counter <= warmup_counter_n; // Counter for the warmup
//         write_cmd_en <= write_cmd_en_n; // Enable the write command
//         read_cmd_en <= read_cmd_en_n; // Enable the read command  
//         redo <= redo_n;
//         read_stop_en <= read_stop_en_n; // Enable the read stop
//         freq_flag <= freq_flag_n;
//     end
// end

// // INIT Logic Block
// always_comb begin
//     cmd_line_n = cmd_line;
//     state_n = state;
//     enables_n = enables;
//     command_n = command;
//     read_byte_n = read_byte;
//     warmup_counter_n = warmup_counter;
//     warmup_enable_n = warmup_enable;
//     read_in_40_n = read_in_40;
//     read_in_timer_n = read_in_timer;
//     index_counter_n = index_counter;
//     timer_50_n = timer_50;
//     read_cmd_en_n = read_cmd_en;
//     mosi = 1;
//     read_output = '0;
//     cmd_en_n = cmd_en;
//     write_cmd_en_n =  write_cmd_en;
//     slave_select = 0;
//     finish = 0;
//     redo_n = redo;
//     read_stop_en_n = read_stop_en;
//     freq_flag_n = freq_flag;

//     case (state)
//         INITIAL: begin
//             freq_flag_n = 0;
//             if(warmup_enable) begin 
//                 if (warmup_counter < 75) begin
//                     warmup_counter_n = warmup_counter + 1; // Warmup counter to stabilize the SD
//                     mosi = 1;
//                     slave_select = 1;
//                 end 
//                 else begin
//                     enables_n = EN_0;
//                     warmup_enable_n = 0;
//                     warmup_counter_n = 0; // Reset the warmup counter
//                     slave_select = 1;
//                 end
//             end else begin
//                 if(read_in_40) begin
//                     if(read_in_timer < 120) begin
//                         read_in_timer_n = read_in_timer + 1;
//                     end else begin
//                         read_in_timer_n = 0;
//                         read_in_40_n = 0;
//                         enables_n = RESPONSE;
//                     end
//                 end

//             // Response for CMD0 
//                 if (cmd_en) begin
//                     slave_select = 0;
//                     if (index_counter == 47) begin
//                         index_counter_n = 0; // Reset the index counter after sending the command
//                         cmd_en_n = 0;
//                     end
//                     else if (index_counter < 47) begin
//                         index_counter_n = index_counter + 1; // Increment the index counter for each bit
//                     end
//                     mosi = cmd_line[47 - index_counter]; // Shift out the command bit
//                 end 

//                 case(enables)
//                     RESPONSE: begin
//                         case(command)
//                             C1: begin
//                                 enables_n = EN_8;
//                                 command_n = CIDLE;
//                             end
//                             C2: begin
//                                 enables_n = EN_55;
//                                 command_n = CIDLE;
//                             end
//                             C3: begin
//                                 enables_n = EN_41;
//                                 command_n = CIDLE;
//                             end
//                             C4: begin
//                                 if (redo) begin
//                                     redo_n = 0;
//                                     command_n = C2;
//                                     enables_n = RESPONSE;
//                                 end else begin
//                                     enables_n = EN_58; // Enable the fifth bit of the command
//                                     command_n = CIDLE;
//                                 end
//                             end
//                             C5: begin
//                                 state_n = READ_SPI;
//                                 read_cmd_en_n = 1;
//                                 command_n = CIDLE;
//                             end
//                             default: command_n = CIDLE;
//                         endcase
//                     end
//                     EN_0: begin
//                         cmd_line_n = CMD0; 
//                         if (timer_50 > 49) begin
//                             read_in_40_n = 1; 
//                             command_n = C1;
//                             cmd_en_n = 0;
//                             timer_50_n = 0;
//                         end
//                         else if (timer_50 < 50 && command_n == CIDLE) begin
//                             timer_50_n = timer_50 + 1; // Increment the timer for 50 clock cycles
//                             if(timer_50 < 48) begin
//                                 cmd_en_n = 1;
//                             end
//                         end 
//                     end
//                     EN_8: begin
//                         cmd_line_n = CMD8; 
//                         if (timer_50 > 49) begin
//                             cmd_en_n = 0;
//                             command_n = C2;
//                             read_in_40_n = 1;
//                             timer_50_n = 0;
//                         end
//                         else if (timer_50 < 50 && command_n == CIDLE) begin
//                             timer_50_n = timer_50 + 1; // Increment the timer for 50 clock cycles
//                             if(timer_50 < 48) begin
//                                 cmd_en_n = 1;
//                             end
//                         end 
//                     end
//                     EN_55: begin
//                         cmd_line_n = CMD55; 
//                          if (timer_50 > 49) begin
//                             cmd_en_n = 0;
//                             read_in_40_n = 1;
//                             command_n = C3;
//                             timer_50_n = 0;
//                         end else if (timer_50 < 50 && command_n == CIDLE) begin
//                             timer_50_n = timer_50 + 1; // Increment the timer for 50 clock cycles
//                             if(timer_50 < 48) begin
//                                 cmd_en_n = 1;
//                             end
//                         end
//                     end
//                     EN_41: begin
//                         cmd_line_n = ACMD41; 
//                         if (timer_50 > 49) begin
//                             cmd_en_n = 0;
//                             read_in_40_n = 1;
//                             command_n = C4;
//                             timer_50_n = 0;
//                         end else if (timer_50 < 50 && command_n == CIDLE) begin
//                             timer_50_n = timer_50 + 1; // Increment the timer for 50 clock cycles
//                             if(timer_50 < 48) begin
//                                 cmd_en_n = 1;
//                             end
//                         end 
//                     end
//                     EN_58: begin
//                         cmd_line_n = CMD58; 
//                         if (timer_50 > 49) begin
//                             cmd_en_n = 0;
//                             read_in_40_n = 1;
//                             command_n = C5;
//                             timer_50_n = 0;
//                         end else if (timer_50 < 50 && command_n == CIDLE) begin
//                             timer_50_n = timer_50 + 1; // Increment the timer for 50 clock cycles
//                             if(timer_50 < 48) begin
//                                 cmd_en_n = 1;
//                             end
//                         end 
//                     end
//                     default:
//                         enables_n = IDLE_SPI;
//                 endcase
//             end 
//         end
//         READ_SPI: begin  // Logic for reading data from MISO
//             freq_flag_n = 1;
//             if(cmd_en) begin
//                 slave_select = 0;
//                 if (index_counter == 47) begin
//                     index_counter_n = 0; // Reset the index counter after sending the command
//                     cmd_en_n = 0;
//                     read_cmd_en_n = 0;
//                 end
//                 else if (index_counter < 47) begin
//                     index_counter_n = index_counter + 1; // Increment the index counter for each bit
//                 end
//                 mosi = cmd_line[47 - index_counter]; // Shift out the command bit
//             end
//             else if(read_en || nextCharEn) begin
//                 read_output = read_byte; 
//                 read_in_timer_n = 0;
//                 if(read_cmd_en) begin
//                     cmd_line_n = cmd18;
//                     cmd_en_n = 1;
//                     read_stop_en_n = 1;
//                 end
//             end
//             else if(write_en == 1 && read_stop == 1) begin
//                 state_n = WRITE_SPI;  
//                 write_cmd_en_n = 1; 
//             end  
//             else if (read_en == 0 && read_stop == 0) begin
//                 if (read_in_timer < 8) begin
//                     read_in_timer_n = read_in_timer + 1; // Increment the read-in timer for each bit
//                     read_byte_n = {read_byte[6:0], miso}; // Shift in data on MISO
//                 end else begin
//                     read_in_timer_n = 0; 
//                 end
//             end
//             else if(read_stop_en) begin
//                 if (read_stop) begin
//                     cmd_line_n = CMD12;    
//                     cmd_en_n = 1;
//                     if(cmd_en) begin
//                         slave_select = 0;
//                         if (index_counter == 47) begin
//                             index_counter_n = 0; // Reset the index counter after sending the command
//                             cmd_en_n = 0;
//                             read_cmd_en_n = 0;
//                             read_stop_en_n = 0;
//                         end
//                         else if (index_counter < 47) begin
//                             index_counter_n = index_counter + 1; // Increment the index counter for each bit
//                         end
//                         mosi = cmd_line[47 - index_counter]; // Shift out the command bit
//                     end
//                 end
//             end
//         end
//         WRITE_SPI: begin // Logic for writing data to MISO can be added here
//             if(write_en) begin
//                 if(write_cmd_en) begin
//                     cmd_line_n = cmd24;    
//                     cmd_en_n = 1;
//                     if(cmd_en) begin
//                         if (index_counter == 47) begin
//                             index_counter_n = 0; // Reset the index counter after sending the command
//                             cmd_en_n = 0;
//                             write_cmd_en_n = 0;
//                         end
//                         else if (index_counter < 47) begin
//                             index_counter_n = index_counter + 1; // Increment the index counter for each bit
//                         end
//                         mosi = cmd_line[47 - index_counter]; // Shift out the command bit
//                     end
//                 end
//                 else begin
//                     mosi = writebit;
//                 end
//             end
//             else begin
//                 state_n = DONE; // Transition to DONE state if not writing
//             end
//         end

//         DONE: begin // Logic for finalizing the operation can be added here
//             slave_select = 1;
//             if (warmup_counter < 8) begin
//                 warmup_counter_n = warmup_counter + 1; // Warmup counter variable is just used to stabilize the SD
//             end 
//             else if (warmup_counter == 8) begin
//                 finish = 7; // Enable the first bit of the command
//             end
//         end
//         default: state_n = INITIAL; // Reset to INIT on unexpected state
//     endcase
// end
// endmodule