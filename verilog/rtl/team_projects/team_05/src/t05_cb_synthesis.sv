// typedef enum logic [2:0] {
//     LEFT=0,
//     RIGHT,
//     TRACK,
//     BACKTRACK,
//     FINISH,
//     INIT,
//     SEND
// } state_cb;

module t05_cb_synthesis (
    input logic clk,
    input logic rst,
    input logic [6:0] max_index, // max index sent from HTREE
    input logic [70:0] h_element, // HTREE element sent from SRAM
    input logic write_finish, // write finish sent from WRITE FINISH
    //input logic [2:0] curr_process, // curr process (EN STATE FROM CONTROLLER)
    output logic char_found, // char found (enable sent to header synthesis)
    output logic [127:0] char_path, // path of a character (sent to SRAM for TRANSLATION MODULE)
    output logic [7:0] char_index, // index of character found (sent to SRAM for TRANSLATION MODULE) 
    output state_cb curr_state, // INTERNAL state of CB SYNTHESIS
    output logic [6:0] curr_index, // HTREE INDEX, sent to SRAM to fetch
    output logic [127:0] curr_path, // INTERNAL path when traversing the tree
    output logic [8:0] least1, // least1 (parsed from h_element)
    output logic [8:0] least2, // least2 (parse from h_element)
    output logic [3:0] finished, // FIN state sent to CONTROLLER
    output logic [6:0] track_length, // keeps track of internal path length 
    output logic [6:0] pos // keeps track of position in the internal path during the track state
);


// next state logic
logic [127:0] next_path; // store current path
logic [6:0] next_index; // htree element index
state_cb next_state; // current codebook state
logic [6:0] next_track_length; // current path length (for tracking state)
logic wait_cycle = 1;


always_ff @(posedge clk, posedge rst) begin
    if (rst) begin
        curr_state <= INIT; // initial state
        curr_path <= 128'b1; // control bit
        curr_index <= max_index; // top of tree
        track_length <= 7'b0; // set current path length to 0
    end
    else begin
        curr_path <= next_path;
        curr_state <= next_state;
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

        case (curr_state)
            INIT: begin 
                if (!wait_cycle) begin // wait one cycle to wait for htree element to come in from max index and inputs to stabilize
                    next_state = LEFT;
                end
                else begin
                    next_state = INIT; 
                    pos = 1;
                    wait_cycle = 0;
                end
            end
            LEFT: begin // move left (add 0 to path)
                next_track_length = track_length + 1; // update total path length
                next_state = state_cb'((least1[8] == 1'b0) ? SEND : LEFT);
                if (least1[8] == 1'b0 || least1 == 9'b110000000) begin // if LSE is a char (or there is no element)
                    if (least1 != 9'b110000000) begin
                        char_index = least1[7:0]; // set output character (index) to LSE, NOT to tracking index
                        char_found = 1'b1;
                        next_state = SEND;
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
                end
            end
            SEND: begin // send char index to header synthesis and wait for writing to be done in SPI
                if (write_finish) begin
                        next_state = BACKTRACK;
                end
                else begin
                    next_state = curr_state;
                end
            end
            TRACK: begin // once backtracking after finding a character, track to the new path made by the backtrack from the top of the tree
                next_state = state_cb'((track_length >= pos) ? TRACK : RIGHT);
                if (track_length >= pos) begin // if the h_tree element of the previous node hasn't been reached

                    if (curr_path[track_length - pos] == 1'b0) begin// if the movement in the tree is left
                        next_index = least1[6:0]; // set next index to get from htree to LSE
                        pos += 1; // remove one from the tracking length
                    end
                    else if (curr_path[track_length - pos] == 1'b1) begin// if the movement in the tree is right
                        next_index = least2[6:0]; // set next index to get from htree to RSE
                        pos += 1; // remove one from the tracking length
                    end
                end
                else begin
                        pos = 1; // to account for track length index being one less than actual length
                end
            end
            BACKTRACK: begin // once a char was found and SPI writing is finished, shift out the most recent move and move to either track or finish or backtrack again
                // if the top of the tree has been reached and left and right have already been traversed, next state is FINISH
                next_state = state_cb'(state_cb'(track_length < 7'b1 && curr_path[0] == 1'b1) ? FINISH : (state_cb'(curr_path[0] == 1'b1) ? BACKTRACK : TRACK)); 
                if (curr_path[0] == 1'b1 && track_length > 0) begin // if last move was right and the number moves is greater than 0 (not at top of tree)
                    next_path = {1'b0, curr_path[127:1]}; // right shift path to remove last move to "backtrack"
                    next_track_length = track_length - 1; // remove one from track length
                end
                else if (curr_path[0] == 1'b0 && track_length > 0) begin // if not at top and didn't go right but went left
                    next_state = TRACK;
                    next_index = max_index;
                    next_path = {1'b0, curr_path[127:1]};
                    next_track_length = track_length - 1;
                end
            end
            RIGHT: begin // move right (add a 1 to the path)
                next_track_length = track_length + 1; // update total path length
                next_state = state_cb'((least2[8] == 1'b0) ? SEND : LEFT);

                if (least2[8] == 1'b0 || least2 == 9'b110000000) begin // if RSE is a char or there is no chracter
                    if (least2 != 9'b110000000) begin
                        char_index = least2[7:0]; // set output character (index) to LSE, NOT to tracking index
                        char_found = 1'b1;
                    end
                    else begin  // case for only one element in htree (if character is a null character)
                        next_state = FINISH;
                    end
                    next_path = {curr_path[126:0], 1'b1}; // left shift and add 1 (left) to output character path
                    char_path = next_path;
                    wait_cycle = 1;
                end

                else if (least2[8] == 1'b1) begin // if RSE is a sum
                    next_path = {curr_path[126:0], 1'b1}; // left shift and add 0 (left) to next path
                    next_index = least2[6:0]; // set next index to get from htree to the sum
                end
            end
            FINISH: begin // finish (FIN state to be sent to CONTROLLER)
                finished = 4'b0101;
            end
            default: begin
                next_state = curr_state;
            end
        endcase

end
endmodule;