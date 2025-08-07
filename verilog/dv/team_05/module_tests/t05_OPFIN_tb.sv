// Testbench for t05_controller module (OPFIN version)
// Tests state machine transitions for compression and decompression flows
// Author: Team 05

`timescale 1ns / 1ps

module t05_OPFIN_tb;

    // Testbench signals matching the actual module interface
    logic clk;
    logic rst;
    logic cont_en;
    logic restart_en;
    logic compDecomp;
    logic [3:0] comp_state;
    logic [1:0] decomp_state;
    logic [3:0] opFin;
    logic finished_signal;
    logic compEN_reg;
    logic decompEN_reg;

    // DUT instantiation
    t05_OPFIN dut (
        .clk(clk),
        .rst(rst),
        .cont_en(cont_en),
        .restart_en(restart_en),
        .compDecomp(compDecomp),
        .comp_state(comp_state),
        .decomp_state(decomp_state),
        .opFin(opFin),
        .finished_signal(finished_signal),
        .compEN_reg(compEN_reg),
        .decompEN_reg(decompEN_reg)
    );

    // State enums (matching the module)
    typedef enum logic [3:0] {
        IDLE=0, SELECT=1, COMP=2, HISTO=3, FLV=4, HTREE=5, CBS=6, TRN=7, 
        SPI=8, DECOMP=9, STATE0=10, STATE1=11, STATE2=12, STATE3=13, DONE=14, ERROR=15
    } state_t;

    // Clock generation (100MHz)
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 10ns period = 100MHz
    end

    // Task to apply reset
    task apply_reset();
        begin
            rst = 1;
            #20;
            rst = 0;
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

    // Task to check current state by observing opFin output
    task check_opFin(input [3:0] expected_opFin, input string state_name);
        begin
            if (opFin == expected_opFin) begin
                $display("✓ opFin check PASSED: %s (opFin=%0d) at time %0t", 
                         state_name, expected_opFin, $time);
            end else begin
                $display("✗ opFin check FAILED: Expected %s (%0d), got %0d at time %0t", 
                         state_name, expected_opFin, opFin, $time);
            end
        end
    endtask

    // Task to set compression state and test
    task test_comp_state(input [3:0] comp_val, input [3:0] expected_opFin, input string state_name);
        begin
            comp_state = comp_val;
            #10;
            pulse_continue();
            #20;
            check_opFin(expected_opFin, state_name);
        end
    endtask

    // Task to set decompression state and test  
    task test_decomp_state(input [1:0] decomp_val, input [3:0] expected_opFin, input string state_name);
        begin
            decomp_state = decomp_val;
            #10;
            pulse_continue();
            #20;
            check_opFin(expected_opFin, state_name);
        end
    endtask

    // Main test sequence
    initial begin
        $dumpfile("t05_OPFIN.vcd");
        $dumpvars(0, t05_OPFIN_tb);

        // Initialize signals
        rst = 0;
        cont_en = 0;
        restart_en = 0;
        compDecomp = 0;
        comp_state = 0;
        decomp_state = 0;

        $display("Starting t05_OPFIN testbench...");
        
        // Test 1: Complete Compression Flow
        $display("\n=== Test 1: Complete Compression Flow ===");
        apply_reset();
        #20;
        check_opFin(IDLE, "IDLE_AFTER_RESET");
        
        // Set compression mode BEFORE going to SELECT
        compDecomp = 1; // Choose compression
        #10;
        
        // IDLE -> SELECT (wait for cont_en)
        $display("Step 1: IDLE -> SELECT");
        pulse_continue();
        #20;
        check_opFin(SELECT, "SELECT_STATE");
        
        // SELECT automatically goes to COMP because compDecomp = 1
        #10;
        check_opFin(COMP, "COMP_STATE");
        
        // COMP -> Enable compression (wait for cont_en again)
        $display("Step 2: Enable compression mode");
        pulse_continue();
        #20;
        if (compEN_reg) begin
            $display("✓ compEN_reg correctly asserted");
        end else begin
            $display("✗ compEN_reg not asserted");
        end
        
        // Now comp_state controls opFin - simulate compression flow
        $display("Step 3: Compression states controlled by comp_state");
        comp_state = 1; // HISTO
        #20;
        check_opFin(HISTO, "HISTO_STATE");
        
        comp_state = 2; // FLV
        #20;
        check_opFin(FLV, "FLV_STATE");
        
        comp_state = 3; // HTREE
        #20;
        check_opFin(HTREE, "HTREE_STATE");
        
        comp_state = 4; // CBS
        #20;
        check_opFin(CBS, "CBS_STATE");
        
        comp_state = 5; // TRN
        #20;
        check_opFin(TRN, "TRN_STATE");
        
        comp_state = 6; // SPI
        #20;
        check_opFin(SPI, "SPI_STATE");
        
        comp_state = 8; // DONE
        #20;
        check_opFin(DONE, "DONE_STATE");
        
        // DONE -> IDLE (with restart_en)
        $display("Step 4: DONE -> IDLE with restart");
        apply_restart();
        #20;
        check_opFin(IDLE, "BACK_TO_IDLE");

        // Test 2: Complete Decompression Flow
        $display("\n=== Test 2: Complete Decompression Flow ===");
        
        // Set decompression mode BEFORE going to SELECT
        compDecomp = 0; // Choose decompression
        #10;
        
        // IDLE -> SELECT
        $display("Step 1: IDLE -> SELECT");
        pulse_continue();
        #20;
        check_opFin(SELECT, "SELECT_STATE");
        
        // SELECT automatically goes to DECOMP because compDecomp = 0
        #10;
        check_opFin(DECOMP, "DECOMP_STATE");
        
        // DECOMP -> Enable decompression
        $display("Step 2: Enable decompression mode");
        pulse_continue();
        #20;
        if (decompEN_reg) begin
            $display("✓ decompEN_reg correctly asserted");
        end else begin
            $display("✗ decompEN_reg not asserted");
        end
        
        // Now decomp_state controls opFin
        $display("Step 3: Decompression states controlled by decomp_state");
        decomp_state = 2'd0; // STATE0
        #20;
        check_opFin(STATE0, "STATE0");
        
        decomp_state = 2'd1; // STATE1
        #20;
        check_opFin(STATE1, "STATE1");
        
        decomp_state = 2'd2; // STATE2
        #20;
        check_opFin(STATE2, "STATE2");
        
        decomp_state = 2'd3; // STATE3
        #20;
        check_opFin(STATE3, "STATE3");
        
        // Note: In a real system, the decompression controller would eventually
        // signal completion and transition to DONE. For this testbench, we're only
        // testing that decomp_state properly controls the opFin output.
        $display("Decompression flow complete - decomp_state controls opFin correctly");
        
        // Test restart from decompression mode
        $display("Step 4: Restart from decompression mode");
        apply_restart();
        #20;
        check_opFin(IDLE, "BACK_TO_IDLE_FROM_DECOMP");

        // Test 3: Error State Testing
        $display("\n=== Test 3: Error State Testing ===");
        pulse_continue(); // IDLE -> SELECT
        #20;
        compDecomp = 1; // Choose compression
        #10;
        pulse_continue(); // Enable compression
        #20;
        
        comp_state = 7; // ERROR state
        #20;
        check_opFin(ERROR, "ERROR_STATE");
        
        // Test restart from error
        apply_restart();
        #20;
        check_opFin(IDLE, "RESTART_FROM_ERROR");

        // Test 4: Mode Switching Before Enable
        $display("\n=== Test 4: Mode Switching in SELECT State ===");
        pulse_continue(); // IDLE -> SELECT
        #20;
        check_opFin(SELECT, "SELECT_STATE");
        
        // Switch modes in SELECT state
        compDecomp = 1; // Compression
        #10;
        check_opFin(COMP, "SWITCHED_TO_COMP");
        
        compDecomp = 0; // Decompression
        #10;
        check_opFin(DECOMP, "SWITCHED_TO_DECOMP");
        
        compDecomp = 1; // Back to compression
        #10;
        check_opFin(COMP, "BACK_TO_COMP");

        // Test 5: Invalid States
        $display("\n=== Test 5: Invalid State Testing ===");
        pulse_continue(); // Enable compression
        #20;
        
        comp_state = 4'hF; // Invalid state (15)
        #20;
        check_opFin(IDLE, "INVALID_COMP_STATE_DEFAULT");
        
        // Switch to decompression and test invalid decomp_state
        apply_restart();
        pulse_continue(); // IDLE -> SELECT
        compDecomp = 0; // Decompression
        #10;
        pulse_continue(); // Enable decompression
        #20;
        
        // All decomp_state values (0-3) are valid, so test edge case
        decomp_state = 2'd3; // Maximum valid value
        #20;
        check_opFin(STATE3, "MAX_VALID_DECOMP_STATE");

        $display("\n=== All Tests Completed ===");
        #100;
        $finish;
    end

    // Monitor for debugging
    initial begin
        $monitor("Time=%0t | opFin=%0d | compDecomp=%b | cont_en=%b | compEN_reg=%b | decompEN_reg=%b | comp_state=%0d | decomp_state=%0d", 
                 $time, opFin, compDecomp, cont_en, compEN_reg, decompEN_reg, comp_state, decomp_state);
    end

endmodule
