`timescale 1ms/10ps

typedef enum logic [2:0] {
    LEFT=0,
    RIGHT,
    TRACK,
    BACKTRACK,
    FINISH,
    INIT,
    SEND
} state_cb;

module t05_cb_synthesis_tb;
    logic clk, reset, char_found;
    logic [3:0] finished;
    logic [6:0] max_index;
    logic [70:0] h_element;
    //logic [2:0] curr_process;
    logic [127:0] char_path;
    logic [7:0] char_index;
    logic [6:0] curr_index;
    state_cb state;
    logic [70:0] htree [127:0];
    logic [127:0] curr_path;
    logic [8:0] least1;
    logic [8:0] least2;
    logic [8:0] header;
    logic [6:0] track_length;
    logic [6:0] pos;
    logic mid_reset;
    logic [7:0] count;
    logic enable;
    logic bit1;
    logic write_finish;
    logic wait_cycle;
    logic SRAM_enable;

    always #5 clk = ~clk;
    t05_cb_synthesis cb1(.clk(clk), .SRAM_enable(SRAM_enable), .write_finish(write_finish), .track_length(track_length), .pos(pos), .least1(least1), .least2(least2), .rst(reset), .max_index(max_index), .curr_path(curr_path), .curr_index(curr_index), .h_element(h_element), .curr_state(state), .char_path(char_path), .char_index(char_index), .char_found(char_found), .finished(finished), .wait_cycle(wait_cycle));
    t05_header_synthesis hd1 (.clk(clk), .track_length(track_length), .write_finish(write_finish), .rst(reset), .bit1(bit1), .enable(enable), .char_index(char_index), .char_path(char_path), .char_found(char_found), .least1(least1), .least2(least2), .header(header));
    task reset_fsm();
      begin
        reset = 1;
        @(posedge clk);
        reset = 0;
        @(posedge clk);
      end
    endtask

    task set_inputs(logic [6:0] max_index1, logic [70:0] h_element1);
      begin
        max_index = max_index1;
        h_element = h_element1;
        @(posedge clk);
      end
    endtask

    initial begin
      $dumpfile("t05_cb_synthesis.vcd"); //change the vcd vile name to your source file name
      $dumpvars(0, t05_cb_synthesis_tb);
      
      clk = 0;
      reset = 0;
      max_index = 0;
      mid_reset = 0;
      SRAM_enable = 1;
      //h_element = {{7'd0}, {1'b0, 8'd67}, {2'b11, 7'd0}, {46'd0}};
      
      //ONE ELEMENT ARRAY:
      htree[0] = {{7'd0}, {1'b0, 8'd67}, {2'b11, 7'd0}, {46'd0}};
      //htree[1] = {{7'd0}, {1'b0, 8'd67}, {2'b11, 7'd0}, {46'd0}};
      // reset_fsm();
      // set_inputs(0, htree[curr_index]);
      // $display("STATE: %d", state);
      // set_inputs(0, htree[curr_index]);
      // $display("STATE: %d", state); 
      // set_inputs(0, htree[curr_index]);
      // $display("STATE: %d", state);
      // set_inputs(0, htree[curr_index]);
      // $display("STATE: %d", state);
      // set_inputs(0, htree[curr_index]);
      // $display("STATE: %d", state);
      // set_inputs(0, htree[curr_index]);
      // $display("STATE: %d", state); 
      // set_inputs(0, htree[curr_index]);
      // $display("STATE: %d", state);
      // set_inputs(0, htree[curr_index]);
      // $display("STATE: %d", state);
      // set_inputs(0, htree[curr_index]);
      // $display("STATE: %d", state);
      // set_inputs(0, htree[curr_index]);
      // $display("STATE: %d", state); 
      // set_inputs(0, htree[curr_index]);
      // $display("STATE: %d", state);
      // set_inputs(0, htree[curr_index]);
      // $display("STATE: %d", state);
      // #10

      // NORMAL ARRAY
      max_index = 8;
      htree[0] = {{7'd8}, {1'b0, 8'd67}, {1'b0, 8'd66}, {46'd5}}; // max_index=8, C=2, B=3, sum=5
      htree[1] = {{7'd8}, {1'b0, 8'd68}, {1'b0, 8'd69}, {46'd7}}; // max_index=8, D=3, E=4, sum=7
      htree[2] = {{7'd8}, {1'b0, 8'd72}, {1'b0, 8'd73}, {46'd8}}; // max_index=8, H=4, I=4, sum=8
      htree[3] = {{7'd8}, {1'b1, 8'd0}, {1'b0, 8'd65}, {46'd10}}; // max_index=8, A=5, index0=5, sum=10
      htree[4] = {{7'd8}, {1'b0, 8'd70}, {1'b1, 8'd1}, {46'd13}}; // max_index=8, F=6, index1=7, sum=13
      htree[5] = {{7'd8}, {1'b0, 8'd71}, {1'b1, 8'd2}, {46'd15}}; // max_index=8, G=7, index2=8, sum=15
      htree[6] = {{7'd8}, {1'b1, 8'd3}, {1'b1, 8'd4}, {46'd23}}; // max_index=8, index3=10, index4=13, sum=23
      htree[7] = {{7'd8}, {1'b0, 8'd74}, {1'b1, 8'd5}, {46'd29}}; // max_index=8, J=14, index5=15, sum=29
      htree[8] = {{7'd8}, {1'b1, 8'd6}, {1'b1, 8'd7}, {46'd52}}; // max_index=8, index6=23, index7=29, sum=52

      //LONG HTREE: long paths
//       max_index = 30;
//       htree[0] = {{7'd8}, {1'b0, 8'd0}, {1'b0, 8'd1}, {46'b0}};
//       htree[1] = {{7'd8}, {1'b0, 8'd65}, {1'b1, 8'd0}, {46'b0}};
//       htree[2] = {{7'd8}, {1'b0, 8'd66}, {1'b1, 8'd1}, {46'b0}};
//       htree[3] = {{7'd8}, {1'b0, 8'd67}, {1'b1, 8'd2}, {46'b0}};
//       htree[4] = {{7'd8}, {1'b0, 8'd68}, {1'b1, 8'd3}, {46'b0}};
//       htree[5] = {{7'd8}, {1'b0, 8'd69}, {1'b1, 8'd4}, {46'b0}};
//       htree[6] = {{7'd8}, {1'b0, 8'd70}, {1'b1, 8'd5}, {46'b0}};
//       htree[7] = {{7'd8}, {1'b0, 8'd71}, {1'b1, 8'd6}, {46'b0}};
//       htree[8] = {{7'd8}, {1'b0, 8'd72}, {1'b1, 8'd7}, {46'b0}};
//       htree[9] = {{7'd8}, {1'b0, 8'd73}, {1'b1, 8'd8}, {46'b0}};
//       htree[10] = {{7'd8}, {1'b0, 8'd74}, {1'b1, 8'd9}, {46'b0}};
//       htree[11] = {{7'd8}, {1'b0, 8'd75}, {1'b1, 8'd10}, {46'b0}};
//       htree[12] = {{7'd8}, {1'b0, 8'd76}, {1'b1, 8'd11}, {46'b0}};
//       htree[13] = {{7'd8}, {1'b0, 8'd77}, {1'b1, 8'd12}, {46'b0}};
//       htree[14] = {{7'd8}, {1'b0, 8'd78}, {1'b1, 8'd13}, {46'b0}};
//       htree[15] = {{7'd8}, {1'b0, 8'd79}, {1'b1, 8'd14}, {46'b0}};
//       htree[16] = {{7'd8}, {1'b0, 8'd80}, {1'b1, 8'd15}, {46'b0}};
//       htree[17] = {{7'd8}, {1'b0, 8'd81}, {1'b1, 8'd16}, {46'b0}};
//       htree[18] = {{7'd8}, {1'b0, 8'd82}, {1'b1, 8'd17}, {46'b0}};
//       htree[19] = {{7'd8}, {1'b0, 8'd83}, {1'b1, 8'd18}, {46'b0}};
//       htree[20] = {{7'd8}, {1'b0, 8'd84}, {1'b1, 8'd19}, {46'b0}};
//       htree[21] = {{7'd8}, {1'b0, 8'd85}, {1'b1, 8'd20}, {46'b0}};
//       htree[22] = {{7'd8}, {1'b0, 8'd86}, {1'b1, 8'd21}, {46'b0}};
//       htree[23] = {{7'd8}, {1'b0, 8'd87}, {1'b1, 8'd22}, {46'b0}};
//       htree[24] = {{7'd8}, {1'b0, 8'd88}, {1'b1, 8'd23}, {46'b0}};
//       htree[25] = {{7'd8}, {1'b0, 8'd89}, {1'b1, 8'd24}, {46'b0}};
//       htree[26] = {{7'd8}, {1'b0, 8'd90}, {1'b1, 8'd25}, {46'b0}};
//       htree[27] = {{7'd8}, {1'b0, 8'd91}, {1'b1, 8'd26}, {46'b0}};
//       htree[28] = {{7'd8}, {1'b0, 8'd92}, {1'b1, 8'd27}, {46'b0}};
//       htree[29] = {{7'd8}, {1'b0, 8'd93}, {1'b1, 8'd28}, {46'b0}};
//       htree[30] = {{7'd8}, {1'b0, 8'd94}, {1'b1, 8'd29}, {46'b0}};

      //test 4
      // max_index = 46;
      // htree[0] = {{7'd8}, {1'b0, 8'd95}, {1'b0, 8'd30}, {46'b0}};
      // htree[1] = {{7'd8}, {1'b0, 8'd96}, {1'b0, 8'd31}, {46'b0}};
      // htree[2] = {{7'd8}, {1'b0, 8'd97}, {1'b0, 8'd32}, {46'b0}};
      // htree[3] = {{7'd8}, {1'b0, 8'd98}, {1'b0, 8'd33}, {46'b0}};
      // htree[4] = {{7'd8}, {1'b0, 8'd99}, {1'b0, 8'd34}, {46'b0}};
      // htree[5] = {{7'd8}, {1'b0, 8'd100}, {1'b0, 8'd35}, {46'b0}};
      // htree[6] = {{7'd8}, {1'b0, 8'd101}, {1'b0, 8'd36}, {46'b0}};
      // htree[7] = {{7'd8}, {1'b0, 8'd102}, {1'b0, 8'd37}, {46'b0}};
      // htree[8] = {{7'd8}, {1'b0, 8'd103}, {1'b0, 8'd38}, {46'b0}};
      // htree[9] = {{7'd8}, {1'b0, 8'd104}, {1'b0, 8'd39}, {46'b0}};
      // htree[10] = {{7'd8}, {1'b0, 8'd105}, {1'b0, 8'd40}, {46'b0}};
      // htree[11] = {{7'd8}, {1'b0, 8'd106}, {1'b0, 8'd41}, {46'b0}};
      // htree[12] = {{7'd8}, {1'b0, 8'd107}, {1'b0, 8'd42}, {46'b0}};
      // htree[13] = {{7'd8}, {1'b0, 8'd108}, {1'b0, 8'd43}, {46'b0}};
      // htree[14] = {{7'd8}, {1'b0, 8'd109}, {1'b0, 8'd44}, {46'b0}};
      // htree[15] = {{7'd8}, {1'b0, 8'd110}, {1'b0, 8'd45}, {46'b0}};
      // htree[16] = {{7'd8}, {1'b0, 8'd111}, {1'b0, 8'd46}, {46'b0}};
      // htree[17] = {{7'd8}, {1'b0, 8'd112}, {1'b0, 8'd47}, {46'b0}};
      // htree[18] = {{7'd8}, {1'b0, 8'd113}, {1'b0, 8'd48}, {46'b0}};
      // htree[19] = {{7'd8}, {1'b0, 8'd114}, {1'b0, 8'd49}, {46'b0}};
      // htree[20] = {{7'd8}, {1'b0, 8'd115}, {1'b0, 8'd50}, {46'b0}};
      // htree[21] = {{7'd8}, {1'b0, 8'd116}, {1'b0, 8'd51}, {46'b0}};
      // htree[22] = {{7'd8}, {1'b0, 8'd117}, {1'b0, 8'd52}, {46'b0}};
      // htree[23] = {{7'd8}, {1'b0, 8'd118}, {1'b0, 8'd53}, {46'b0}};
      // htree[24] = {{7'd8}, {1'b1, 8'd0}, {1'b1, 8'd1}, {46'b0}};
      // htree[25] = {{7'd8}, {1'b1, 8'd2}, {1'b1, 8'd3}, {46'b0}};
      // htree[26] = {{7'd8}, {1'b1, 8'd4}, {1'b1, 8'd5}, {46'b0}};
      // htree[27] = {{7'd8}, {1'b1, 8'd6}, {1'b1, 8'd7}, {46'b0}};
      // htree[28] = {{7'd8}, {1'b1, 8'd8}, {1'b1, 8'd9}, {46'b0}};
      // htree[29] = {{7'd8}, {1'b1, 8'd10}, {1'b1, 8'd11}, {46'b0}};
      // htree[30] = {{7'd8}, {1'b1, 8'd12}, {1'b1, 8'd13}, {46'b0}};
      // htree[31] = {{7'd8}, {1'b1, 8'd14}, {1'b1, 8'd15}, {46'b0}};
      // htree[32] = {{7'd8}, {1'b1, 8'd16}, {1'b1, 8'd17}, {46'b0}};
      // htree[33] = {{7'd8}, {1'b1, 8'd18}, {1'b1, 8'd19}, {46'b0}};
      // htree[34] = {{7'd8}, {1'b1, 8'd20}, {1'b1, 8'd21}, {46'b0}};
      // htree[35] = {{7'd8}, {1'b1, 8'd22}, {1'b1, 8'd23}, {46'b0}};
      // htree[36] = {{7'd8}, {1'b1, 8'd24}, {1'b1, 8'd25}, {46'b0}};
      // htree[37] = {{7'd8}, {1'b1, 8'd26}, {1'b1, 8'd27}, {46'b0}};
      // htree[38] = {{7'd8}, {1'b1, 8'd28}, {1'b1, 8'd29}, {46'b0}};
      // htree[39] = {{7'd8}, {1'b1, 8'd30}, {1'b1, 8'd31}, {46'b0}};
      // htree[40] = {{7'd8}, {1'b1, 8'd32}, {1'b1, 8'd33}, {46'b0}};
      // htree[41] = {{7'd8}, {1'b1, 8'd34}, {1'b1, 8'd35}, {46'b0}};
      // htree[42] = {{7'd8}, {1'b1, 8'd36}, {1'b1, 8'd37}, {46'b0}};
      // htree[43] = {{7'd8}, {1'b1, 8'd38}, {1'b1, 8'd39}, {46'b0}};
      // htree[44] = {{7'd8}, {1'b1, 8'd40}, {1'b1, 8'd41}, {46'b0}};
      // htree[45] = {{7'd8}, {1'b1, 8'd42}, {1'b1, 8'd43}, {46'b0}};
      // htree[46] = {{7'd8}, {1'b1, 8'd44}, {1'b1, 8'd45}, {46'b0}};
   

      
      
      reset_fsm();
      // for (int i = 0; i < 1000; i++) begin
      //   set_inputs(max_index, htree[curr_index]);
      // end
      while (finished != 4'b0101) begin
        set_inputs(max_index, htree[curr_index]);
        $display("STATE: %d", state);
        if (({1'b0, curr_index} == {1'b0, max_index}/2) && (!mid_reset)) begin
          reset_fsm();
          mid_reset = 1;
        end
      end

      #100;

      #1 $finish;

    end
  
endmodule

