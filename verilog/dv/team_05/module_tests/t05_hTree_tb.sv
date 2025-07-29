`timescale 1ms/10ps
module t05_hTree_tb;
  logic clk, rst;
  logic [8:0] least1, least2;
  logic [45:0] sum;
  logic [63:0] nulls;
  logic  SRAM_finished;
  logic [70:0] tree, null1, null2,node;
  logic [6:0] clkCount, nullSumIndex;
  logic HT_Finished, HT_fin_reg;
  logic [3:0] HT_en,state; //temp
  logic [3:0] op_fin;
  logic WorR;
  logic err;
  int test_progress = 0;

  t05_hTree inst (.clk(clk), .rst(rst), .least1(least1), .least2(least2), .sum(sum),
   .nulls(nulls), .HT_en(HT_en), .SRAM_finished(SRAM_finished),.node_reg(node) /* .tree_reg(tree), .null1_reg(null1),
    .null2_reg(null2)*/, .clkCount(clkCount), .nullSumIndex(nullSumIndex), .op_fin(op_fin)/*,.state_reg(state)For testing only*/
    , .WriteorRead(WorR),.tree_reg(tree), .null1_reg(null1), .null2_reg(null2), .state_reg(state));

  always begin
        clk = 1'b1;
        #10;
        clk = 1'b0;
        #10; // 20ms period for 50Hz clock
  end

  task automatic createNode(input logic [8:0] l1, input logic [8:0] l2, input logic [45:0] nsum); 
    logic [70:0] node_before;
    logic [3:0] last_state;
    logic [70:0] expected_tree, expected_null1, expected_null2, expected_final_node;
    string expected_type;

    // Capture node state before operation
    node_before = node;

    least1 = l1;
    least2 = l2;
    sum = nsum;
    test_progress ++;
    $display("=== NODE CREATION TEST START ===");
    $display("Inputs: L1=%b, L2=%b, Sum=%d", l1, l2, nsum);

    // Start with SRAM ready to avoid waiting in SRAM states initially
    SRAM_finished = 1'b1;
    HT_en = 4'b0011; // Enable HTREE operation
    
    // Wait for at least 3 clock cycles for inputs to register and state to change
    @(posedge clk);
    @(posedge clk);
    @(posedge clk);
    
    // Check if we entered NEWNODE state and node is being formed
    $display("After enable: State=%d, node=%b, op_fin=%b", state, node, op_fin);
    
    // If we need to handle SRAM states, simulate the delay
    if (state == 4'd2 || state == 4'd4) begin // L1SRAM or L2SRAM
        $display("Entering SRAM state, simulating delay...");
        SRAM_finished = 1'b0; // Make SRAM not ready
        @(posedge clk);
        @(posedge clk);
        @(posedge clk); // Wait 3 cycles for SRAM not ready to propagate
        SRAM_finished = 1'b1; // Make SRAM ready
        
        // Wait for SRAM operation to complete - 3 cycles minimum
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
    end
    
    // Wait for state machine to complete its cycle and for node to be registered
    // Give extra time for all state transitions to complete properly
    // Monitor state changes during this period
    $display("=== MONITORING STATE TRANSITIONS ===");
    last_state = state;
    for (int i = 0; i < 15; i++) begin
        @(posedge clk);
        if (state != last_state) begin
            case(state)
                4'd0: $display("  Cycle %0d -> FIN state: node=%b", i+1, node);
                4'd1: $display("  Cycle %0d -> NEWNODE state: node=%b", i+1, node); 
                4'd2: $display("  Cycle %0d -> L1SRAM state: node=%b", i+1, node);
                4'd3: $display("  Cycle %0d -> NULLSUM1 state: node=%b", i+1, node);
                4'd4: $display("  Cycle %0d -> L2SRAM state: node=%b", i+1, node);
                4'd5: $display("  Cycle %0d -> NULLSUM2 state: node=%b", i+1, node);
                4'd6: $display("  Cycle %0d -> RESET state: node=%b", i+1, node);
                default: $display("  Cycle %0d -> Unknown state %d: node=%b", i+1, state, node);
            endcase
            last_state = state;
        end
        // Show node updates even within the same state (for multi-cycle states)
        if (i % 5 == 4) begin // Every 5 cycles, show current status
            $display("  Cycle %0d: State=%d, node=%b", i+1, state, node);
        end
    end
    
    // Check final results BEFORE disabling HT_en (so we can see the actual node value)
    $display("=== FINAL RESULTS (while enabled) ===");
    $display("State: %d, clkCount: %d, op_fin: %b, WorR: %b", state, clkCount, op_fin, WorR);
    $display("Node before disable: %b", node);
    
    // Check for NULL + NULL case (Huffman tree completion)
    // Also check for NULL + SUM NODE and SUM NODE + NULL cases
    if (l1 == 9'b110000000 && l2 == 9'b110000000) begin
        // NULL + NULL case - expect same node (no change) and finished signal
        $display("NULL + NULL case detected");
        $display("Expected: Node unchanged, op_fin = 4'b0100");
        $display("Actual: node_before=%b, node_now=%b, op_fin=%b", node_before, node, op_fin);
        
        if (node == node_before) begin
            $display("✓ NODE UNCHANGED (as expected for NULL + NULL)");
        end else begin
            $display("✗ NODE CHANGED (should remain unchanged for NULL + NULL)");
            $display("  Before: %b", node_before);
            $display("  After:  %b", node);
        end

        if (op_fin == 4'b0100) begin
            $display("✓ OP_FIN CORRECT (4'b0100 for completion)");
        end else begin
            $display("✗ OP_FIN INCORRECT (expected 4'b0100, got %b)", op_fin);
        end
    end else if (l1 == 9'b110000000 && l2[8] && l2 != 9'b110000000) begin
        // NULL + SUM NODE case - special handling (single character file case)
        $display("=== NULL + SUM NODE CASE DETECTED (SPECIAL CASE) ===");
        $display("L1 (NULL): %b", l1);
        $display("L2 (SUM NODE): %b (index %d)", l2, l2[7:0]);
        $display("Expected behavior: Create special tree with NULL in L1, sum node in L2, go to RESET");
        $display("This is a single character file case - NO null creation expected");
        
        // Expected tree format: {clkCount_reg, NULL, sum_node, sum} 
        // Note: Special case increments clkCount_reg->clkCount, then next cycle clkCount->clkCount_reg
        // So tree uses old clkCount_reg, but we read incremented clkCount, need clkCount-2
        expected_tree = {(clkCount-7'd2), 9'b110000000, l2, nsum};
        $display("Expected Tree Node: %b", expected_tree);
        $display("Actual Tree (from tree_reg): %b", tree);
        
        if (tree == expected_tree) begin
            $display("✓ TREE CREATION SUCCESSFUL");
        end else begin
            $display("✗ TREE CREATION FAILED");
            $display("  Expected Tree: %b", expected_tree);
            $display("  Actual Tree:   %b", tree);
        end
        
        // For this special case, NO null creation occurs - verify null registers remain unchanged
        $display("=== NULL REGISTER VALIDATION (should be unchanged) ===");
        $display("Null1: %b (should remain at previous value)", null1);
        $display("Null2: %b (should remain at previous value)", null2);
        
        // Final node behavior: HDL behavior - special case goes to RESET state without updating node
        // The tree is created correctly but node output is not updated, so it stays at previous value
        expected_final_node = node_before; // RESET state doesn't update node output
        expected_type = "previous node value (RESET state doesn't update node output)";
        
        $display("=== FINAL NODE OUTPUT VALIDATION ===");
        $display("Expected Final Node (%s): %b", expected_type, expected_final_node);
        $display("Actual Final Node:   %b", node);
        
        if (node == expected_final_node) begin
            $display("✓ FINAL NODE OUTPUT SUCCESSFUL (%s)", expected_type);
        end else begin
            $display("✗ FINAL NODE OUTPUT FAILED");
            $display("  Expected (%s): %b", expected_type, expected_final_node);
            $display("  Actual:   %b", node);
        end
        
    end else if (l1[8] && l1 != 9'b110000000 && l2 == 9'b110000000) begin
        // SUM NODE + NULL case - special handling (single character file case)
        $display("=== SUM NODE + NULL CASE DETECTED (SPECIAL CASE) ===");
        $display("L1 (SUM NODE): %b (index %d)", l1, l1[7:0]);
        $display("L2 (NULL): %b", l2);
        $display("Expected behavior: Create special tree with sum node in L1, NULL in L2, go to RESET");
        $display("This is a single character file case - NO null creation expected");
        
        // Expected tree format: {clkCount_reg, sum_node, NULL, sum}
        // Note: Special case increments clkCount_reg->clkCount, then next cycle clkCount->clkCount_reg
        // So tree uses old clkCount_reg, but we read incremented clkCount, need clkCount-2
        expected_tree = {(clkCount-7'd2), l1, 9'b110000000, nsum};
        $display("Expected Tree Node: %b", expected_tree);
        $display("Actual Tree (from tree_reg): %b", tree);
        
        if (tree == expected_tree) begin
            $display("✓ TREE CREATION SUCCESSFUL");
        end else begin
            $display("✗ TREE CREATION FAILED");
            $display("  Expected Tree: %b", expected_tree);
            $display("  Actual Tree:   %b", tree);
        end
        
        // For this special case, NO null creation occurs - verify null registers remain unchanged
        $display("=== NULL REGISTER VALIDATION (should be unchanged) ===");
        $display("Null1: %b (should remain at previous value)", null1);
        $display("Null2: %b (should remain at previous value)", null2);
        
        // Final node behavior: HDL behavior - special case goes to RESET state without updating node
        // The tree is created correctly but node output is not updated, so it stays at previous value
        expected_final_node = node_before; // RESET state doesn't update node output
        expected_type = "previous node value (RESET state doesn't update node output)";
        
        $display("=== FINAL NODE OUTPUT VALIDATION ===");
        $display("Expected Final Node (%s): %b", expected_type, expected_final_node);
        $display("Actual Final Node:   %b", node);
        
        if (node == expected_final_node) begin
            $display("✓ FINAL NODE OUTPUT SUCCESSFUL (%s)", expected_type);
        end else begin
            $display("✗ FINAL NODE OUTPUT FAILED");
            $display("  Expected (%s): %b", expected_type, expected_final_node);
            $display("  Actual:   %b", node);
        end
    end else begin
        // Normal case - expect new node to be created
        // For sum nodes, need to validate both tree creation and null node processing
        logic [70:0] expected_tree, expected_null1, expected_null2, expected_final_node;
        string expected_type;
        
        // Always expect tree to be created first
        expected_tree = {(clkCount-7'd1), l1, l2, nsum};
        $display("Expected Tree Node: %b", expected_tree);
        $display("Actual Tree (from tree_reg): %b", tree);
        
        if (tree == expected_tree) begin
            $display("✓ TREE CREATION SUCCESSFUL");
        end else begin
            $display("✗ TREE CREATION FAILED");
            $display("  Expected Tree: %b", expected_tree);
            $display("  Actual Tree:   %b", tree);
        end
        
        // Check sum node null processing
        if (l1[8] && l1 != 9'b110000000) begin
            // L1 is sum node - expect null1 creation
            expected_null1 = {l1[6:0], nulls[63:46], 46'b0};
            $display("Expected Null1 (for L1 sum node): %b", expected_null1);
            $display("Actual Null1 (from null1_reg):   %b", null1);
            
            if (null1 == expected_null1) begin
                $display("✓ NULL1 CREATION SUCCESSFUL (L1 sum node nullification)");
            end else begin
                $display("✗ NULL1 CREATION FAILED");
                $display("  Expected Null1: %b", expected_null1);
                $display("  Actual Null1:   %b", null1);
            end
        end
        
        if (l2[8] && l2 != 9'b110000000) begin
            // L2 is sum node - expect null2 creation
            expected_null2 = {l2[6:0], nulls[63:46], 46'b0};
            $display("Expected Null2 (for L2 sum node): %b", expected_null2);
            $display("Actual Null2 (from null2_reg):   %b", null2);
            
            if (null2 == expected_null2) begin
                $display("✓ NULL2 CREATION SUCCESSFUL (L2 sum node nullification)");
            end else begin
                $display("✗ NULL2 CREATION FAILED");
                $display("  Expected Null2: %b", expected_null2);
                $display("  Actual Null2:   %b", null2);
            end
        end
        
        // Determine expected final node output based on "most recently updated" logic
        if ((l1[8] && l1 != 9'b110000000) && (l2[8] && l2 != 9'b110000000)) begin
            // Both are sum nodes -> expect null2 (most recently updated)
            expected_final_node = {l2[6:0], nulls[63:46], 46'b0};
            expected_type = "null2 (both sum nodes, null2 most recent)";
        end else if (l1[8] && l1 != 9'b110000000) begin
            // Only l1 is sum node -> expect null1 (most recently updated)  
            expected_final_node = {l1[6:0], nulls[63:46], 46'b0};
            expected_type = "null1 (only L1 sum node, null1 most recent)";
        end else if (l2[8] && l2 != 9'b110000000) begin
            // Only l2 is sum node -> expect null2 (most recently updated)
            expected_final_node = {l2[6:0], nulls[63:46], 46'b0};
            expected_type = "null2 (only L2 sum node, null2 most recent)";
        end else begin
            // Neither is sum node -> expect tree (most recently updated)
            expected_final_node = expected_tree;
            expected_type = "tree (no sum nodes, tree most recent)";
        end
        
        $display("=== FINAL NODE OUTPUT VALIDATION ===");
        $display("Expected Final Node (%s): %b", expected_type, expected_final_node);
        $display("Actual Final Node:   %b", node);
        
        if (node == expected_final_node) begin
            $display("✓ FINAL NODE OUTPUT SUCCESSFUL (%s)", expected_type);
        end else begin
            $display("✗ FINAL NODE OUTPUT FAILED");
            $display("  Expected (%s): %b", expected_type, expected_final_node);
            $display("  Actual:   %b", node);
        end
    end
    
    // Check null node creation for internal nodes (these are not directly observable via node output)
    // Note: null1 and null2 are internal signals, we can't verify them directly in this test
    // The null node creation would be tested indirectly through SRAM operations
    if (least1[8] && least1 != 9'b110000000) begin
        $display("INFO: least1 is a sum node - null1 creation expected internally");
    end
    
    if (least2[8] && least2 != 9'b110000000) begin
        $display("INFO: least2 is a sum node - null2 creation expected internally");
    end
    
    // Disable operation and wait for completion - give 3 cycles for disable to propagate
    HT_en = 4'b0;
    @(posedge clk);
    @(posedge clk);
    @(posedge clk);
    
    $display("After disable: node=%b (should be cleared to 0)", node);
    $display("===============================\n");

  endtask

  initial begin
    $display("=== HTREE TESTBENCH STARTED ===");
    
    // Dump signals for waveform viewing
    $dumpfile("t05_hTree.vcd");
    $dumpvars(0, t05_hTree_tb);
    
    // Initialize all signals
    rst = 1'b1;
    HT_en = 4'b0;
    SRAM_finished = 1'b1;
    least1 = 9'b0;
    least2 = 9'b0;
    sum = 46'b0;
    nulls = 64'b0;
    
    // Reset sequence
    #20;
    rst = 1'b0; // Release reset
    #20; 
    
    $display("Reset complete, starting node creation tests...");
    $display("Initial state: %d, clkCount: %d, node: %b", state, clkCount, node);
    $display("");
    
    // Simple test: Check if HT_en works
    $display("\n\n=== BASIC FUNCTIONALITY TEST ===");
    least1 = 9'b000000001; // Simple character
    least2 = 9'b000000010; // Simple character  
    sum = 46'd50;
    
    $display("Before enable: State=%d, HT_en=%b, op_fin=%b", state, HT_en, op_fin);
    HT_en = 4'b0011;
    @(posedge clk);
    @(posedge clk);
    @(posedge clk); // Wait 3 cycles for enable to propagate
    $display("After enable: State=%d, node=%b, op_fin=%b", state, node, op_fin);
    @(posedge clk);
    @(posedge clk);
    @(posedge clk); // Wait 3 more cycles for state machine to process
    $display("Next cycle: State=%d, node=%b, op_fin=%b", state, node, op_fin);
    
    HT_en = 4'b0000;
    @(posedge clk);
    @(posedge clk);
    @(posedge clk); // Wait 3 cycles for disable to propagate
    $display("After disable: State=%d, node=%b, op_fin=%b", state, node, op_fin);
    $display("");

    rst = 1'b1; // Reset for next test
    #20;
    rst = 1'b0; // Release reset
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
    createNode({1'b1, 8'd4}, {9'b110000000}, 46'd480); // 'sum node', 'null node', sum = 480

    // TEST 6 - L1 = Null, L2 = Sum Node
    $display("\n\n=== TEST 6: NULL + SUM NODE ===\n");
    createNode({9'b110000000}, {1'b1, 8'd4}, 46'd480); // 'null node', 'sum node', sum = 480

    // TEST 7 - L1 = Null, L2 = CHARACTER
    $display("\n\n=== TEST 7: NULL + CHARACTER ===\n");
    createNode({9'b110000000}, {1'b0, 8'd4}, 46'd480); // 'null node', 'character', sum = 480

    // TEST 8 - L1 = CHARACTER, L2 = NULL
    $display("\n\n=== TEST 8: CHARACTER + NULL ===\n");
    createNode({1'b0, 8'd4}, {9'b110000000}, 46'd480); // 'character', 'null node', sum = 480

    // TEST 9 - L1 = NULL, L2 = NULL
    $display("\n\n=== TEST 9: NULL + NULL ===\n");
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
    
    // TEST 10 - Clock count ramping test
    test_progress ++;
    $display("\n\n=== TEST 10: CLOCK COUNT RAMPING ===\n");
    $display("Starting clkCount ramp test from count: %d", clkCount);
    
    for (int i = 0; i < 121; i++) begin
        // Set up test data for each iteration
        least1 = {1'b0, 8'd48 + i[7:0] % 8'd10}; // Cycle through characters '0'-'9'
        least2 = {1'b0, 8'd65 + i[7:0] % 8'd26}; // Cycle through 'A'-'Z'
        sum = 46'd1000 + 46'(i);                // Increment sum each time
        
        HT_en = 4'b0011;
        #60; // Give enough time for operation to complete (increased from 40 to allow 3+ cycles per state)
        HT_en = 4'b0;
        #30; // Brief pause between operations (increased from 20 to allow proper settling)
        
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
    
    // TEST 11 - Maximum Node Indices
    test_progress ++;
    $display("\n\n=== TEST 11: MAXIMUM NODE INDICES ===\n");
    least1 = {1'b0, 8'b11111111}; // Max index 127
    least2 = {1'b0, 8'b11111111}; // Index 126
    sum = 46'd70368744177663;
    
    HT_en = 4'b0011;
    #75; // Increased timing to allow 3+ cycles per state for proper propagation
    $display("Test 11: Maximum Node Indices");
    $display("[%b]node[%b,%b,%b]", clkCount, node[63:55], node[54:46], node[45:0]);
    if (node == {(clkCount-7'd1), least1, least2, sum}) begin
        $display("✓ Test 11 PASSED");
    end else begin
        $display("✗ Test 11 FAILED");
        $display("  Expected: %b", {(clkCount-7'd1), least1, least2, sum});
        $display("  Actual:   %b", node);
    end
    
    HT_en = 4'b0;
    #30; // Increased timing for disable propagation
    
    // Reset for next test
    rst = 1'b1;
    #20;
    rst = 1'b0;
    #20;
    
    // TEST 12 - SRAM Not Ready
    test_progress ++;
    $display("\n\n=== TEST 12: SRAM NOT READY ===\n");
    least1 = {1'b1, 8'h10}; // Sum node
    least2 = {1'b0, 8'h42}; // 'B'
    sum = 46'd5000;
    SRAM_finished = 1'b0;   // SRAM not ready
    
    HT_en = 4'b0011;
    #150; // Wait longer for SRAM states - increased to allow multiple state transitions
    $display("SRAM Not Ready - Should stay in L1SRAM");
    $display("State: %b (should be 2=L1SRAM)", state);
    
    SRAM_finished = 1'b1;   // Now SRAM ready
    #75; // Increased timing for SRAM ready propagation
    $display("After SRAM ready - State: %b", state);
    
    HT_en = 4'b0000;
    #30; // Increased timing for disable

    // TEST 13 - OP_FIN SIGNAL TESTING
    test_progress ++;
    $display("\n\n=== TEST 13: OP_FIN SIGNAL TESTING ===\n");
    rst = 1'b1;
    #20;
    rst = 1'b0;
    #20;
    
    // Test that op_fin signals are properly generated
    least1 = {1'b0, 8'h50}; // 'P'
    least2 = {1'b0, 8'h51}; // 'Q'
    sum = 46'd1000;
    
    $display("Starting op_fin test...");
    $display("Initial: op_fin=%b, WorR=%b", op_fin, WorR);
    
    HT_en = 4'b0011;
    @(posedge clk);
    @(posedge clk);
    @(posedge clk); // Wait 3 cycles for enable
    $display("After enable: op_fin=%b, WorR=%b, state=%d", op_fin, WorR, state);
    
    // Wait for completion - increased from 15 to 20 cycles
    repeat (20) @(posedge clk);
    $display("After completion: op_fin=%b, WorR=%b, state=%d", op_fin, WorR, state);
    
    HT_en = 4'b0;
    @(posedge clk);
    @(posedge clk);
    @(posedge clk); // Wait 3 cycles for disable
    $display("After disable: op_fin=%b, WorR=%b, state=%d", op_fin, WorR, state);

    $display("\n\n=== ALL TESTS COMPLETED ===\n");

    // Finish the simulation
    #20 $finish;
  end
endmodule