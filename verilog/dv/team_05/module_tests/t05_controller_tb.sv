`timescale 1ns/1ps

module t05_controller_tb;
    // Testbench signals
    logic clk, rst, cont_en, restart_en;
    logic [3:0] finState, op_fin;
    logic [3:0] state_reg;
    logic finished_signal;
    int test_progress = 0;

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
        .rst(rst),
        .cont_en(cont_en),
        .restart_en(restart_en),
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

    // Reset task
    task automatic reset();
        begin
            $display("=== PERFORMING RESET ===");
            rst = 1'b1;
            cont_en = 1'b0;
            finState = 4'h0;
            op_fin = 4'h0;
            
            // Hold reset for longer period
            #100;  // Hold reset longer
            rst = 1'b0;
            #100;  // Wait longer after reset release
            
            // Check reset worked
            if (state_reg !== IDLE) begin
                $error("Reset failed, state_reg = %0d (expected IDLE=0)", state_reg);
                $display("State register shows: %b", state_reg);
            end else begin
                $display("-=-=-=-=-=-=-=-Reset Complete: state_reg = %0d-=-=-=-=-=-=-=-", state_reg);
            end
        end
    endtask
    
    // Task to properly advance from current state to next state
    task automatic auto_advance(input string test_name,input int i, int err); // err 1 = module error, 2 = SRAM error, 0 = normal, 3 = both error
        logic [3:0] expected_next_state;
        logic [3:0] current_state;
        restart_en = 1'b0;
        begin
            current_state = state_reg; // Capture current state at start
            $display("Starting %s from state %0d", test_name, current_state);
            
            // Check for unknown/uninitialized state
            if (current_state === 4'bxxxx) begin
                $error("State is uninitialized (X)! Controller reset failed.");
                $finish; // Exit simulation instead of return
            end
            
            case(current_state)
                IDLE: begin
                    cont_en = 1'b1;
                    restart_en = 1'b0;
                    expected_next_state = HISTO;
                    $display("Setting cont_en=1 to move IDLE→HISTO");
                end
                HISTO: begin
                    cont_en = 1'b0; // Clear cont_en after leaving IDLE
                    $display("Clearing cont_en - now using completion signals");
                    case (err)
                        0: begin
                            finState = HFIN;
                            #15; // simulate delay
                            op_fin = HIST_S;
                            #20; // Wait for state machine to process
                            expected_next_state = FLV;
                            $display("Setting HFIN + HIST_S to move HISTO→FLV");
                            // Wait for one clock cycle for finState to be registered
                            #10;
                        end
                        1: begin
                            // Simulate module error
                            finState = ERROR_FIN;
                            #15;
                            op_fin = HIST_S;
                            #20;
                            expected_next_state = ERROR;
                            $display("Simulating module error, moving to ERROR state");
                            // Wait for one clock cycle for finState to be registered
                            #10;
                        end
                        2: begin
                            // Simulate SRAM error
                            finState = HFIN;
                            #15;
                            op_fin = ERROR_S; 
                            #20;
                            expected_next_state = ERROR;
                            $display("Simulating SRAM error, moving to ERROR state");
                            // Wait for one clock cycle for finState to be registered
                            #10;
                        end
                        3: begin
                            // Simulate both errors
                            finState = ERROR_FIN;
                            #15;
                            op_fin = ERROR_S; 
                            #20;
                            expected_next_state = ERROR;
                            $display("Simulating both module and SRAM errors, moving to ERROR state");
                            // Wait for one clock cycle for finState to be registered
                            #10;
                        end
                    endcase
                end
                FLV: begin
                    cont_en = 1'b0; // Keep cont_en low for all non-IDLE states
                    case (err)
                        0: begin
                            finState = FLV_FIN;
                            #100;
                            op_fin = FLV_S; 
                            #20;
                            expected_next_state = HTREE;
                            $display("Setting FLV_FIN + FLV_S to move FLV→HTREE");
                            // Wait for one clock cycle for finState to be registered
                            #10;
                        end
                        1: begin
                            // Simulate module error
                            finState = ERROR_FIN;
                            #100;
                            op_fin = FLV_S; 
                            #20;
                            expected_next_state = ERROR;
                            $display("Simulating module error, moving to ERROR state");
                            #10;
                        end
                        2: begin
                            // Simulate SRAM error
                            finState = FLV_FIN; // Assume HTREE_FINISHED is a valid state for SRAM error
                            #100;
                            op_fin = ERROR_S; // Continue with HTREE operation
                            #20;
                            expected_next_state = ERROR;
                            $display("Simulating SRAM error, moving to ERROR state");
                            #10;
                        end
                        3: begin
                            // Simulate both errors
                            finState = ERROR_FIN;
                            #100;
                            op_fin = ERROR_S; 
                            #20;
                            expected_next_state = ERROR;
                            $display("Simulating both module and SRAM errors, moving to ERROR state");
                            #10;
                        end
                    endcase
                end
                HTREE: begin
                    cont_en = 1'b0; // Keep cont_en low for all non-IDLE states
                    if (i == 1) begin
                        // Special case for HTREE loop back
                        case (err)
                            0: begin
                                finState = HTREE_FIN;
                                #100;
                                op_fin = HTREE_S; 
                                #20;
                                expected_next_state = FLV;
                                $display("Setting HTREE_FIN + HTREE_S to move HTREE→FLV (loop back)");
                                #10;
                            end
                            1: begin
                                // Simulate module error
                                finState = ERROR_FIN;
                                #100;
                                op_fin = HTREE_S; 
                                #20;
                                expected_next_state = ERROR;
                                $display("Simulating module error, moving to ERROR state");
                                #10;
                            end
                            2: begin
                                // Simulate SRAM error
                                finState = HTREE_FIN;
                                #100;
                                op_fin = ERROR_S; 
                                #20;
                                expected_next_state = ERROR;
                                $display("Simulating SRAM error, moving to ERROR state");
                                #10;
                            end
                            3: begin
                                // Simulate both errors
                                finState = ERROR_FIN;
                                #100;
                                op_fin = ERROR_S; 
                                #20;
                                expected_next_state = ERROR;
                                $display("Simulating both module and SRAM errors, moving to ERROR state");
                                #10;
                            end
                        endcase
                    end else begin
                        case (err)
                            0: begin
                                finState = HTREE_FINISHED;
                                #100;
                                op_fin = 4'b0; 
                                #20;
                                expected_next_state = CBS;
                                $display("Setting HTREE_FINISHED to move HTREE→CBS");
                                #10;
                            end
                            1,2,3: begin
                                // Simulate module error
                                finState = ERROR_FIN;
                                #100;
                                op_fin = 4'b0; 
                                #20;
                                expected_next_state = ERROR;
                                $display("Simulating module error, moving to ERROR state");
                                #10;
                            end
                        endcase
                    end
                end
                CBS: begin
                    cont_en = 1'b0; // Keep cont_en low for all non-IDLE states
                    case (err)
                        0: begin
                            finState = CBS_FIN;
                            #100;
                            op_fin = CBS_S; 
                            #20;
                            expected_next_state = TRN;
                            $display("Setting CBS_FIN + CBS_S to move CBS→TRN");
                            #10;
                        end
                        1: begin
                            // Simulate module error
                            finState = ERROR_FIN;
                            #100;
                            op_fin = CBS_S; 
                            #20;
                            expected_next_state = ERROR;
                            $display("Simulating module error, moving to ERROR state");
                            #10;
                        end
                        2: begin
                            // Simulate SRAM error
                            finState = CBS_FIN; 
                            #100;
                            op_fin = ERROR_S;  
                            #20;
                            expected_next_state = ERROR;
                            $display("Simulating SRAM error, moving to ERROR state");
                            #10;
                        end
                        3: begin
                            // Simulate both errors
                            finState = ERROR_FIN;
                            #100;
                            op_fin = ERROR_S; 
                            #20;
                            expected_next_state = ERROR;
                            $display("Simulating both module and SRAM errors, moving to ERROR state");
                            #10;
                        end
                    endcase
                end
                TRN: begin
                    cont_en = 1'b0; // Keep cont_en low for all non-IDLE states
                    case (err)
                        0: begin
                            finState = TRN_FIN;
                            #100;
                            op_fin = TRN_S; 
                            #20;
                            expected_next_state = SPI;
                            $display("Setting TRN_FIN + TRN_S to move TRN→SPI");
                            #10;
                        end
                        1: begin
                            // Simulate module error
                            finState = ERROR_FIN;
                            #100;
                            op_fin = TRN_S; 
                            #20;
                            expected_next_state = ERROR;
                            $display("Simulating module error, moving to ERROR state");
                            #10;
                        end
                        2: begin
                            // Simulate SRAM error
                            finState = TRN_FIN; 
                            #100;
                            op_fin = ERROR_S; 
                            #20; 
                            expected_next_state = ERROR;
                            $display("Simulating SRAM error, moving to ERROR state");
                            #10;
                        end
                        3: begin
                            // Simulate both errors
                            finState = ERROR_FIN;
                            #100;
                            op_fin = ERROR_S; 
                            #20;
                            expected_next_state = ERROR;
                            $display("Simulating both module and SRAM errors, moving to ERROR state");
                            #10;
                        end
                    endcase
                end
                SPI: begin
                    cont_en = 1'b0; // Keep cont_en low for all non-IDLE states
                    case (err)
                        0: begin
                            finState = SPI_FIN;
                            #100;
                            op_fin = SPI_S; 
                            #20;
                            expected_next_state = DONE;
                            $display("Setting SPI_FIN + SPI_S to move SPI→DONE");
                            #10;
                        end
                        1: begin
                            // Simulate module error
                            finState = ERROR_FIN;
                            #100;
                            op_fin = SPI_S; 
                            #20;
                            expected_next_state = ERROR;
                            $display("Simulating module error, moving to ERROR state");
                            #10;
                        end
                        2: begin
                            // Simulate SRAM error
                            finState = SPI_FIN; 
                            #100;
                            op_fin = ERROR_S;  
                            #20;
                            expected_next_state = ERROR;
                            $display("Simulating SRAM error, moving to ERROR state");
                            #10;
                        end
                        3: begin
                            // Simulate both errors
                            finState = ERROR_FIN;
                            #100;
                            op_fin = ERROR_S; 
                            #20;
                            expected_next_state = ERROR;
                            $display("Simulating both module and SRAM errors, moving to ERROR state");
                            #10;
                        end
                    endcase
                end
                DONE: begin
                    cont_en = 1'b0; // Keep cont_en low for all non-IDLE states
                    // DONE automatically goes to IDLE - clear signals
                    finState = 4'h0;
                    op_fin = 4'h0; 
                    #20;
                    restart_en = 1'b1;
                    #20;
                    expected_next_state = IDLE;
                    $display("DONE should automatically return to IDLE");
                    // Wait for one clock cycle for finState to be registered
                    #10;
                end
                ERROR: begin
                    cont_en = 1'b0; // Keep cont_en low for all non-IDLE states
                    // Error state, typically stays in ERROR
                    #20;
                    expected_next_state = ERROR;
                    $display("Error state reached: %s", test_name);
                    #10;
                end
                default: begin
                    cont_en = 1'b0; // Keep cont_en low for all non-IDLE states
                    $error("Invalid current state for auto_advance: %0d", current_state);
                    finState = ERROR_FIN;
                    op_fin = ERROR_S;
                    expected_next_state = ERROR;
                end
            endcase

            // Wait for state machine to process the signals
            #20;
            #20;
            
            total_tests++;
            
            if (state_reg == expected_next_state) begin
                $display("✓ PASS: %s - State = %0d (expected %0d)\n", test_name, state_reg, expected_next_state);
                passed_tests++;
            end else begin
                $display("✗ FAIL: %s - State = %0d (expected %0d)\n", test_name, state_reg, expected_next_state);
            end
        end
    endtask
    initial begin
        // Variable declarations for testing
        logic [3:0] current_state_snapshot;
        
        $dumpfile("t05_controller.vcd"); 
        $dumpvars(0, t05_controller_tb);

        
        // Initialize ALL signals at start
        finState = 4'h0;
        op_fin = 4'h0;
        cont_en = 1'b0;
        rst = 1'b1;  // Start with reset asserted
        
        // Wait for several clock cycles before releasing reset
        #100;
        
        // Now do proper reset
        reset();
        
        // Check if state initialized properly
        $display("After reset: state_reg = %0d", state_reg);
        if (state_reg !== IDLE) begin
            $error("State not properly initialized! state_reg = %0d (should be IDLE=0)", state_reg);
            $finish;
        end

    // BASIC STATE MACHINE FLOW
        test_progress ++;
        $display("\n\nTEST 1: BASIC MACHINE FLOW\n");

        auto_advance("Test 1A: IDLE to HISTO", 0,0);
        #5;
        auto_advance("Test 1B: HISTO to FLV", 0,0);
        #5;
        auto_advance("Test 1C: FLV to HTREE", 0,0);
        #5;
        auto_advance("Test 1D: HTREE to FLV", 1,0);
        #5;
        auto_advance("Test 1E: FLV to HTREE", 0,0);
        #5;
        auto_advance("Test 1F: HTREE to CBS", 0,0);
        #5;
        auto_advance("Test 1G: CBS to TRN", 0,0);
        #5;
        auto_advance("Test 1H: TRN to SPI", 0,0);
        #5;
        auto_advance("Test 1I: SPI to DONE", 0,0);
        #5;
        auto_advance("Test 1J: DONE to IDLE", 0,0);
        #5;

    // HTREE LOOPING
        test_progress ++;
        $display("TEST 2: HTREE LOOPING");

        auto_advance("Test 2A: IDLE to HISTO", 0,0);
        #5;
        auto_advance("Test 2B: HISTO to FLV", 0,0);
        #5;
        for (int i = 0; i < 128; i++) begin
            auto_advance("Test 2C: FLV to HTREE", 0,0);
            #5;
            auto_advance("Test 2D: HTREE to FLV", 1,0);
            #5;
        end
        auto_advance("Test 2E: FLV to HTREE", 0,0);
        #5;
        auto_advance("Test 2F: HTREE to CBS", 0,0);
        #5;
        auto_advance("Test 2G: CBS to TRN", 0,0);
        #5;
        auto_advance("Test 2H: TRN to SPI", 0,0);
        #5;
        auto_advance("Test 2I: SPI to DONE", 0,0);
        #5;
        auto_advance("Test 2J: DONE to IDLE", 0,0);
        #5;


    // ERROR HANDLING
        test_progress ++;
        $display("TEST 3: ERROR HANDLING");

        for (int targetState = 0; targetState < 6; targetState++) begin
            for (int testMode = 0; testMode < 3; testMode++) begin
                reset();

                // Advance to the desired state using mode 0
                for (int a = 0; a < targetState; a++) begin
                    auto_advance("--", 0, 0);
                    #5;
                end

                // Apply test mode (1, 2, or 3) at the target state
                auto_advance($sformatf("Test 3A: ERROR to %0d", targetState), 0, testMode);
                #5;
            end
        end
        reset();
    // OPERATION AFTER ERROR
        test_progress ++;
        $display("TEST 4: OPERATION AFTER ERROR");
        auto_advance("Test 4A: IDLE to HISTO", 0,0);
        #5;
        auto_advance("Test 4B: HISTO to FLV", 0,0);
        #5;
        auto_advance("Test 4C: FLV to HTREE", 0,0);
        #5;
        auto_advance("Test 4D: HTREE to FLV", 1,0);
        #5;
        auto_advance("Test 4E: FLV to HTREE", 0,0);
        #5;
        auto_advance("Test 4F: HTREE to CBS/ ERROR", 0,3);
        #5;
        auto_advance("Test 4A: IDLE to HISTO", 0,0);
        #5;
        auto_advance("Test 4B: HISTO to FLV", 0,0);
        #5;
        auto_advance("Test 4C: FLV to HTREE", 0,0);
        #5;
        auto_advance("Test 4D: HTREE to FLV", 1,0);
        #5;
        auto_advance("Test 4E: FLV to HTREE", 0,0);
        #5;
        auto_advance("Test 4F: HTREE to CBS", 0,0);
        #5;
        auto_advance("Test 4G: CBS to TRN", 0,0);
        #5;
        auto_advance("Test 4H: TRN to SPI", 0,0);
        #5;
        auto_advance("Test 4I: SPI to DONE", 0,0);
        #5;
        auto_advance("Test 4J: DONE to IDLE", 0,0);
        #5;


    // ENABLE CONTROL
        test_progress ++;
        $display("TEST 5: ENABLE CONTROL");

        cont_en = 1'b1; // Enable control signal
        #5;
        auto_advance("Test 5A: IDLE to HISTO", 0,0);
        cont_en = 1'b0;
        #1;
        cont_en = 1'b1;
        #1;
        cont_en = 1'b1;
        #1;
        auto_advance("Test 5B: HISTO to FLV", 0,0);
        #5;
        cont_en = 1'b0; // Disable control signal
        auto_advance("Test 5C: FLV to HTREE", 0,0);
        #5;
        cont_en = 1'b1; // Re-enable control signal
        #5;
        auto_advance("Test 5D: HTREE to FLV", 1,0);
        #5;
        auto_advance("Test 5E: FLV to HTREE", 0,0);
        #5;


    // INVALID COMPLETION SIGNALS
        test_progress ++;
        $display("TEST 6: INVALID COMPLETION SIGNALS");

        reset();
        auto_advance("Test 6A: IDLE to HISTO", 0,0);
        #5;
        auto_advance("Test 6B: HISTO to FLV", 0,0);
        #5;
        // Test wrong signals - should stay in FLV
        finState = CBS_FIN;
        op_fin = CBS_S;
        #20;
        #20;
        if (state_reg == FLV) begin
            $display("✓ PASS: Wrong signals - stayed in FLV");
        end else begin
            $display("✗ FAIL: Wrong signals - moved to state %0d", state_reg);
        end
        
        // Now do correct transition
        auto_advance("Test 6C: FLV to HTREE", 0,0);
        #5;
        auto_advance("Test 6D: HTREE to FLV", 1,0);
        #5;
        auto_advance("Test 6E: FLV to HTREE", 0,0);
        #5;
        auto_advance("Test 6F: HTREE to CBS", 0,0);
        #5;
        auto_advance("Test 6G: CBS to TRN", 0,0);
        #5;
        auto_advance("Test 6H: TRN to SPI", 0,0);
        #5;
        auto_advance("Test 6I: SPI to DONE", 0,0);
        #5;
        auto_advance("Test 6J: DONE to IDLE", 0,0);
        #5;

    // RESET BEHAVIOR 
        test_progress ++;
        $display("TEST 7: RESET BEHAVIOR");
        // Re-run the basic flow to ensure reset works correctly
        for (int desiredState = 0; desiredState < 6; desiredState++) begin
            reset(); // Reset the state machine to initial state
            #5;

            for (int stepCount = 0; stepCount < desiredState; stepCount++) begin
                auto_advance($sformatf("Stepping to state %0d", stepCount + 1), /*id=*/ 0, /*mode=*/ 0);
                #5;
            end
        end

    // CLOCK EDGE BEHAVIOR - wave form - IGNORE

    // SIGNAL PERSISTENCE - DELAYS ADDED in auto_advance - IGNORE

    // SIMULTANEOUS ERROR AND COMPLETION SIGNALS - IGNORE JUST AN INSTABILITY

    // MULTIPLE COMPLETION CYCLES
        test_progress ++;
        $display("TEST 8: MULTIPLE COMPLETION CYCLES");
        reset();
        for(int cycle = 0; cycle < 20; cycle++) begin
            auto_advance("Test 8A: IDLE to HISTO", 0,0);
            #5;
            auto_advance("Test 8B: HISTO to FLV", 0,0);
            #5;
            auto_advance("Test 8C: FLV to HTREE", 0,0);
            #5;
            auto_advance("Test 8D: HTREE to FLV", 1,0);
            #5;
            auto_advance("Test 8E: FLV to HTREE", 0,0);
            #5;
            auto_advance("Test 8F: HTREE to CBS", 0,0);
            #5;
            auto_advance("Test 8G: CBS to TRN", 0,0);
            #5;
            auto_advance("Test 8H: TRN to SPI", 0,0);
            #5;
            auto_advance("Test 8I: SPI to DONE", 0,0);
            #5;
            auto_advance("Test 8J: DONE to IDLE", 0,0);
            #5;
        end

    // NORMAL OPERATION WITH VARIOUS ERRORS AT VARIOUS STATES - IGNORE

    // UNIDENTIFIED INPUT STATES
        test_progress ++;
        $display("TEST 9: UNIDENTIFIED INPUT STATES");
        
        // Test invalid finState values
        reset();
        auto_advance("Test 9A: IDLE to HISTO", 0, 0);
        #5;
        
        // Try invalid finState (should stay in current state)
        $display("Testing invalid finState values...");
        cont_en = 1'b0;
        finState = 4'hF; // Invalid finState (15)
        op_fin = HIST_S;
        #40;
        if (state_reg == HISTO) begin
            $display("✓ PASS: Invalid finState - stayed in HISTO");
            passed_tests++;
        end else begin
            $display("✗ FAIL: Invalid finState - moved to state %0d", state_reg);
        end
        total_tests++;
        
        // Try invalid op_fin values  
        $display("Testing invalid op_fin values...");
        finState = HFIN;
        op_fin = 4'hF; // Invalid op_fin (15)
        #40;
        if (state_reg == HISTO) begin
            $display("✓ PASS: Invalid op_fin - stayed in HISTO");
            passed_tests++;
        end else begin
            $display("✗ FAIL: Invalid op_fin - moved to state %0d", state_reg);
        end
        total_tests++;
        
        // Test mismatched completion signals
        $display("Testing mismatched completion signals...");
        finState = FLV_FIN; // Wrong finState for HISTO
        op_fin = HIST_S;    // Correct op_fin
        #40;
        if (state_reg == HISTO) begin
            $display("✓ PASS: Mismatched signals - stayed in HISTO");
            passed_tests++;
        end else begin
            $display("✗ FAIL: Mismatched signals - moved to state %0d", state_reg);
        end
        total_tests++;
        
        // // Test all X (unknown) inputs
        // $display("Testing unknown/X input values...");
        // finState = 4'bxxxx;
        // op_fin = 4'bxxxx;
        // #40;
        // if (state_reg == HISTO) begin
        //     $display("✓ PASS: Unknown inputs - stayed in HISTO");
        //     passed_tests++;
        // end else begin
        //     $display("✗ FAIL: Unknown inputs - moved to state %0d", state_reg);
        // end
        // total_tests++;
        
        // Test during state transitions with invalid inputs
        $display("Testing invalid inputs during various states...");
        for (int test_state = 1; test_state <= 6; test_state++) begin
            reset();
            
            // Advance to the test state
            for (int step = 0; step < test_state; step++) begin
                auto_advance($sformatf("Advance to state %0d", step + 1), 0, 0);
                #5;
            end
            
            current_state_snapshot = state_reg;
            
            // Apply invalid inputs
            finState = 4'hA; // Invalid value
            op_fin = 4'hB;   // Invalid value
            #40;
            
            if (state_reg == current_state_snapshot) begin
                $display("✓ PASS: State %0d - invalid inputs rejected", current_state_snapshot);
                passed_tests++;
            end else begin
                $display("✗ FAIL: State %0d - moved to %0d with invalid inputs", current_state_snapshot, state_reg);
            end
            total_tests++;
        end
        
        // Test boundary values
        $display("Testing boundary input values...");
        reset();
        auto_advance("Setup for boundary test", 0, 0);
        #5;
        
        // Test maximum valid values
        finState = 4'd8; // Just above valid range
        op_fin = 4'd7;   // Just above valid range  
        #40;
        if (state_reg == HISTO) begin
            $display("✓ PASS: Boundary values - stayed in HISTO");
            passed_tests++;
        end else begin
            $display("✗ FAIL: Boundary values - moved to state %0d", state_reg);
        end
        total_tests++;

    // TEST SUMMARY
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
endmodule