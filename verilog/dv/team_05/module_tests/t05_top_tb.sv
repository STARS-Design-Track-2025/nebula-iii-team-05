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

    logic [23:0] i;

    logic pulse, confirm;

    logic nextChar, init;

    t05_top top (
    .hwclk(hwclk),
    .reset(reset),
    .mosi(mosi),
    .miso(miso),
    .op_fin(op_fin),
    .read_out(read_out),
    .finished_signal(finished_signal),
    .en_state(en_state),
    .cont_en(cont_en),
    .pulse_in(pulse),
    .spi_confirm_out(confirm),
    .nextChar(nextChar),
    .init(init),

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

    always begin
        #1
        hwclk = ~hwclk;
    end


    task pulseit (int pass, logic [7:0] bits);
        begin
            for(int i = 0; i < pass; i++) begin
                @(negedge nextChar);
                #20
                pulse = 1;
                read_out = bits;
                @(posedge confirm);
                @(negedge hwclk);
                pulse = 0;     
            end   
        end
    endtask

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
        pulse = 0;
        //nulls = '0;
        //SRAM_finished = 0;

        // TEST 1: Basic Reset and Normal Flow
        $display("\n=== TEST 1: Basic Flow with Node Progression ===");
        test_num = 1;
        resetOn();
        #15000;

        pulse = 1;
        read_out = 8'b0010010;
        @(posedge confirm);
        @(negedge hwclk);
        pulse = 0;
        
        //while(!init) begin
        pulseit (3, 18);
        pulseit (2, 31);
        pulseit (1, 18);
        pulseit (1, 49);
        pulseit (1, 18);
        pulseit (1, 8'h1A);

        #10000 $finish;
    end

endmodule