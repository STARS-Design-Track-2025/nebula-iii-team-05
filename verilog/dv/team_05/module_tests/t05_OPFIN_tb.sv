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
        
        // Test 1: Initial reset
        $display("\n=== Test 1: Reset Functionality ===");
        apply_reset();
        #20;
        $display("State after reset: opFin=%0d, compEN_reg=%b, decompEN_reg=%b", 
                 opFin, compEN_reg, decompEN_reg);

        // Test 2: IDLE to SELECT transition
        $display("\n=== Test 2: IDLE to SELECT Transition ===");
        pulse_continue();
        #20;
        $display("After cont_en pulse: opFin=%0d", opFin);

        // Test 3: SELECT to COMP (compression mode)
        $display("\n=== Test 3: SELECT to COMP (Compression Mode) ===");
        compDecomp = 1; // Select compression
        #20;
        $display("After compDecomp=1: opFin=%0d", opFin);

        // Test 4: Compression state testing
        $display("\n=== Test 4: Compression State Testing ===");
        test_comp_state(1, HISTO, "HISTO");
        test_comp_state(2, FLV, "FLV");
        test_comp_state(3, HTREE, "HTREE");
        test_comp_state(4, CBS, "CBS");
        test_comp_state(5, TRN, "TRN");
        test_comp_state(6, SPI, "SPI");
        test_comp_state(7, ERROR, "ERROR");
        test_comp_state(8, DONE, "DONE");

        // Test 5: Enable signal testing
        $display("\n=== Test 5: Enable Signal Testing ===");
        comp_state = 1;
        pulse_continue();
        #10;
        if (compEN_reg) begin
            $display("✓ compEN_reg correctly asserted");
        end else begin
            $display("✗ compEN_reg not asserted");
        end

        // Test 6: Switch to decompression mode
        $display("\n=== Test 6: Switch to Decompression Mode ===");
        apply_restart();
        pulse_continue(); // IDLE to SELECT
        #20;
        compDecomp = 0; // Select decompression
        #20;
        $display("Switched to decompression mode: opFin=%0d", opFin);

        // Test 7: Decompression state testing
        $display("\n=== Test 7: Decompression State Testing ===");
        test_decomp_state(2'd0, STATE0, "STATE0");
        test_decomp_state(2'd1, STATE1, "STATE1");
        test_decomp_state(2'd2, STATE2, "STATE2");
        test_decomp_state(2'd3, STATE3, "STATE3");

        // Test 8: Decompression enable signal testing
        $display("\n=== Test 8: Decompression Enable Signal Testing ===");
        decomp_state = 2'd1;
        pulse_continue();
        #10;
        if (decompEN_reg) begin
            $display("✓ decompEN_reg correctly asserted");
        end else begin
            $display("✗ decompEN_reg not asserted");
        end

        // Test 9: Mode switching
        $display("\n=== Test 9: Mode Switching Test ===");
        apply_restart();
        pulse_continue(); // IDLE to SELECT
        #20;
        
        // Start with compression
        compDecomp = 1;
        #20;
        $display("Compression mode: opFin=%0d", opFin);
        
        // Switch to decompression
        compDecomp = 0;
        #20;
        $display("Decompression mode: opFin=%0d", opFin);
        
        // Switch back to compression
        compDecomp = 1;
        #20;
        $display("Back to compression: opFin=%0d", opFin);

        // Test 10: Edge cases
        $display("\n=== Test 10: Edge Cases ===");
        apply_restart();
        
        // Test default case in compression states
        pulse_continue(); // IDLE to SELECT
        compDecomp = 1; // Select compression
        #20;
        comp_state = 4'hF; // Invalid compression state
        pulse_continue();
        #20;
        check_opFin(IDLE, "IDLE_DEFAULT");

        // Test default case in decompression states  
        apply_restart();
        pulse_continue(); // IDLE to SELECT
        compDecomp = 0; // Select decompression
        #20;
        decomp_state = 2'd3; // This should map to STATE3, but let's test edge
        pulse_continue();
        #20;
        check_opFin(STATE3, "STATE3");

        // Test 11: Rapid switching
        $display("\n=== Test 11: Rapid Mode Switching ===");
        apply_restart();
        for (int i = 0; i < 5; i++) begin
            pulse_continue();
            #5;
            compDecomp = ~compDecomp;
            #5;
            $display("Rapid switch %0d: compDecomp=%b, opFin=%0d", i, compDecomp, opFin);
        end

        // Test 12: Restart functionality
        $display("\n=== Test 12: Restart Functionality ===");
        pulse_continue(); // Set some state
        compDecomp = 1;
        comp_state = 3;
        pulse_continue();
        #20;
        $display("Before restart: opFin=%0d", opFin);
        
        apply_restart();
        #20;
        $display("After restart: opFin=%0d", opFin);

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
