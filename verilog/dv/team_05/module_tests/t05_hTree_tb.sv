`timescale 1ms/10ps
module t05_hTree_tb;
  logic clk, rst_n;
  logic [8:0] least1, least2;
  logic [45:0] sum;
  logic [63:0] nulls;
  logic  SRAM_finished;
  logic [70:0] tree, null1, null2;
  logic [6:0] clkCount, nullSumIndex;
  logic HT_Finished, HT_fin_reg;
  logic [3:0] HT_en,state; //temp
  logic [3:0] op_fin;
  logic WorR;
  logic err;

  t05_hTree inst (.clk(clk), .rst_n(rst_n), .least1(least1), .least2(least2), .sum(sum),
   .nulls(nulls), .HT_en(HT_en), .SRAM_finished(SRAM_finished), .tree_reg(tree), .null1_reg(null1),
    .null2_reg(null2), .clkCount(clkCount), .nullSumIndex(nullSumIndex), .op_fin(op_fin),.state_reg(state)/*For testing only*/, .WorR(WorR));

  always begin
        clk = 1'b1;
        #10;
        clk = 1'b0;
        #10; // 20ms period for 50Hz clock
  end

  task automatic createNode(input logic [8:0] l1, input logic [8:0] l2, input logic [45:0] nsum); 
    logic [70:0] tree_before;
    
    least1 = l1;
    least2 = l2;
    sum = nsum;

    $display("=== NODE CREATION TEST START ===");
    $display("Inputs: L1=%b, L2=%b, Sum=%d", l1, l2, nsum);

    // Capture tree state before operation
    tree_before = tree;

    // Start with SRAM ready to avoid waiting in SRAM states initially
    SRAM_finished = 1'b1;
    HT_en = 4'b0011; // Enable HTREE operation
    
    // Wait for at least one clock cycle for inputs to register
    @(posedge clk);
    @(posedge clk);
    
    // Check if we entered NEWNODE state and tree is being formed
    $display("After enable: State=%d, tree=%b, op_fin=%b", state, tree, op_fin);
    
    // If we need to handle SRAM states, simulate the delay
    if (state == 4'd2 || state == 4'd4) begin // L1SRAM or L2SRAM
        $display("Entering SRAM state, simulating delay...");
        SRAM_finished = 1'b0; // Make SRAM not ready
        @(posedge clk);
        @(posedge clk);
        SRAM_finished = 1'b1; // Make SRAM ready
        
        // Wait for SRAM operation to complete
        @(posedge clk);
        @(posedge clk);
    end
    
    // Wait for state machine to complete its cycle
    repeat (10) @(posedge clk);
    
    // Check final results
    $display("=== FINAL RESULTS ===");
    $display("State: %d, clkCount: %d, op_fin: %b, WorR: %b", state, clkCount, op_fin, WorR);
    
    // Check for NULL + NULL case (Huffman tree completion)
    if (l1 == 9'b110000000 && l2 == 9'b110000000) begin
        // NULL + NULL case - expect same tree (no change) and finished signal
        $display("NULL + NULL case detected");
        $display("Expected: Tree unchanged, op_fin = 4'b0100");
        $display("Actual: tree_before=%b, tree_now=%b, op_fin=%b", tree_before, tree, op_fin);
        
        if (tree == tree_before) begin
            $display("✓ TREE UNCHANGED (as expected for NULL + NULL)");
        end else begin
            $display("✗ TREE CHANGED (should remain unchanged for NULL + NULL)");
            $display("  Before: %b", tree_before);
            $display("  After:  %b", tree);
        end
        
        if (op_fin == 4'b0100) begin
            $display("✓ OP_FIN CORRECT (4'b0100 for completion)");
        end else begin
            $display("✗ OP_FIN INCORRECT (expected 4'b0100, got %b)", op_fin);
        end
    end else begin
        // Normal case - expect new tree to be created
        $display("Expected Tree: {%d, %b, %b, %d}", clkCount-1, l1, l2, nsum);
        $display("Actual Tree:   %b", tree);
        
        if (tree == {(clkCount-7'd1), least1, least2, sum}) begin
            $display("✓ NODE CREATION SUCCESSFUL");
        end else begin
            $display("✗ NODE CREATION FAILED");
            $display("  Expected: %b", {(clkCount-7'd1), least1, least2, sum});
            $display("  Actual:   %b", tree);
        end
    end
    
    // Check null node creation for internal nodes
    if (least1[8] && least1 != 9'b110000000) begin
      if (null1 == {least1[6:0], nulls[63:46], 46'b0}) begin
        $display("✓ NULL1 CREATION SUCCESSFUL");
      end else begin
        $display("✗ NULL1 CREATION FAILED");
        $display("  Expected: %b", {least1[6:0], nulls[63:46], 46'b0});
        $display("  Actual:   %b", null1);
      end
    end
    
    if (least2[8] && least2 != 9'b110000000) begin
      if (null2 == {least2[6:0], nulls[63:46], 46'b0}) begin
        $display("✓ NULL2 CREATION SUCCESSFUL");
      end else begin
        $display("✗ NULL2 CREATION FAILED");
        $display("  Expected: %b", {least2[6:0], nulls[63:46], 46'b0});
        $display("  Actual:   %b", null2);
      end
    end
    
    // Disable operation and wait for completion
    HT_en = 4'b0;
    @(posedge clk);
    @(posedge clk);
    
    $display("===============================\n");

  endtask

  initial begin
    $display("=== HTREE TESTBENCH STARTED ===");
    
    // Dump signals for waveform viewing
    $dumpfile("t05_hTree.vcd");
    $dumpvars(0, t05_hTree_tb);
    
    // Initialize all signals
    rst_n = 1'b0;
    HT_en = 4'b0;
    SRAM_finished = 1'b1;
    least1 = 9'b0;
    least2 = 9'b0;
    sum = 46'b0;
    nulls = 64'b0;
    
    // Reset sequence
    #20;
    rst_n = 1'b1; // Release reset
    #20; 
    
    $display("Reset complete, starting node creation tests...");
    $display("Initial state: %d, clkCount: %d, tree: %b", state, clkCount, tree);
    $display("");
    
    // Simple test: Check if HT_en works
    $display("\n\n=== BASIC FUNCTIONALITY TEST ===");
    least1 = 9'b000000001; // Simple character
    least2 = 9'b000000010; // Simple character  
    sum = 46'd50;
    
    $display("Before enable: State=%d, HT_en=%b, op_fin=%b", state, HT_en, op_fin);
    HT_en = 4'b0011;
    @(posedge clk);
    $display("After enable: State=%d, tree=%b, op_fin=%b", state, tree, op_fin);
    @(posedge clk);
    $display("Next cycle: State=%d, tree=%b, op_fin=%b", state, tree, op_fin);
    
    HT_en = 4'b0000;
    @(posedge clk);
    @(posedge clk);
    $display("After disable: State=%d, tree=%b, op_fin=%b", state, tree, op_fin);
    $display("");

    rst_n = 1'b0; // Reset for next test
    #20;
    rst_n = 1'b1; // Release reset
    #20;
    
    // TEST 1 - L1 = CHARACTER, L2 = CHARACTER
    $display("\n\n=== TEST 1: CHARACTER + CHARACTER ===\n");
    createNode({1'b0, 8'h41}, {1'b0, 8'h42}, 46'd120); // 'A', 'B', sum = 120
    
    // TEST 2 - L1 = CHARACTER, L2 = SUM NODE
    $display("\n\n=== TEST 2: CHARACTER + SUM NODE ===\n");
    createNode({1'b0, 8'h43}, {1'b1, 8'd1}, 46'd200); // 'C', 'sum node', sum = 200
    
    // TEST 3 - L1 = SUM NODE, L2 = CHARACTER
    $display("\n\n=== TEST 3: SUM NODE + CHARACTER ===\n");
    createNode({1'b0, 8'h44}, {1'b0, 8'h45}, 46'd280); // 'D', 'E', sum = 280
    
    // TEST 4 - L1 = SUM NODE, L2 = SUM NODE
    $display("\n\n=== TEST 4: SUM NODE + SUM NODE ===\n");
    createNode({1'b1, 8'd2}, {1'b1, 8'd3}, 46'd480); // 'sum node', 'sum node', sum = 480
    
    // TEST 5 - L1 = SUM NODE, L2 = NULL
    $display("\n\n=== TEST 5: SUM NODE + NULL ===\n");
    createNode({1'b0, 8'd4}, {9'b110000000}, 46'd480); // 'sum node', 'null node', sum = 480
    
    // TEST 6 - L1 = NULL, L2 = NULL
    $display("\n\n=== TEST 6: NULL + NULL ===\n");
    createNode({9'b110000000}, {9'b110000000}, 46'd0); // 'null node', 'null node', sum = 0
    
    // Wait for op_fin signal to propagate through state machine
    @(posedge clk);
    @(posedge clk);
    
    if (op_fin == 4'b0100) begin
      $display("✓ op_fin correctly asserted (4'b0100) for NULL + NULL completion");
    end else begin
      $display("✗ ERROR: op_fin should be 4'b0100 for NULL + NULL, got %b", op_fin);
    end
    
    // Set up universal null pattern
    nulls = {1'b1, 8'hFF, 1'b1, 8'hFF, 46'd46912496118442}; // null node sum = binary 101 pattern
    
    // TEST 7 - Clock count ramping test
    $display("\n\n=== TEST 7: CLOCK COUNT RAMPING ===\n");
    $display("Starting clkCount ramp test from count: %d", clkCount);
    
    for (int i = 0; i < 121; i++) begin
        // Set up test data for each iteration
        least1 = {1'b0, 8'd48 + i[7:0] % 8'd10}; // Cycle through characters '0'-'9'
        least2 = {1'b0, 8'd65 + i[7:0] % 8'd26}; // Cycle through 'A'-'Z'
        sum = 46'd1000 + 46'(i);                // Increment sum each time
        
        HT_en = 4'b0011;
        #40; // Give enough time for operation to complete
        HT_en = 4'b0;
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
    $display("\n\n=== TEST 8: MAXIMUM NODE INDICES ===\n");
    least1 = {1'b1, 8'h7F}; // Max index 127
    least2 = {1'b1, 8'h7E}; // Index 126
    sum = 46'd999999;
    
    HT_en = 4'b0011;
    #50;
    $display("Test 8: Maximum Node Indices");
    $display("[%b]tree[%b,%b,%b]", clkCount, tree[70:64], tree[63:46], tree[44:0]);
    if (tree == {(clkCount-7'd1), least1, least2, sum}) begin
        $display("✓ Test 8 PASSED");
    end else begin
        $display("✗ Test 8 FAILED");
        $display("  Expected: %b", {(clkCount-7'd1), least1, least2, sum});
        $display("  Actual:   %b", tree);
    end
    
    HT_en = 4'b0;
    #20;
    
    // Reset for next test
    rst_n = 1'b0;
    #20;
    rst_n = 1'b1;
    #20;
    
    // TEST 9 - SRAM Not Ready
    $display("\n\n=== TEST 9: SRAM NOT READY ===\n");
    least1 = {1'b1, 8'h10}; // Sum node
    least2 = {1'b0, 8'h42}; // 'B'
    sum = 46'd5000;
    SRAM_finished = 1'b0;   // SRAM not ready
    
    HT_en = 4'b0011;
    #100; // Wait longer for SRAM states
    $display("SRAM Not Ready - Should stay in L1SRAM");
    $display("State: %b (should be 2=L1SRAM)", state);
    
    SRAM_finished = 1'b1;   // Now SRAM ready
    #50;
    $display("After SRAM ready - State: %b", state);
    
    HT_en = 4'b0000;
    #20;

    // TEST 10 - OP_FIN SIGNAL TESTING
    $display("\n\n=== TEST 10: OP_FIN SIGNAL TESTING ===\n");
    rst_n = 1'b0;
    #20;
    rst_n = 1'b1;
    #20;
    
    // Test that op_fin signals are properly generated
    least1 = {1'b0, 8'h50}; // 'P'
    least2 = {1'b0, 8'h51}; // 'Q'
    sum = 46'd1000;
    
    $display("Starting op_fin test...");
    $display("Initial: op_fin=%b, WorR=%b", op_fin, WorR);
    
    HT_en = 4'b0011;
    @(posedge clk);
    $display("After enable: op_fin=%b, WorR=%b, state=%d", op_fin, WorR, state);
    
    // Wait for completion
    repeat (15) @(posedge clk);
    $display("After completion: op_fin=%b, WorR=%b, state=%d", op_fin, WorR, state);
    
    HT_en = 4'b0;
    @(posedge clk);
    @(posedge clk);
    $display("After disable: op_fin=%b, WorR=%b, state=%d", op_fin, WorR, state);

    $display("\n\n=== ALL TESTS COMPLETED ===\n");

    // Finish the simulation
    #20 $finish;
  end
endmodule