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
    input logic [6:0] max_index, // max index e.g. the top of the tree, given from HTREE MODULE
    input logic [70:0] h_element, // h_element given to traverse to from SRAM (given curr_index)
    input logic write_finish, // sent from the header synthesis when all bits of header potion have been written in SPI (then continue to traverse the tree)
    input logic [3:0] curr_process, // controller state, comment out when testing this module individually
    output logic char_found, // sent as an enable to the SRAM if a character was found to write path (also to the header synthesis module)
    output logic [127:0] char_path, // sends the character path to SRAM as data
    output logic [7:0] char_index, // sends the character index to SRAM as an index to write at correct address
    output state_cb curr_state, // current internal state of this module in binary tree traversal
    output logic [6:0] curr_index, // current index of the htree element currently being searched (sent to HTREE MODULE)
    output logic [127:0] curr_path, // current path in the tree (begin updated as the tree is traversed)
    output logic [8:0] least1, // least1 of the current htree element
    output logic [8:0] least2, // least2 of the current htree element
    output logic [3:0] finished, // finish signal sent to the CONTROLLER
    output logic [6:0] track_length, // keeps track of current path length to know when to stop tracking the path in the TRACK state
    output logic [6:0] pos, // keeps track of current position in the path when in TRACK state
    output logic wait_cycle //waits one clock cycle in transistion between states to allow for output to stabilize
);
// next state logic
logic [127:0] next_path; // store current path
logic [6:0] next_index; // htree element index
state_cb next_state; // current codebook state
logic [6:0] next_track_length; // current path length (for tracking state)
//logic wait_cycle;
logic next_wait_cycle;
logic [6:0] next_pos;

always_ff @(posedge clk, posedge rst) begin
    if (rst) begin
        curr_state <= INIT; // initial state
        curr_path <= 128'b1; // control bit
        curr_index <= max_index; // top of tree
        track_length <= 7'b0; // set current path length to 0
        pos <= 7'b1;
        wait_cycle <= 1;
    end
    else begin
        curr_path <= next_path;
        curr_state <= next_state;
        track_length <= next_track_length;
        curr_index <= next_index;
        pos <= next_pos;
        wait_cycle <= next_wait_cycle;
    end
end

always_comb begin
    //if (curr_process == CODEBOOK) begin
        least2 = h_element[54:46];
        least1 = h_element[63:55];
        char_found = 1'b0;
        char_path = 128'b0;
        char_index = 8'b0;
        finished = 4'b0;
        next_state = curr_state;
        next_path = curr_path;
        next_index = curr_index;
        next_track_length = track_length;
        next_pos = pos;
        next_wait_cycle = wait_cycle;

        case (curr_state)
            INIT: begin 
                //next_index = max_index;
              if (wait_cycle == 0) begin // wait one cycle for inputs (like getting htree element from curr_index) to stabilize between states
                    next_state = LEFT;
                  next_pos = 1;
                end
                else begin
                     next_state = INIT; 
                     next_wait_cycle = 0;
                end
            end
            LEFT: begin // move left (add 0 to path)
              if (wait_cycle == 0) begin
                  next_track_length = track_length + 1; // update total path length
                  next_state = state_cb'((least1[8] == 1'b0) ? SEND : LEFT);
                  if (least1[8] == 1'b0 || least1 == 9'b110000000) begin // if LSE is a char (or there is no element)
                      if (least1 != 9'b110000000) begin // if there is a char (not no element)
                          char_index = least1[7:0]; // set output character (index) to LSE, NOT to tracking index
                          char_found = 1'b1;
                          next_state = SEND;
                          next_wait_cycle = 1;
                      end
                      else begin  // case for only one element in htree (if character is a null character)
                          next_state = FINISH;
                      end
                      next_path = {curr_path[126:0], 1'b0}; // left shift and add 0 (left) to next path
                      char_path = next_path;
                  end

                  else if (least1[8] == 1'b1) begin // if LSE is a sum
                      next_path = {curr_path[126:0], 1'b0}; // left shift and add 0 (left) to next path
                      next_index = least1[6:0]; // set next index to get from htree to the sum
                    next_wait_cycle = 1;
                  end
              end
              else begin
                next_wait_cycle = 0;
              end
            end
            SEND: begin // state after a character was found and waiting for char bits to be written through SPI
              if (wait_cycle == 0) begin
                  if (write_finish) begin
                      next_state = BACKTRACK;
                      next_wait_cycle = 1;
                  end
                  else begin
                      next_state = curr_state;
                  end
              end
              else begin
                next_wait_cycle = 0;
              end
            end
            TRACK: begin // after backtrack state when a character was found, use that backtracked path to start from the top of the tree and then retrieve the htree element
              if (wait_cycle == 0) begin
                  next_state = state_cb'((track_length >= pos) ? TRACK : RIGHT);
                  next_wait_cycle = 1;
                  if (track_length >= pos) begin // if the h_tree element of the previous node hasn't been reached

                      if (curr_path[track_length - pos] == 1'b0) begin// if the movement in the tree is left
                          next_index = least1[6:0]; // set next index to get from htree to LSE
                          next_pos = pos + 1; // remove one from the tracking length
                      end
                      else if (curr_path[track_length - pos] == 1'b1) begin// if the movement in the tree is right
                          next_index = least2[6:0]; // set next index to get from htree to RSE
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
              if (wait_cycle == 0) begin
                next_wait_cycle = 1;
                  // if the top of the tree has been reached and left and right have already been traversed, next state is FINISH
                  next_state = state_cb'(track_length < 7'b1 && curr_path[0] == 1'b1 ? FINISH : (curr_path[0] == 1'b1 ? BACKTRACK : TRACK)); 
                  if (curr_path[0] == 1'b1 && track_length > 0) begin // if last move was right and the number moves is greater than 0 (not at top of tree)
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
              if (wait_cycle == 0) begin
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
                      next_index = least2[6:0]; // set next index to get from htree to the sum
                  end
              end
              else begin
                next_wait_cycle = 0;
              end
            end
            FINISH: begin
                finished = 4'b0101; // FIN state sent to (CONTROLLER)
            end
            default: begin
                next_state = curr_state;
            end
        endcase
        //curr_index = next_index;

end
endmodule;

