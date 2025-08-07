module t05_1602_spi #(
    parameter WIDTH = 10,                    // Number of bits to transmit
    parameter CLK_DIV = 4                   // Clock divider (system_clk / CLK_DIV = spi_clk)
) (
    input  logic                clk,        // System clock
    input  logic                rst_n,      // Active low reset
    input  logic                start,      // Start transmission (pulse)
    input  logic [WIDTH-1:0]    data_in,    // Data to transmit
    output logic                sdo,        // Serial data out (MOSI)
    output logic                sclk,       // SPI clock
    output logic                cs_n,       // Chip select (active low)
    output logic                busy,       // Transmission in progress
    output logic                done        // Transmission complete (pulse)
);

    // Internal signals
    logic [$clog2(CLK_DIV)-1:0] clk_counter_q, clk_counter_d;
    logic [$clog2(WIDTH + 1)-1:0]   bit_counter_q, bit_counter_d;
    logic [WIDTH-1:0]           shift_reg_q, shift_reg_d;
    logic                       spi_clk_q, spi_clk_d;
    logic                       spi_clk_en;
    logic [$clog2(CLK_DIV + 1) - 1:0] cs_low_counter_q, cs_low_counter_d;
    
    // State machine
    typedef enum logic [2:0] {
        IDLE    = 3'b000,
        ACTIVE  = 3'b001,
        FINISH  = 3'b010,
        CS_LOW  = 3'b011,
        CS_LOW1 = 3'b100
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
        
        if (state_q == ACTIVE) begin
            if (clk_counter_q == CLK_DIV/2 - 1) begin
                clk_counter_d = '0;
                spi_clk_d = ~spi_clk_q;
                spi_clk_en = 1'b1;
            end else begin
                clk_counter_d = clk_counter_q + 1;
            end
        end else begin
            clk_counter_d = '0;
            spi_clk_d = 0;
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
    
    // Combinational logic for state machine
    always_comb begin
        state_d = state_q;
        cs_n = 1;
        case (state_q)
            IDLE: begin
                if (start) begin
                    state_d = CS_LOW;
                end
            end
            CS_LOW: begin
                if (cs_low_counter_q == CLK_DIV - 1) begin
                    state_d = ACTIVE;
                end
                cs_n = 0;
            end
            ACTIVE: begin
                if (bit_counter_q == WIDTH - 1 && spi_clk_en) begin
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
            default: state_d = IDLE;
        endcase
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
        end else if (state_q == ACTIVE && spi_clk_en && sclk == 1) begin
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
            shift_reg_d = data_in;  // Load new data
        end else if (state_q == ACTIVE && spi_clk_en) begin
            // Shift on the appropriate clock edge based on CPHA
            if (spi_clk_q) begin
                if (WIDTH > 1) begin
                    shift_reg_d = {shift_reg_q[WIDTH-2:0], 1'b0};  // Shift left (MSB first)
                end else begin
                    shift_reg_d = 10'b0;  // Special case for WIDTH=1
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
    
    // Output assignments (combinational)
    assign sclk = (state_q == ACTIVE) ? spi_clk_q : 1;
    assign sdo = shift_reg_q[WIDTH-1];  // Always output MSB
    assign busy = !cs_n;
    assign done = (state_q == FINISH);

endmodule