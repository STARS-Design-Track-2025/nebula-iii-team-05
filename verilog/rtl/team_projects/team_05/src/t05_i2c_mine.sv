module t05_i2c
(
   input logic clk, rst, rs_in, en, sda_in,line,
   input logic [7:0] lcdData,
   output logic scl,sda,
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


    logic sda_n, scl_n, dshift;
    logic [4:0] transmissionCount, transmissionCount_n;
    logic [7:0] lcdData_reg, lcdData_reg_n; // shift registers

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
            sda <= sda_n;
            transmissionCount <= transmissionCount_n;
            lcdData_reg <= lcdData_reg_n;
        end
    end

    always_comb begin
        state_n = state;
        scl_n = scl;
        sda_n = sda;
        transmissionCount_n = transmissionCount + 1;

        if (transmissionCount < 10) begin
            if(line) begin // 2nd line

            end else begin // 1st line

            end
        end else begin

        end

        case (state)

            INIT: begin
                //#50ms;
                lcdData_reg_n = 8'b00000001;
                #1;
                for ( int a = 0; a < 9; a++ ) begin // normal data shifting
                    sda_n = lcdData[7];
                    lcdData_reg_n = {lcdData[6:0], 1'b0};
                end
            end
            IDLE: begin
                if(en) begin
                    state_n = CLEAR;
                end else begin
                    state_n = IDLE;
                end
            end
            CLEAR: begin
                lcdData_reg_n = 8'b00000001; // clear display command
                #1;
                for ( int a = 0; a < 9; a++ ) begin // normal data shifting
                    sda_n = lcdData[7];
                    lcdData_reg_n = {lcdData[6:0], 1'b0};
                end
                // #?
                lcdData_reg_n = 8'b00000010; // return home command
                #1;
                for ( int a = 0; a < 9; a++ ) begin // normal data shifting
                    sda_n = lcdData[7];
                    lcdData_reg_n = {lcdData[6:0], 1'b0};
                end
                transmissionCount_n = 0;

                state_n = SEND; // go to send state
            end
            SEND: begin
                if (transmissionCount < 9) begin // what line to write to
                    if (line) begin // 2nd line
                        lcdData_reg_n = 8'b11000000;
                        #1;
                        for ( int i = 0; i < 12; i++ ) begin // add padding bits
                            sda_n = lcdData[7];
                            if (i == 4 || i == 5 || i == 11 || i == 12)begin
                                sda_n = 1'b0; // padding bits
                            end else begin
                                lcdData_reg_n = {lcdData[6:0], 1'b0};
                            end
                        end
                        // #?
                    end else begin // 1st line
                        lcdData_reg_n = 8'b10000000;
                        #1;
                        for ( int j = 0; j < 12; j++ ) begin // add padding bits
                            sda_n = lcdData[7];
                            if (j == 4 || j == 5 || j == 11 || j == 12)begin
                                sda_n = 1'b0; // padding bits
                            end else begin
                                lcdData_reg_n = {lcdData[6:0], 1'b0};
                            end
                        end
                        // #?
                    end
                end else begin
                    lcdData_reg_n = lcdData;
                    #1;
                    for ( int k = 0; k < 9; k++ ) begin // normal data shifting
                        sda_n = lcdData[7];
                        lcdData_reg_n = {lcdData[6:0], 1'b0};
                    end
                    if (transmissionCount == 18) begin
                        transmissionCount_n = transmissionCount;
                    end
                    if (transmissionCount == 18 && ~sda_in) begin
                        state_n = IDLE;
                    end
                end
            end
        endcase
    end

endmodule