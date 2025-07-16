    module t05_SPI (
        input mosi, // Write
        output miso, // Read
        input serial_clk,
        input slave_select,
        output logic [7:0] read_output,
    );

    // Shift Register
    commands [47:0]cmd_line, cmd_line_n; 
    state_t state, state_n;
    logic [7:0] read_byte, read_byte_n; 
    logic [39:0] response_holder; // Used to hold the response byte
    logic [6:0] warmup_counter, warmup_counter_n; // Used to stabilize the SD before data transfer begin
    logic [4:0] index_counter, index_counter_n; // Used to count the number of bits received
    logic enable_0, enable_0_n, idle_enable, idle_enable_n; // Used to enable the first bit of the command
    logic enable_8, enable_8_n; 
    logic enable_55, enable_55_n; 
    logic [5:0] timer_50, timer_50_n; 
    logic enable_41, enable_41_n; 
    logic response_enable, response_enable_n; 
    logic [5:0] read_in_timer, read_in_timer_n;
    logic read_in_40, read_in_40_n;
    logic warmup_enable, warmup_enable_n;
    logic [31:0] read_address, read_address_n; 

    typedef enum logic{
        INIT = 0,
        READ = 1,
        WRITE = 2,
        DONE = 3
    } state_t;

    typedef enum logic { 
        CMD0 = 48'b010000000000000000000000000000000000000010010101 // To go into IDLE STATE
        CMD58 = 48'b011110100000000000000000000000000000000001110101 // OCR Conditions
        CMD55 = 48'b011101110000000000000000000000000000000001100101 // Prepares the SD Card for the next command
        ACMD41 = 48'b011010010100000000000000000000000000000000000001 // Exits initialization mode and begn the data transfer
        CMD18 = {01010010, read_address, 00000001} // Read multiple blocks until termination code
        CMD12 = 48'b010011000000000000000000000000000000000000000001 // Stop reading multiple blocks
        CMD24 = 48'b01011000 /* ARGUMENT ADDRESS */ 00000001 // Write single 
        CMD8 =  48'b010010000000000000000000000000011010101010000111 // Check the voltage range and if the card is compatible
    } commands;
    
        always_ff @(posedge clock, posedge reset) begin
            if (reset) begin
                cmd_line <= CMD0; // Reset with CMD0
                state <= INIT;
                read_byte <= '0;
            end else begin
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
                        response_holder = {response_holder[38:0], mosi}; // Shift in data on MOSI
                        if(read_in_timer < 40) begin
                            read_in_timer_n = read_in_timer + 1;
                        end else begin
                            read_in_tiner_n = 0;
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
                        if (index_counter == 48) begin
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
                        cmd_line = CMD55; 
                        cmd_en_n = 1;
                        if (timer_50 < 50) begin
                            timer_50_n = timer_50 + 1; // Increment the timer for 50 clock cycles
                        end else begin
                            enable_41_n = 1; // Enable the ACMD41 command after 50 clock cycles
                            enable_55_n = 0;
                            timer_50_n = 0;  
                        end
                    end 
                    
                    else if (enable__41) begin 
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
                    cmd_line_n = CMD18;
                        if (index_counter == 48) begin
                            index_counter_n = 0; // Reset the index counter after sending the command
                            cmd_en_n = 0;
                        end
                        if (index_counter < 48) begin
                            index_counter_n = index_counter + 1; // Increment the index counter for each bit
                        end
                        mosi = cmd_line[47 - index_counter]; // Shift out the command bit


                    if (read_in_timer < 8) begin
                        read_in_timer_n = read_in_timer + 1; // Increment the read-in timer for each bit
                        read_byte_n = {read_byte[6:0], miso}; // Shift in data on MISO
                    end else begin
                        read_output = read_byte; 
                        read_in_timer_n = 0; 
                    end
                end
            end
            WRITE: begin
                // Logic for writing data to MISO can be added here
            end

            DONE: begin
                // Logic for finalizing the operation can be added here
            end

            default: state_n = INIT; // Reset to INIT on unexpected state
        endcase
    end
    endmodule