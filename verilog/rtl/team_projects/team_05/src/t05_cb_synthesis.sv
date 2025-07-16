// typedef enum logic [2:0] {
//     LEFT=0,
//     RIGHT,
//     TRACK,
//     BACKTRACK,
//     FINISH,
//     INIT
// } state_cb;

module t05_cb_synthesis (
    input logic clk,
    input logic rst,
    input logic [6:0] max_index,
    input logic [70:0] h_element,
    //input logic [2:0] curr_process,
    output logic char_found,
    output logic [127:0] char_path,
    output logic [7:0] char_index,
    output state_cb curr_state,
    output logic [6:0] curr_index,
    output logic [127:0] curr_path,
    output logic [8:0] least1,
    output logic [8:0] least2,
    output logic finished
);
//logic [127:0] curr_path; // store current path
logic [6:0] track_length; // current path length (for tracking state)
logic [6:0] pos; // current position in path (for tracking state)

// next state logic
logic [127:0] next_path; // store current path
logic [6:0] next_index; // htree element index
state_cb next_state; // current codebook state
logic [6:0] next_track_length; // current path length (for tracking state)
logic [6:0] next_pos; // current position in path (for tracking state)
logic wait_cycle = 0;


always_ff @(posedge clk, posedge rst) begin
    if (rst) begin
        curr_state <= INIT; // initial state
        curr_path <= 128'b1; // control bit
        curr_index <= max_index; // top of tree
        track_length <= 7'b0; // set current path length to 0
        pos <= 7'b1; // set current tracking postion to 0
    end
    else begin
        curr_path <= next_path;
        curr_index <= next_index;
        curr_state <= next_state;
        pos <= next_pos;
        track_length <= next_track_length;
    end
end

always_comb begin
    //if (curr_process == CODEBOOK) begin
        least2 = h_element[54:46];
        least1 = h_element[63:55];
        char_found = 1'b0;
        char_path = 128'b0;
        char_index = 8'b0;
        finished = 1'b0;
        next_state = curr_state;
        next_path = curr_path;
        next_index = curr_index;
        next_track_length = track_length;
        next_pos = pos;

        case (curr_state)
            INIT: begin next_state = LEFT; end
            LEFT: begin
                if (!wait_cycle) begin
                    next_track_length = track_length + 1; // update total path length
                    next_state = state_cb'((least1[8] == 1'b0) ? BACKTRACK : LEFT);
                    wait_cycle = 1;
                    if (least1[8] == 1'b0) begin // if LSE is a char 
                        char_index = least1[7:0]; // set output character (index) to LSE, NOT to tracking index
                        next_path = {curr_path[126:0], 1'b0}; // left shift and add 0 (left) to next path
                        char_path = next_path;
                        char_found = 1'b1;
                    end

                    else if (least1[8] == 1'b1) begin // if LSE is a sum
                        next_path = {curr_path[126:0], 1'b0}; // left shift and add 0 (left) to next path
                        next_index = least1[6:0]; // set next index to get from htree to the sum
                    end
                end
                else begin
                    wait_cycle = 0;
                end
            end
            TRACK: begin
                if (!wait_cycle) begin
                    next_state = state_cb'((track_length - pos > 7'b0) ? TRACK : BACKTRACK);
                    if (track_length - pos > 7'b0) begin // if the h_tree element of the previous node hasn't been reached

                        if (curr_path[track_length - pos] == 1'b0) begin// if the movement in the tree is left
                            next_index = least1[6:0]; // set next index to get from htree to LSE
                            wait_cycle = 1;
                            next_pos = pos + 1; // remove one from the tracking length
                        end
                        else if (curr_path[track_length - pos] == 1'b1) begin// if the movement in the tree is right
                            next_index = least2[6:0]; // set next index to get from htree to RSE
                            wait_cycle = 1;
                            next_pos = pos + 1; // remove one from the tracking length
                        end
                    end
                    else begin
                            next_pos = 7'b1; // to account for track length index being one less than actual length
                            next_state = BACKTRACK;
                            wait_cycle  = 1;
                    end
                end
                else begin
                    wait_cycle = 0;
                end
            end
            BACKTRACK: begin
                    // if the top of the tree has been reached and left and right have already been traversed, next state is FINISH
                    next_state = state_cb'(state_cb'(curr_path[0] == 1'b1) ? (state_cb'(track_length) > 7'b1 ? TRACK : FINISH) : RIGHT);
                    if (curr_path[0] == 1'b1) begin // not at top but went right and left, backtrack again
                        next_path = {1'b0, curr_path[127:1]}; // right shift path to remove last move to "backtrack"
                        next_track_length = track_length - 1;
                        next_index = max_index;
                        wait_cycle = 1;
                        //next_state = TRACK;
                    end
                    else begin // if not at top and didn't go right but went left
                        wait_cycle = 1;
                        next_path = {1'b0, curr_path[127:1]};
                        next_track_length = track_length - 1;
                    end
            end
            RIGHT: begin
                    next_track_length = track_length + 1; // update total path length
                    next_state = state_cb'((least2[8] == 1'b0) ? TRACK : LEFT);

                    if (least2[8] == 1'b0) begin // if RSE is a char 
                        char_index = least2[7:0]; // set output character (index) to LSE, NOT to tracking index
                        next_path = {curr_path[126:0], 1'b1}; // left shift and add 1 (left) to output character path
                        char_path = next_path;
                        char_found = 1'b1;
                        next_index = max_index; // track from the top of the tree
                    end

                    else if (least2[8] == 1'b1) begin // if RSE is a sum
                        next_path = {curr_path[126:0], 1'b1}; // left shift and add 0 (left) to next path
                        next_index = least2[6:0]; // set next index to get from htree to the sum
                    end
            end
            FINISH: begin
                finished = 1'b1;
            end
            default: begin
                next_state = curr_state;
            end

        endcase



end
endmodule;