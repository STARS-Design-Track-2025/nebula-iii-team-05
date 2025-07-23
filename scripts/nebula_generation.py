import os
import glob

def find_root_directory(start_path):
    # Check if running in GitHub Actions
    github_workspace = os.getenv("GITHUB_WORKSPACE")
    if github_workspace:
        return github_workspace

    # Fallback to local method
    current_path = os.path.abspath(os.path.dirname(__file__))
    while current_path != os.path.dirname(current_path):
        if os.path.isdir(os.path.join(current_path, '.git')):
            return current_path
        current_path = os.path.dirname(current_path)
    print("Project directory not found")
    return None  # Return None if project directory is not found

def get_teams(root_directory):
    team_folders = glob.glob(root_directory + "/verilog/rtl/team_projects/*")
    return [os.path.basename(team_folder) for team_folder in team_folders]


def main():
    
    # Find the project directory
    root_directory = find_root_directory(os.getcwd())
    
    teams = get_teams(root_directory)
    num_teams = max(int(team.split('_')[1]) for team in teams)
    print(f"Generating Nebula with {num_teams} teams")
    
    # Specify the file to create
    output_file = root_directory + "/verilog/rtl/nebula.v"

    # Write to the file
    with open(output_file, 'w') as f:
        f.write(\
"""\
// PLEASE DO NOT EDIT!!! This file will automatically update when "make nebula" is called.
// It has dependencies of each of the teams' yaml files.  If the LA, or GPIO change significantly, 
// this script may need to be changed.  The relevant script is ./scripts/nebula_generation.py
module nebula (
`ifdef USE_POWER_PINS
    inout vccd1,	// User area 1 1.8V supply
    inout vssd1,	// User area 1 digital ground
`endif

    // User clk, rst
    input wb_clk_i,
    input wb_rst_i,

    // Wishbone Slave ports (WB MI A)
    input wbs_stb_i,
    input wbs_cyc_i,
    input wbs_we_i,
    input [3:0] wbs_sel_i,
    input [31:0] wbs_dat_i,
    input [31:0] wbs_adr_i,
    output wbs_ack_o,
    output [31:0] wbs_dat_o,

    // Logic Analyzer Signals
    input  [127:0] la_data_in,
    output [127:0] la_data_out,
    input  [127:0] la_oenb,

    // IOs, give all here, the wrapper will default 1:4 to unused (to make it easier for teams to change)
    input  [37:0] io_in,
    output [37:0] io_out,
    output [37:0] io_oeb,

    // IRQ
    output [2:0] irq
);

    // Number of teams
"""\
)
            
            
            
        f.write(f"    localparam NUM_TEAMS = {num_teams};\n")

        f.write(\
"""

    //Synchronous rst for all the teams
    wire teams_nrst;

    // LA outputs from all designs
    wire [31:0] designs_la_data_out [NUM_TEAMS:0];

    // GPIO outputs from all designs
    wire [37:0] designs_gpio_out [NUM_TEAMS:0]; // Breakout Board Pins
    wire [37:0] designs_gpio_oeb [NUM_TEAMS:0]; // Active Low Output Enable

    // IRQ from all designs
    // (not used unless a team wants to)
    // wire [2:0] designs_irq [NUM_TEAMS:0];
    assign irq = 3'b0; // Default of 0

    //Project Manager Arbitrator Signals
    wire [31:0] arbitrator_dat_i [NUM_TEAMS:0];
    wire [31:0] arbitrator_adr_i [NUM_TEAMS:0];
    reg [31:0] arbitrator_dat_o [NUM_TEAMS:0];
    wire [3:0] arbitrator_sel_i [NUM_TEAMS:0];
    wire [NUM_TEAMS:0] arbitrator_ack_o;
    wire [NUM_TEAMS:0] arbitrator_we_i;
    wire [NUM_TEAMS:0] arbitrator_stb_i;
    wire [NUM_TEAMS:0] arbitrator_cyc_i;

    //to arbitrator
    wire        wbs_ack_o_m;
    wire [31:0] wbs_dat_o_m;
    //from arbitrator
    wire        wbs_cyc_i_m;
    wire        wbs_stb_i_m;
    wire        wbs_we_i_m;
    wire [31:0] wbs_adr_i_m;
    wire [31:0] wbs_dat_i_m;
    wire [3:0]  wbs_sel_i_m;


    wire [NUM_TEAMS:0]  wbs_ack_i_projects;
    wire                wbs_ack_i_gpio, wbs_ack_i_la, wbs_ack_i_ram;
    
    wire [31:0]         wbs_dat_i_projects [NUM_TEAMS:0];
    wire [31:0]         wbs_dat_i_gpio, wbs_dat_i_la, wbs_dat_i_ram;

    wire [NUM_TEAMS:0]  wbs_cyc_o_projects;
    wire                wbs_cyc_o_gpio, wbs_cyc_o_la, wbs_cyc_o_ram;

    wire [NUM_TEAMS:0]  wbs_stb_o_projects;
    wire                wbs_stb_o_gpio, wbs_stb_o_la, wbs_stb_o_ram;
    
    wire [NUM_TEAMS:0]  wbs_we_o_projects;
    wire                wbs_we_o_gpio, wbs_we_o_la, wbs_we_o_ram;
    
    reg [31:0]         wbs_adr_o_projects [NUM_TEAMS:0];
    wire [31:0]         wbs_adr_o_gpio, wbs_adr_o_la, wbs_adr_o_ram;
    
    reg [31:0]         wbs_dat_o_projects [NUM_TEAMS:0];
    wire [31:0]         wbs_dat_o_gpio, wbs_dat_o_la, wbs_dat_o_ram;
    
    reg [3:0]          wbs_sel_o_projects [NUM_TEAMS:0];
    wire [3:0]          wbs_sel_o_gpio, wbs_sel_o_la, wbs_sel_o_ram;
"""\
)

        for team in teams:
            team_number = int(team.split('_')[1])
            f.write(\
f"""      
    // {team} Project Instance
    {team}_Wrapper {team}_Wrapper (
    `ifdef USE_POWER_PINS
            .vccd1(vccd1),	// User area 1 1.8V power
            .vssd1(vssd1),	// User area 1 digital ground
    `endif
        .nrst(teams_nrst),
        //Wishbone Slave and user clk, rst
        .wb_clk_i(wb_clk_i),
        .wb_rst_i(wb_rst_i),
        .wbs_stb_i(wbs_stb_o_projects[{team_number}]),
        .wbs_cyc_i(wbs_cyc_o_projects[{team_number}]),
        .wbs_we_i(wbs_we_o_projects[{team_number}]),
        .wbs_sel_i(wbs_sel_o_projects[{team_number}]),
        .wbs_dat_i(wbs_dat_o_projects[{team_number}]),
        .wbs_adr_i(wbs_adr_o_projects[{team_number}]),
        .wbs_ack_o(wbs_ack_i_projects[{team_number}]),
        .wbs_dat_o(wbs_dat_i_projects[{team_number}]),

        // Logic Analyzer
        .la_data_in(la_data_in[31:0]),
        .la_data_out(designs_la_data_out[{team_number}]),
        .la_oenb(la_oenb[31:0]),

        // GPIOs
        .gpio_in(io_in), // Breakout Board Pins
        .gpio_out(designs_gpio_out[{team_number}]), // Breakout Board Pins
        .gpio_oeb(designs_gpio_oeb[{team_number}]), // Active Low Output Enable

        .DAT_I(arbitrator_dat_o[{team_number}]),
        .ACK_I(arbitrator_ack_o[{team_number}]),
        .ADR_O(arbitrator_adr_i[{team_number}]),
        .DAT_O(arbitrator_dat_i[{team_number}]),
        .SEL_O(arbitrator_sel_i[{team_number}]),
        .WE_O  (arbitrator_we_i[{team_number}]),
        .STB_O(arbitrator_stb_i[{team_number}]),
        .CYC_O(arbitrator_cyc_i[{team_number}])
    ); 
        
"""\
)

        f.write(\
"""
    
    // Flattened GPIO outputs
    reg [38*(NUM_TEAMS+1)-1:0] designs_gpio_out_flat;
    reg [38*(NUM_TEAMS+1)-1:0] designs_gpio_oeb_flat;

    // Flattening of GPIO outputs
    integer i1;
    always @* begin
        for (i1 = 0; i1 <= NUM_TEAMS; i1 = i1 + 1) begin
            designs_gpio_out_flat[i1*38 +: 38] = designs_gpio_out[i1];//[38(i+1)-1:38i]
            designs_gpio_oeb_flat[i1*38 +: 38] = designs_gpio_oeb[i1];//[38(i+1)-1:38i]
        end
    end

    // GPIO Control
    gpio_control_Wrapper #(
        .NUM_TEAMS(NUM_TEAMS)
    ) gpio_control_wrapper (
        // Wishbone Slave ports (WB MI A)
    `ifdef USE_POWER_PINS
            .vccd1(vccd1),	// User area 1 1.8V power
            .vssd1(vssd1),	// User area 1 digital ground
    `endif
        .wb_clk_i(wb_clk_i),
        .wb_rst_i(wb_rst_i),
        .wbs_stb_i(wbs_stb_o_gpio),
        .wbs_cyc_i(wbs_cyc_o_gpio),
        .wbs_we_i(wbs_we_o_gpio),
        .wbs_sel_i(wbs_sel_o_gpio),
        .wbs_dat_i(wbs_dat_o_gpio),
        .wbs_adr_i(wbs_adr_o_gpio),
        .wbs_ack_o(wbs_ack_i_gpio),
        .wbs_dat_o(wbs_dat_i_gpio),
        
        // GPIOs
        .designs_gpio_out_flat(designs_gpio_out_flat),
        .designs_gpio_oeb_flat(designs_gpio_oeb_flat),
        .gpio_out(io_out),
        .gpio_oeb(io_oeb)
    );

    // Flattened LA outputs
    reg [32*(NUM_TEAMS+1)-1:0] designs_la_data_out_flat;

    // Flattening of LA outputs
    integer i2;
    always @* begin
        for (i2 = 0; i2 <= NUM_TEAMS; i2 = i2 + 1) begin
            designs_la_data_out_flat[i2*32 +: 32] = designs_la_data_out[i2];//[32(i+1)-1:32i]]
        end
    end

    // LA Control
    la_control_Wrapper #(
        .NUM_TEAMS(NUM_TEAMS)
    ) la_control_wrapper (
    `ifdef USE_POWER_PINS
            .vccd1(vccd1),	// User area 1 1.8V power
            .vssd1(vssd1),	// User area 1 digital ground
    `endif
        // Wishbone Slave ports (WB MI A)
        .wb_clk_i(wb_clk_i),
        .wb_rst_i(wb_rst_i),
        .wbs_stb_i(wbs_stb_o_la),
        .wbs_cyc_i(wbs_cyc_o_la),
        .wbs_we_i(wbs_we_o_la),
        .wbs_sel_i(wbs_sel_o_la),
        .wbs_dat_i(wbs_dat_o_la),
        .wbs_adr_i(wbs_adr_o_la),
        .wbs_ack_o(wbs_ack_i_la),
        .wbs_dat_o(wbs_dat_i_la),
        
        // LA
        .designs_la_data_out_flat(designs_la_data_out_flat),
        .la_data_out(la_data_out[31:0])
    );

    // Flattened WB signals from projects
    reg [32*(NUM_TEAMS+1)-1:0] wbs_dat_i_projects_flat;
    wire [32*(NUM_TEAMS+1)-1:0] wbs_adr_o_projects_flat;
    wire [32*(NUM_TEAMS+1)-1:0] wbs_dat_o_projects_flat;
    wire [4*(NUM_TEAMS+1)-1:0] wbs_sel_o_projects_flat;
    // Flattening of WB signals from projects
    integer i3;
    always @* begin
        for (i3 = 0; i3 <= NUM_TEAMS; i3 = i3 + 1) begin
            wbs_dat_i_projects_flat[i3*32 +: 32] = wbs_dat_i_projects[i3];//[32(i+1)-1:32i]]

            wbs_adr_o_projects[i3] = wbs_adr_o_projects_flat[i3*32 +: 32];//[32(i+1)-1:32i]]
            wbs_dat_o_projects[i3] = wbs_dat_o_projects_flat[i3*32 +: 32];//[32(i+1)-1:32i]]
            wbs_sel_o_projects[i3] = wbs_sel_o_projects_flat[i3*4 +: 4];//[4(i+1)-1:4i]]
        end
    end

    
    // Flattened manager signals to arbitrator
    reg [32*(NUM_TEAMS+1)-1:0] arbitrator_dat_i_flat;
    reg [32*(NUM_TEAMS+1)-1:0] arbitrator_adr_i_flat;
    wire [32*(NUM_TEAMS+1)-1:0] arbitrator_dat_o_flat;
    reg [4*(NUM_TEAMS+1)-1:0] arbitrator_sel_i_flat;
    // Flattening of manager signals to arbitrator
    integer i4;
    always @* begin
        for (i4 = 0; i4 <= NUM_TEAMS; i4 = i4 + 1) begin
            arbitrator_dat_i_flat[i4*32 +: 32] = arbitrator_dat_i[i4];//[32(i+1)-1:32i]]
            arbitrator_adr_i_flat[i4*32 +: 32] = arbitrator_adr_i[i4];//[32(i+1)-1:32i]]
            arbitrator_sel_i_flat[i4* 4 +:  4] = arbitrator_sel_i[i4];//[4(i+1)-1:4i]]

            arbitrator_dat_o[i4] = arbitrator_dat_o_flat[i4*32 +: 32];//[32(i+1)-1:32i]]
        end
    end

    // Wishbone Arbitrator
    wishbone_arbitrator #(
        .NUM_MANAGERS(NUM_TEAMS+2)  //+2 for caravel core processor and sample project
    ) wb_arbitrator (
        
    `ifdef USE_POWER_PINS
        .vccd1(vccd1),	// User area 1 1.8V power
        .vssd1(vssd1),	// User area 1 digital ground
    `endif

        .CLK(wb_clk_i),
        .nRST(~wb_rst_i),

        //manager to arbitrator, input
        .A_ADR_I({arbitrator_adr_i_flat, wbs_adr_i}),
        .A_DAT_I({arbitrator_dat_i_flat, wbs_dat_i}),
        .A_SEL_I({arbitrator_sel_i_flat, wbs_sel_i}),
        .A_WE_I({arbitrator_we_i, wbs_we_i}),
        .A_STB_I({arbitrator_stb_i, wbs_stb_i}),
        .A_CYC_I({arbitrator_cyc_i, wbs_cyc_i}),

        //arbitrator to manager, output
        .A_DAT_O({arbitrator_dat_o_flat, wbs_dat_o}),
        .A_ACK_O({arbitrator_ack_o, wbs_ack_o}),

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

    wishbone_decoder #(
        .NUM_TEAMS(NUM_TEAMS)
    ) wb_decoder (

    `ifdef USE_POWER_PINS
        .vccd1(vccd1),	// User area 1 1.8V power
        .vssd1(vssd1),	// User area 1 digital ground
    `endif

        .CLK(wb_clk_i),
        .nRST(~wb_rst_i),

        //muxxing signals that go to manager
        .wbs_ack_i_periph({wbs_ack_i_projects, wbs_ack_i_la, wbs_ack_i_gpio, wbs_ack_i_ram}),
        .wbs_dat_i_periph({wbs_dat_i_projects_flat, wbs_dat_i_la, wbs_dat_i_gpio, wbs_dat_i_ram}),

        .wbs_ack_o_m(wbs_ack_o_m),
        .wbs_dat_o_m(wbs_dat_o_m),

        //muxxing signals that come from manager
        .wbs_cyc_i_m(wbs_cyc_i_m),
        .wbs_stb_i_m(wbs_stb_i_m),
        .wbs_we_i_m(wbs_we_i_m),
        .wbs_adr_i_m(wbs_adr_i_m),
        .wbs_dat_i_m(wbs_dat_i_m),
        .wbs_sel_i_m(wbs_sel_i_m),

        .wbs_cyc_o_periph({wbs_cyc_o_projects, wbs_cyc_o_la, wbs_cyc_o_gpio, wbs_cyc_o_ram}),
        .wbs_stb_o_periph({wbs_stb_o_projects, wbs_stb_o_la, wbs_stb_o_gpio, wbs_stb_o_ram}),
        .wbs_we_o_periph({wbs_we_o_projects, wbs_we_o_la, wbs_we_o_gpio, wbs_we_o_ram}),
        .wbs_adr_o_periph({wbs_adr_o_projects_flat, wbs_adr_o_la, wbs_adr_o_gpio, wbs_adr_o_ram}),
        .wbs_dat_o_periph({wbs_dat_o_projects_flat, wbs_dat_o_la, wbs_dat_o_gpio, wbs_dat_o_ram}),
        .wbs_sel_o_periph({wbs_sel_o_projects_flat, wbs_sel_o_la, wbs_sel_o_gpio, wbs_sel_o_ram})
    );

     // SRAM instantiation
    sram_WB_Wrapper sram (
    `ifdef USE_POWER_PINS
        .vccd1(vccd1),	// User area 1 1.8V power
        .vssd1(vssd1),	// User area 1 digital ground
    `endif

        .wb_clk_i(wb_clk_i),
        .wb_rst_i(wb_rst_i),

        // MGMT SoC Wishbone Slave

        .wbs_stb_i(wbs_stb_o_ram),
        .wbs_cyc_i(wbs_cyc_o_ram),
        .wbs_we_i(wbs_we_o_ram),
        .wbs_sel_i(wbs_sel_o_ram),
        .wbs_dat_i(wbs_dat_o_ram),
        .wbs_adr_i(wbs_adr_o_ram),
        .wbs_ack_o(wbs_ack_i_ram),
        .wbs_dat_o(wbs_dat_i_ram)
    );

    // Synchronizer for reset
    async_reset_sync designs_sync_rst (
    `ifdef USE_POWER_PINS
        .vccd1(vccd1),	// User area 1 1.8V power
        .vssd1(vssd1),	// User area 1 digital ground
    `endif
        .clk(wb_clk_i),
        .asyncrst_n(~wb_rst_i),
        .n_rst(teams_nrst)
    );
endmodule

// Async assert, sync deassert nrst
// https://electronics.stackexchange.com/questions/21696/reset-synchronous-vs-asynchronous
// When this signal reaches any of the design FFs, they will all deassert the nrst after the second clock edge
module async_reset_sync (

`ifdef USE_POWER_PINS
    inout vccd1,	// User area 1 1.8V supply
    inout vssd1,	// User area 1 digital ground
`endif

    input clk,
    input asyncrst_n,
    output reg n_rst
);
    reg rff;
    wire next_n_rst;
    assign next_n_rst = rff;

    always @ (posedge clk or negedge asyncrst_n) begin
        if(!asyncrst_n) begin
            n_rst <= 1'b0;
            rff <= 1'b0;
        end 
        else begin
            n_rst <= next_n_rst;
            rff <= 1'b1;
        end
    end
endmodule

`default_nettype wire
"""\
)         
            


        
    print("Done writing nebula.sv")

if __name__ == "__main__":
    main()
