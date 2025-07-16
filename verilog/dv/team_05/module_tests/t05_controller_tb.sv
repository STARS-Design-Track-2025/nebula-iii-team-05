`timescale 1ns/1ps

module t05_controller_tb;
    // Testbench signals
    logic clk, rst_n, cont_en;
    logic [3:0] finState, op_fin;
    logic [3:0] state_reg;
    logic finished_signal;
    
    // Clock generation
    always begin
        clk = 1'b0;
        #5;
        clk = 1'b1;
        #5; // 100MHz clock
    end
    
    // DUT instantiation
    t05_controller dut (
        .clk(clk),
        .rst_n(rst_n),
        .cont_en(cont_en),
        .finState(finState),
        .op_fin(op_fin),
        .state_reg(state_reg),
        .finished_signal(finished_signal)
    );
    
    // State and completion enums for reference
    typedef enum logic [3:0] {
        IDLE=0, HISTO=1, FLV=2, HTREE=3, CBS=4, TRN=5, SPI=6, ERROR=7, DONE=8
    } state_t;
    
    typedef enum logic [3:0] {
        IDLE_FIN=0, HFIN=1, FLV_FIN=2, HTREE_FIN=3, HTREE_FINISHED=4,
        CBS_FIN=5, TRN_FIN=6, SPI_FIN=7, ERROR_FIN=8
    } finState_t;
    
    typedef enum logic [3:0] {
        IDLE_S=0, HIST_S=1, FLV_S=2, HTREE_S=3, CBS_S=4, TRN_S=5, SPI_S=6, ERROR_S=7
    } op_fin_t;
    
    // Test counters for summary
    int passed_tests = 0;
    int total_tests = 0;
    
    // Task to show completion signal requirements for each state
    task show_transition_requirements();
        begin
            $display("\n=== STATE TRANSITION REQUIREMENTS ===");
            $display("IDLE→HISTO:   Set cont_en = 1");
            $display("HISTO→FLV:    Set finState = HFIN (1) + op_fin = HIST_S (1)");
            $display("FLV→HTREE:    Set finState = FLV_FIN (2) + op_fin = FLV_S (2)");
            $display("HTREE→CBS:    Set finState = HTREE_FINISHED (4) + op_fin = don't care");
            $display("HTREE→FLV:    Set finState = HTREE_FIN (3) + op_fin = HTREE_S (3)");
            $display("CBS→TRN:      Set finState = CBS_FIN (5) + op_fin = CBS_S (4)");
            $display("TRN→SPI:      Set finState = TRN_FIN (6) + op_fin = TRN_S (5)");
            $display("SPI→DONE:     Set finState = SPI_FIN (7) + op_fin = SPI_S (6)");
            $display("DONE→IDLE:    Automatic (no signals needed)");
            $display("ANY→ERROR:    Set finState = ERROR_FIN (8) OR op_fin = ERROR_S (7)");
            $display("====================================\n");
        end
    endtask
    
    // Task to properly advance from current state to next state
    task automatic auto_advance(input string test_name);
        logic [3:0] expected_next_state;
        logic [3:0] current_state;
        begin
            current_state = state_reg; // Capture current state at start
            $display("Starting %s from state %0d", test_name, current_state);
            
            case(current_state)
                IDLE: begin
                    cont_en = 1'b1;
                    expected_next_state = HISTO;
                    $display("Setting cont_en=1 to move IDLE→HISTO");
                end
                HISTO: begin
                    finState = HFIN;
                    op_fin = HIST_S;
                    expected_next_state = FLV;
                    $display("Setting HFIN + HIST_S to move HISTO→FLV");
                end
                FLV: begin
                    finState = FLV_FIN;
                    op_fin = FLV_S;
                    expected_next_state = HTREE;
                    $display("Setting FLV_FIN + FLV_S to move FLV→HTREE");
                end
                HTREE: begin
                    finState = HTREE_FINISHED; 
                    op_fin = 4'h0; // Don't care for HTREE_FINISHED
                    expected_next_state = CBS;
                    $display("Setting HTREE_FINISHED to move HTREE→CBS");
                end
                CBS: begin
                    finState = CBS_FIN;
                    op_fin = CBS_S;
                    expected_next_state = TRN;
                    $display("Setting CBS_FIN + CBS_S to move CBS→TRN");
                end
                TRN: begin
                    finState = TRN_FIN;
                    op_fin = TRN_S;
                    expected_next_state = SPI;
                    $display("Setting TRN_FIN + TRN_S to move TRN→SPI");
                end
                SPI: begin
                    finState = SPI_FIN;
                    op_fin = SPI_S;
                    expected_next_state = DONE;
                    $display("Setting SPI_FIN + SPI_S to move SPI→DONE");
                end
                DONE: begin
                    // DONE automatically goes to IDLE
                    expected_next_state = IDLE;
                    $display("DONE should automatically return to IDLE");
                end
                ERROR: begin
                    // Error state, typically stays in ERROR
                    expected_next_state = ERROR;
                    $display("Error state reached: %s", test_name);
                end
                default: begin
                    $error("Invalid current state for auto_advance: %0d", current_state);
                    finState = ERROR_FIN;
                    op_fin = ERROR_S;
                    expected_next_state = ERROR;
                end
            endcase

            // Wait for state machine to process the signals
            @(posedge clk);
            @(posedge clk);
            
            total_tests++;
            
            if (state_reg == expected_next_state) begin
                $display("✓ PASS: %s - State = %0d (expected %0d)", test_name, state_reg, expected_next_state);
                passed_tests++;
            end else begin
                $display("✗ FAIL: %s - State = %0d (expected %0d)", test_name, state_reg, expected_next_state);
            end
        end
    endtask
    
    // Task to set specific completion signals manually
    task set_completion(input logic [3:0] fin_val, input logic [3:0] op_val, input logic [3:0] expected_state, input string test_name);
        begin
            $display("Setting finState=%0d, op_fin=%0d for %s", fin_val, op_val, test_name);
            finState = fin_val;
            op_fin = op_val;
            @(posedge clk);
            @(posedge clk);
            total_tests++;
            
            if (state_reg == expected_state) begin
                $display("✓ PASS: %s - State = %0d (expected %0d)", test_name, state_reg, expected_state);
                passed_tests++;
            end else begin
                $display("✗ FAIL: %s - State = %0d (expected %0d)", test_name, state_reg, expected_state);
            end
        end
    endtask
    // Special task for HTREE loop back (HTREE→FLV instead of HTREE→CBS)
    task htree_loop_back(input string test_name);
        begin
            if (state_reg != HTREE) begin
                $display("✗ ERROR: htree_loop_back called from wrong state %0d (expected HTREE=3)", state_reg);
                return;
            end
            
            $display("Setting HTREE_FIN + HTREE_S to move HTREE→FLV (loop back)");
            finState = HTREE_FIN;
            op_fin = HTREE_S;
            @(posedge clk);
            @(posedge clk);
            total_tests++;
            
            if (state_reg == FLV) begin
                $display("✓ PASS: %s - State = %0d (FLV)", test_name, state_reg);
                passed_tests++;
            end else begin
                $display("✗ FAIL: %s - State = %0d (expected FLV=2)", test_name, state_reg);
            end
        end
    endtask
    
    // Test task to inject error and check result
    task inject_error(input string test_name);
        begin
            $display("--- %s ---", test_name);
            $display("Setting ERROR_FIN + ERROR_S to force error state");
            finState = ERROR_FIN;
            op_fin = ERROR_S;
            @(posedge clk);
            @(posedge clk);
            total_tests++;
            if (state_reg == ERROR) begin
                $display("✓ PASS: Error injection - State = %0d (ERROR)", state_reg);
                passed_tests++;
            end else begin
                $display("✗ FAIL: Error injection - State = %0d (expected ERROR=7)", state_reg);
            end
        end
    endtask
    
    // Task to check state and update counters
    task check_state(input logic [3:0] expected_state, input string test_name);
        begin
            total_tests++;
            if (state_reg == expected_state) begin
                $display("✓ PASS: %s - State = %0d", test_name, state_reg);
                passed_tests++;
            end else begin
                $display("✗ FAIL: %s - State = %0d (expected %0d)", test_name, state_reg, expected_state);
            end
        end
    endtask
    
    // Reset task
    task reset_dut();
        begin
            rst_n = 1'b0;
            cont_en = 1'b0;
            finState = 4'h0;
            op_fin = 4'h0;
            @(posedge clk);
            @(posedge clk);
            rst_n = 1'b1;
            @(posedge clk);
        end    endtask
    
    // Task to reset and verify IDLE state
    task reset_to_idle(input string test_name);
        begin
            reset_dut();
            cont_en = 1'b1;
            @(posedge clk);
            total_tests++;
            
            if (state_reg == IDLE) begin
                $display("✓ PASS: %s - State = %0d (IDLE)", test_name, state_reg);
                passed_tests++;
            end else begin
                $display("✗ FAIL: %s - State = %0d (expected IDLE=0)", test_name, state_reg);
            end
        end
    endtask
    
    // Comprehensive test sequence covering all state transitions
    task run_complete_sequence();
        begin
            $display("\n=== COMPLETE STATE MACHINE SEQUENCE TEST ===");
            $display("Testing all possible state transitions...\n");
            
            // 1. Reset and verify IDLE
            reset_to_idle("Reset to IDLE");
            
            // 2. Normal forward progression IDLE→HISTO→FLV→HTREE→CBS→TRN→SPI→DONE→IDLE
            $display("\n--- Testing normal forward progression ---");
            auto_advance("IDLE to HISTO");
            auto_advance("HISTO to FLV");
            auto_advance("FLV to HTREE");
            auto_advance("HTREE to CBS");
            auto_advance("CBS to TRN");
            auto_advance("TRN to SPI");
            auto_advance("SPI to DONE");
            auto_advance("DONE to IDLE");
            
            // 3. Test HTREE loop back (HTREE→FLV)
            $display("\n--- Testing HTREE loop back ---");
            auto_advance("IDLE to HISTO for loop test");
            auto_advance("HISTO to FLV for loop test");
            auto_advance("FLV to HTREE for loop test");
            htree_loop_back("HTREE loop back to FLV");
            
            // Continue from FLV again
            auto_advance("FLV to HTREE after loop");
            auto_advance("HTREE to CBS after loop");
            auto_advance("CBS to TRN after loop");
            auto_advance("TRN to SPI after loop");
            auto_advance("SPI to DONE after loop");
            auto_advance("DONE to IDLE after loop");
            
            // 4. Test error injection
            $display("\n--- Testing error injection ---");
            inject_error("Error injection test");
            check_state(ERROR, "Error state check");
            reset_to_idle("Reset from error state");
            
            $display("\n=== SEQUENCE TEST COMPLETE ===\n");
        end
    endtask

    initial begin
        $dumpfile("t05_controller.vcd");
        $dumpvars(0, t05_controller_tb);
        
        // Show transition requirements first
        show_transition_requirements();
        
        // Test 1: Basic Reset
        $display("=== TEST 1: Reset Behavior ===");
        reset_dut();
        check_state(IDLE, "Reset test");
        
        // Test 2: Enable controller
        $display("\n=== TEST 2: Enable Controller ===");
        cont_en = 1'b1;
        @(posedge clk);
        @(posedge clk);
        check_state(HISTO, "Enable test");
        
        // Test 2.5: Comprehensive sequence test
        $display("\n=== TEST 2.5: Comprehensive Sequence Test ===");
        run_complete_sequence();
        
        // Test 3: Normal operation flow
        $display("\n=== TEST 3: Normal Operation Flow ===");
        auto_advance("HISTO→FLV");
        auto_advance("FLV→HTREE");
        auto_advance("HTREE→CBS");
        auto_advance("CBS→TRN");
        auto_advance("TRN→SPI");
        auto_advance("SPI→DONE");
        
        // Check finished_signal
        total_tests++;
        if (finished_signal == 1'b1) begin
            $display("✓ PASS: Finished signal asserted in DONE state");
            passed_tests++;
        end else begin
            $display("✗ FAIL: Finished signal not asserted in DONE state");
        end
        
        @(posedge clk);
        check_state(IDLE, "Return to IDLE");
        
        // Test 4: HTREE loop case
        $display("\n=== TEST 4: HTREE Loop Test ===");
        reset_dut();
        cont_en = 1'b1;
        @(posedge clk);
        auto_advance("HISTO→FLV");
        auto_advance("FLV→HTREE");
        set_completion(HTREE_FIN, HTREE_S, FLV, "HTREE→FLV (loop back)");
        auto_advance("FLV→HTREE (second time)");
        auto_advance("HTREE→CBS (completion)");
        
        // Test 5: Error injection in each state
        $display("\n=== TEST 5: Error Injection Tests ===");
        reset_dut();
        cont_en = 1'b1;
        @(posedge clk);
        inject_error("Error in HISTO");
        
        reset_dut();
        cont_en = 1'b1;
        @(posedge clk);
        auto_advance("HISTO→FLV");
        inject_error("Error in FLV");
        
        // Test 6: Invalid completion signals
        $display("\n=== TEST 6: Invalid Completion Signals ===");
        reset_dut();
        cont_en = 1'b1;
        @(posedge clk);
        // Try wrong completion for HISTO - should stay in HISTO
        set_completion(FLV_FIN, HIST_S, HISTO, "Wrong finState for HISTO");
        set_completion(HFIN, FLV_S, HISTO, "Wrong op_fin for HISTO");
        set_completion(HFIN, HIST_S, FLV, "Correct completion for HISTO");
        
        // Test 7: Rapid cont_en toggling
        $display("\n=== TEST 7: Rapid cont_en Toggling ===");
        reset_dut();
        for (int i = 0; i < 5; i++) begin
            cont_en = 1'b1;
            @(posedge clk);
            cont_en = 1'b0;
            @(posedge clk);
            check_state(IDLE, $sformatf("Toggle %0d", i));
        end
        
        // Test 8: Edge case values
        $display("\n=== TEST 8: Edge Case Values ===");
        reset_dut();
        cont_en = 1'b1;
        @(posedge clk);
        finState = 4'hF; // Invalid value
        op_fin = 4'hF;   // Invalid value
        @(posedge clk);
        @(posedge clk);
        check_state(HISTO, "Invalid values test (should stay in HISTO)");
        
        // Test 9: Reset during operation
        $display("\n=== TEST 9: Reset During Operation ===");
        reset_dut();
        cont_en = 1'b1;
        @(posedge clk);
        auto_advance("HISTO→FLV");
        auto_advance("FLV→HTREE");
        // Reset in middle of operation
        $display("Resetting during HTREE state...");
        reset_dut();
        check_state(IDLE, "Mid-operation reset");
        
        // Test 10: Stuck state detection
        $display("\n=== TEST 10: Stuck State Test ===");
        reset_dut();
        cont_en = 1'b1;
        @(posedge clk);
        // Stay in HISTO without proper completion
        finState = 4'h0;
        op_fin = 4'h0;
        repeat(10) @(posedge clk);
        check_state(HISTO, "Stuck state test (should stay in HISTO)");
        
        // Test Summary
        $display("\n" + "="*50);
        $display("=== TEST SUMMARY ===");
        $display("Total Tests: %0d", total_tests);
        $display("Passed: %0d", passed_tests);
        $display("Failed: %0d", total_tests - passed_tests);
        if (passed_tests == total_tests) begin
            $display("🎉 ALL TESTS PASSED! 🎉");
        end else begin
            $display("❌ %0d TESTS FAILED", total_tests - passed_tests);
        end
        $display("="*50);
        
        #100;
        $finish;
    end
    
    // Monitor for unexpected state changes
    always @(posedge clk) begin
        if (state_reg > 8) begin
            $error("Invalid state detected: %0d", state_reg);
        end
    end
    
endmodule
