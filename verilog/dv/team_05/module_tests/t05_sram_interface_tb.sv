`timescale 1ms/1ns

module t05_sram_interface_tb;

  // Clock and reset
  logic clk = 0;
  logic rst = 1;

  // Inputs
  logic busy_o = 0;
  logic trn_nxt_char = 0;
  logic [31:0] histogram;
  logic [7:0] histgram_addr;
  logic [8:0] find_least;
  logic [70:0] new_node;
  logic [6:0] htreeindex;
  logic [7:0] codebook;
  logic [127:0] codebook_path;
  logic [7:0] translation;
  logic [2:0] state;

  // Outputs
  logic wr_en, r_en;
  logic [3:0] select;
  logic [31:0] old_char;
  logic [31:0] sram [0:63];
  logic [63:0] comp_val;
  logic [70:0] h_element;
  logic [128:0] char_code;

  // Instantiate DUT
  t05_sram_interface dut (
    .clk(clk),
    .rst(rst),
    .busy_o(busy_o),
    .trn_nxt_char(trn_nxt_char),
    .histogram(histogram),
    .histgram_addr(histgram_addr),
    .find_least(find_least),
    // .new_node(new_node),
    // .htreeindex(htreeindex),
    .codebook(codebook),
    .codebook_path(codebook_path),
    .translation(translation),
    .state(state),
    .wr_en(wr_en),
    .r_en(r_en),
    .select(select),
    .old_char(old_char),
    .comp_val(comp_val),
    .h_element(h_element),
    .char_code(char_code),
    .sram(sram)
  );

  // Clock generation
  always #1 clk = ~clk;

  // Reset task
  task reset();
    begin
      $display("\n=== Resetting DUT ===");
      rst = 1;
      repeat (2) @(posedge clk);
      rst = 0;
      @(posedge clk);
      $display("Reset complete.\n");
    end
  endtask

  // Histogram test
  task test_histogram();
    begin
      $display("\n--- Histogram Test ---");
      histogram = 32'd12;
      histgram_addr = 8'd10;
      state = 3'd1; // HIST
      @(posedge clk); 

      // Now read back
      state = 3'd1; // HIST
      @(posedge clk); 
      $display("Histogram Read Result: old_char=0x%08h", old_char);
    end
  endtask



  // Codebook test
  task test_codebook();
    begin
      $display("\n--- Codebook Test ---");
      codebook = 8'd14;
    //   histogram = 32'h12345678; // reused for writing
      state = 3'd5; // CBS
      @(posedge clk); 
      //h_element should be sending back an output

      // Now read back
      state = 3'd5;
      @(posedge clk);
      $display("Codebook Read Result: h_element=0x%017h", h_element);
    end
  endtask

  // FLV test
  task test_flv();
    begin
      $display("\n--- FLV Test ---");
      find_least = 9'd15;
    //   sram[4*15] = 32'hAABBCCDD; // preload
      state = 3'd2;
    //   comp_val should be showing
      @(posedge clk); 
      $display("FLV Read Result: comp_val=0x%016h", comp_val);
    end
  endtask

  // Translation test
  task test_translation();
    begin
      $display("\n--- Translation Test ---");
      translation = 8'd7;
      trn_nxt_char = 1;
    //   sram[4*30] = 32'hDEADCAFE; // preload
      state = 3'd6;
    //   char_cade should show
      @(posedge clk);
      trn_nxt_char = 0;
      $display("Translation Read Result: char_code=0x%019h", char_code);
    end
  endtask

  initial begin
    $dumpfile("t05_sram_interface.vcd");
    $dumpvars(0, t05_sram_interface_tb);

    reset();

    // Clear SRAM
    for (int i = 0; i < 2048; i++) sram[i] = 32'h0;

    test_histogram();
    // test_htree();
    test_codebook();
    test_flv();
    test_translation();
    #2;
    state = '0;
    #10;

    $display("\nAll tests completed.");
    $finish;
  end
endmodule



//   // HTREE test
//   task test_htree();
//     begin
//       $display("\n--- HTREE Test ---");
//       htreeindex = 7'd5;
//       new_node = {64'hCAFEBABEDEADBEEF, 7'd5};
//       state = 3'd3; // HTREE
//       @(posedge clk); @(posedge clk);
//       $display("HTREE Read Result: h_element=0x%017h", h_element);
//     end
//   endtask