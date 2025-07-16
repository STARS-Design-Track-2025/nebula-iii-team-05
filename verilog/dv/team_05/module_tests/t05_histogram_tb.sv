`timescale 1ms/100ps
module t05_histogram_tb;

    logic clk, rst;
    logic [7:0] data;
    logic eof, clear;
    logic [31:0] total;
    logic [31:0] hist [0:255];

    // Instantiate modules
    t05_histogram team5(
        .clk(clk),
        .rst(rst), 
        .clear(clear), 
        .data(data), 
        .total(total), 
        .hist(hist), 
        .eof(eof)
    );

    // Clock
    always #1 clk = ~clk;

    // Control logic for clear
    always_ff @(posedge clk or posedge rst) begin
        if (rst)
            clear <= 0;
        else
            clear <= eof;  // Clear total count when EOF is detected
    end

    // Test sequence
    initial begin
        $dumpfile("t05_histogram.vcd");
        $dumpvars(0, t05_histogram_tb);

        for (int i = 0; i <= 255; i++) begin
            $dumpvars(0, t05_histogram_tb.hist[i]);
        end

        clk = 0;
        rst = 1;
        data = 0;
        #3;

        rst = 0;
        #2;

        // Send some bytes
        data = 8'b01000001; #1;
        data = 8'b01000010; #2;
        data = 8'b01000011; #1;
        data = 8'b01000100; #2;
        data = 8'b01000101; #1;
        data = 8'b01000110; #2;
        data = 8'b01000001; #1;
        data = 8'b01000010; #2;
        data = 8'b01000101; #1;
        data = 8'b01000110; #2;

        // Send EOF pattern (DE AD BE EF 01)
        data = 8'b01000100; #1;
        data = 8'b01000101; #2;
        data = 8'b01000001; #1;
        data = 8'b01000100; #2;
        data = 8'b01000010; #1;
        data = 8'b01000101; #2;
        data = 8'b01000101; #1;
        data = 8'b01000110; #2;
        data = 8'b00110000; #1;
        data = 8'b00110001; #2;
        data = 8'b00011010; 


        #1;

        $display("EOF: %b", eof);
        $display("Total count before clear: %0d", total);
        $display("Histogram entries:");
        for (int i = 0; i < 256; i++) begin
            if (hist[i] != 0)
                $display("Byte %0h: %0d", i, hist[i]);
    
        end
#10;
        $finish;
    end

endmodule
