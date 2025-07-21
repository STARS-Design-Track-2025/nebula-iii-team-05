
`timescale 1ms/100ps
module t05_histogram_tb;

    logic clk, rst, clear;
    logic [7:0] addr_i, sram_addr_in;
    logic [31:0] sram_in, sram_out;
    logic [7:0] hist_addr;
    logic [31:0] total;
    logic eof, complete;

    // Simulated SRAM storage
    logic [31:0] sram [0:255];

    // Instantiate DUT
    t05_histogram dut (
        .clk(clk),
        .rst(rst),
        .addr_i(addr_i),
        .sram_addr_in(sram_addr_in),
        .sram_in(sram_in),
        .sram_out(sram_out),
        .eof(eof),
        .complete(complete),
        .total(total),
        .hist_addr(hist_addr)
    );

    // Clock generation
    always #1 clk = ~clk;

    // Simulated SRAM behavior
    always_ff @(posedge clk) begin
        if (!rst && !eof) begin
            sram_in <= sram[hist_addr];     // Read from SRAM
            if (sram_out != 0)              // Write back updated value (skip 0 on reset)
                sram[hist_addr] <= sram_out;
        end
    end

    // Clear on EOF
    always_ff @(posedge clk or posedge rst) begin
        if (rst)
            clear <= 0;
        else
            clear <= eof;
    end

    // Test sequence
    initial begin
        $dumpfile("t05_histogram.vcd");
        $dumpvars(0, t05_histogram_tb);

        // Initialize
        clk = 0;
        rst = 1;
        addr_i = 0;
        sram_in = 0;
        sram_addr_in = 0;
        #2;

        for (int i = 0; i < 256; i++) begin
            sram[i] = $urandom_range(0, 10);
        end

        #1;

        rst = 0;
        #2;

        // Send some bytes
        addr_i = 8'h41; #2; // A
        addr_i = 8'h42; #2; // B
        addr_i = 8'h43; #2; // C
        addr_i = 8'h44; #2; // D
        addr_i = 8'h45; #2; // E
        addr_i = 8'h46; #2; // F
        addr_i = 8'h41; #2; // A
        addr_i = 8'h42; #2; // B
        addr_i = 8'h45; #2; // E
        addr_i = 8'h46; #2; // F

        // EOF (0x1A)
        addr_i = 8'h1A; #2;

        #2;
        $display("EOF: %b", eof);
        $display("Total count before clear: %0d", total);

        $display("Histogram:");
        for (int i = 0; i < 256; i++) begin
            if (sram[i] != 0)
                $display("Byte 0x%02h: %0d", i, sram[i]);
        end

        #10;
        $finish;
    end
endmodule