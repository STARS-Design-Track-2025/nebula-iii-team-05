// the _O and _I at the end of variables denotes inputs and outputs
// as viewed from the perspective of the wishbone bus manager that is 
// instatiated to be testbenched here


`timescale 1ns/10ps

module wishbone_manager_tb();
    parameter CLK_PERIOD = 25;  // 40 MHz
    logic tb_CLK;
    logic tb_nRST;

    //manager ports:
    //module inputs
    logic [31:0] tb_DAT_I;
    logic        tb_ACK_I;
    
    logic        tb_WRITE_I;
    logic        tb_READ_I;
    logic [31:0] tb_ADR_I;
    logic [31:0] tb_CPU_DAT_I;
    logic [3:0]  tb_SEL_I;

    //module outputs
    logic [31:0] tb_ADR_O;
    logic [31:0] tb_DAT_O;
    logic [3:0]  tb_SEL_O;
    logic        tb_WE_O;
    logic        tb_STB_O;
    logic        tb_CYC_O;

    logic [31:0] tb_CPU_DAT_O;
    logic        tb_BUSY_O;

    //clock gen
    always begin
        tb_CLK = 1'b0;
        #(CLK_PERIOD/2);
        tb_CLK = 1'b1;
        #(CLK_PERIOD/2);
    end

    // Signal Dump
    initial begin
        $dumpfile ("wishbone_manager.vcd");
        $dumpvars;
    end

    // Wishbone Manager
    wishbone_manager manager(
        .CLK(tb_CLK),
        .nRST(tb_nRST),

        .DAT_I(tb_DAT_I),
        .ACK_I(tb_ACK_I),

        .WRITE_I(tb_WRITE_I),
        .READ_I(tb_READ_I),
        .ADR_I(tb_ADR_I),
        .CPU_DAT_I(tb_CPU_DAT_I),
        .SEL_I(tb_SEL_I),

        //outputs
        .ADR_O(tb_ADR_O),
        .DAT_O(tb_DAT_O),
        .SEL_O(tb_SEL_O),
        .WE_O(tb_WE_O),
        .STB_O(tb_STB_O),
        .CYC_O(tb_CYC_O),

        .CPU_DAT_O(tb_CPU_DAT_O),
        .BUSY_O(tb_BUSY_O)
    );

    logic [31:0] tb_la_data_in;

    logic [31:0] tb_la_data;

    // Wishbone Arbitrator
    // everywhere with squigly brackets is where more manager signals can be concatinated!!!
    wishbone_arbitrator #(
        .NUM_MANAGERS(1)
    ) wb_arbitrator (

        .CLK(tb_CLK),
        .nRST(tb_nRST),

        //manager to arbitrator, input
        .A_ADR_I({tb_ADR_O}),
        .A_DAT_I({tb_DAT_O}),
        .A_SEL_I({tb_SEL_O}),
        .A_WE_I({tb_WE_O}),
        .A_STB_I({tb_STB_O}),
        .A_CYC_I({tb_CYC_O}),

        //arbitrator to manager, output
        .A_DAT_O({tb_DAT_I}),
        .A_ACK_O({tb_ACK_I}),

        //arbitrator to peripheral, input
        .DAT_I(wbs_dat_o_m),
        .ACK_I(wbs_ack_o_m),

        //arbitrator to peripheral, output
        .ADR_O(wbs_adr_i_m),
        .DAT_O(wbs_dat_i_m),
        .SEL_O(wbs_sel_i_m),
        .WE_O(wbs_we_i_m),
        .STB_O(wbs_stb_i_m),
        .CYC_O(wbs_cyc_i_m)
    );
    //to arbitrator
    logic        wbs_ack_o_m;
    logic [31:0] wbs_dat_o_m;
    //from arbitrator
    logic        wbs_cyc_i_m;
    logic        wbs_stb_i_m;
    logic        wbs_we_i_m;
    logic [31:0] wbs_adr_i_m;
    logic [31:0] wbs_dat_i_m;
    logic [3:0]  wbs_sel_i_m;

    logic        wbs_ack_i_gpio, wbs_ack_i_la, wbs_ack_i_sram;
    logic [31:0] wbs_dat_i_gpio, wbs_dat_i_la, wbs_dat_i_sram;

    logic        wbs_cyc_o_gpio, wbs_cyc_o_la, wbs_cyc_o_sram;
    logic        wbs_stb_o_gpio, wbs_stb_o_la, wbs_stb_o_sram;
    logic        wbs_we_o_gpio, wbs_we_o_la, wbs_we_o_sram;
    logic [31:0] wbs_adr_o_gpio, wbs_adr_o_la, wbs_adr_o_sram;
    logic [31:0] wbs_dat_o_gpio, wbs_dat_o_la, wbs_dat_o_sram;
    logic [3:0]  wbs_sel_o_gpio, wbs_sel_o_la, wbs_sel_o_sram;

    
    // Project Signals (only Team 00 right now)
    logic wbs_ack_i_projects, wbs_cyc_o_projects, wbs_stb_o_projects, wbs_we_o_projects;
    logic [31:0] wbs_dat_i_projects, wbs_adr_o_projects, wbs_dat_o_projects;
    logic [3:0] wbs_sel_o_projects;
    
    assign wbs_ack_i_gpio = '0;
    assign wbs_ack_i_projects = '0;

    assign wbs_dat_i_gpio = '0;
    assign wbs_dat_i_projects = '0;


    // Wishbone Decoder
    wishbone_decoder #(
        .NUM_TEAMS(0)
    ) wb_decoder (
        .CLK(tb_CLK),
        .nRST(tb_nRST),

        //muxxing signals that go to manager
        .wbs_ack_i_periph({wbs_ack_i_projects, wbs_ack_i_la, wbs_ack_i_gpio, wbs_ack_i_sram}),
        .wbs_dat_i_periph({wbs_dat_i_projects, wbs_dat_i_la, wbs_dat_i_gpio, wbs_dat_i_sram}),

        .wbs_ack_o_m(wbs_ack_o_m),
        .wbs_dat_o_m(wbs_dat_o_m),

        //muxxing signals that come from manager
        .wbs_cyc_i_m(wbs_cyc_i_m),
        .wbs_stb_i_m(wbs_stb_i_m),
        .wbs_we_i_m(wbs_we_i_m),
        .wbs_adr_i_m(wbs_adr_i_m),
        .wbs_dat_i_m(wbs_dat_i_m),
        .wbs_sel_i_m(wbs_sel_i_m),

        .wbs_cyc_o_periph({wbs_cyc_o_projects, wbs_cyc_o_la, wbs_cyc_o_gpio, wbs_cyc_o_sram}),
        .wbs_stb_o_periph({wbs_stb_o_projects, wbs_stb_o_la, wbs_stb_o_gpio, wbs_stb_o_sram}),
        .wbs_we_o_periph({wbs_we_o_projects, wbs_we_o_la, wbs_we_o_gpio, wbs_we_o_sram}),
        .wbs_adr_o_periph({wbs_adr_o_projects, wbs_adr_o_la, wbs_adr_o_gpio, wbs_adr_o_sram}),
        .wbs_dat_o_periph({wbs_dat_o_projects, wbs_dat_o_la, wbs_dat_o_gpio, wbs_dat_o_sram}),
        .wbs_sel_o_periph({wbs_sel_o_projects, wbs_sel_o_la, wbs_sel_o_gpio, wbs_sel_o_sram})
    );

    la_control_Wrapper #(
        .NUM_TEAMS(0)
    )la_controller(
        //wishbone input
        .wb_clk_i(tb_CLK),
        .wb_rst_i(~tb_nRST),
        .wbs_stb_i(wbs_stb_o_la), 
        .wbs_cyc_i(wbs_cyc_o_la),
        .wbs_we_i (wbs_we_o_la),
        .wbs_sel_i(wbs_sel_o_la),
        .wbs_dat_i(wbs_dat_o_la),
        .wbs_adr_i(wbs_adr_o_la),

        //wishbone output
        .wbs_ack_o(wbs_ack_i_la),
        .wbs_dat_o(wbs_dat_i_la),
        //la input
        .designs_la_data_out_flat(tb_la_data_in),
        //la output
        .la_data_out(tb_la_data)
    );

    // SRAM
    sram_WB_Wrapper sram (

        .wb_clk_i(tb_CLK),
        .wb_rst_i(~tb_nRST),

        // MGMT SoC Wishbone Slave

        .wbs_stb_i(wbs_stb_o_sram),
        .wbs_cyc_i(wbs_cyc_o_sram),
        .wbs_we_i(wbs_we_o_sram),
        .wbs_sel_i(wbs_sel_o_sram),
        .wbs_dat_i(wbs_dat_o_sram),
        .wbs_adr_i(wbs_adr_o_sram),
        .wbs_ack_o(wbs_ack_i_sram),
        .wbs_dat_o(wbs_dat_i_sram)
    );

    // Reset Task
    task reset;
    begin
        @(posedge tb_CLK);
        tb_nRST = 1'b0;
        @(posedge tb_CLK);
        @(posedge tb_CLK);
        tb_nRST = 1'b1;
        @(posedge tb_CLK);
    end
    endtask

    logic tb_write_occur;
    logic tb_read_occur;

    // Write Task
    task wb_write(
        input logic [31:0] addr,
        input logic [31:0] data,
        input logic [3:0] sel
    );
    begin
        tb_write_occur = 1'b1;
        @(negedge tb_CLK);
        
        tb_WRITE_I   = '1;
        tb_SEL_I     = sel;
        tb_ADR_I     = addr;
        tb_CPU_DAT_I = data;

        @(negedge tb_CLK);
        tb_WRITE_I   = '0;

        @(negedge tb_BUSY_O);

        tb_WRITE_I   = '0;
        tb_SEL_I     = '0;
        tb_ADR_I     = '0;
        tb_CPU_DAT_I = '0;

        tb_write_occur = 1'b0;
    end
    endtask

    // Read Task
    task wb_read(
        input logic [31:0] addr,
        input logic [31:0] data,
        input logic [3:0] sel
    );
    begin
        tb_read_occur = 1'b1;
        @(negedge tb_CLK);
        
        tb_READ_I   = '1;
        tb_SEL_I     = sel;
        tb_ADR_I     = addr;

        @(negedge tb_CLK);
        tb_READ_I   = '0;

        @(negedge tb_BUSY_O);

        tb_READ_I   = '0;
        tb_SEL_I     = '0;
        tb_ADR_I     = '0;

        tb_read_occur = 1'b0;

        if(data != tb_CPU_DAT_O || (^~tb_CPU_DAT_O !== 1'b1 && ^~tb_CPU_DAT_O !== 1'b0) ) begin
            $error("expected: %h actual: %h", data, tb_CPU_DAT_O);
        end
        else begin
            $info("Praise be!");
        end
    end
    endtask

    // Main testbench task
    initial begin
        // Initialize signals
        tb_write_occur = 1'b0;
        tb_read_occur  = 1'b0;

        tb_la_data_in = '0;
        tb_nRST = 1'b1;
        tb_WRITE_I = '0;
        tb_READ_I = '0;
        tb_ADR_I = '0;
        tb_CPU_DAT_I = '0;
        tb_SEL_I = '0;

        // Perform reset
        reset();

        // Write and read from address 0x0 in SRAM
        wb_write(32'h33000000, 32'h12345678, 'b1111);
        repeat (5) @(posedge tb_CLK);
        wb_read(32'h33000000, 32'h12345678, 'b1111);
        repeat (5) @(posedge tb_CLK);

        // Modify Byte 0 in address 0x0 in SRAM
        wb_write(32'h33000000, 32'hAAAAAAAA, 'b0001);
        repeat (5) @(posedge tb_CLK);
        wb_read(32'h33000000, 32'hAA, 'b0001);
        repeat (5) @(posedge tb_CLK);
        wb_read(32'h33000000, 32'h123456AA, 'b1111);
        repeat (5) @(posedge tb_CLK);
        
        // Modify Byte 2 in address 0x0 in SRAM
        wb_write(32'h33000000, 32'hBBBBBBBB, 'b0100);
        repeat (5) @(posedge tb_CLK);
        wb_read(32'h33000000, 32'h00BB0000, 'b0100);
        repeat (5) @(posedge tb_CLK);
        wb_read(32'h33000000, 32'h12BB56AA, 'b1111);
        repeat (5) @(posedge tb_CLK);

        // Write and read from last address in SRAM
        wb_write(32'h33001FFF, 32'h22334455, 'b1111);
        repeat (5) @(posedge tb_CLK);
        wb_read(32'h33001FFF, 32'h22334455, 'b1111);
        repeat (5) @(posedge tb_CLK);

        // Write and read from address 0x0 in LA Controller
        wb_write(32'h31000000, 32'h12345678, 'b1111);
        repeat (5) @(posedge tb_CLK);
        wb_read(32'h31000000, 32'h8, 'b1111);
        repeat (5) @(posedge tb_CLK);

        // Done!
        $info("TESTBENCH DONE!!");
        $finish;
    end
    endmodule
