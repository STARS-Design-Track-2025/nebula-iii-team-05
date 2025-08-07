`timescale 10ms/10ns
module t05_top_tb;

    logic hwclk, reset, miso;
    logic mosi;
    //logic SRAM_finished;
    logic [6:0] read_out;
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
    logic histo_complete;
    logic out_of_init;

    logic read_in_pulse;
    logic [6:0] in;

    logic busy_o;

    t05_top top (
    .hwclk(hwclk),
    .reset(reset),
    .mosi(mosi),
    .miso(miso),
    // .spi_confirm_out(confirm),
    .nextChar(nextChar),
    .init(init),
    .in(in),
    .read_in_pulse(read_in_pulse),
    // .readEn(histo_complete),
    .out_of_init(out_of_init),
    .busy_o(busy_o),

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

    // initial begin
    //     #37000 $finish;
    // end

    logic [12:0] index, index_n;
    
    logic alt, alt_n;

    logic [6:0] in_hold;

    //logic [6:0] mem [135:0];
    // logic [6:0] mem [23:0];
    //logic [6:0] mem [47:0];
    logic [6:0] mem [4687:0];

    initial begin
        $readmemb("7bitschunk.mem", mem);
    end

    always_ff @(posedge hwclk, posedge reset) begin
        if(reset) begin
            index <= '0;
            alt <= 0;
            in_hold <= '0;
        end else begin
            index <= index_n;
            alt <= alt_n;
            in_hold <= in;
        end
    end

    always_comb begin
        alt_n = !alt;
        index_n = index;
        read_in_pulse = 0;
        in = in_hold;

        if((!init && !out_of_init && !wbs_ack_o) || (nextChar && !busy_o)) begin
            index_n = index + 1;
            read_in_pulse = 1;
            in = mem[index][6:0];
        end
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
        test_num = '0;
        pulse = 0;
        //nulls = '0;
        //SRAM_finished = 0;

        // TEST 1: Basic Reset and Normal Flow
        // $display("\n=== TEST 1: Basic Flow with Node Progression ===");
        // test_num = 1;
        resetOn();
        // #15000;

        // pulse = 1;
        // read_out = 8'b0010010;
        // @(posedge confirm);
        // @(negedge hwclk);
        // pulse = 0;
        
        // //while(!init) begin
        // pulseit (3, 18);
        // pulseit (2, 31);
        // pulseit (1, 18);
        // pulseit (1, 49);
        // pulseit (1, 18);
        // pulseit (1, 8'h1A);
        // #60000;
        

        // test_num = 2;
        // resetOn();
        // #15000;

        // pulse = 1;
        // read_out = 65;
        // @(posedge confirm);
        // @(negedge hwclk);
        // pulse = 0;
        // pulseit (3, 65);
        // pulseit (4, 66);
        // pulseit (6, 67);
        // pulseit (7, 68);
        // pulseit (1, 8'h1A);
        // #27200;

        // read_out = 65;
        // #250;
        // read_out = 66;
        // #250;
        // read_out = 67;
        // #250;
        // read_out = 68;
        // #250
        // read_out = 7'h1A;

        // #32800

        // test_num = 3;
        // resetOn();
        // #15000;

        // pulse = 1;
        // read_out = 65;
        // @(posedge confirm);
        // @(negedge hwclk);
        // pulse = 0;
        // pulseit (2, 66);
        // pulseit (3, 67);
        // pulseit (3, 68);
        // pulseit (3, 69);
        // pulseit (1, 8'h1A);
        // #32550;

        // read_out = 65;
        // #276;
        // read_out = 66;
        // #276;
        // read_out = 67;
        // #276;
        // read_out = 68;
        // #276;
        // read_out = 69;
        // #276;
        // read_out = 8'h1A;

        // #27450;
        // test_num = 3;
        // resetOn();
        // #15000;

        // pulse = 1;
        // read_out = 0;
        // @(posedge confirm);
        // @(negedge hwclk);
        // pulse = 0;
        // for(int i = 0; i < 256; i++) begin
        //     pulseit (, i);
        // end
        // pulseit (1, 8'h1A);
//        #104380 $finish;
        #930000 $finish;
    end

endmodule