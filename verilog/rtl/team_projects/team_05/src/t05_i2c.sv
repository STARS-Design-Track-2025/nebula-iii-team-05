module t05_i2c
(
   input logic clk, rst, rs_in, en, sda_in,
   input logic [7:0] lcdData,
   output logic scl, sda,
   output logic newData
);

    //  CLK DIVIDER

    logic [8:0] counter, counter_n;
    logic clkdiv, clkdiv_temp;
    
    always_ff @(posedge clk or posedge rst) begin
        if(rst) begin
            counter <= 0;
            clkdiv <= 0;
        end else begin
            counter <= counter_n;
            clkdiv <= clkdiv_temp;
        end 
    end

    always_comb begin
        counter_n = counter + 1;
        clkdiv_temp = clkdiv;
        if(counter == 9'd400) begin
            clkdiv_temp = ~clkdiv;
        end
    end


    // STATE MACHINE

    logic sda_n, scl_n;

    typedef enum logic [1:0] {
        INIT,
        IDLE,
        CLEAR,
        SEND
    } state_t;

    state_t state, state_n;

    always_ff @(posedge clkdiv or posedge rst) begin
        if(rst) begin
            state <= INIT;
            scl <= 0;
            sda <= 0;
            newData <= 0;
        end else begin
            state <= state_n;
            newData <= 0; //?
            scl <= scl_n;
            sda <= s;
        end
    end

    always_comb begin
        state_n = state;
        case (state)

            INIT: begin
                
            end
            IDLE: begin
                if(en) begin
                    state_n = SEND;
                end
            end
            SEND: begin
                // Logic to send data goes here
                // For example, set scl and sda based on lcdData
                // After sending, transition back to IDLE or another state
                state_n = IDLE; // Placeholder for next state logic
            end
        endcase
    end

endmodule