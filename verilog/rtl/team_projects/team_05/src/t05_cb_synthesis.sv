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
  
module t05_cb_synthesis (
    input logic clk,
    input logic rst,
    input logic [7:0] max_index,
    input logic [70:0] h_element,
    input logic write_finish,
    input logic [3:0] en_state,
    //input logic [2:0] curr_process,
    input logic SRAM_enable,
    output logic char_found,
    output logic [127:0] char_path,
    output logic [7:0] char_index,
    output logic [7:0] curr_index,
    output logic [8:0] least1,
    output logic [8:0] least2,
    output logic finished,
    output logic [6:0] track_length
);

// next state logic
logic [127:0] next_path, curr_path; // store current path
logic [7:0] next_index; // htree element index
state_cb next_state, curr_state; // current codebook state
logic [6:0] next_track_length; // current path length (for tracking state)
//logic wait_cycle;
logic next_wait_cycle;
logic [6:0] next_pos, pos;
logic sent;
logic next_sent, wait_cycle;

always_ff @(posedge clk, posedge rst) begin
    if (rst) begin
        curr_state <= INIT; // initial state
        curr_path <= 128'b1; // control bit
        curr_index <= max_index; // top of tree
        track_length <= 7'b0; // set current path length to 0
        pos <= 7'b1;
        wait_cycle <= 1;
        sent <= 0;
    end
    else if (en_state == 4) begin
        curr_path <= next_path;
        curr_state <= next_state;
        track_length <= next_track_length;
        curr_index <= next_index;
        pos <= next_pos;
        wait_cycle <= next_wait_cycle;
        sent <= next_sent;
    end
end

always @(*) begin
    //if (curr_process == CODEBOOK) begin
        least2 = h_element[54:46];
        least1 = h_element[63:55];
        char_found = 1'b0;
        char_path = 128'b0;
        char_index = 8'b0;
        finished = 0;
        next_state = curr_state;
        next_path = curr_path;
        next_index = curr_index;
        next_track_length = track_length;
        next_pos = pos;
        next_wait_cycle = wait_cycle;
        next_sent = sent;

        case (curr_state)
            INIT: begin 
                //next_index = max_index;
              if (wait_cycle == 0 && SRAM_enable) begin // wait one cycle for inputs (like getting htree element from curr_index) to stabilize between states
                    next_state = LEFT;
                  next_pos = 1;
                end
                else begin
                     next_state = INIT; 
                     next_wait_cycle = 0;
                end
            end
            LEFT: begin // move left (add 0 to path)
              if (wait_cycle == 0 && SRAM_enable) begin
                  next_track_length = track_length + 1; // update total path length
                //   if(least1[8] == 1'b0) begin
                //       next_state = SEND;
                //   end
                  if (least1 == 9'b110000000) begin
                        next_state = FINISH;
                  end
                  else if (least1[8]) begin
                      next_state = LEFT;
                  end
                  else if (least1[8] == 1'b0) begin // if LSE is a char (or there is no element)
                      if (least1 != 9'b110000000) begin // if there is a char (not no element)
                          char_index = least1[7:0]; // set output character (index) to LSE, NOT to tracking index
                          char_found = 1'b1;
                          next_state = SEND;
                          next_wait_cycle = 1;
                      end
                      next_path = {curr_path[126:0], 1'b0}; // left shift and add 0 (left) to next path
                      char_path = next_path;
                  end

                  else if (least1[8] == 1'b1) begin // if LSE is a sum
                      next_path = {curr_path[126:0], 1'b0}; // left shift and add 0 (left) to next path
                      next_index = least1[7:0]; // set next index to get from htree to the sum
                    next_wait_cycle = 1;
                  end
              end
              else begin
                next_wait_cycle = 0;
              end
            end
            SEND: begin // state after a character was found and waiting for char bits to be written through SPI
              //if (wait_cycle == 0) begin
                  if (write_finish) begin
                      next_state = BACKTRACK;
                      next_wait_cycle = 1;
                      //next_sent = 0;
                  end
                  else begin
                      next_sent = 1;
                      next_state = curr_state;
                  end
              //end
              // else begin
              //   next_wait_cycle = 0;
              // end
            end
            TRACK: begin // after backtrack state when a character was found, use that backtracked path to start from the top of the tree and then retrieve the htree element
              if (wait_cycle == 0 && SRAM_enable) begin
                  next_state = state_cb'((track_length >= pos) ? TRACK : RIGHT);
                  next_wait_cycle = 1;
                  if (track_length >= pos) begin // if the h_tree element of the previous node hasn't been reached

                      if (curr_path[track_length - pos] == 1'b0) begin// if the movement in the tree is left
                          next_index = least1[7:0]; // set next index to get from htree to LSE
                          next_pos = pos + 1; // remove one from the tracking length
                      end
                      else if (curr_path[track_length - pos] == 1'b1) begin// if the movement in the tree is right
                          next_index = least2[7:0]; // set next index to get from htree to RSE
                          next_pos = pos + 1; // remove one from the tracking length
                      end
                  end
                  else begin
                          next_pos = 1; // to account for track length index being one less than actual length
                  end
              end
              else begin
                next_wait_cycle = 0;
              end
            end
            BACKTRACK: begin // after a char was found and bits were written through the spi (header portion) start to backtrack until you can move right again
              if (wait_cycle == 0 && SRAM_enable) begin
                next_wait_cycle = 1;
                  // if the top of the tree has been reached and left and right have already been traversed, next state is FINISH
                  next_state = state_cb'(track_length < 7'b1 && curr_path[0] == 1'b1 ? FINISH : (curr_path[0] == 1'b1 ? BACKTRACK : TRACK)); 
                    if (track_length == 7'd1 && !sent) begin //  once top of tree is about to be reached send 0's accumulated to be written and then return to backtrack again
                          next_state = SEND;
                          next_sent = 1; // set sent to 1 so when coming back to this state it doesn't go to sent again
                    end
                    else if (curr_path[0] == 1'b1 && track_length > 0) begin // if last move was right and the number moves is greater than 0 (not at top of tree)
                          next_sent = 0; // once SEND is done and state is backtrack again, set sent to 0 and remove the last move to reach the top of the tree
                          next_path = {1'b0, curr_path[127:1]}; // right shift path to remove last move to "backtrack"
                          next_state = BACKTRACK;
                          next_track_length = track_length - 1; // remove one from track length
                    end
                    else if (curr_path[0] == 1'b0 && track_length > 0) begin // if not at top and didn't go right but went left
                        next_state = TRACK;
                        next_index = max_index;
                        next_path = {1'b0, curr_path[127:1]};
                        next_track_length = track_length - 1;
                    end
              end
              else begin
                next_wait_cycle = 0;
              end
            end
            RIGHT: begin  // move right (add 1 to path)
              if (wait_cycle == 0 && SRAM_enable) begin
                  next_track_length = track_length + 1; // update total path length
                  next_wait_cycle = 1;
                  next_state = state_cb'((least2[8] == 1'b0) ? SEND : LEFT);
                  if (least2[8] == 1'b0 || least2 == 9'b110000000) begin // if RSE is a char or there is no chracter
                      if (least2 != 9'b110000000) begin
                          char_index = least2[7:0]; // set output character (index) to LSE, NOT to tracking index
                          char_found = 1'b1;
                          next_state = SEND;
                      end
                      else begin  // case for only one element in htree (if character is a null character)
                          next_state = FINISH;
                      end
                      next_path = {curr_path[126:0], 1'b1}; // left shift and add 1 (left) to output character path
                      char_path = next_path;
                  end

                  else if (least2[8] == 1'b1) begin // if RSE is a sum
                      next_path = {curr_path[126:0], 1'b1}; // left shift and add 0 (left) to next path
                      next_index = least2[7:0]; // set next index to get from htree to the sum
                  end
              end
              else begin
                next_wait_cycle = 0;
              end
            end
            FINISH: begin
                finished = 1; // FIN state sent to (CONTROLLER)
            end
            default: begin
                next_state = curr_state;
            end
        endcase

end
endmodule;