// `default_nettype none
// module t05_SPI (
//     input   logic           miso,                       // Read
//     input   logic           rst,                        // Reset
//     input   logic           clk,                        //Clock
//     input   logic           serial_clk,                 //Serial Clock
//     input   logic           writebit,                   //Bit that needs to be written
//     input   logic           read_en,                    //Determines when to start reading
//     input   logic           write_en,                   //Determines when to start writing
//     input   logic           read_stop,                  //Determines when to stop reading
//     input   logic           nextCharEn,     
//     output  logic           slave_select,               //CS
//     output  logic           reading,                    //Reading active
//     output  logic           read_output,                //Goes to bytecount
//     output  logic           finish,                     //Finish Signal
//     output  logic           freq_flag,                  //Clock Frequency Flag
//     output  logic           mosi                        // Write
// );

// typedef enum logic [3:0] {
//     WARMUP = 1,
//     CMD_CHOOSE = 2,
//     CMD_INPUT = 3,
//     CMD_RESPONSE = 4,
//     IDLE = 5,
//     READ_PREP = 6,
//     READING = 7,
//     READ_STOP = 8,
//     WRITE_PREP = 9,
//     WRITING = 10,
//     WRITE_STOP = 11
// } state_t;

// localparam
//     CMD0 = 48'b010000000000000000000000000000000000000010010101,                // To go into IDLE STATE
//     CMD58 = 48'b011110100000000000000000000000000000000001110101,               // OCR Conditions
//     CMD55 = 48'b011101110000000000000000000000000000000001100101,               // Prepares the SD Card for the next command
//     ACMD41 = 48'b011010010100000000000000000000000000000000000001,              // Exits initialization mode and begn the data transfer
//     CMD12 = 48'b010011000000000000000000000000000000000000000001,               // Stop reading 
//     CMD8 =  48'b010010000000000000000000000000011010101010000111;               // Check the voltage range and if the card is compatible

// logic [47:0] cmd18;
// assign cmd18 = {8'b01010010, read_address, 8'b00000001};                        // Read multiple blocks until termination code
// logic [47:0] cmd24; 
// assign cmd24 = {8'b01011000, write_address, 8'b00000001};                       // Write single 

// // Logic declarations
// state_t         state, state_n;
// logic [47:0]    cmd_line, cmd_line_n;                                           //CMD being written

// //WARMUP
// logic [6:0]     warmup_counter, warmup_counter_n;                               // Used to stabilize the SD before data transfer begin

// //CMD_CHOOSE
// logic           redo_init <= 1;                                                 //Control the repeat in sd initialization

// //CMD_INPUT
// logic [5:0]     cmd_counter, cmd_counter_n;                                     // Used to count the number of bits received

// //CMD_RESPONSE 
// logic [6:0]     read_40, read_40_n;                                             //Reading in response timer

// //IDLE
// logic [31:0] address, address_n;                                                //Address for writing/reading

// logic [7:0] read_byte, read_byte_n; 
// logic [5:0] timer_50, timer_50_n; 
// logic [6:0] read_in_timer, read_in_timer_n;
// logic read_in_40, read_in_40_n;
// logic read_cmd_en, read_cmd_en_n, write_cmd_en, write_cmd_en_n, warmup_enable, warmup_enable_n, freq_flag_n; // Used to enable the read command
// logic cmd_en_n; // Used to enable the command
// logic redo, redo_n; // Used to redo the command if the response is not valid
// logic read_stop_en, read_stop_en_n; // Used to enable the read stop

// always_ff @(posedge clk, posedge rst) begin
//     if (rst) begin
//         //GENERAL
//         state <= WARMUP;   
//         cmd_line <= '0;

//         //WARMUP
//         warmup_counter <= '0;  

//         //CMD_CHOOSE
//         redo_init <= 1;

//         //CMD_INPUT
//         cmd_counter <= '0;

//         //CMD_RESPONSE
//         read_40 <= '0;

//         //IDLE
//         address <= '0;

//     end else if (serial_clk) begin
//         //GENERAL
//         state <= state_n;
//         cmd_line <= cmd_line_n;

//         //WARMUP
//         warmup_counter <= warmup_counter_n; // Counter for the warmup

//         //CMD_CHOOSE
//         redo_init <= redo_init_n;

//         //CMD_INPUT
//         cmd_counter <= cmd_counter_n; // Counter for the number of bits received

//         //CMD_RESPONSE
//         read_40 <= read_40_n;

//         //IDLE
//         address <= address_n;

//         enables <= enables_n;
//         command <= command_n;
//         read_byte <= read_byte_n;
//         warmup_enable <= warmup_enable_n; // Enable warmup to stabilize the SD
//         read_in_40 <= read_in_40_n; // Enable the read in 40 bits
//         read_in_timer <= read_in_timer_n; // Timer for reading in 40 bits
//         timer_50 <= timer_50_n; // Timer for 50 clock cycles
//         read_cmd_en <= read_cmd_en_n; // Enable the read command
//         cmd_en <= cmd_en_n; // Enable the command
//         write_cmd_en <= write_cmd_en_n; // Enable the write command
//         read_cmd_en <= read_cmd_en_n; // Enable the read command  
//         redo <= redo_n;
//         read_stop_en <= read_stop_en_n; // Enable the read stop
//         freq_flag <= freq_flag_n;
//     end
// end

// // INIT Logic Block
// always_comb begin
//     //GENERAL
//     state_n = state;
//     cmd_line_n = cmd_line;
//     slave_select = 0;
//     mosi = 1;

//     //WARMUP
//     warmup_counter_n = warmup_counter;

//     //CMD_CHOOSE
//     redo_init_n = redo_init;

//     //CMD_INPUT
//     cmd_counter_n = cmd_counter;

//     //CMD_RESPONSE
//     read_40_n = read_40;

//     //IDLE
//     address_n = address;

//     //READING
//     reading = 0;
//     read_output = 0;

//     finish = 0;
//     redo_n = redo;
//     read_stop_en_n = read_stop_en;
//     freq_flag_n = freq_flag;

//     case (state)
//         WARMUP: begin
//             freq_flag_n = 0;
//             if (warmup_counter < 75) begin
//                 warmup_counter_n = warmup_counter + 1; // Warmup counter to stabilize the SD
//                 mosi = 1;
//                 slave_select = 1;
//             end 
//             else begin
//                 state_n = CMD_INPUT;
//                 cmd_line_n = CMD_0;
//                 warmup_counter_n = 0;
//                 slave_select = 1; 
//             end
//         end
//         CMD_CHOOSE: begin
//             case(cmd_line[45:40])
//                 '0: begin //CMD_0
//                     cmd_line_n= CMD_8;
//                     state_n = CMD_INPUT;
//                 end
//                 8: begin //CMD_8
//                     cmd_line_n = CMD_55;
//                     state_n = CMD_INPUT;
//                 end
//                 55: begin //CMD_55
//                     cmd_line_n = CMD_41;
//                     state_n = CMD_INPUT;
//                 end
//                 41: begin //ACMD_41
//                     if(redo_init) begin
//                         cmd_line_n = CMD_8;
//                         state_n = CMD_CHOOSE;
//                     end
//                     else begin
//                         redo_init_n = 0;
//                         cmd_line_n = CMD_58;
//                         state_n = CMD_INPUT;
//                     end
//                 end
//                 58: begin //CMD_58
//                     cmd_line_n = '0;
//                     state_n = IDLE;
//                 end
//                 18: begin //CMD_18
//                     cmd_line_n = '0;
//                     state_n = READING;
//                 end
//                 12: begin //CMD_12
//                     cmd_line_n = '0;
//                     state_n = IDLE;
//                 end
//                 25: begin //CMD_25
//                     cmd_line_n = '0;
//                     state_n = WRITING;
//                 end
//             endcase
//         end
//         CMD_INPUT: begin
//             slave_select = 0;
//             if (cmd_counter == 47) begin
//                 cmd_counter_n = 0;                      // Reset the index counter after sending the command
//                 state_n = CMD_RESPONSE;
//             end
//             else if (cmd_counter < 47) begin
//                 cmd_counter_n = cmd_counter + 1;        // Increment the index counter for each bit
//             end
//             mosi = cmd_line[47 - cmd_counter];          // Shift out the command bit
//         end
//         CMD_RESPONSE: begin
//             if(read_40 < 40) begin
//                 read_40_n = read_40 + 1;
//             end else begin
//                 read_40_n = '0;
//                 state_n = CMD_CHOOSE;
//             end
//         end
//         IDLE: begin
//             freq_flag_n = 1;
//             if(read_en) begin
//                 cmd_line_n = cmd_18;
//                 address = '0;
//                 state_n = CMD_INPUT;
//             end
//             else if(write_en) begin
//                 cmd_line_n = cmd_25;
//                 address = '0;
//                 state_n = CMD_INPUT;
//             end
//         end
//         READING: begin
//             if(read_stop) begin
//                 cmd_line_n = CMD_12;
//                 state_n = CMD_INPUT;
//             end
//             else begin
//                 state_n = READING;
//                 read_output = miso;
//                 reading = 1;
//             end
//         end
//         WRITING: begin
//             if(write_stop) begin
//                 state_n = WRITE_STOP;
//             end
//             else begin
//                 state_n = WRITING;
//                 mosi = writebit;
//             end
//         end
//         WRITE_STOP: begin
            
//         end
//     endcase
// end
// endmodule