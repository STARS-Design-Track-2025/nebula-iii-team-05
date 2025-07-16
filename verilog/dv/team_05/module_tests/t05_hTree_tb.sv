`timescale 1ms/10ps
module t05_hTree_tb;
  logic clk, rst_n;
  logic [8:0] least1, least2;
  logic [45:0] sum;
  logic [63:0] nulls;
  logic HT_en, SRAM_finished;
  logic [70:0] tree, null1, null2;
  logic [6:0] clkCount, nullSumIndex;
  logic HT_Finished, HT_fin_reg;
  logic [3:0] state; //temp
  logic err;

  t05_hTree inst (.clk(clk), .rst_n(rst_n), .least1(least1), .least2(least2), .sum(sum), .nulls(nulls), .HT_en(HT_en), .SRAM_finished(SRAM_finished), .tree_reg(tree), .null1_reg(null1), .null2_reg(null2), .clkCount(clkCount), .nullSumIndex(nullSumIndex), .HT_Finished(HT_Finished), .HT_fin_reg(HT_fin_reg), .state_reg(state), .ERROR(err));

  always begin
        clk = 1'b1;
        #10;
        $display("index: %b | state: %b", clkCount,state);
        clk = 1'b0;
        #10; // 10ms period for 100Hz clock
    end

  initial begin
    // make sure to dump the signals so we can see them in the waveform
    $dumpfile("t05_hTree.vcd"); //change the vcd vile name to your source file name
    $dumpvars(0, t05_hTree_tb);
    // for loop to test all possible inputs

  // VARIABLE INITIALIZATION
    rst_n = 1'b0;
    #5;
    rst_n = 1'b1; // release reset
    #5; 
    
    
    HT_en = 1'b0;
    SRAM_finished = 1'b1;
    least1 = 9'b0;
    least2 = 9'b0;
    sum = 46'b0;
    nulls = 64'b0;
    // clkCount = 7'b0;

  // Universal null
  nulls = {1'b1, 8'hFF,1'b1,8'hFF, 46'd46912496118442}; // null node sum = binary 101 pattern
 
  // TEST 1 - L1 = CHARACTER, L2 = CHARACTER
    least1 = {1'b0, 8'h41}; // 'A'
    least2 = {1'b0, 8'h42}; // 'B'
    sum = 46'd1234567; // no sum
    HT_en = 1'b1;
    #50; 
    $display("Test 1: L1 = CHARACTER, L2 = CHARACTER");
    $display("[%b]tree[%b,%b,%b]",clkCount, tree[70:64], tree[63:46], tree[45:0]);
    $display(" tree = %b", tree);
    // Tree uses clkCount_reg (which starts at 0), not clkCount output
    if ( tree == {7'd0, least1, least2, sum} ) begin
        $display("Test 1a Passed");
    end else begin
        $display("Test 1a Failed");
        $display("Expected: {7'd0, least1=%b, least2=%b, sum=%b}", least1, least2, sum);
        $display("Got:      tree=%b", tree);
    end

    #50;

    if (null1 == null2 && null1 == 71'b0) begin
        $display("Test 1b Passed | status:%b",HT_fin_reg);
    end else begin
        $display("Test 1b Failed | status:%b",HT_fin_reg);
    end
    if (HT_Finished) begin
        $display("ERROR HT Finished");
    end

    // Disable HT_en to reset state machine for next test
    HT_en = 1'b0;
    #20;

  // TEST 2 - L1 = CHARACTER, L2 = SUM NODE
    least1 = {1'b0, 8'h41}; // 'A'
    least2 = {1'b1, 8'h7F}; // 'ÿ'
    sum = 46'd1234567; 

    HT_en = 1'b1;
    #50;
    $display("Test 2: L1 = CHARACTER, L2 = SUM NODE");
    $display("[%b]tree[%b,%b,%b]",clkCount, tree[70:64], tree[63:46], tree[44:0]);
    $display(" tree = %b", tree);
    // Tree should use clkCount_reg (now 1 after first test)
    if ( tree == {7'd1, least1, least2, sum} ) begin
        $display("Test 2a Passed");
    end else begin
        $display("Test 2a Failed");
        $display("Expected: {7'd1, least1=%b, least2=%b, sum=%b}", least1, least2, sum);
        $display("Got:      tree=%b", tree);
    end

    #50;

    if (null1 == 71'b0 && null2 == {7'd127,1'b1, 8'hFF,1'b1,8'hFF, 46'b0}) begin
        $display("Test 2b Passed | status:%b",HT_fin_reg);
    end else begin
        $display("Test 2b Failed | status:%b",HT_fin_reg);
    end
    if (HT_Finished) begin
        $display("ERROR HT Finished");
    end

    // Disable HT_en to reset state machine for next test
    HT_en = 1'b0;
    #20;
  
  // TEST 3 - L1 = SUM NODE, L2 = CHARACTER
    least1 = {1'b1, 8'h7F}; // 'ÿ'
    least2 = {1'b0, 8'h41}; // 'A'
    sum = 46'd1234567;

    HT_en = 1'b1;
    #50;
    $display("Test 3: L1 = SUM NODE, L2 = CHARACTER");
    $display("[%b]tree[%b,%b,%b]",clkCount, tree[70:64], tree[63:46], tree[44:0]);
    $display(" tree = %b", tree);
    if ( tree == {7'd2, least1, least2, sum} ) begin  // Should be count 2
        $display("Test 3a Passed");
    end else begin
        $display("Test 3a Failed");
        $display("Expected: {7'd2, least1=%b, least2=%b, sum=%b}", least1, least2, sum);
        $display("Got:      tree=%b", tree);
    end

    #50;

    if (null2 == 71'b0 && null1 == {7'd127,1'b1, 8'hFF,1'b1,8'hFF, 46'b0}) begin
        $display("Test 3b Passed | status:%b",HT_fin_reg);
    end else begin
        $display("Test 3b Failed | status:%b",HT_fin_reg);
    end
    if (HT_Finished) begin
        $display("ERROR HT Finished");
    end

    HT_en = 1'b0;
    #20;


  // TEST 4 - L1 = SUM NODE, L2 = SUM NODE
    least1 = {1'b1, 8'h7F}; // SUM NODE 
    least2 = {1'b1, 8'h7E}; // SUM NODE (fixed: was character)
    sum = 46'd1234567;

    HT_en = 1'b1;
    #50;
    $display("Test 4: L1 = SUM NODE, L2 = SUM NODE");
    $display("[%b]tree[%b,%b,%b]",clkCount, tree[70:64], tree[63:46], tree[44:0]);
    $display(" tree = %b", tree);
    if ( tree == {7'd3, least1, least2, sum} ) begin  // Should be count 3 by now
        $display("Test 4a Passed");
    end else begin
        $display("Test 4a Failed");
        $display("Expected: {7'd3, least1=%b, least2=%b, sum=%b}", least1, least2, sum);
        $display("Got:      tree=%b", tree);
    end

    #50;

    if (null2 == {7'd126,1'b1, 8'hFF,1'b1,8'hFF, 46'b0} && null1 == {7'd127,1'b1, 8'hFF,1'b1,8'hFF, 46'b0}) begin
        $display("Test 4b Passed | status:%b",HT_fin_reg);
    end else begin
        $display("Test 4b Failed | status:%b",HT_fin_reg);
        $display("Expected null1: {7'd127, nulls pattern}");
        $display("Expected null2: {7'd126, nulls pattern}"); 
        $display("Got null1: %b", null1);
        $display("Got null2: %b", null2);
    end
    if (HT_Finished) begin
        $display("ERROR HT Finished");
    end

    HT_en = 1'b0;
    #20;

  // TEST 5 - L1 = NULL, L2 = NULL?
    least1 = {9'b0}; // 'ÿ'
    least2 = {9'b0}; // 'A'
    sum = 46'd1234567;

    HT_en = 1'b1;
    #50;
    $display("Test 5: L1 = NULL, L2 = NULL");
    $display("[%b]tree[%b,%b,%b]",clkCount, tree[70:64], tree[63:46], tree[44:0]);
    $display(" tree = %b", tree);
    if ( tree == {7'd4, least1, least2, sum} ) begin  // Should be count 4
        $display("Test 5a Passed");
    end else begin
        $display("Test 5a Failed");
        $display("Expected: {7'd4, least1=%b, least2=%b, sum=%b}", least1, least2, sum);
        $display("Got:      tree=%b", tree);
    end

    #50;

    if (null2 == 71'b0 && null1 == null2) begin
        $display("Test 5b Passed | status:%b",HT_fin_reg);
    end else begin
        $display("Test 5b Failed | status:%b",HT_fin_reg);
    end
    if (HT_Finished) begin
        $display("ERROR HT Finished");
    end

    HT_en = 1'b0;
    #20;

  // TEST 6 - Test HT_Finished with SUM = 46'b0 
    least1 = {1'b1, 8'h7F}; // 'ÿ'
    least2 = {1'b0, 8'h41}; // 'A'
    sum = 46'd0;  // Non-zero sum to allow clkCount increment

    HT_en = 1'b1;
    #50;
    $display("Test 6: Normal operation before testing sum=0");
    $display("[%b]tree[%b,%b,%b]",clkCount, tree[70:64], tree[63:46], tree[44:0]);
    $display(" tree = %b", tree);
    if ( tree == 71'b0 ) begin  // Should be count 5
        $display("Test 6a Passed");
    end else begin
        $display("Test 6a Failed");
        $display("Expected:%b", 71'b0);
        $display("Got:      tree=%b", tree);
    end

    // Now test sum = 0 for HT_Finished
    sum = 46'd0;
    #20;


    #50;

    if (null2 == 71'b0 && null1 == 71'b0) begin
        $display("Test 6b Passed | status:%b",HT_fin_reg);
    end else begin
        $display("Test 6b Failed | status:%b",HT_fin_reg);
    end

    if (HT_Finished) begin
        $display("HT Finished Successfully");
    end else begin
        $display("HT Failed to Finish");
    end

    HT_en = 1'b0;
    #20;

  // TEST 7 - Single Character Tree (Degenerate Case)
    least1 = {1'b0, 8'h41}; // 'A'
    least2 = 9'b0;          // NULL
    sum = 46'd1;            // Minimum frequency

    HT_en = 1'b1;
    #50;
    $display("Test 7: Single Character Tree");
    $display("[%b]tree[%b,%b,%b]",clkCount, tree[70:64], tree[63:46], tree[44:0]);
    if ( tree == {7'd5, least1, least2, sum} ) begin
        $display("Test 7a Passed");
    end else begin
        $display("Test 7a Failed");
    end

    #50;
    HT_en = 1'b0;
    #20;

    // TEST: Rapid HT_en toggling to ramp up clkCount
    $display("Starting clkCount ramp test from count: %d", clkCount);
    
    for (int i = 0; i < 121; i++) begin
        logic [6:0] expected_count;
        expected_count = clkCount + 1;  // What we expect after this iteration
        
        // Set up test data for each iteration
        least1 = {1'b0, 8'd48 + i[7:0] % 8'd10}; // Cycle through characters '0'-'9'
        least2 = {1'b0, 8'd65 + i[7:0] % 8'd26}; // Cycle through 'A'-'Z'
        sum = 46'd1000 + 46'(i);                // Increment sum each time
        
        HT_en = 1'b1;
        #40; // Give enough time for operation to complete
        HT_en = 1'b0;
        #20; // Brief pause between operations
        
        // Every 10 iterations, check progress
        if (i % 10 == 0) begin
            $display("Iteration %d: clkCount = %d", i, clkCount);
        end
        
        // Check for specific issues
        if (clkCount == 7'd127) begin
            $display("*** clkCount reached MAXIMUM (127) at iteration %d ***", i);
        end
        
        if (clkCount == 7'd0 && i > 10) begin
            $display("*** clkCount WRAPPED to 0 at iteration %d ***", i);
        end
    end
    
    $display("Final clkCount after ramping: %d", clkCount);
    $display("Math check: 6 + 121 = %d, but 7-bit max is 127", 6+121);
    $display("Expected behavior: Should saturate at 127 or wrap around");
    
  // TEST 8 - Maximum Node Indices
    least1 = {1'b1, 8'h7F}; // Max index 127
    least2 = {1'b1, 8'h7E}; // Index 126
    sum = 46'd999999;

    HT_en = 1'b1;
    #50;
    $display("Test 8: Maximum Node Indices");
    $display("[%b]tree[%b,%b,%b]",clkCount, tree[70:64], tree[63:46], tree[44:0]);
    if ( tree == {7'd6, least1, least2, sum} ) begin
        $display("Test 8a Passed");
    end else begin
        $display("Test 8a Failed");
    end

    #50;
    HT_en = 1'b0;
    #20;
    rst_n = 1'b0; // Reset for next test
    #5;
    rst_n = 1'b1; // Release reset
  // TEST 9 - SRAM Not Ready
    least1 = {1'b1, 8'h10}; // Sum node
    least2 = {1'b0, 8'h42}; // 'B'
    sum = 46'd5000;
    SRAM_finished = 1'b0;   // SRAM not ready

    HT_en = 1'b1;
    #100; // Wait longer for SRAM states
    $display("Test 9: SRAM Not Ready - Should stay in L1SRAM");
    $display("State: %b (should be 2=L1SRAM)", state);
    
    SRAM_finished = 1'b1;   // Now SRAM ready
    #50;
    $display("After SRAM ready - State: %b", state);

    #50;
    HT_en = 1'b0;
    #20;


  // // TEST 7 - SUM OVERFLOW ?
  // least1 = {1'b0, 8'hFF}; // 'ÿ'
  // least2 = {1'b0, 8'hFF}; // 'ÿ'
  // sum = 46'd70368744177665; // max sum 1 over max
  // HT_en = 1'b1;
  // #50;
  // $display("Test 7: L1 = CHARACTER, L2 = CHARACTER");
  // $display("[%b]tree[%b,%b,%b]",clkCount, tree[70:64], tree[63:46], tree[45:0]);
  // $display(" tree = %b", tree);
  // if ( tree == {clkCount, least1, least2, sum} ) begin
  //     $display("Test 7a Passed");
  // end else begin
  //     $display("Test 7a Failed");
  // end

  // finish the simulation
  #1 $finish;
  end
endmodule