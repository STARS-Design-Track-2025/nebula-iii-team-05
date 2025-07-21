// `timescale 1ns/1ps

// module update_tb;

//   logic clk = 0;
//   logic rst = 1;

//   logic busy_o = 0, trn_nxt_char = 0;
//   logic [31:0] histogram;
//   logic [7:0] histgram_addr;
//   logic [8:0] find_least;
//   logic [70:0] new_node;
//   logic [6:0] htreeindex;
//   logic [7:0] codebook;
//   logic [127:0] codebook_path;
//   logic [7:0] translation;
//   logic [2:0] state;

//   logic wr_en, r_en;
//   logic [3:0] select;
//   logic [31:0] old_char;
//   logic [63:0] comp_val;
//   logic [70:0] h_element;
//   logic [128:0] char_code;

//   update dut (
//     .clk(clk), .rst(rst),
//     .busy_o(busy_o), .trn_nxt_char(trn_nxt_char),
//     .histogram(histogram),
//     .histgram_addr(histgram_addr),
//     .find_least(find_least),
//     .new_node(new_node),
//     .htreeindex(htreeindex),
//     .codebook(codebook),
//     .codebook_path(codebook_path),
//     .translation(translation),
//     .state(state),
//     .wr_en(wr_en), .r_en(r_en),
//     .select(select),
//     .old_char(old_char),
//     .comp_val(comp_val),
//     .h_element(h_element),
//     .char_code(char_code),
//   );

//   always #5 clk = ~clk;

//   task reset_dut();
//     begin
//       rst = 1; repeat (2) @(posedge clk);
//       rst = 0; @(posedge clk);
//     end
//   endtask

//   task test_histogram();
//     begin
//       $display("----- Histogram Test -----");
//       histogram = 32'hDEADBEEF;
//       histgram_addr = 8'd10;
//       state = 3'b001;
//       @(posedge clk);
//       @(posedge clk);
//       state = 3'b001; // trigger read
//       @(posedge clk);
//       @(posedge clk);
//       $display("Histogram read: 0x%08h", old_char);
//     end
//   endtask

//   task test_flv();
//     begin
//       $display("----- FLV Test -----");
//       find_least = 9'd10;
//       state = 3'b010;
//       @(posedge clk);
//       @(posedge clk);
//       $display("FLV comp_val: 0x%016h", comp_val);
//     end
//   endtask

//   task test_codebook();
//     begin
//       $display("----- Codebook Test -----");
//       codebook = 8'd12;
//       state = 3'b101;
//       @(posedge clk);
//       @(posedge clk);
//       $display("h_element from codebook: 0x%017h", h_element);
//     end
//   endtask

//   task test_translation();
//     begin
//       $display("----- Translation Test -----");
//       translation = 8'd3;
//       trn_nxt_char = 1;
//       state = 3'b110;
//       @(posedge clk);
//       @(posedge clk);
//       trn_nxt_char = 0;
//       $display("char_code: 0x%019h", char_code);
//     end
//   endtask

//   initial begin
//     $dumpfile("update_tb.vcd");
//     $dumpvars(0, update_tb);

//     reset_dut();



//     test_histogram();
//     test_flv();
//     test_codebook();
//     test_translation();

//     $display("✅ All tests done.");
//     $finish;
//   end
// endmodule