`timescale 1ns / 1ps

module t05_histogram_tb;

    // Clock and reset
    logic clk, rst;

    // Inputs to DUT
    logic [7:0]  addr_i;
    logic [31:0] sram_in;

    // Outputs from DUT
    logic eof, complete;
    logic [31:0] total, sram_out;
    logic [7:0]  hist_addr;
    logic wr_r_en;

    // Instantiate DUT
    t05_histogram dut (
        .clk(clk),
        .rst(rst),
        .spi_in(addr_i),
        .sram_in(sram_in),
        .eof(eof),
        .complete(complete),
        .total(total),
        .sram_out(sram_out),
        .hist_addr(hist_addr),
        .wr_r_en(wr_r_en)
    );

    // Clock generator
    always #5 clk = ~clk;

    // SRAM model: very simple ROM for test
    logic [31:0] fake_sram[0:255];

    initial begin
        clk = 0;
        rst = 1;
        addr_i = 0;
        sram_in = 0;

        // Init fake SRAM contents
        foreach (fake_sram[i])
            fake_sram[i] = i;

        // Apply reset
        #20;
        rst = 0;

        // Send some bytes
        repeat (10) begin
            @(negedge clk);
            // addr_i = $urandom_range('0, 32'd255);
            addr_i = 0; 
            @(posedge clk);
            sram_in = fake_sram[addr_i];

            wait (complete || eof);
        end

        // Send EOF character (0x1A)
        @(negedge clk);
        addr_i = 8'h1A;
        @(posedge clk);
        sram_in = fake_sram[8'h1A];

        wait (eof);

        // Show final result
        $display("=== Simulation Complete ===");
        $display("Total Characters Processed: %0d", total);
        $display("Final Output Value: %0d", sram_out);
        $stop;
    end

endmodule
// `timescale 1ms/100ps
// module t05_histogram_tb;

//     logic clk, rst, clear;
//     logic [7:0] addr_i, sram_addr_in;
//     logic [31:0] sram_in, sram_out;
//     logic [7:0] hist_addr;
//     logic [31:0] total;
//     logic eof, complete;

//     // Simulated SRAM storage
//     logic [31:0] sram [0:255];

//     // Instantiate DUT
//     t05_histogram dut (
//         .clk(clk),
//         .rst(rst),
//         .addr_i(addr_i),
//         .sram_addr_in(sram_addr_in),
//         .sram_in(sram_in),
//         .sram_out(sram_out),
//         .eof(eof),
//         .complete(complete),
//         .total(total),
//         .hist_addr(hist_addr)
//     );

//     // Clock generation
//     always #1 clk = ~clk;

//     // Simulated SRAM behavior
//     always_ff @(posedge clk) begin
//         if (!rst && !eof) begin
//             sram_in <= sram[hist_addr];     // Read from SRAM
//             if (sram_out != 0)              // Write back updated value (skip 0 on reset)
//                 sram[hist_addr] <= sram_out;
//         end
//     end

//     // Clear on EOF
//     always_ff @(posedge clk or posedge rst) begin
//         if (rst)
//             clear <= 0;
//         else
//             clear <= eof;
//     end

//     // Test sequence
//     initial begin
//         $dumpfile("t05_histogram.vcd");
//         $dumpvars(0, t05_histogram_tb);

//         // Initialize
//         clk = 0;
//         rst = 1;
//         addr_i = 0;
//         sram_in = 0;
//         sram_addr_in = 0;
//         #2;

//         for (int i = 0; i < 256; i++) begin
//             sram[i] = $urandom_range(0, 10);
//         end

//         #1;

//         rst = 0;
//         #2;

//         // Send some bytes
//         addr_i = 8'h41; #2; // A
//         addr_i = 8'h42; #2; // B
//         addr_i = 8'h43; #2; // C
//         addr_i = 8'h44; #2; // D
//         addr_i = 8'h45; #2; // E
//         addr_i = 8'h46; #2; // F
//         addr_i = 8'h41; #2; // A
//         addr_i = 8'h42; #2; // B
//         addr_i = 8'h45; #2; // E
//         addr_i = 8'h46; #2; // F

//         // EOF (0x1A)
//         addr_i = 8'h1A; #2;

//         #2;
//         $display("EOF: %b", eof);
//         $display("Total count before clear: %0d", total);

//         $display("Histogram:");
//         for (int i = 0; i < 256; i++) begin
//             if (sram[i] != 0)
//                 $display("Byte 0x%02h: %0d", i, sram[i]);
//         end

//         #10;
//         $finish;
//     end
// endmodule