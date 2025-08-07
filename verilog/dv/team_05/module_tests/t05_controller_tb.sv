// Testbench for t05_controller module
// Tests state machine transitions for compression flow
// Author: Team 05

`timescale 1ns / 1ps

module t05_controller_tb;

    // Testbench signals matching the actual module interface
    logic clk;
    logic rst_n;
    logic cont_en;
    logic restart_en;
    logic compEN;
    logic [3:0] finState;
    logic [3:0] op_fin;
    logic [3:0] state_reg;
    logic finished_signal;

    // DUT instantiation
    t05_controller dut (
        .clk(clk),
        .rst_n(rst_n),
        .cont_en(cont_en),
        .restart_en(restart_en),
        .compEN(compEN),
        .finState(finState),
        .op_fin(op_fin),
        .state_reg(state_reg),
        .finished_signal(finished_signal)
    );

// Testbench for t05_controller module
// Tests state machine transitions for compression flow
// Author: Team 05

`timescale 1ns / 1ps

module t05_controller_tb;

    // Testbench signals matching the actual module interface
    logic clk;
    logic rst_n;
    logic cont_en;
    logic restart_en;
    logic compEN;
    logic [3:0] finState;
    logic [3:0] op_fin;
    logic [3:0] state_reg;
    logic finished_signal;

    // DUT instantiation
    t05_controller dut (
        .clk(clk),
        .rst_n(rst_n),
        .cont_en(cont_en),
        .restart_en(restart_en),
        .compEN(compEN),
        .finState(finState),
        .op_fin(op_fin),
        .state_reg(state_reg),
        .finished_signal(finished_signal)
    );

    // State and completion enums (matching the module)
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

    // Clock generation (100MHz)
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 10ns period = 100MHz
    end

    // Task to apply reset
    task apply_reset();
        begin
            rst_n = 0;
            #20;
            rst_n = 1;
            #10;
            $display("Reset applied at time %0t", $time);
        end
    endtask

    // Task to apply restart
    task apply_restart();
        begin
            restart_en = 1;
            #10;
            restart_en = 0;
            #10;
            $display("Restart applied at time %0t", $time);
        end
    endtask

    // Task to pulse cont_en
    task pulse_continue();
        begin
            cont_en = 1;
            #10;
            cont_en = 0;
            #10;
            $display("Continue pulsed at time %0t", $time);
        end
    endtask

    // Task to check current state
    task check_state(input [3:0] expected_state, input string state_name);
        begin
            if (state_reg == expected_state) begin
                $display("✓ State check PASSED: %s (state=%0d) at time %0t", 
                         state_name, expected_state, $time);
            end else begin
                $display("✗ State check FAILED: Expected %s (%0d), got %0d at time %0t", 
                         state_name, expected_state, state_reg, $time);
            end
        end
    endtask

    // Task to simulate module completion with proper signals
    task complete_operation(input [3:0] fin_signal, input [3:0] op_signal, input string operation_name);
        begin
            $display("Completing %s with finState=%0d, op_fin=%0d", operation_name, fin_signal, op_signal);
            finState = fin_signal;
            op_fin = op_signal;
            #20; // Wait for state machine to process
            // Clear completion signals
            finState = IDLE_FIN;
            op_fin = IDLE_S;
            #10;
        end
    endtask

    // Task to simulate error condition
    task trigger_error(input string error_type);
        begin
            $display("Triggering %s error", error_type);
            if (error_type == "module") begin
                finState = ERROR_FIN;
                op_fin = IDLE_S; // Keep op_fin normal
            end else if (error_type == "sram") begin
                finState = IDLE_FIN; // Keep finState normal
                op_fin = ERROR_S;
            end else begin // both
                finState = ERROR_FIN;
                op_fin = ERROR_S;
            end
            #20;
            // Clear error signals
            finState = IDLE_FIN;
            op_fin = IDLE_S;
            #10;
        end
    endtask

    // Main test sequence
    initial begin
        $dumpfile("t05_controller.vcd");
        $dumpvars(0, t05_controller_tb);

        // Initialize signals
        rst_n = 1;
        cont_en = 0;
        restart_en = 0;
        compEN = 1; // Enable compression mode
        finState = IDLE_FIN;
        op_fin = IDLE_S;

        $display("Starting t05_controller testbench...");
        
        // Test 1: Initial reset
        $display("\n=== Test 1: Reset Functionality ===");
        apply_reset();
        check_state(IDLE, "IDLE");

        // Test 2: Basic state transitions - IDLE to HISTO
        $display("\n=== Test 2: IDLE to HISTO Transition ===");
        pulse_continue();
        #20;
        check_state(HISTO, "HISTO");

        // Test 3: HISTO to FLV (normal completion)
        $display("\n=== Test 3: HISTO to FLV (Normal Completion) ===");
        complete_operation(HFIN, HIST_S, "HISTO");
        check_state(FLV, "FLV");

        // Test 4: FLV to HTREE
        $display("\n=== Test 4: FLV to HTREE ===");
        complete_operation(FLV_FIN, FLV_S, "FLV");
        check_state(HTREE, "HTREE");

        // Test 5: HTREE loop back to FLV
        $display("\n=== Test 5: HTREE Loop Back to FLV ===");
        complete_operation(HTREE_FIN, HTREE_S, "HTREE_LOOP");
        check_state(FLV, "FLV");

        // Test 6: FLV to HTREE again
        $display("\n=== Test 6: FLV to HTREE (Second Time) ===");
        complete_operation(FLV_FIN, FLV_S, "FLV");
        check_state(HTREE, "HTREE");

        // Test 7: HTREE to CBS (finished)
        $display("\n=== Test 7: HTREE to CBS (Finished) ===");
        complete_operation(HTREE_FINISHED, IDLE_S, "HTREE_FINISHED");
        check_state(CBS, "CBS");

        // Test 8: CBS to TRN
        $display("\n=== Test 8: CBS to TRN ===");
        complete_operation(CBS_FIN, CBS_S, "CBS");
        check_state(TRN, "TRN");

        // Test 9: TRN to SPI
        $display("\n=== Test 9: TRN to SPI ===");
        complete_operation(TRN_FIN, TRN_S, "TRN");
        check_state(SPI, "SPI");

        // Test 10: SPI to DONE
        $display("\n=== Test 10: SPI to DONE ===");
        complete_operation(SPI_FIN, SPI_S, "SPI");
        check_state(DONE, "DONE");

        // Test 11: Check finished signal
        $display("\n=== Test 11: Check Finished Signal ===");
        #20;
        if (finished_signal) begin
            $display("✓ finished_signal correctly asserted in DONE state");
        end else begin
            $display("✗ finished_signal not asserted in DONE state");
        end

        // Test 12: DONE to IDLE with restart
        $display("\n=== Test 12: DONE to IDLE (Restart) ===");
        apply_restart();
        check_state(IDLE, "IDLE");

        // Test 13: Error handling from HISTO
        $display("\n=== Test 13: Error Handling from HISTO ===");
        pulse_continue(); // Go to HISTO
        #20;
        trigger_error("module");
        check_state(ERROR, "ERROR");

        // Test 14: Error handling from FLV
        $display("\n=== Test 14: Error Handling from FLV ===");
        apply_reset();
        pulse_continue(); // IDLE to HISTO
        #20;
        complete_operation(HFIN, HIST_S, "HISTO"); // HISTO to FLV
        trigger_error("sram");
        check_state(ERROR, "ERROR");

        // Test 15: compEN disabled
        $display("\n=== Test 15: compEN Disabled ===");
        apply_reset();
        compEN = 0; // Disable compression
        pulse_continue();
        #20;
        check_state(IDLE, "IDLE"); // Should stay in IDLE

        // Test 16: Re-enable compEN
        $display("\n=== Test 16: Re-enable compEN ===");
        compEN = 1; // Re-enable compression
        pulse_continue();
        #20;
        check_state(HISTO, "HISTO");

        // Test 17: Invalid completion signals
        $display("\n=== Test 17: Invalid Completion Signals ===");
        // Try wrong signals - should stay in HISTO
        finState = CBS_FIN; // Wrong signal for HISTO
        op_fin = CBS_S;
        #30;
        check_state(HISTO, "HISTO"); // Should stay in HISTO
        
        // Clear signals
        finState = IDLE_FIN;
        op_fin = IDLE_S;

        // Test 18: Rapid state changes
        $display("\n=== Test 18: Complete Flow Test ===");
        apply_reset();
        
        // Complete full flow quickly
        pulse_continue(); // IDLE to HISTO
        #20;
        complete_operation(HFIN, HIST_S, "HISTO");
        complete_operation(FLV_FIN, FLV_S, "FLV");
        complete_operation(HTREE_FIN, HTREE_S, "HTREE_LOOP");
        complete_operation(FLV_FIN, FLV_S, "FLV");
        complete_operation(HTREE_FINISHED, IDLE_S, "HTREE_FINISHED");
        complete_operation(CBS_FIN, CBS_S, "CBS");
        complete_operation(TRN_FIN, TRN_S, "TRN");
        complete_operation(SPI_FIN, SPI_S, "SPI");
        check_state(DONE, "DONE");
        
        apply_restart();
        check_state(IDLE, "IDLE");

        $display("\n=== All Tests Completed ===");
        #100;
        $finish;
    end

    // Monitor for debugging
    initial begin
        $monitor("Time=%0t | state_reg=%0d | compEN=%b | cont_en=%b | finState=%0d | op_fin=%0d | finished=%b", 
                 $time, state_reg, compEN, cont_en, finState, op_fin, finished_signal);
    end

endmodule