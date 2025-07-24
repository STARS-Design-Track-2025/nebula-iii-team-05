`timescale 1ns/1ps

module t05_histogram_tb;

  logic clk, rst;
  logic [7:0] spi_in;
  logic [31:0] sram_in;
<<<<<<< HEAD
  logic eof, complete;
=======
  logic [3:0] eof, en_state, state;
  logic complete;
>>>>>>> 93c89207a86f7d90771c1bfd8e81072026bccc93
  logic [31:0] total, sram_out;
  logic [7:0] hist_addr;
  logic [1:0] wr_r_en;

  // Instantiate DUT
  t05_histogram dut (
    .clk(clk),
    .rst(rst),
    .spi_in(spi_in),
    .sram_in(sram_in),
    .eof(eof),
<<<<<<< HEAD
=======
    .state(state),
    .en_state(en_state),
>>>>>>> 93c89207a86f7d90771c1bfd8e81072026bccc93
    .complete(complete),
    .total(total),
    .sram_out(sram_out),
    .hist_addr(hist_addr),
    .wr_r_en(wr_r_en)
  );

  // Clock generation
  initial clk = 0;
  always #5 clk = ~clk; // 10ns clock period

  // SRAM model: dummy 256-entry memory initialized to 0
  logic [31:0] sram_mem [0:255];
  logic [7:0] data_sequence [0:4];

  // Test stimulus
  initial begin

  data_sequence[0] = 8'd65;  // 'A'
  data_sequence[1] = 8'd66;  // 'B'
  data_sequence[2] = 8'd65;  // 'A'
  data_sequence[3] = 8'd67;  // 'C'
  data_sequence[4] = 8'h1A;  // EOF
  en_state = 1;

    $display("Starting t05_histogram testbench...");
    $dumpfile("t05_histogram.vcd");
    $dumpvars(0, t05_histogram_tb);

    // Initialize everything
    rst = 1;
    spi_in = 8'd0;
    sram_in = 32'd0;
    #20;

    rst = 0;

    // Feed in a sequence of characters: A, B, A, C, EOF (0x1A)

      @(posedge clk);
      spi_in = data_sequence[0];
      sram_in = 0;  // simulate returning value from SRAM
      wait (complete);
      $display("first complete");             // wait until module says it's done
      @(posedge clk);
      @(posedge clk);
      spi_in = data_sequence[1];
      sram_in = 0;  // simulate returning value from SRAM
      wait (complete);             // wait until module says it's done
      $display ("Second Complete");
      @(posedge clk);
      @(posedge clk);
      spi_in = data_sequence[2];
      sram_in = 1;  // simulate returning value from SRAM
      wait (complete);             // wait until module says it's done
            $display ("Third Complete");
      @(posedge clk);
      @(posedge clk);
      spi_in = data_sequence[3];
      sram_in = 0;  // simulate returning value from SRAM
      wait (complete);             // wait until module says it's done
            $display ("1: %d", state);
      @(posedge clk);
                  $display ("2: %d", state);

      @(posedge clk);
                  $display ("3: %d", state);

      spi_in = data_sequence[4];
                  $display ("4: %d", state);

      sram_in = 0;  // simulate returning value from SRAM
                  $display ("5: %d", state);

      wait (complete);             // wait until module says it's done
            $display ("6: %d", state);

      @(posedge clk);

      //if (eof == 1) begin
        $display("here");

        sram_mem[hist_addr] = sram_out; // emulate SRAM write
        $display("Updated [%0d] = %0d", hist_addr, sram_out);
      //end

    en_state = 0;

    // Wait for histogram to halt
    repeat (10) @(posedge clk);

    // Check results
    $display("Histogram Complete. Total characters processed: %0d", total);
    $display("A count: %0d", sram_mem[8'd65]);
    $display("B count: %0d", sram_mem[8'd66]);
    $display("C count: %0d", sram_mem[8'd67]);

    $finish;
  end

endmodule
