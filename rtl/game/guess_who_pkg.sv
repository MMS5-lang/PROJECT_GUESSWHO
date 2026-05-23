/**
 * Copyright (C) 2025  AGH University of Science and Technology
 * MTM UEC2
 * Author: Miłosz M. Karolina M.
 *
 * Description:
 * Shared constants and types for the Guess Who game logic.
 */

package guess_who_pkg;

localparam int CHAR_COUNT = 18;
localparam int CHAR_ID_W = 5;

typedef enum logic [3:0] {
    S_RESET                = 4'd0,
    S_WAIT_LINK            = 4'd1,
    S_SELECT_SECRET        = 4'd2,
    S_LOCAL_READY          = 4'd3,
    S_GAME_START           = 4'd4,
    S_MY_TURN              = 4'd5,
    S_OPPONENT_TURN        = 4'd6,
    S_WAIT_GUESS_RESULT    = 4'd7,
    S_WRONG_GUESS_FEEDBACK = 4'd8,
    S_FINAL_CHECK          = 4'd9,
    S_WIN                  = 4'd10,
    S_LOSE                 = 4'd11,
    S_GAME_OVER            = 4'd12,
    S_COMM_ERROR           = 4'd13
} game_state_t;

typedef enum logic [3:0] {
    PKT_READY          = 4'd0,
    PKT_TURN_END       = 4'd1,
    PKT_GUESS          = 4'd2,
    PKT_FINAL_CHECK    = 4'd3,
    PKT_RESULT_CORRECT = 4'd4,
    PKT_RESULT_WRONG   = 4'd5,
    PKT_RESET_GAME     = 4'd6
} packet_type_t;

endpackage
