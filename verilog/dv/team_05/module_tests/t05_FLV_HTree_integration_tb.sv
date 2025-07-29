`timescale 1ms/10ps

// Simplified Combined Testbench for FLV + HTree Integration
module t05_FLV_HTree_integration_tb;
    
    // Common signals
    logic clk, rst_n;
    
    // FLV signals (matching t05_findLeastValue_tb.sv naming)
    logic rst; // FLV uses active high reset
    logic [3:0] en_state;
    logic [7:0] charWipe1, charWipe2;
    logic [8:0] least1, least2, histo_index;
    logic [63:0] compVal, sum;
    logic [2:0] fin_state;
    
    // HTree signals (matching t05_hTree_tb.sv naming)
    logic [8:0] ht_least1_in, ht_least2_in;
    logic [45:0] ht_sum_in;
    logic [63:0] nulls;
    logic SRAM_finished;
    logic [70:0] node, tree, null1, null2;
    logic [6:0] clkCount, nullSumIndex;
    logic [3:0] op_fin, state;
    logic WriteorRead;
    
    // Test control
    logic auto_connect;
    int test_num = 0;
    
    // Test data structures for realistic scenarios
    logic [63:0] char_frequencies[256]; // Character frequency table
    string test_text;
    
    // Integration test helper variables
    logic [7:0] expected_least_char1, expected_least_char2;
    logic [63:0] expected_sum;
    logic test_passed;
    
    // Module instances
    t05_findLeastValue flv (
        .clk(clk),
        .rst(rst), // FLV uses active high reset
        .compVal(compVal),              // from SRAM        SUDOCONTROLLER
        .en_state(en_state),            // from controller  SUDOCONTROLLER
        .sum(sum),                      // to hTree
        .charWipe1(charWipe1),          // to SRAM          
        .charWipe2(charWipe2),          // to SRAM          
        .least1(least1),                // to hTree
        .least2(least2),                // to hTree
        .histo_index(histo_index),      // to SRAM         
        .fin_state(fin_state)           // to controller    SUDOCONTROLLER
    );
    
    t05_hTree inst (
        .clk(clk), 
        .rst(rst), 
        .least1(least1),                // from FLV
        .least2(least2),                // from FLV
        .sum(sum[45:0]),                // from FLV
        .nulls(nulls),                  // from SRAM        SUDOCONTROLLER
        .HT_en(en_state),               // from controller  SUDOCONTROLLER
        .SRAM_finished(SRAM_finished),  // from SRAM        SUDOCONTROLLER
        .node_reg(node),                // to SRAM          
        .clkCount(clkCount),            // to CBS
        .nullSumIndex(nullSumIndex),    // to SRAM
        .op_fin(op_fin),                // to controller    SUDOCONTROLLER
        .WriteorRead(WriteorRead),      // to SRAM          
        .tree_reg(tree),
        .null1_reg(null1),
        .null2_reg(null2),
        .state_reg(state)       
    );
    // Clock generation
    always begin
        #5 clk = ~clk; // 1 ms clock period
    end

    task automatic reset();
        rst = 1; // Assert reset
        #10;
        rst = 0; // Deassert reset
        #10;
    endtask

    task automatic sramDelay();
        SRAM_finished = 0;
        #10;
        SRAM_finished = 1;
        #2;
    endtask

    task automatic createNode();
        en_state = 4'b0010; // Enable FLV processing
        #20;
          
    endtask

    initial begin
        reset();
endmodule
    
   