`timescale 1ms/10ps
module t05_cb_synthesis (
    input logic clk,
    input logic rst,
    input logic [6:0] max_index,
    input logic [70:0] h_element,
    input logic write_finish,
    input logic [3:0] en_state,
    input logic SRAM_enable,
    input logic read_complete,
    input logic write_complete,
    output logic char_found,
    output logic [127:0] char_path,
    output logic [7:0] char_index,
    output logic [3:0] curr_state,
    output logic [6:0] curr_index,
    output logic [127:0] curr_path,
    output logic finished,
    output logic [6:0] track_length,
    output logic [7:0] num_lefts,
    output logic left,
    output logic pulse,
    output logic cb_r_wr
);

typedef enum logic [3:0] {
    LEFT = 0,
    RIGHT = 1,
    TRACK = 2,
    BACKTRACK = 3,
    FINISH = 4,
    INIT = 5,
    SEND = 6,
    SEND_WAIT = 7,
    TRACK_GPS = 8,
    TRACK_GPS2 = 9,
    TRACK_GPS3 = 10
} state_cb;

logic [8:0] least1, least2;

// next state logic
logic [127:0] next_path; // store current path
logic [6:0] next_index; // htree element index
state_cb next_state; // current codebook state
logic [6:0] next_track_length; // current path length (for tracking state)
logic wait_cycle, next_wait_cycle;
logic [6:0] pos, next_pos;
logic sent;
logic next_sent;
logic [7:0] next_num_lefts;
logic next_left;
logic [127:0] char_path_n;
logic setup, setup_n;
logic left_check, left_check_n;
logic check_right, check_right_n;
logic [6:0] prev_index, prev_index_n;
logic [8:0] saved_least1, saved_least1_n, saved_least2, saved_least2_n;
logic track_check, track_check_n;
logic relapse, relapse_n;
logic backed, backed_n;
logic [8:0] parent, parent_n;
logic [7:0] char_index_n;

logic [6:0] cb_length, cb_length_n;
logic [6:0] end_cnt, end_cnt_n;
logic [6:0] end_track, end_track_n;
logic end_cond, end_cond_n;
logic end_check, end_check_n;
logic cb_enable, cb_enable_n;

always_ff @(posedge clk, posedge rst) begin
  if (rst) begin
    curr_state <= INIT; // initial state
    curr_path <= 128'b1; // control bit
    curr_index <= '0; // top of tree
    track_length <= 7'b0; // set current path length to 0
    pos <= 7'b1;
    wait_cycle <= 1;
    sent <= 0;
    num_lefts <= 0;
    left <= 0;
    char_path <= '0;
    setup <= 1;
    left_check <= 0;
    check_right <= 0;
    prev_index <= 0;
    saved_least1 <= 0;
    saved_least2 <= 0;
    track_check <= 0;
    relapse <= 0;
    backed <= 0;
    parent <= 0;
    cb_length <= '0;
    end_cnt <= 127;
    end_track <= 0;
    end_check <= 0;
    cb_enable <= 0;
    end_cond <= 0;
    char_index <= 0;
  end
  else if (en_state == 4) begin
    char_path <= char_path_n;
    curr_path <= next_path;
    curr_state <= next_state;
    track_length <= next_track_length;
    curr_index <= next_index;
    pos <= next_pos;
    wait_cycle <= next_wait_cycle;
    sent <= next_sent;
    num_lefts <= next_num_lefts;
    left <= next_left;
    setup <= setup_n;
    left_check <= left_check_n;
    check_right <= check_right_n;
    prev_index <= prev_index_n;
    saved_least1 <= saved_least1_n;
    saved_least2 <= saved_least2_n;
    track_check <= track_check_n;
    relapse <= relapse_n;
    backed <= backed_n;
    parent <= parent_n;
    cb_length <= cb_length_n;
    end_cnt <= end_cnt_n;
    end_track <= end_track_n;
    end_check <= end_check_n;
    cb_enable <= cb_enable_n;
    end_cond <= end_cond_n;
    char_index <= char_index_n;
  end
end

always_comb begin
  least2 = h_element[54:46];
  least1 = h_element[63:55];
  char_found = 1'b0;
  char_path_n = char_path;
  char_index_n = char_index;
  finished = 0;
  pulse = 0;
  end_cond_n = end_cond;
  setup_n = setup;
  next_state = state_cb'(curr_state);
  next_path = curr_path;
  next_index = curr_index;
  next_track_length = track_length;
  next_pos = pos;
  next_wait_cycle = wait_cycle;
  next_sent = sent;
  next_num_lefts = num_lefts;
  next_left = left;
  check_right_n = check_right;
  cb_r_wr = 0;
  left_check_n = left_check;
  prev_index_n = prev_index;
  saved_least1_n = saved_least1;
  saved_least2_n = saved_least2;
  track_check_n = track_check;
  relapse_n = relapse;
  backed_n = backed;
  parent_n = parent;
  cb_length_n = cb_length;
  end_cnt_n = end_cnt;
  end_track_n = end_track;
  end_check_n = end_check;
  cb_enable_n = cb_enable;

  case (curr_state)
    INIT: begin 
      if (setup) begin
        next_state = SEND;
        next_index = max_index;
      end
      else if (wait_cycle == 0 && !SRAM_enable) begin // wait one cycle for inputs (like getting htree element from curr_index) to stabilize between states
        next_state = LEFT;
        next_pos = 1;
      end
      else begin
        next_state = INIT; 
        next_wait_cycle = 0;
      end
    end
    LEFT: begin // move left (add 0 to path)
      if (wait_cycle == 0 && !SRAM_enable) begin
        next_track_length = track_length + 1; // update total path length
        // next_state = state_cb'((least1[8] == 1'b0) ? SEND : LEFT);
        if (least1[8] == 1'b0 || least1 == 9'b110000000) begin // if LSE is a char (or there is no element)
          if (least1 != 9'b110000000 && (read_complete || write_complete)) begin // if there is a char (not no element)
            char_index_n = least1[7:0]; // set output character (index) to LSE, NOT to tracking index
            char_found = 1'b1;
            next_state = SEND;
            next_wait_cycle = 1;
            next_left = 1;
            if(check_right) begin
              next_path = {curr_path[126:0], 1'b0}; // left shift and add 0 (left) to next path
              next_num_lefts = num_lefts + 1; // store {1'b1, number of lefts} after the left char to aid in decompression
              char_path_n = next_path;
              check_right_n = 0;
              cb_length_n = cb_length + 1;
            end
          end
          else if (least1 == 9'b110000000 && least2 == 9'b110000000 && (read_complete || write_complete)) begin  // case for only one element in htree (if character is a null character)
            next_state = FINISH;
          end
          // next_path = {curr_path[126:0], 1'b0}; // left shift and add 0 (left) to next path
          // next_num_lefts = num_lefts + 1; // store {1'b1, number of lefts} after the left char to aid in decompression
          // char_path_n = next_path;
        end

        else if (least1[8] == 1'b1 && (read_complete || write_complete)) begin // if LSE is a sum
          pulse = 1;
          next_path = {curr_path[126:0], 1'b0}; // left shift and add 0 (left) to next path
          next_num_lefts = num_lefts + 1; // store {1'b1, number of lefts} after the left char to aid in decompression
          char_path_n = next_path;
          next_index = least1[6:0] * 2; // set next index to get from htree to the sum
          next_wait_cycle = 1;
          cb_length_n = cb_length + 1;
        end
      end
      else begin
        next_wait_cycle = 0;
      end
    end
    SEND: begin // state after a character was found and waiting for char bits to be written through SPI
      if (end_check) begin
        end_cnt_n = end_cnt - 1;
        if(cb_enable) begin
          if(curr_path[end_cnt] == 1) begin
            end_track_n = end_track + 1;
            if(end_cnt == 0) begin
              cb_enable_n = 0;
              end_check_n = 0;
              end_cond_n = 1;
            end
            if(end_track == cb_length - 1) begin
              end_cond_n = 1;
              cb_enable_n = 0;
              end_check_n = 0;
            end
          end
          else begin
            end_check_n = 0;
            cb_enable_n = 0;
          end
        end
        else if (curr_path[end_cnt] == 1) begin
          cb_enable_n = 1;
        end
      end
      else begin
        pulse = 1;
        next_state = SEND_WAIT;
      end
    end
    SEND_WAIT: begin 
      if (end_cond && write_complete) begin
        next_state = FINISH;
      end
      else if (write_complete) begin
        next_state = BACKTRACK;
        next_wait_cycle = 1;
        next_num_lefts = 0;
        next_left = 0;
      end
      else if(!read_complete && !setup) begin
        cb_r_wr = 1;
      end
      else if((setup && read_complete)) begin
        setup_n = 0;
        next_state = INIT;
      end
      else begin
        next_sent = 1;
        next_state = state_cb'(curr_state);
      end
    end
    TRACK: begin // after backtrack state when a character was found, use that backtracked path to start from the top of the tree and then retrieve the htree element
      if (wait_cycle == 0 && !SRAM_enable) begin
        if(!track_check) begin
          next_state = state_cb'((track_length >= pos) ? TRACK : RIGHT);
          next_wait_cycle = 1;
          if (track_length >= pos) begin // if the h_tree element of the previous node hasn't been reached
            if (curr_path[track_length - pos] == 1'b0) begin// if the movement in the tree is left
              next_index = least1[6:0] * 2; // set next index to get from htree to LSE
              next_pos = pos + 1; // remove one from the tracking length
            end
            else if (curr_path[track_length - pos] == 1'b1) begin// if the movement in the tree is right
              next_index = least2[6:0] * 2; // set next index to get from htree to RSE
              next_pos = pos + 1; // remove one from the tracking length
              left_check_n = 1;
              next_state = RIGHT;
              cb_length_n = cb_length + 1;
            end
          end
          else begin
            next_pos = 1; // to account for track length index being one less than actual length
          end
        end
        else if (track_check && (read_complete || write_complete)) begin
          if(backed && read_complete) begin
            backed_n = 0;
            if(least1 == 9'b110000000 || least2 == 9'b110000000) begin
              next_state = FINISH;
            end
            if(!least2[8] || (least2[8] && least2 != parent)) begin
              track_check_n = 0;
              next_state = RIGHT;
              left_check_n = 1;
              cb_length_n = cb_length + 1;
            end
            // else begin
              next_index = prev_index;
              relapse_n = 0;
              saved_least1_n = least1;
              saved_least2_n = least2;
            // end
          end
          else if(least1 != saved_least1 && least2 != saved_least2) begin
            next_state = TRACK_GPS2;
          end
          else if (least1 == saved_least1 && least2 == saved_least2 && relapse) begin
            next_index = prev_index;
            next_state = TRACK_GPS3;
          end else begin
            next_index = max_index;
            next_state = TRACK_GPS;
          end
        end
      end
      else begin
        next_wait_cycle = 0;
      end
    end
    BACKTRACK: begin // after a char was found and bits were written through the spi (header portion) start to backtrack until you can move right again
      next_wait_cycle = 1;
      // if the top of the tree has been reached and left and right have already been traversed, next state is FINISH
      next_state = state_cb'(track_length < 7'b1 && curr_path[0] == 1'b1 ? FINISH : (curr_path[0] == 1'b1 ? BACKTRACK : TRACK)); 
      if (curr_path[0] == 1'b1 && track_length > 0) begin // if last move was right and the number moves is greater than 0 (not at top of tree)
        next_sent = 0; // once SEND is done and state is backtrack again, set sent to 0 and remove the last move to reach the top of the tree
        next_path = {1'b0, curr_path[127:1]}; // right shift path to remove last move to "backtrack"
        next_sent = 0;
        next_track_length = track_length - 1; // remove one from track length
        cb_length_n = cb_length - 1;
      end
      else if (curr_path[0] == 1'b0 && track_length > 0) begin // if not at top and didn't go right but went left
        next_index = max_index;
        next_path = {1'b0, curr_path[127:1]};
        next_track_length = track_length - 1;
        cb_length_n = 1;
      end
      else if (curr_path[0] == 1'b1 && track_length < 1) begin
        next_state = FINISH;
      end
    end
    RIGHT: begin  // move right (add 1 to path)
      next_pos = 1;
      if (wait_cycle == 0 && !SRAM_enable) begin
        next_track_length = track_length + 1; // update total path length
        next_wait_cycle = 1;
        //next_state = state_cb'((least2[8] == 1'b0) ? SEND : LEFT);
        // for(int i = 128; i > 0; i--) begin
        //   if (curr_path[i] == 1) begin
        //     end_cnt_n = end_cnt + 1;
        //   end
        //   if(end_cnt == cb_length) begin
        //     end_cond = 1;
        //   end
        // end
        if (least2[8] == 1'b0 || least2 == 9'b110000000 ) begin // if RSE is a char or there is no chracter
          if (least2 != 9'b110000000 && (read_complete || write_complete)) begin
            end_check_n = 1;
            cb_enable_n = 0;
            end_track_n = 0;
            end_cnt_n = 127;
            char_index_n = least2[7:0]; // set output character (index) to LSE, NOT to tracking index
            char_found = 1'b1;
            next_state = SEND;
            saved_least1_n = least1;
            saved_least2_n = least2;
            track_check_n = 1;
            if(left_check) begin
              next_path = {curr_path[126:0], 1'b1}; // right shift and add 0 (right) to next path
              char_path_n = next_path;
              left_check_n = 0;
              cb_length_n = cb_length + 1;
            end
          end
        end
        else if (least2[8] == 1'b1 && (read_complete || write_complete)) begin // if RSE is a sum
          pulse = 1;
          next_path = {curr_path[126:0], 1'b1}; // right shift and add 0 (right) to next path
          parent_n = least2;
          next_index = least2[6:0] * 2; // set next index to get from htree to the sum
          char_path_n = next_path;
          next_num_lefts = 0; // reset lefts counted to only count lefts after going right
          next_state = LEFT;
          check_right_n = 1;
          cb_length_n = cb_length + 1;
        end
      end
      else begin
        next_wait_cycle = 0;
      end
    end
    TRACK_GPS: begin
      pulse = 1;
      next_state = TRACK;
    end
    TRACK_GPS2: begin
      pulse = 1;
      relapse_n = 1;
      prev_index_n = curr_index;
      if(least1[8]) begin
        next_index = least1[6:0] * 2; // set next index to get from htree to the sum
      end
      else if (!least1[8]) begin
        next_index = least2[6:0] * 2;
      end
      next_state = TRACK;
    end
    TRACK_GPS3: begin
      pulse = 1;
      next_state = TRACK;
      backed_n = 1;
    end
    FINISH: begin
      finished = 1; // FIN state sent to (CONTROLLER)
    end
    default: begin
      next_state = state_cb'(curr_state);
    end
  endcase
end
endmodule