typedef enum logic [2:0] {
    LEFT=0,
    RIGHT,
    TRACK,
    BACKTRACK,
    FINISH,
    INIT
} state_cb;

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
    output logic finished
);
logic [127:0] curr_path; // store current path
logic [6:0] track_length; // current path length (for tracking state)
logic [6:0] pos; // current position in path (for tracking state)

// next state logic
logic [127:0] next_path; // store current path
logic [6:0] next_index; // htree element index
state_cb next_state; // current codebook state
logic [6:0] next_track_length; // current path length (for tracking state)
logic [6:0] next_pos; // current position in path (for tracking state)

logic [8:0] least1;
logic [8:0] least2;


always_ff @(posedge clk, posedge rst) begin
    if (rst) begin
        curr_path <= 128'b1; // control bit
        curr_index <= max_index; // top of tree
        curr_state <= INIT; // initial state
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
        least1 = h_element[54:46];
        least2 = h_element[63:55];
        char_found = 0;
        char_path = 0;
        char_index = 0;
        finished = 0;
        next_state = curr_state;
        next_path = curr_path;
        next_index = curr_index;
        next_track_length = track_length;
        next_pos = pos;

        case (curr_state)
            INIT: begin next_state = LEFT; end
            LEFT: begin

                next_track_length = track_length + 1; // update total path length

                if (least1[8] == 0) begin // if LSE is a char 
                    char_index = least1[7:0]; // set output character (index) to LSE, NOT to tracking index
                    char_path = {curr_path[126:0], 1'b0}; // left shift and add 0 (left) to output character path
                    char_found = 1;
                    next_state = TRACK; // track to the previous node
                    next_index = max_index; // track from the top of the tree
                end

                else if (least1[8] == 1) begin // if LSE is a sum
                    next_path = {curr_path[126:0], 1'b0}; // left shift and add 0 (left) to next path
                    next_index = least1[6:0]; // set next index to get from htree to the sum
                    next_state = LEFT; // continue to go left if a character isn't reached yet
                end
            end
            TRACK: begin
                if (track_length - pos > 0) begin // if the h_tree element of the previous node hasn't been reached

                    if (curr_path[track_length - pos] == 0) begin// if the movement in the tree is left
                        next_index = least1[6:0]; // set next index to get from htree to LSE
                        next_track_length = track_length - 1; // remove one from the tracking length
                        next_state = TRACK;
                    end
                    else if (curr_path[track_length - pos] == 1) begin// if the movement in the tree is right
                        next_index = least2[6:0]; // set next index to get from htree to RSE
                        next_track_length = track_length - 1; // remove one from the tracking length
                        next_state = TRACK;
                    end
                    else begin
                        next_pos = 7'b1; // to account for track length index being one less than actual length
                        next_state = BACKTRACK;
                    end
                end
            end
            BACKTRACK: begin
                if (track_length == 1 && curr_path[0] == 1) begin // if the top of the tree has been reached and left and right have already been traversed
                    next_state = FINISH;
                end
                else if (curr_path[0] == 1) begin // not at top but went right and left, backtrack again
                    next_path = {1'b0, curr_path[127:1]}; // right shift path to remove last move to "backtrack"
                    next_track_length -= 1;
                end
                else begin // if not at top and didn't go right but went left
                    next_state = RIGHT;
                end
            end
            RIGHT: begin
                next_track_length = track_length + 1; // update total path length

                if (least2[8] == 0) begin // if RSE is a char 
                    char_index = least1[7:0]; // set output character (index) to LSE, NOT to tracking index
                    char_path = {curr_path[126:0], 1'b0}; // left shift and add 0 (left) to output character path
                    char_found = 1;
                    next_state = TRACK; // track to the previous node
                    next_index = max_index; // track from the top of the tree
                end

                else if (least2[8] == 1) begin // if RSE is a sum
                    next_path = {curr_path[126:0], 1'b0}; // left shift and add 0 (left) to next path
                    next_index = least1[6:0]; // set next index to get from htree to the sum
                    next_state = LEFT; // continue to go left if a character isn't reached yet
                end
            end
            FINISH: begin
                finished = 1;
                next_state = INIT;
            end
            default: begin
                next_state = curr_state;
            end

        endcase



end
endmodule;