`default_nettype none

module t05_bytecount (
    input  logic        clk,             //clock
    input  logic        en,              //synchronous enable
    input  logic        nrst,            //active-low reset
    input  logic        pulse,           //pulse: new 7-bit input available this cycle
    input  logic [6:0]  in,              //7-bit chunk
    output logic [7:0]  out,             //assembled byte
    output logic        out_valid,       //high when `out` is valid this cycle
    output logic [6:0]  leftover_data,   //leftover bits (right-aligned)
    output logic [2:0]  leftover_count   //number of valid leftover bits (0..7)
);

    //internal state
    logic [13:0] bit_buf;       //buffer: oldest bits in MSBs, can hold up to 14 bits
    logic [3:0]  bits_in_buf;   //count of valid bits in bit_buf (0..14)

    //combinational next-state / output signals
    logic [13:0] bit_buf_next;
    logic [3:0]  bits_in_buf_next;
    logic [7:0]  out_next;
    logic        out_valid_next;
    logic [6:0] leftover_data_next;
    logic [2:0] leftover_count_next;

    //derived combinational leftovers (after possible byte consumption)
    logic [6:0]  leftover_data_comb;
    logic [2:0]  leftover_count_comb;

    logic [3:0]  temp_count;
    logic [13:0] temp_buf;
    logic [3:0] shift_amount;
    logic [13:0] mask;
    logic [3:0] leftover_bits;
    logic [6:0] tbam;

    //combinational logic: build next state, output, and leftover info
    always @(*) begin
        //default: hold current
        leftover_bits = '0;
        shift_amount = '0;
        mask = '0;
        tbam = '0;
        
        bit_buf_next      = bit_buf;
        bits_in_buf_next  = bits_in_buf;
        out_next          = out;
        out_valid_next    = 1'b0;

        //temporary working copies
        temp_buf     = bit_buf;
        temp_count   = bits_in_buf;

        //append new 7 bits if pulse
        if (pulse) begin
            temp_buf   = (bit_buf << 7) | in;
            temp_count = bits_in_buf + 4'd7;
        end

        //default leftover is before consumption
        leftover_count_comb = temp_count[2:0]; // safe because temp_count <= 14
        leftover_data_comb  = temp_buf[6:0];   // right-aligned lower bits (valid when count <=7)

        //if we have at least 8 bits, consume oldest byte
        if (temp_count >= 4'd8) begin
            shift_amount = temp_count - 4'd8; // how many bits remain after taking byte
            out_next       = temp_buf >> shift_amount;
            out_valid_next = 1'b1;

            //compute leftovers after consuming the byte
            leftover_bits = temp_count - 4'd8; // 0..6
            if (leftover_bits == 0) begin
                bit_buf_next      = 14'd0;
                bits_in_buf_next  = 4'd0;
                leftover_count_comb = 3'd0;
                leftover_data_comb  = 7'd0;
            end else begin
                //mask to keep only the lower `leftover_bits` bits
                mask = ((14'd1 << leftover_bits) - 1);
                bit_buf_next      = temp_buf & mask;
                bits_in_buf_next  = leftover_bits;
                leftover_count_comb = leftover_bits[2:0];
                tbam = temp_buf & mask;
                leftover_data_comb  = tbam[6:0]; //right-aligned (lower bits)
            end
        end else begin
            //no byte consumed; next state holds temp values
            bit_buf_next     = temp_buf;
            bits_in_buf_next = temp_count;
        end
    end

    //sequential update with enable and async reset
    always_ff @(posedge clk or negedge nrst) begin
        if (~nrst) begin
            bit_buf        <= 14'd0;
            bits_in_buf    <= 4'd0;
            out            <= 8'd0;
            out_valid      <= 1'b0;
            leftover_count <= leftover_count_next;
            leftover_data  <= leftover_data_next;
        end else if (en) begin
            bit_buf        <= bit_buf_next;
            bits_in_buf    <= bits_in_buf_next;
            out            <= out_next;
            out_valid      <= out_valid_next;
            leftover_count <= leftover_count_next;
            leftover_data  <= leftover_data_next;
        end else begin
            //hold state but deassert valid (policy)
            out_valid <= 1'b0;
        end
    end

    //drive leftover outputs combinationally (reflect post-consumption leftovers)
    assign leftover_count_next = leftover_count_comb;
    assign leftover_data_next  = leftover_data_comb;

endmodule
