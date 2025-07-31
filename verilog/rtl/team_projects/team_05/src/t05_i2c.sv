module t05_i2c
(
    input logic clk, rst, sda_i, // sda_i is what we recieve from the display (ack signal)
    input logic trans, // This is telling the i2c when to begin transmitting
    input logic [7:0] lcdData, // What data you want to send to the LCD ||
    output logic sda_o, scl, oeb,  //sda_o is data, scl is the clock line, and oeb is whether we are sending or recieving on the sda
    output logic [2:0] state, // So that the display FSM can check when you are ready for a new transmission ||
    output logic commsError,  // This tells the display FSM that we have not succeeded in getting an ack ||
    output logic ready, // This tells the display FSM that we are prepared for more data ||
    output logic [6:0] slaveAddress 
);

    // CLOCK DIVIDER

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
        if(counter == 9'd511) begin
            clkdiv_temp = ~clkdiv;
        end
    end

    // STATE MACHINE

    logic [2:0] state_n;
    logic ack, ack_n, sda_o_n, scl_n, oeb_n, complete, commsError_n, ready_n;

    typedef enum logic [2:0] {BEGINS = 3'b0, SEND = 3'b1, ACK = 3'd2, ENDS = 3'd3, OFF = 3'd4, ERROR = 3'd6} state_I2C;

    always_ff @(posedge clk or posedge rst) begin
        if(rst) begin
            state <= OFF;
            sda_o <= 0;
            scl <= 1;
            oeb <= 0;
            ack <= 0;
            commsError <= 0;
            ready <= 0;
        end else begin
            state <= state_n;
            sda_o <= sda_o_n;
            scl <= scl_n;
            oeb <= oeb_n;
            ack <= ack_n;
            commsError <= commsError_n;
            ready <= ready_n;
        end 
    end

    always_comb begin
        ready_n = 0;
        commsError_n = 0;
        case (state)
            OFF: 
            begin 
                if (trans) begin // If the effect has changed, we start a transmission
                    state_n = BEGINS;
                end else begin
                    state_n = OFF;
                end 
            end
            ACK: 
            begin
                if (complete) begin  // if we are done             
                    if (ack && transmissionCount != 2) begin // If we have recieved an ack from the slave and we need to continue                                                       
                        state_n = BEGINS;
                        ready_n = 1;
                    end else begin // If we need to end
                        state_n = ENDS;
                        commsError_n = ack ? 0 : 1; // Tells display FSM if there is a lack of ack
                    end
                end else begin
                    state_n = ACK;
                end
            end
            default:
            begin
                if (complete) begin // If we are done with our current state, go to our next state
                    state_n = state + 1'b1;
                end else begin
                    state_n = state; 
                end
                end
        endcase
    end

    // Counters
    logic [1:0] transmissionCount, transmissionCount_n;
    logic [1:0] waitCounter, waitCounter_n, endCounter, endCounter_n, beginCounter, beginCounter_n;
    logic [4:0] sendCounter, sendCounter_n;
    logic [2:0] ackCounter, ackCounter_n;
    logic [7:0] lcdDataPadded;

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            beginCounter <= 0;
            sendCounter <= 0;
            ackCounter <= 0;
            transmissionCount <= 0;
            waitCounter <= 0;
            endCounter <= 0;
        end else begin
            beginCounter <= beginCounter_n;
            sendCounter <= sendCounter_n;
            ackCounter <= ackCounter_n;
            transmissionCount <= transmissionCount_n;
            waitCounter <= waitCounter_n;
            endCounter <= endCounter_n;
        end
    end

    always_comb begin
        lcdDataPadded = 0;
        sda_o_n = sda_o;
        scl_n = scl;
        endCounter_n = endCounter;
        beginCounter_n = beginCounter;
        sendCounter_n = sendCounter;
        ackCounter_n = ackCounter;
        waitCounter_n = waitCounter;
        transmissionCount_n = transmissionCount;
        complete = 0;
        oeb_n = oeb;
        ack_n = ack;

        if (clkdiv && !clkdiv_temp) begin
            oeb_n = 0;
            case (state)
            OFF: // If we are off, we keep our output high
            begin 
                sda_o_n = sda_o;
                scl_n = 1;
            end
            BEGINS: // If we need to begin, we must lower SDA then SCL
            begin
                ack_n = 0;
                beginCounter_n = beginCounter + 1;
                if (beginCounter == 0) begin // Raise SCL
                    sda_o_n = 1;
                    scl_n = scl;
                end else if (beginCounter == 1) begin // Raise SDA
                    sda_o_n = 1;
                    scl_n = 1;
                end else if (beginCounter == 2) begin // Lower SDA 
                    sda_o_n = 0; 
                    scl_n = 1;
                end else if (beginCounter == 3) begin // Then SCL
                    sda_o_n = 0;
                    scl_n = 0;
                end
                if (beginCounter == 3) begin // After one transmission (1x2), complete
                    complete = 1;
                end
            end
            SEND: // If we need to send, we need 8 cycles where we change the data, turn clock on, then turn clock off
            begin
                sendCounter_n = sendCounter + 1;
                if (sendCounter[1:0] == 0) begin        // First, update the data
                    sda_o_n = lcdData[7-sendCounter[4:2]]; // This means we transmit 8 bits, and the last two are padding
                    scl_n = 0;
                end else if (sendCounter[1:0] == 3) begin // At the end, turn clock off
                    scl_n = 0;
                    sda_o_n = sda_o;
                end else begin  // In the middle, clock is on
                    scl_n = 1;
                    sda_o_n = sda_o;
                end
                if (sendCounter == 31) begin // After 8 (8x4) transmissions, complete
                    complete = 1;
                    transmissionCount_n = transmissionCount + 1;
                end
            end
            ACK: // During acknolwedge, we do not output anything on sda and allow slave to input data
            begin
                if (sda_i == 1) begin // If we ever recieve a signal from slave, ack should be on
                    ack_n = 1;
                end
                ackCounter_n = ackCounter + 1; 
                sda_o_n = 0; // This should be disabled by the IO
                oeb_n = 1; // Enables slave output
                if (ackCounter == 0 || ackCounter >= 3) begin // Start and end by telling the peripheral to write, no clock
                    scl_n = 0;
                end else  begin // In the middle, clock is on
                    scl_n = 1;
                end
                if (ackCounter == 4) begin // After 1 (1x4) transmissions, complete
                    ackCounter_n = 0;
                    complete = 1;
                    oeb_n = 0;
                end
            end
            ENDS:
            begin
                endCounter_n = endCounter + 1;
                if (endCounter <= 1) begin// Lower SDA
                    sda_o_n = 0;
                    scl_n = 0;
                end
                if (endCounter == 2) begin // Raise SCL
                    sda_o_n = 0; 
                    scl_n = 1;
                end else if (endCounter == 3) begin // Then SDA
                    sda_o_n = 1;
                    scl_n = 1;
                end
                if (endCounter == 3) begin // After one transmission (1x2), complete
                    complete = 1;
                    transmissionCount_n = 0;
                end 
            end
            default: 
            begin
                sda_o_n = sda_o;
                scl_n = scl;
            end
            endcase
        end
    end


endmodule
// credits for this goes to Ben Sisk