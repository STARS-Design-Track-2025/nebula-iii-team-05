// Parametrizable VGA Driver
// active low reset, active high enable
// Input timing parameters must be supported by VGA
// Default Parameters set for 640x480 Resolution, 60Hz Refresh rate which expects clk of 25.175MHz
// Author: Andy Hu

    // General Operation:
    // use hpos and vpos counters to control hState and vState,
    // generate VGA output signals based off hState and vState

    // Timing values for Varying Resolutions and Refresh Rates:
    //              |        Horizontal (in pixels)                      |               Vertical (in lines)                    |
    //   640x480    |----------------------------------------------------|------------------------------------------------------|
    //    @60Hz     | Active Video| Front Porch | Sync Pulse | Back Porch| Active Video | Front Porch | Sync Pulse | Back Porch |
    //25.175MHz Clk |     640     |     16      |     96     |     48    |     480      |      11     |      2     |     31     |
    //  1920x1080   |----------------------------------------------------|------------------------------------------------------|
    //    @60Hz     |Active Video | Front Porch | Sync Pulse | Back Porch| Active Video | Front Porch | Sync Pulse | Back Porch |
    //148.5MHz Clk  |    1920     |     88      |     44     |     148   |     1080     |      4      |      5     |     36     |




module t05_VGA_Driver_param #(
    parameter
        H_ACTIVE_VIDEO = 640,
        H_FRONT_PORCH = 16,
        H_SYNC_PULSE = 96,
        H_BACK_PORCH = 48,
        V_ACTIVE_VIDEO = 480,
        V_FRONT_PORCH = 11,
        V_SYNC_PULSE = 2,
        V_BACK_PORCH = 31
)(
    input logic clk, nrst, enable, //control 
        Rin, Gin, Bin, //RGB data inputs
    output logic hsync, vsync, Rout, Gout, Bout, //VGA outputs
    
    output logic [$clog2(H_ACTIVE_VIDEO):0] hpos, vpos //active pixel coordinates
);

    logic [$clog2(H_ACTIVE_VIDEO):0] nextHpos, nextVpos;

    typedef enum logic [1:0] {
        ACTIVE_VIDEO,
        FRONT_PORCH,
        SYNC_PULSE,
        BACK_PORCH
    } state_t; 

    state_t hState, vState, 
        nextHState, nextVState;



    always_ff @( posedge clk, negedge nrst ) begin : StateUpdate
        if (~nrst) begin
            hState <= ACTIVE_VIDEO;
            vState <= ACTIVE_VIDEO;
            hpos <= 0;
            vpos <= 0;
        end 
        else if (enable) begin
            hState <= nextHState;
            vState <= nextVState;
            hpos <= nextHpos;
            vpos <= nextVpos;
        end
    end
    
    always_comb begin : NextStateLogic
        // Horizontal
        
        // hpos
        if (hpos == H_ACTIVE_VIDEO + H_FRONT_PORCH + H_SYNC_PULSE + H_BACK_PORCH - 1) begin  //total pixel clocks in a line (Default = 800 = 640 + 16 + 96 + 48)
            nextHpos = 0;
        end
        else begin
            nextHpos = hpos + 1;
        end
        
        // hState
        if (hpos == H_ACTIVE_VIDEO - 1) begin // Active video from pixel 0 to 639
            nextHState = FRONT_PORCH;
        end 
        else if (hpos == H_ACTIVE_VIDEO + H_FRONT_PORCH -1 ) begin // Front Porch (Default from pixel 640 to 655)
            nextHState = SYNC_PULSE;
        end
        else if (hpos == H_ACTIVE_VIDEO + H_FRONT_PORCH + H_SYNC_PULSE - 1) begin // Sync Pulse (Default from pixel 656 to 751)
            nextHState = BACK_PORCH;
        end
        else if (hpos == H_ACTIVE_VIDEO + H_FRONT_PORCH + H_SYNC_PULSE + H_BACK_PORCH - 1) begin // Back Porch (Default from pixel 752 to 799
            nextHState = ACTIVE_VIDEO;
        end
        else begin
            nextHState = hState;
        end


        // Vertical 

        // vpos
        if (vpos == V_ACTIVE_VIDEO + V_FRONT_PORCH + V_SYNC_PULSE + V_BACK_PORCH -1) begin  //total lines in a frame(Default = 524 = 480 + 11 + 2 + 31)
            nextVpos = 0;
        end
        else if (hpos == H_ACTIVE_VIDEO + H_FRONT_PORCH + H_SYNC_PULSE + H_BACK_PORCH - 1) begin
            nextVpos = vpos + 1;
        end
        else begin
            nextVpos = vpos;
        end
        
        // VState
        if (vpos == V_ACTIVE_VIDEO - 1) begin // Active video (Default from line 0 to 479)
            nextVState = FRONT_PORCH;
        end 
        else if (vpos == V_ACTIVE_VIDEO + V_FRONT_PORCH - 1) begin // Front Porch (Default from line 480 to 490)
            nextVState = SYNC_PULSE;
        end
        else if (vpos ==  V_ACTIVE_VIDEO + V_FRONT_PORCH + V_SYNC_PULSE - 1) begin // Sync Pulse (Default from line 491 to 492)
            nextVState = BACK_PORCH;
        end
        else if (vpos == V_ACTIVE_VIDEO + V_FRONT_PORCH + V_SYNC_PULSE + V_BACK_PORCH - 1) begin // Back Porch (Default from line 493 to 523)
            nextVState = ACTIVE_VIDEO;
        end
        else begin
            nextVState = vState;
        end
    end

    always_comb begin : OutputLogic
        if (hState == ACTIVE_VIDEO && vState == ACTIVE_VIDEO) begin
                Rout = Rin;
                Gout = Gin;
                Bout = Bin;

                hsync = 1;
                vsync = 1;
        end
        else begin
            Rout = 0;
            Gout = 0;
            Bout = 0;

            if (hState == SYNC_PULSE) begin
                hsync = 0;
            end
            else begin
                hsync = 1;
            end

            if (vState == SYNC_PULSE) begin
                vsync = 0;
            end
            else begin
                vsync = 1;
            end
        end
    end
endmodule