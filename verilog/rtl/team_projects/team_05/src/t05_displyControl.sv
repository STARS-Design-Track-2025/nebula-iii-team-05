module t05_displayControl
(
    input logic clk, rst,
    input logic [2:0] i2c_state,
    input logic [3:0] contState,
    output logic [2:0] state
);

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= 3'b0;
        end else begin
            state <= i2c_state;
        end
    end

    typedef enum logic [3:0] {
        IDLE=0,     // Waiting for start signal
        HISTO=1,    // Histogram generation state
        FLV=2,      // Frequency/Length/Value processing state  
        HTREE=3,    // Huffman tree construction state
        CBS=4,      // Code book generation state
        TRN=5,      // Data transmission/encoding state
        SPI=6,      // SPI communication state
        ERROR=7,    // Error handling state
        DONE=8      // Completion state
    } state_t;

    

    always_comb begin
        case (contState)
            IDLE: begin
                

endmodule