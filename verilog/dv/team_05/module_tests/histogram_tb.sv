`timescale 1ms/100ps
module histogram_tb;

    logic clk, rst;
    logic [7:0] data_in;
    logic eof, clear;
    logic [31:0] total_count;
    logic [31:0] hist [0:255];

    // Instantiate modules
    end_file eof_detector (
        .clk(clk),
        .rst(rst),
        .data_in(data_in),
        .eof(eof)
    );

    totalchar char_counter (
        .clk(clk),
        .rst(rst),
        .clear(clear),
        .total(total_count)
    );

    histogram hist_inst (
        .clk(clk),
        .rst(rst),
        .data_in(data_in),
        .eof(eof), // Pass EOF directly into histogram
        .hist(hist)
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
        $dumpfile("waves/histogram.vcd");
        $dumpvars(0, histogram_tb);

        clk = 0;
        rst = 1;
        data_in = 0;
        #5;

        rst = 0;
        #2;

        // Send some bytes
        data_in = 8'hAB; #2;
        data_in = 8'hCD; #2;
        data_in = 8'hEF; #2;
        data_in = 8'hAB; #2;
        data_in = 8'hEF; #2;

        // Send EOF pattern (DE AD BE EF 01)
        data_in = 8'hDE; #2;
        data_in = 8'hAD; #2;
        data_in = 8'hBE; #2;
        data_in = 8'hEF; #2;
        data_in = 8'h01; #2;

        #5;

        $display("EOF: %b", eof);
        $display("Total count before clear: %0d", total_count);
        $display("Histogram entries:");
        for (int i = 0; i < 256; i++) begin
            if (hist[i] != 0)
                $display("Byte %0h: %0d", i, hist[i]);
        end

        $finish;
    end

endmodule