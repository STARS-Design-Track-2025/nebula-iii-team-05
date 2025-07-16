module t05_spiClockDivider (
    input  logic current_clock_signal,
    input  logic reset,
    output logic divided_clock_signal
);
    logic [9:0] counter, counter_n; 
    logic divided_clock_signal_n; 

        // Regsiters
    always_ff @(posedge current_clock_signal or posedge reset) begin 
        if (reset) begin
            counter <= 0;
            divided_clock_signal <= 0;
        end else begin
            counter <= counter_n;
            divided_clock_signal <= divided_clock_signal_n; 
        end
    end
    always_comb begin
        counter_n = counter;
        divided_clock_signal_n = divided_clock_signal;
        if(counter < 512) begin
            counter_n = counter + 1;
            divided_clock_signal_n = 0; // Keep the divided clock low until the counter reaches 512
        end else begin
            counter_n = 0; // Reset the counter after reaching 512
            divided_clock_signal_n = ~divided_clock_signal; // Toggle the divided clock signal
        end
    end
endmodule