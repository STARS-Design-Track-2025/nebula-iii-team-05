module t05_1602_spi_tb;

    // Test parameters
    localparam CLK_PERIOD = 10;  // 100MHz system clock
    localparam WIDTH = 10;
    localparam CLK_DIV = 4;
    
    // Testbench signals
    logic clk;
    logic rst_n;
    
    // Test case control
    int test_case;
    int error_count;
    
    // DUT signals
    logic                start;
    logic [WIDTH-1:0]    data_in;
    logic                sdo;
    logic                sclk;
    logic                cs_n;
    logic                busy;
    logic                done;
    
    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end
    
    // DUT instance
    t05_1602_spi #(
        .WIDTH(WIDTH), 
        .CLK_DIV(CLK_DIV)
    ) dut (
        .clk(clk), 
        .rst_n(rst_n), 
        .start(start), 
        .data_in(data_in),
        .sdo(sdo), 
        .sclk(sclk), 
        .cs_n(cs_n), 
        .busy(busy), 
        .done(done)
    );
    
    // Initialize signals
    initial begin
        rst_n = 0;
        start = 0;
        data_in = 0;
        test_case = 0;
        error_count = 0;
    end
    
    // Task to wait for transmission completion
    task wait_for_done(input string test_name);
        fork
            begin
                wait(done);
                $display("[%0t] %s: Transmission completed", $time, test_name);
            end
            begin
                #50000; // Timeout after 50us
                $error("[%0t] %s: Timeout waiting for transmission completion", $time, test_name);
                error_count++;
            end
        join_any
        disable fork;
    endtask
    
    // Task to verify MSB-first transmission
    task verify_msb_first(input logic [WIDTH-1:0] expected_data, input string test_name);
        logic [WIDTH-1:0] captured_data;
        int bit_count;
        
        captured_data = 0;
        bit_count = 0;
        
        // Wait for transmission to start
        wait(busy);
        
        // Capture data on clock edges (CPHA=0 means data valid on first edge)
        while (bit_count < WIDTH) begin
            @(posedge sclk);  // CPOL=0, so sample on positive edge
            captured_data = (captured_data << 1) | sdo;
            bit_count++;
        end
        
        // Verify captured data matches expected (MSB first)
        if (captured_data == expected_data) begin
            $display("[%0t] %s: MSB-first verification PASSED - Expected: 0x%03h, Got: 0x%03h", 
                    $time, test_name, expected_data, captured_data);
        end else begin
            $error("[%0t] %s: MSB-first verification FAILED - Expected: 0x%03h, Got: 0x%03h", 
                  $time, test_name, expected_data, captured_data);
            error_count++;
        end
    endtask
    
    // Task to check initial conditions
    task check_initial_state(input string test_name);
        if (!busy && cs_n && !done) begin
            $display("[%0t] %s: Initial state verification PASSED", $time, test_name);
        end else begin
            $error("[%0t] %s: Initial state verification FAILED - busy:%b, cs_n:%b, done:%b", 
                  $time, test_name, busy, cs_n, done);
            error_count++;
        end
    endtask
    
    // Main test sequence
    initial begin
        $display("Starting SPI Master Testbench (10-bit, CPOL=0, CPHA=0)");
        $display("=======================================================");
        $dumpfile("t05_1602_spi.vcd"); 
        $dumpvars(0, t05_1602_spi_tb);
        // Apply reset
        repeat(5) @(posedge clk);
        rst_n = 1;
        repeat(5) @(posedge clk);
        
        // Test Case 1: Basic 10-bit transmission
        test_case = 1;
        $display("\n[%0t] Test Case %0d: Basic 10-bit transmission", $time, test_case);
        check_initial_state("Basic test");
        
        data_in = 10'h123;  // Test pattern
        @(posedge clk);
        start = 1;
        @(posedge clk);
        start = 0;
        
        fork
            verify_msb_first(data_in, "Basic 10-bit");
            wait_for_done("Basic 10-bit");
        join
        
        repeat(10) @(posedge clk);
        
        // Test Case 2: 10-bit command pattern
        test_case = 2;
        $display("\n[%0t] Test Case %0d: 10-bit command pattern", $time, test_case);
        
        data_in = 10'h2A5;  // Typical 10-bit pattern
        @(posedge clk);
        start = 1;
        @(posedge clk);
        start = 0;
        
        fork
            verify_msb_first(data_in, "10-bit command");
            wait_for_done("10-bit command");
        join
        
        repeat(10) @(posedge clk);
        
        // Test Case 3: Back-to-back transmissions
        test_case = 3;
        $display("\n[%0t] Test Case %0d: Back-to-back transmissions", $time, test_case);
        
        // First transmission
        data_in = 10'h155;
        @(posedge clk);
        start = 1;
        @(posedge clk);
        start = 0;
        wait_for_done("Back-to-back 1st");
        
        // Immediate second transmission
        data_in = 10'h2AA;
        @(posedge clk);
        start = 1;
        @(posedge clk);
        start = 0;
        wait_for_done("Back-to-back 2nd");
        
        repeat(10) @(posedge clk);
        
        // Test Case 4: Edge patterns
        test_case = 4;
        $display("\n[%0t] Test Case %0d: Edge patterns (all 0s, all 1s)", $time, test_case);
        
        // All zeros
        data_in = 10'h000;
        @(posedge clk);
        start = 1;
        @(posedge clk);
        start = 0;
        fork
            verify_msb_first(data_in, "All zeros");
            wait_for_done("All zeros");
        join
        
        repeat(5) @(posedge clk);
        
        // All ones
        data_in = 10'h3FF;
        @(posedge clk);
        start = 1;
        @(posedge clk);
        start = 0;
        fork
            verify_msb_first(data_in, "All ones");
            wait_for_done("All ones");
        join
        
        repeat(10) @(posedge clk);
        
        // Test Case 5: Reset during transmission
        test_case = 5;
        $display("\n[%0t] Test Case %0d: Reset during transmission", $time, test_case);
        
        data_in = 10'h1FA;
        @(posedge clk);
        start = 1;
        @(posedge clk);
        start = 0;
        
        // Wait for transmission to start
        wait(busy);
        repeat(5) @(posedge clk);
        
        // Apply reset
        rst_n = 0;
        repeat(3) @(posedge clk);
        rst_n = 1;
        repeat(5) @(posedge clk);
        
        // Check if reset worked
        check_initial_state("Post-reset");
        
        // Test Case 6: Multiple start pulses (should ignore after first)
        test_case = 6;
        $display("\n[%0t] Test Case %0d: Multiple start pulses", $time, test_case);
        
        data_in = 10'h0C3;
        @(posedge clk);
        start = 1;
        @(posedge clk);
        start = 0;
        
        // Send additional start pulses during transmission
        wait(busy);
        repeat(3) @(posedge clk);
        start = 1;
        @(posedge clk);
        start = 0;
        repeat(3) @(posedge clk);
        start = 1;
        @(posedge clk);
        start = 0;
        
        wait_for_done("Multiple starts");
        
        // Final results
        repeat(20) @(posedge clk);
        
        $display("\n=======================================================");
        $display("Testbench Summary:");
        $display("Total Test Cases: %0d", test_case);
        $display("Total Errors: %0d", error_count);
        
        if (error_count == 0) begin
            $display("*** ALL TESTS PASSED ***");
        end else begin
            $display("*** %0d TESTS FAILED ***", error_count);
        end
        
        $display("Testbench completed at time %0t", $time);
        $finish;
    end
    
    // Monitor critical signals
    initial begin
        $monitor("[%0t] Test:%0d | busy=%b cs_n=%b done=%b sdo=%b sclk=%b | data_in=0x%03h", 
                $time, test_case, busy, cs_n, done, sdo, sclk, data_in);
    end
    
    // Timeout watchdog
    initial begin
        #200000; // 200us timeout
        $error("Global timeout reached!");
        $finish;
    end

endmodule