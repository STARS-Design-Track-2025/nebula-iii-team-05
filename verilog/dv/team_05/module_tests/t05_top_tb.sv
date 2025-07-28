`timescale 10ms/10ns
module t05_top_tb;

    logic hwclk, reset, miso;
    logic mosi, cont_en;
    //logic SRAM_finished;
    logic [5:0] op_fin; // when SRAM finishes
    logic [7:0] read_out;
    //logic [63:0] compVal, nulls;
    logic [8:0] fin_State;      // Output from top module        // outputs from modules
    logic error_detected;      // For error status tracking

    logic HT_fin_reg;
    logic fin_state_HG, fin_state_FLV, fin_state_HT, fin_state_CB, fin_state_TL, fin_state_SPI;
    logic finished_signal;
    logic [3:0] en_state;
    // logic [70:0] h_element;
    int total_tests;
    int passed_tests;

    //WRAPPER
    logic wbs_stb_i;
    logic wbs_cyc_i;
    logic wbs_we_i;
    logic [3:0] wbs_sel_i;
    logic [31:0] wbs_dat_i;
    logic [31:0] wbs_adr_i;
    logic wbs_ack_o;
    logic [31:0] wbs_dat_o;
    logic [2:0] test_num;

    t05_top top (
    .hwclk(hwclk),
    .reset(reset),
    .mosi(mosi),
    .miso(miso),
    .op_fin(op_fin),
    .read_out(read_out),
    //.compVal(compVal),
    //.nulls(nulls),
    //.h_element(h_element),
    //.SRAM_finished(SRAM_finished),
    .finished_signal(finished_signal),
    .en_state(en_state),
    .cont_en(cont_en),
    .fin_State(fin_State),

    //WRAPPER
    .wbs_stb_o(wbs_stb_i),
    .wbs_cyc_o(wbs_cyc_i),
    .wbs_we_o(wbs_we_i),
    .wbs_sel_o(wbs_sel_i),
    .wbs_dat_o(wbs_dat_i),
    .wbs_adr_o(wbs_adr_i),
    .wbs_ack_i(wbs_ack_o),
    .wbs_dat_i(wbs_dat_o)
    );

    sram_WB_Wrapper sram (
        .wb_clk_i(hwclk),
        .wb_rst_i(reset),
        .wbs_stb_i(wbs_stb_i),
        .wbs_cyc_i(wbs_cyc_i),
        .wbs_we_i(wbs_we_i),
        .wbs_sel_i(wbs_sel_i),
        .wbs_dat_i(wbs_dat_i),
        .wbs_adr_i(wbs_adr_i),
        .wbs_ack_o(wbs_ack_o),
        .wbs_dat_o(wbs_dat_o)
    );
 
  
    task resetOn ();
        begin
            reset = 1;
            #10
            reset = 0;
        end
    endtask

    // task readA ();
    //     begin
    //         miso = 0; 
    //         #6
    //         miso = 1;
    //         #6
    //         miso = 0;
    //         #33
    //         miso = 1;
    //         #6;
    //         miso = 0;
    //         #6;
    //     end
    // endtask

    // task readB ();
    //     begin
    //         miso = 0; 
    //         #6;
    //         miso = 1;
    //         #6;
    //         miso = 0;
    //         #24;
    //         miso = 1;
    //         #6;
    //         miso = 0;
    //         #6;
    //     end
    // endtask

    // task readC ();
    //     begin
    //         miso = 0; 
    //         #6;
    //         miso = 1;
    //         #6;
    //         miso = 0;
    //         #24;
    //         miso = 1;
    //         #12;
    //     end
    // endtask

    typedef enum logic [3:0] {
        IDLE=0, HISTO=1, FLV=2, HTREE=3, CBS=4, TRN=5, SPI=6, ERROR=7, DONE=8
    } state_t;
    
    typedef enum logic [8:0] {
        IDLE_FIN=       9'b100000000,
        HFIN=           9'b010000000,
        FLV_FIN=        9'b001000000,
        HTREE_FIN=      9'b000100000,
        HTREE_FINISHED= 9'b000010000,
        CBS_FIN=        9'b000001000,
        TRN_FIN=        9'b000000100,
        SPI_FIN=        9'b000000010,
        ERROR_FIN=      9'b000000001
    } fin_State_t;
    
    typedef enum logic [5:0] {
        IDLE_S=0, HIST_S=1, FLV_S=2, HTREE_S=3, CBS_S=4, TRN_S=5, SPI_S=6, ERROR_S=7
    } op_fin_t;

    task automatic auto_advance(input string test_name,input int i, int err); // err 1 = module error, 2 = SRAM error, 0 = normal, 3 = both error
        logic [3:0] expected_next_state;
        logic [3:0] current_state;
        logic restart_en = 1'b0;
        begin
            current_state = en_state; // Capture current state at start
            $display("Starting %s from state %0d", test_name, current_state);
            
            // Check for unknown/uninitialized state
            if (current_state === 4'bxxxx) begin
                $error("State is uninitialized (X)! Controller reset failed.");
                $finish; // Exit simulation instead of return
            end

            // Initialize data based on current state
            case(current_state)
                HISTO: begin
                    read_out = 8'h1A; // Initialize histogram data
                end
                FLV: begin
                    //compVal = 64'd0; // Initialize frequency comparison value
                end
                HTREE: begin
                    //nulls = 64'd500; // Initialize nulls for Huffman tree
                    if (i == 1) begin
                        // Loop case - might need different data
                        //compVal = 64'd0; // Different comparison for loop
                    end
                end
                CBS: begin
                    // Initialize codebook data
                    read_out = 8'hFF; // Example codebook data
                    //SRAM_finished = 1;
                    #10;
                    //SRAM_finished = 0;
                end
                TRN: begin
                    // Initialize translation data
                    read_out = 8'hEE; // Example translation data
                    //SRAM_finished = 1;
                    #10;
                    //SRAM_finished = 0;
                end
                default: begin
                    // Other states don't need specific data initialization
                end
            endcase
            
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
                            // fin_state_HG = 1'b1; // ????
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
                            // fin_State = ERROR_FIN;  // ASSUMES THAT FINISH STATE SIGNALS HAPPEN ON THEIR OWN
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
                            // fin_State = HFIN;
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
                            // fin_State = ERROR_FIN;
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
                            // fin_State = FLV_FIN;
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
                            // fin_State = ERROR_FIN;
                            #100;
                            op_fin = FLV_S; 
                            #20;
                            expected_next_state = ERROR;
                            $display("Simulating module error, moving to ERROR state");
                            #10;
                        end
                        2: begin
                            // Simulate SRAM error
                            // fin_State = FLV_FIN; // Assume HTREE_FINISHED is a valid state for SRAM error
                            #100;
                            op_fin = ERROR_S; // Continue with HTREE operation
                            #20;
                            expected_next_state = ERROR;
                            $display("Simulating SRAM error, moving to ERROR state");
                            #10;
                        end
                        3: begin
                            // Simulate both errors
                            // fin_State = ERROR_FIN;
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
                                // fin_State = HTREE_FIN;
                                #100;
                                op_fin = HTREE_S; 
                                #20;
                                expected_next_state = FLV;
                                $display("Setting HTREE_FIN + HTREE_S to move HTREE→FLV (loop back)");
                                #10;
                            end
                            1: begin
                                // Simulate module error
                                // fin_State = ERROR_FIN;
                                #100;
                                op_fin = HTREE_S; 
                                #20;
                                expected_next_state = ERROR;
                                $display("Simulating module error, moving to ERROR state");
                                #10;
                            end
                            2: begin
                                // Simulate SRAM error
                                // fin_State = HTREE_FIN;
                                #100;
                                op_fin = ERROR_S; 
                                #20;
                                expected_next_state = ERROR;
                                $display("Simulating SRAM error, moving to ERROR state");
                                #10;
                            end
                            3: begin
                                // Simulate both errors
                                // fin_State = ERROR_FIN;
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
                                // fin_State = HTREE_FINISHED;
                                #100;
                                op_fin = 6'b0; 
                                #20;
                                expected_next_state = CBS;
                                $display("Setting HTREE_FINISHED to move HTREE→CBS");
                                #10;
                            end
                            1,2,3: begin
                                // Simulate module error
                                // fin_State = ERROR_FIN;
                                #100;
                                op_fin = 6'b0; 
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
                            // fin_State = CBS_FIN;
                            #100;
                            op_fin = CBS_S; 
                            #20;
                            expected_next_state = TRN;
                            $display("Setting CBS_FIN + CBS_S to move CBS→TRN");
                            #10;
                        end
                        1: begin
                            // Simulate module error
                            // fin_State = ERROR_FIN;
                            #100;
                            op_fin = CBS_S; 
                            #20;
                            expected_next_state = ERROR;
                            $display("Simulating module error, moving to ERROR state");
                            #10;
                        end
                        2: begin
                            // Simulate SRAM error
                            // fin_State = CBS_FIN; 
                            #100;
                            op_fin = ERROR_S;  
                            #20;
                            expected_next_state = ERROR;
                            $display("Simulating SRAM error, moving to ERROR state");
                            #10;
                        end
                        3: begin
                            // Simulate both errors
                            // fin_State = ERROR_FIN;
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
                            // fin_State = TRN_FIN;
                            #100;
                            op_fin = TRN_S; 
                            #20;
                            expected_next_state = SPI;
                            $display("Setting TRN_FIN + TRN_S to move TRN→SPI");
                            #10;
                        end
                        1: begin
                            // Simulate module error
                            // fin_State = ERROR_FIN;
                            #100;
                            op_fin = TRN_S; 
                            #20;
                            expected_next_state = ERROR;
                            $display("Simulating module error, moving to ERROR state");
                            #10;
                        end
                        2: begin
                            // Simulate SRAM error
                            // fin_State = TRN_FIN; 
                            #100;
                            op_fin = ERROR_S; 
                            #20; 
                            expected_next_state = ERROR;
                            $display("Simulating SRAM error, moving to ERROR state");
                            #10;
                        end
                        3: begin
                            // Simulate both errors
                            // fin_State = ERROR_FIN;
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
                            // fin_State = SPI_FIN;
                            #100;
                            op_fin = SPI_S; 
                            #20;
                            expected_next_state = DONE;
                            $display("Setting SPI_FIN + SPI_S to move SPI→DONE");
                            #10;
                        end
                        1: begin
                            // Simulate module error
                            // fin_State = ERROR_FIN;
                            #100;
                            op_fin = SPI_S; 
                            #20;
                            expected_next_state = ERROR;
                            $display("Simulating module error, moving to ERROR state");
                            #10;
                        end
                        2: begin
                            // Simulate SRAM error
                            // fin_State = SPI_FIN; 
                            #100;
                            op_fin = ERROR_S;  
                            #20;
                            expected_next_state = ERROR;
                            $display("Simulating SRAM error, moving to ERROR state");
                            #10;
                        end
                        3: begin
                            // Simulate both errors
                            // fin_State = ERROR_FIN;
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
                    // {fin_state_HG, fin_state_FLV, fin_state_HT, HT_fin_reg, fin_state_CB, fin_state_TL, fin_state_SPI} = '0;
                    op_fin = 6'h0; 
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
                    // fin_State = ERROR_FIN;
                    op_fin = ERROR_S;
                    expected_next_state = ERROR;
                end
            endcase

            // Wait for state machine to process the signals
            #20;
            #20;
            // Check fin_State matches expected state pattern

            total_tests++;
            
            if (en_state == expected_next_state) begin
                $display("✓ PASS: %s - State = %0d (expected %0d)\n", test_name, en_state, expected_next_state);
                passed_tests++;
            end else begin
                $display("✗ FAIL: %s - State = %0d (expected %0d)\n", test_name, en_state, expected_next_state);
            end
        end
    endtask

    always begin
        #1
        hwclk = ~hwclk;
    end

    initial begin
        $dumpfile("t05_top.vcd");
        $dumpvars(0, t05_top_tb);
        total_tests = 0;
        passed_tests = 0;

        // Initialize signals
        hwclk = 0;
        reset = 0;
        miso = 0;
        read_out = '0;
        //compVal = '0;
        op_fin = '0;
        cont_en = 0;
        test_num = '0;
        //nulls = '0;
        //SRAM_finished = 0;

        // TEST 1: Basic Reset and Normal Flow
        $display("\n=== TEST 1: Basic Flow with Node Progression ===");
        test_num = 1;
        resetOn();
        #100;

        read_out = 8'b0010010;
        #10
        read_out = 8'b00010001;
        #10
        read_out = 8'b00011111;
        #10
        read_out = 8'b00110001;
        #10
        read_out = 8'b00010111;
        #10
        read_out = 8'b00010001;
        #10
        read_out = 8'h1A;
        #10

        

        // Basic flow through all states
        // auto_advance("IDLE to HISTO", 0, 0);
        // #5;
        // read_out = 8'h1A;  // Add histogram data
        // auto_advance("HISTO to FLV", 0, 0);
        // #5;
        // //compVal = 64'd20;  // Add compare value for FLV
        // auto_advance("FLV to HTREE", 0, 0);
        // #5;
        // //nulls = 64'd500;   // Add nulls data for HTREE
        // auto_advance("HTREE to CBS", 0, 0);
        // #5;
        // //h_element = {7'b1000000, 9'b110000000, 9'b110000000, 46'd0};
        // auto_advance("CBS to TRN", 0, 0);
        // #5;
        // auto_advance("TRN to SPI", 0, 0);
        // #5;
        // auto_advance("SPI to DONE", 0, 0);
        // #5;
        // auto_advance("DONE to IDLE", 0, 0);
        // #5;

        // TEST 2: HTREE Looping Test
        #2000;
        test_num = 2;
        $display("\n=== TEST 2: HTREE Looping Test ===");
        resetOn();
        #100;

        auto_advance("Setup: IDLE to HISTO", 0, 0);
        #5;
        auto_advance("Setup: HISTO to FLV", 0, 0);
        #5;

        // Do multiple HTREE loops
        repeat(3) begin
            auto_advance("FLV to HTREE", 0, 0);
            #5;
            auto_advance("HTREE to FLV (loop)", 1, 0); // i=1 triggers HTREE loop
            #5;
        end

        // Complete the flow after loops
        auto_advance("FLV to HTREE final", 0, 0);
        #5;
        auto_advance("HTREE to CBS", 0, 0);
        #5;
        auto_advance("Finish sequence", 0, 0);
        #5;

        // TEST 3: Error Handling
        test_num = 3;
        $display("\n=== TEST 3: Error Cases ===");
        
        // Test SRAM error
        #2000
        resetOn();
        #100;
        auto_advance("SRAM Error Test", 0, 2);  // err=2 for SRAM error
        #20;

        // Test module error
        #2000;
        resetOn();
        #100;
        auto_advance("Module Error Test", 0, 1);  // err=1 for module error
        #20;

        // Test both errors
        #2000;
        resetOn();
        #100;
        auto_advance("Combined Error Test", 0, 3);  // err=3 for both errors
        #20;

        // TEST 4: SRAM Interface
        test_num = 4;
        #2000;
        $display("\n=== TEST 4: SRAM Interface Test ===");
        resetOn();
        #100;
        
        // Progress through states with SRAM interactions
        auto_advance("IDLE to HISTO with SRAM", 0, 0);
        //SRAM_finished = 1;
        #50;
        //SRAM_finished = 0;
        auto_advance("Continue after SRAM", 0, 0);
        #20;

        // Final Summary
        $display("\n=== TEST SUMMARY ===");
        $display("Total Tests: %0d", total_tests);
        $display("Passed: %0d", passed_tests);
        $display("Failed: %0d", total_tests - passed_tests);
        
        if (passed_tests == total_tests) begin
            $display("🎉 ALL TESTS PASSED! 🎉");
        end else begin
            $display("❌ Some tests failed");
        end

        #100 $finish;
    end

endmodule