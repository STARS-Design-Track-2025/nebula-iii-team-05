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
    output logic slave_select,
    output logic [7:0] read_output,
    input logic writebit,
    input logic read_en, write_en, read_stop,
    input logic [31:0] read_address, write_address,
    output logic finish 
);

localparam
    CMD0 = 48'b010000000000000000000000000000000000000010010101, // To go into IDLE STATE
    CMD58 = 48'b011110100000000000000000000000000000000001110101, // OCR Conditions
    CMD55 = 48'b011101110000000000000000000000000000000001100101, // Prepares the SD Card for the next command
    ACMD41 = 48'b011010010100000000000000000000000000000000000001, // Exits initialization mode and begn the data transfer
    CMD12 = 48'b010011000000000000000000000000000000000000000001, // Stop reading multiple blocks
    CMD8 =  48'b010010000000000000000000000000011010101010000111; // Check the voltage range and if the card is compatible

logic [47:0] cmd18;
assign cmd18 = {8'b01010010, read_address, 8'b00000001};  // Read multiple blocks until termination code
logic [47:0] cmd24; 
assign cmd24 = {8'b01011000, write_address, 8'b00000001}; // Write single 

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
logic [6:0] read_in_timer, read_in_timer_n;
logic read_in_40, read_in_40_n;
logic read_cmd_en, read_cmd_en_n, write_cmd_en, write_cmd_en_n; // Used to enable the read command
logic cmd_en, cmd_en_n; // Used to enable the command
logic command2, command2_n; // Used to enable the second command
logic command3, command3_n; // Used to enable the third command
logic command4, command4_n; // Used to enable the fourth command
logic command5, command5_n; // Used to enable the fifth command
logic enable_58, enable_58_n; // Used to enable the fifth bit of the
logic redo, redo_n; // Used to redo the command if the response is not valid
logic read_stop_en, read_stop_en_n; // Used to enable the read stop

always_ff @(posedge clk, posedge rst) begin
    if (rst) begin
        cmd_line <= CMD0; // Reset with CMD0
        state <= INIT;
        read_byte <= '0;
        idle_enable <= 0;
        warmup_enable <= 1; // Enable warmup to stabilize the SD
        response_holder <= '0;
        response_enable <= 0;
        enable_0 <= 0; // Enable the first bit of the command
        enable_8 <= 0; // Enable the second bit of the command
        enable_55 <= 0; // Enable the third bit of the command
        enable_41 <= 0; // Enable the fourth bit of the command
        read_in_40 <= 0; // Enable the read in 40 bits
        read_in_timer <= 0; // Timer for reading in 40 bits
        index_counter <= 0; // Counter for the number of bits received
        timer_50 <= 0; // Timer for 50 clock cycles
        read_cmd_en <= 1; // Enable the read command
        cmd_en <= 0; // Enable the command
        warmup_counter <= 0; // Counter for the warmup
        write_cmd_en <= 0; // Enable the write command
        read_cmd_en <= 0; 
        command2 <= 0;
        command3 <= 0;
        command4 <= 0;
        command5 <= 0; // Enable the fifth command
        enable_58 <= 0; // Enable the fifth bit of the command
        redo <= 1;
        read_stop_en <= 1; // Enable the read stop
    end else if (serial_clk) begin
        cmd_line <= cmd_line_n;
        state <= state_n;
        read_byte <= read_byte_n;
        idle_enable <= idle_enable_n;
        warmup_enable <= warmup_enable_n; // Enable warmup to stabilize the SD
        response_holder <= response_holder_n;
        response_enable <= response_enable_n;
        enable_0 <= enable_0_n; // Enable the first bit of the command
        enable_8 <= enable_8_n; // Enable the second bit of the command
        enable_55 <= enable_55_n; // Enable the third bit of the command
        enable_41 <= enable_41_n; // Enable the fourth bit of the command
        read_in_40 <= read_in_40_n; // Enable the read in 40 bits
        read_in_timer <= read_in_timer_n; // Timer for reading in 40 bits
        index_counter <= index_counter_n; // Counter for the number of bits received
        timer_50 <= timer_50_n; // Timer for 50 clock cycles
        read_cmd_en <= read_cmd_en_n; // Enable the read command
        cmd_en <= cmd_en_n; // Enable the command
        warmup_counter <= warmup_counter_n; // Counter for the warmup
        write_cmd_en <= write_cmd_en_n; // Enable the write command
        read_cmd_en <= read_cmd_en_n; // Enable the read command  
        command2 <= command2_n; 
        command3 <= command3_n;
        command4 <= command4_n; // Enable the fourth command
        command5 <= command5_n; // Enable the fifth command
        enable_58 <= enable_58_n; // Enable the fifth bit of the command
        redo <= redo_n;
        read_stop_en <= read_stop_en_n; // Enable the read stop
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
    mosi = 1;
    read_output = '0;
    cmd_en_n = cmd_en;
    idle_enable_n = idle_enable;
    write_cmd_en_n =  write_cmd_en;
    slave_select = 0;
    finish = 0;
    command2_n = command2;
    command3_n = command3;
    command4_n = command4;
    command5_n = command5;
    enable_58_n = enable_58;
    redo_n = redo;
    read_stop_en_n = read_stop_en;

    case (state)
        INIT: begin
            if(warmup_enable) begin 
                if (warmup_counter < 75) begin
                    warmup_counter_n = warmup_counter + 1; // Warmup counter to stabilize the SD
                    mosi = 1;
                    slave_select = 1;
                end 
                else begin
                    enable_0_n = 1; // Enable the first bit of the command
                    warmup_enable_n = 0;
                    warmup_counter_n = 0; // Reset the warmup counter
                    slave_select = 1;
                end
            end else begin
                if(read_in_40) begin
                    if(read_in_timer < 39) begin
                        response_holder_n = {response_holder[38:0], miso}; // Shift in data on MISO
                    end
                    if(read_in_timer < 120) begin
                        read_in_timer_n = read_in_timer + 1;
                    end else begin
                        read_in_timer_n = 0;
                        read_in_40_n = 0;
                        response_enable_n = 1;
                    end
                end

            // Response for CMD0 
                if (cmd_en) begin
                    slave_select = 0;
                    if (index_counter == 47) begin
                        index_counter_n = 0; // Reset the index counter after sending the command
                        cmd_en_n = 0;
                    end
                    else if (index_counter < 47) begin
                        index_counter_n = index_counter + 1; // Increment the index counter for each bit
                    end
                    mosi = cmd_line[47 - index_counter]; // Shift out the command bit
                end 

                if (response_enable) begin
                    response_enable_n = 0; 
                    if (idle_enable) begin
                        enable_8_n = 1;
                        idle_enable_n = 0;
                        response_holder_n = '0; // Reset the response holder after reading the response
                    end 
                    // Response for CMD8
                    else if (command2) begin
                        enable_55_n = 1;
                        response_holder_n = '0; // Reset the response holder after reading the response
                        enable_8_n = 0;
                        command2_n = 0; // Reset the command2 flag
                    end
                    // Response for ACMD41
                    else if (command4) begin
                        //state_n = READ;
                        response_holder_n = '0; // Reset the response holder after reading the response
                        //read_cmd_en_n = 1; // Enable the read command
                        command4_n = 0;
                        enable_41_n = 0;
                        if(redo) begin
                            redo_n = 0;
                            command2_n = 1;
                            response_enable_n = 1;
                        end else
                            enable_58_n = 1; // Enable the fifth bit of the command
                    end
                    else if (command3) begin
                        enable_41_n = 1;
                        enable_55_n = 0;
                        response_holder_n = '0; // Reset the response holder after reading the response 
                        command3_n = 0; // Reset the command3 flag
                    end
                    else if (command5) begin
                        //enable_58_n = 1;
                        state_n = READ;
                        read_cmd_en_n = 1;
                        response_holder_n = '0; // Reset the response holder after reading the response 
                        command5_n = 0; // Reset the command3 flag
                    end
                end 

                else if(enable_0) begin
                    cmd_line_n = CMD0; 
                    if (timer_50 < 50) begin
                        timer_50_n = timer_50 + 1; // Increment the timer for 50 clock cycles
                        if(timer_50 < 48) begin
                            cmd_en_n = 1;
                        end
                    end else if (timer_50 > 49) begin
                        timer_50_n = 0; 
                        read_in_40_n = 1; 
                        enable_0_n = 0;
                        idle_enable_n = 1;
                        cmd_en_n = 0;
                    end
                    else if(miso == 0) begin
                        response_enable_n = 1;
                    end
                end
                
                else if (enable_8) begin
                    cmd_line_n = CMD8; 
                    if (timer_50 < 50) begin
                        timer_50_n = timer_50 + 1; // Increment the timer for 50 clock cycles
                        if(timer_50 < 48) begin
                            cmd_en_n = 1;
                             
                        end
                    end else if (timer_50 > 49) begin
                        timer_50_n = 0; 
                        enable_8_n = 0;
                        cmd_en_n = 0;
                        command2_n = 1;
                        read_in_40_n = 1;
                    end
                    else if(miso == 0) begin
                        response_enable_n = 1;
                    end
                end 
                
                else if (enable_55) begin
                    cmd_line_n = CMD55; 

                    if (timer_50 < 50) begin
                        timer_50_n = timer_50 + 1; // Increment the timer for 50 clock cycles
                        if(timer_50 < 48) begin
                            cmd_en_n = 1;
                            
                        end
                    end else if (timer_50 > 49) begin
                        enable_55_n = 0;
                        timer_50_n = 0;  
                        cmd_en_n = 0;
                        read_in_40_n = 1;
                        command3_n = 1;
                    end
                    else if(miso == 0) begin
                        response_enable_n = 1;
                    end
                end 
                
                else if (enable_41) begin 
                    cmd_line_n = ACMD41; 

                    if (timer_50 < 50) begin
                        timer_50_n = timer_50 + 1; // Increment the timer for 50 clock cycles
                        if(timer_50 < 48) begin
                            cmd_en_n = 1;
                        end 
                    end else if (timer_50 > 49) begin
                        enable_41_n = 0; 
                        timer_50_n = 0;
                        cmd_en_n = 0;
                        read_in_40_n = 1;
                        command4_n = 1; // Enable the fourth command
                    end
                    else if(miso == 0) begin
                        response_enable_n = 1;
                    end
                end
                else if (enable_58) begin 
                    cmd_line_n = CMD58; 

                    if (timer_50 < 50) begin
                        timer_50_n = timer_50 + 1; // Increment the timer for 50 clock cycles
                        if(timer_50 < 48) begin
                            cmd_en_n = 1;
                        end 
                    end else if (timer_50 > 49) begin
                        enable_58_n = 0; 
                        timer_50_n = 0;
                        cmd_en_n = 0;
                        read_in_40_n = 1;
                        command5_n = 1; // Enable the fourth command
                    end
                    else if(miso == 0) begin
                        response_enable_n = 1;
                    end
                end
            end 
        end

        READ: begin  // Logic for reading data from MISO
            if(read_en) begin
                read_output = read_byte; 
                read_in_timer_n = 0;
                if(read_cmd_en) begin
                    cmd_line_n = cmd18;
                    cmd_en_n = 1;
                    if(cmd_en) begin
                        if (index_counter == 47) begin
                            index_counter_n = 0; // Reset the index counter after sending the command
                            cmd_en_n = 0;
                            read_cmd_en_n = 0;
                        end
                        else if (index_counter < 47) begin
                            index_counter_n = index_counter + 1; // Increment the index counter for each bit
                        end
                        mosi = cmd_line[47 - index_counter]; // Shift out the command bit
                    end
                end
            end
            else if(write_en == 1 && read_stop == 1) begin
                state_n = WRITE;  
                write_cmd_en_n = 1; 
                //mosi = 0;
            end  
            else if(read_stop_en) begin
                if (read_stop)  begin
                    cmd_line_n = CMD12;    
                    cmd_en_n = 1;
                    if(cmd_en) begin
                        slave_select = 0;
                        if (index_counter == 47) begin
                            index_counter_n = 0; // Reset the index counter after sending the command
                            cmd_en_n = 0;
                            read_cmd_en_n = 0;
                            read_stop_en_n = 0;
                        end
                        else if (index_counter < 47) begin
                            index_counter_n = index_counter + 1; // Increment the index counter for each bit
                        end
                        mosi = cmd_line[47 - index_counter]; // Shift out the command bit
                    end
                end
            end
            else if (read_stop == 0 && read_en == 0) begin
                if (read_in_timer < 8) begin
                    read_in_timer_n = read_in_timer + 1; // Increment the read-in timer for each bit
                    read_byte_n = {read_byte[6:0], miso}; // Shift in data on MISO
                end else begin
                    read_in_timer_n = 0; 
                end
            end
        end
        WRITE: begin // Logic for writing data to MISO can be added here
            if(write_en) begin
                if(write_cmd_en) begin
                    cmd_line_n = cmd24;    
                    cmd_en_n = 1;
                    if(cmd_en) begin
                        if (index_counter == 47) begin
                            index_counter_n = 0; // Reset the index counter after sending the command
                            cmd_en_n = 0;
                            write_cmd_en_n = 0;
                        end
                        else if (index_counter < 47) begin
                            index_counter_n = index_counter + 1; // Increment the index counter for each bit
                        end
                        mosi = cmd_line[47 - index_counter]; // Shift out the command bit
                    end
                end
                else begin
                    mosi = writebit;
                end
            end
            else begin
                state_n = DONE; // Transition to DONE state if not writing
            end
        end

        DONE: begin // Logic for finalizing the operation can be added here
            slave_select = 1;
            if (warmup_counter < 8) begin
                warmup_counter_n = warmup_counter + 1; // Warmup counter variable is just used to stabilize the SD
            end 
            else if (warmup_counter == 8) begin
                finish = 1; // Enable the first bit of the command
            end
        end
        default: state_n = INIT; // Reset to INIT on unexpected state
    endcase
end
endmodule