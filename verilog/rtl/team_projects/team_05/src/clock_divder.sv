module slow_clock_signal (
    input  logic current_clock_signal,
    input  logic reset,
    output logic divided_clock_signal,
    output logic init_completed
);
    logic [6:0] warmup_counter;
    logic       spi_toggle;
    logic [4:0] spi_counter;
    
    always_ff @(posedge current_clock_signal or posedge reset) begin // too much logic in always comb
        if (reset) begin
            warmup_counter       <= 0;
            init_completed       <= 0;
            spi_counter          <= 0;
            spi_toggle           <= 0;
            divided_clock_signal <= 0;
        end else begin
            if (!init_completed) begin
                if (warmup_counter < 74)
                    warmup_counter <= warmup_counter + 1;
                else
                    init_completed <= 1;
            end else begin
                // Generate slower SPI clock (~400kHz from 12MHz)
                if (spi_counter == 14) begin // 12 MHz / (2 * 15) = 400kHz
                    spi_counter          <= 0;
                    spi_toggle           <= ~spi_toggle;
                    divided_clock_signal <= ~spi_toggle;  // Fixed: use new toggle value
                end else begin
                    spi_counter <= spi_counter + 1;
                end
            end
        end
    end
endmodule