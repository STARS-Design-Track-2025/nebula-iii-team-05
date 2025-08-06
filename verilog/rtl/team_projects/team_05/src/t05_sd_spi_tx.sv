module t05_sd_spi_tx #(
    parameter WIDTH = 48,           // Number of bits to transmit
    parameter CLK_DIV = 4           // Clock divider (system_clk / CLK_DIV = spi_clk)
) (
    input  logic        clk,        // System clock
    input  logic        rst_n,      // Active low reset
    input  logic        start,      // Start transmission (pulse)
    input  logic [5:0]  command,    // 6-bit command to SD card
    input  logic [31:0] argument,   // 32-bit command argument
    input  logic [6:0]  crc,        // 7-bit cyclic redundancy check
    input  logic        write_mode, // 0: Command, 1: continuous write
    input  logic        ser_w_data, // Serial write data from translation
    input  logic        input_valid,// Provided serial input is valid
    output logic        ser_pulse,  // Pulse to request new serial data
    output logic        sdo,        // Serial data out (MOSI)
    output logic        sclk,       // SPI clock
    output logic        cs_n,       // Chip select (active low)
    output logic        busy,       // Transmission in progress
    output logic        done        // Transmission complete (pulse)
);

    // Internal signals
    logic [WIDTH - 1:0] data_in;
    assign data_in = {2'b01, command, argument, crc, 1'b1};
    logic [$clog2(CLK_DIV)-1:0] clk_counter_q, clk_counter_d;
    logic [$clog2(WIDTH + 2)-1:0]   bit_counter_q, bit_counter_d;
    logic [12:0] serial_bit_count_q, serial_bit_count_d;
    logic [WIDTH:0]           shift_reg_q, shift_reg_d;
    logic                       spi_clk_q, spi_clk_d;
    logic                       spi_clk_en;
    logic [$clog2(CLK_DIV + 1) - 1:0] cs_low_counter_q, cs_low_counter_d;
    
    // State machine
    typedef enum logic [2:0] {
        IDLE          = 3'b000,
        ACTIVE        = 3'b001,
        FINISH        = 3'b010,
        CS_LOW        = 3'b011,
        CS_LOW1       = 3'b100,
        SER_WRITE     = 3'b101,
        WRITE_CRC     = 3'b110,
        RESPONSE_WAIT = 3'b111
    } state_t;
    
    state_t state_q, state_d;
    
    // Combinational logic for clock generation
    always_comb begin
        clk_counter_d = clk_counter_q;
        spi_clk_d = spi_clk_q;
        spi_clk_en = 1'b0;
        cs_low_counter_d = '0;

        if (cs_low_counter_q < CLK_DIV && state_q != IDLE && state_q != ACTIVE) begin
            cs_low_counter_d = cs_low_counter_q + 1;
        end
        
        if (state_q != CS_LOW && state_q != CS_LOW1) begin //also clock in serial write mode
            if (clk_counter_q == CLK_DIV/2 - 1) begin
                clk_counter_d = '0;
                spi_clk_d = ~spi_clk_q;
                spi_clk_en = 1'b1;
            end else begin
                clk_counter_d = clk_counter_q + 1;
            end
        end else begin
            clk_counter_d = '0;
            spi_clk_d = (state_q == ACTIVE || is_ser) ? spi_clk_q : 1;
        end
    end
    
    // Sequential logic for clock generation
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            clk_counter_q <= '0;
            spi_clk_q <= 0;
            cs_low_counter_q <= '0;
        end else begin
            clk_counter_q <= clk_counter_d;
            spi_clk_q <= spi_clk_d;
            cs_low_counter_q <= cs_low_counter_d;
        end
    end
    logic write_mode_l;
    always_ff @(posedge clk, negedge rst_n) begin
      if (!rst_n) begin
        write_mode_l <= 0;
      end else begin
        write_mode_l <= write_mode;
      end
    end

    always_ff @(posedge clk, negedge rst_n) begin
      if (!rst_n) begin
        serial_bit_count_q <= '0;
      end else begin
        serial_bit_count_q <= serial_bit_count_d;
      end
    end
    logic end_wait;
    always_comb begin
      serial_bit_count_d = serial_bit_count_q;
      if (ser_pulse_1 && (is_ser)) begin
        serial_bit_count_d = serial_bit_count_q + 1;
      end else if (state_q == CS_LOW1 || end_wait) begin
        serial_bit_count_d = '0;
      end
    end
    
    // Combinational logic for state machine
    always_comb begin
        state_d = state_q;
        cs_n = 1;
        end_wait = 0;
        case (state_q)
            IDLE: begin
                if (start) begin
                    state_d = CS_LOW;
                end
            end
            CS_LOW: begin
                if (cs_low_counter_q == CLK_DIV - 1) begin
                  if (write_mode) begin
                    state_d = SER_WRITE;
                  end else begin
                    state_d = ACTIVE;
                  end
                end
                cs_n = 0;
            end
            ACTIVE: begin
                if (bit_counter_q == WIDTH && spi_clk_en) begin
                    state_d = CS_LOW1;
                end
                cs_n = 0;
            end
            CS_LOW1: begin
                if (cs_low_counter_q == CLK_DIV - 1) begin
                    state_d = FINISH;
                end
                cs_n = 0;
            end
            FINISH: begin
                state_d = IDLE;
            end
            SER_WRITE: begin
              //serial write code in here

              if ((!write_mode && serial_bit_count_q > 512*8-1) || serial_bit_count_q > 512*8-1) begin
                state_d = WRITE_CRC;
              end
              cs_n = 0;
            end
            WRITE_CRC: begin
              if (serial_bit_count_q > 514*8-1) begin //send dummy 2-byte CRC
                state_d = RESPONSE_WAIT;
              end
              cs_n = 0;
            end
            RESPONSE_WAIT: begin
              if (serial_bit_count_q > 512*8+100) begin
                if (write_mode) begin
                  state_d = SER_WRITE;
                end else begin
                  state_d = CS_LOW1;
                end
                end_wait = 1;
              end
              cs_n = 0;
            end
            default: state_d = IDLE;
        endcase
        if (write_mode && !write_mode_l) begin
          state_d = CS_LOW;
        end
    end
    
    // Sequential logic for state machine
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_q <= IDLE;
        end else begin
            state_q <= state_d;
        end
    end
    
    // Combinational logic for bit counter
    always_comb begin
        bit_counter_d = bit_counter_q;
        
        if (state_q == IDLE) begin
            bit_counter_d = '0;
        end else if (state_q == ACTIVE && spi_clk_en && sclk_1 == 1) begin
            // Increment on the appropriate clock edge based on CPHA
            bit_counter_d = bit_counter_q + 1;
        end
    end
    
    // Sequential logic for bit counter
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bit_counter_q <= '0;
        end else begin
            bit_counter_q <= bit_counter_d;
        end
    end
    
    // Combinational logic for shift register
    always_comb begin
        shift_reg_d = shift_reg_q;
        
        if (state_q == IDLE && start) begin
            shift_reg_d = {1'b0, data_in};  // Load new data
        end else if (state_q == ACTIVE && spi_clk_en) begin
            // Shift on the appropriate clock edge based on CPHA
            if (spi_clk_q) begin
                if (WIDTH > 1) begin
                    shift_reg_d = {shift_reg_q[WIDTH-1:0], 1'b0};  // Shift left (MSB first)
                end else begin
                    shift_reg_d = 1'b0;  // Special case for WIDTH=1
                end
            end
        end
    end
    
    // Sequential logic for shift register
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg_q <= '0;
        end else begin
            shift_reg_q <= shift_reg_d;
        end
    end

    logic ser_w_data_q, ser_w_data_d;
    always_ff @(posedge clk, negedge rst_n) begin
      if (!rst_n) begin
        ser_w_data_q <= 0;
      end else begin
        ser_w_data_q <= ser_w_data_d;
      end
    end

    always_comb begin
      ser_w_data_d = ser_w_data_q;
      if (input_valid) begin
        ser_w_data_d = ser_w_data;
      end
    end
    logic sclk_1, ser_pulse_1;
    logic is_ser;
    assign is_ser = (state_q == SER_WRITE || state_q == WRITE_CRC || state_q == RESPONSE_WAIT);
    // Output assignments (combinational)
    assign sclk_1 = (state_q == ACTIVE || is_ser) ? spi_clk_q : 1;
    assign sclk = (state_q == RESPONSE_WAIT) || (serial_bit_count_q == 0 && is_ser) ? 1 : sclk_1;
    assign sdo  = is_ser ? write_mode ? ser_w_data_q : 0 : shift_reg_q[WIDTH];  // Always output MSB
    assign busy = !cs_n;
    assign done = (state_q == FINISH);
    assign ser_pulse_1 = spi_clk_q && !spi_clk_d && is_ser; //on negedge
    assign ser_pulse = (state_q == SER_WRITE) ? ser_pulse_1 : 0;

endmodule