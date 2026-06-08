/**
 * Copyright (C) 2025  AGH University of Science and Technology
 * MTM UEC2
 *
 * Description:
 * Visual testbench that writes one TIFF frame for every game FSM state.
 */

 module fsm_state_frames_tb;

    timeunit 1ns;
    timeprecision 1ps;

    import vga_pkg::*;
    import guess_who_pkg::*;

    localparam real CLK_PERIOD = 15.384615;
    localparam int NUM_STATES = 14;

    logic clk;
    logic rst_n;

    game_state_t game_state;
    logic [CHAR_COUNT-1:0] eliminated_mask;
    logic [CHAR_ID_W-1:0] selected_id;
    logic [CHAR_ID_W-1:0] last_guess_id;
    logic has_secret;
    logic local_ready;
    logic remote_ready;
    logic [11:0] mouse_xpos;
    logic [11:0] mouse_ypos;
    cursor_mode_t cursor_mode;
    logic capture_enabled;
    logic capture_vs;
    logic active_pixel;

    wire vs;
    wire hs;
    wire [3:0] r;
    wire [3:0] g;
    wire [3:0] b;

    vga_if if_tim ();
    vga_if if_bg ();
    vga_if if_ui ();
    vga_if if_face ();
    vga_if if_board ();
    vga_if if_text ();
    vga_if if_mouse ();

    assign vs = if_mouse.vsync;
    assign hs = if_mouse.hsync;
    assign {r, g, b} = if_mouse.rgb;
    assign capture_vs = capture_enabled && vs;
    assign active_pixel = (if_mouse.hcount < HOR_PIXELS) && (if_mouse.vcount < VER_PIXELS);

    function automatic game_state_t state_by_index(input int idx);
    begin
        case (idx)
            0: state_by_index = S_RESET;
            1: state_by_index = S_WAIT_LINK;
            2: state_by_index = S_SELECT_SECRET;
            3: state_by_index = S_LOCAL_READY;
            4: state_by_index = S_GAME_START;
            5: state_by_index = S_MY_TURN;
            6: state_by_index = S_OPPONENT_TURN;
            7: state_by_index = S_WAIT_GUESS_RESULT;
            8: state_by_index = S_WRONG_GUESS_FEEDBACK;
            9: state_by_index = S_FINAL_CHECK;
            10: state_by_index = S_WIN;
            11: state_by_index = S_LOSE;
            12: state_by_index = S_GAME_OVER;
            default: state_by_index = S_COMM_ERROR;
        endcase
    end
    endfunction

    function automatic string state_name(input game_state_t state);
    begin
        case (state)
            S_RESET: state_name = "S_RESET";
            S_WAIT_LINK: state_name = "S_WAIT_LINK";
            S_SELECT_SECRET: state_name = "S_SELECT_SECRET";
            S_LOCAL_READY: state_name = "S_LOCAL_READY";
            S_GAME_START: state_name = "S_GAME_START";
            S_MY_TURN: state_name = "S_MY_TURN";
            S_OPPONENT_TURN: state_name = "S_OPPONENT_TURN";
            S_WAIT_GUESS_RESULT: state_name = "S_WAIT_GUESS_RESULT";
            S_WRONG_GUESS_FEEDBACK: state_name = "S_WRONG_GUESS_FEEDBACK";
            S_FINAL_CHECK: state_name = "S_FINAL_CHECK";
            S_WIN: state_name = "S_WIN";
            S_LOSE: state_name = "S_LOSE";
            S_GAME_OVER: state_name = "S_GAME_OVER";
            S_COMM_ERROR: state_name = "S_COMM_ERROR";
            default: state_name = "UNKNOWN";
        endcase
    end
    endfunction

    task automatic apply_visual_state(input game_state_t state);
    begin
        game_state = state;
        selected_id = 5'd4;
        last_guess_id = 5'd7;
        has_secret = 1'b1;
        local_ready = 1'b0;
        remote_ready = 1'b0;
        eliminated_mask = '0;
        mouse_xpos = 12'd900;
        mouse_ypos = 12'd650;
        cursor_mode = CURSOR_POINTER;

        case (state)
            S_RESET, S_WAIT_LINK: begin
                has_secret = 1'b0;
            end

            S_SELECT_SECRET: begin
                selected_id = 5'd2;
                has_secret = 1'b1;
            end

            S_LOCAL_READY, S_GAME_START: begin
                selected_id = 5'd2;
                local_ready = 1'b1;
                remote_ready = (state == S_GAME_START);
            end

            S_MY_TURN: begin
                local_ready = 1'b1;
                remote_ready = 1'b1;
                eliminated_mask[1] = 1'b1;
                eliminated_mask[6] = 1'b1;
                eliminated_mask[13] = 1'b1;
            end

            S_OPPONENT_TURN: begin
                local_ready = 1'b1;
                remote_ready = 1'b1;
                eliminated_mask[1] = 1'b1;
                eliminated_mask[6] = 1'b1;
                eliminated_mask[13] = 1'b1;
                cursor_mode = CURSOR_BUSY;
            end

            S_WAIT_GUESS_RESULT: begin
                local_ready = 1'b1;
                remote_ready = 1'b1;
                last_guess_id = 5'd8;
            end

            S_WRONG_GUESS_FEEDBACK: begin
                local_ready = 1'b1;
                remote_ready = 1'b1;
                last_guess_id = 5'd8;
                eliminated_mask[8] = 1'b1;
            end

            S_FINAL_CHECK: begin
                local_ready = 1'b1;
                remote_ready = 1'b1;
                last_guess_id = 5'd15;
                eliminated_mask = '1;
                eliminated_mask[15] = 1'b0;
            end

            S_WIN, S_LOSE, S_GAME_OVER, S_COMM_ERROR: begin
                local_ready = 1'b1;
                remote_ready = 1'b1;
                eliminated_mask[1] = 1'b1;
                eliminated_mask[6] = 1'b1;
                eliminated_mask[13] = 1'b1;
                last_guess_id = 5'd8;
            end

            default: begin
            end
        endcase
    end
    endtask

    task automatic wait_until_pre_writer_start;
    begin
        @(posedge clk iff rst_n &&
            (if_tim.vcount == VER_SYNC_START - 2) &&
            (if_tim.hcount == 11'd0));
    end
    endtask

    task automatic wait_until_sync_low;
    begin
        @(posedge clk iff rst_n &&
            (if_tim.vcount == VER_SYNC_START + 1) &&
            (if_tim.hcount == 11'd0));
    end
    endtask

    initial begin
        clk = 1'b0;
        forever #(CLK_PERIOD / 2) begin
            clk = ~clk;
        end
    end

    vga_timing u_vga_timing (
        .clk,
        .rst_n,
        .vcount (if_tim.vcount),
        .vsync  (if_tim.vsync),
        .vblnk  (if_tim.vblnk),
        .hcount (if_tim.hcount),
        .hsync  (if_tim.hsync),
        .hblnk  (if_tim.hblnk)
    );

    draw_bg u_draw_bg (
        .clk,
        .rst_n,
        .sw0 (1'b0),
        .in  (if_tim.in),
        .out (if_bg.out)
    );

    ui_renderer u_ui_renderer (
        .clk,
        .rst_n,
        .game_state (game_state),
        .in         (if_bg.in),
        .out        (if_ui.out)
    );

    face_renderer u_face_renderer (
        .clk,
        .rst_n,
        .selected_id (selected_id),
        .has_secret  (has_secret),
        .in          (if_ui.in),
        .out         (if_face.out)
    );

    board_renderer u_board_renderer (
        .clk,
        .rst_n,
        .game_state      (game_state),
        .eliminated_mask (eliminated_mask),
        .selected_id     (selected_id),
        .last_guess_id   (last_guess_id),
        .has_secret      (has_secret),
        .in              (if_face.in),
        .out             (if_board.out)
    );

    text_renderer u_text_renderer (
        .clk,
        .rst_n,
        .game_state      (game_state),
        .local_ready     (local_ready),
        .remote_ready    (remote_ready),
        .eliminated_mask (eliminated_mask),
        .in              (if_board.in),
        .out             (if_text.out)
    );

    draw_mouse u_draw_mouse (
        .clk,
        .rst_n,
        .xpos        (mouse_xpos),
        .ypos        (mouse_ypos),
        .cursor_mode (cursor_mode),
        .in          (if_text.in),
        .out         (if_mouse.out)
    );

    tiff_writer #(
        .XDIM(HOR_PIXELS),
        .YDIM(VER_PIXELS),
        .FILE_DIR("../../results"),
        .FILE_PREFIX("fsm_state_"),
        .MAX_FRAMES(NUM_STATES)
    ) u_tiff_writer (
        .clk(clk),
        .r({r, r}),
        .g({g, g}),
        .b({b, b}),
        .pixel_valid(active_pixel),
        .go(capture_vs)
    );

    initial begin
        integer idx_fd;
        game_state_t next_state;

        rst_n = 1'b0;
        capture_enabled = 1'b0;
        apply_visual_state(S_RESET);

        idx_fd = $fopen("../../results/fsm_state_frames.txt", "w");
        assert (idx_fd != 0) else $fatal(1, "Could not open ../../results/fsm_state_frames.txt");
        $fwrite(idx_fd, "FSM visual state frames\n");
        $fwrite(idx_fd, "Generated by sim/fsm_state_frames/fsm_state_frames_tb.sv\n\n");
        $fwrite(idx_fd, "fsm_state_%03d.tif : %s\n", 0, state_name(S_RESET));

        repeat (5) begin
            @(posedge clk);
        end
        rst_n = 1'b1;

        wait_until_sync_low();
        capture_enabled = 1'b1;
        @(posedge vs);
        $display("Capturing fsm_state_%03d.tif for %s", 0, state_name(S_RESET));

        for (int idx = 1; idx < NUM_STATES; idx++) begin
            next_state = state_by_index(idx);
            wait_until_pre_writer_start();
            apply_visual_state(next_state);
            $fwrite(idx_fd, "fsm_state_%03d.tif : %s\n", idx, state_name(next_state));
            @(posedge vs);
            $display("Capturing fsm_state_%03d.tif for %s", idx, state_name(next_state));
        end

        @(posedge vs);
        $fclose(idx_fd);
        $display("Generated %0d FSM visual frames in ../../results", NUM_STATES);
        $display("Frame index: ../../results/fsm_state_frames.txt");
        $finish;
    end

    initial begin
        #(NUM_STATES * 25_000_000);
        $fatal(1, "Timeout while generating FSM visual frames");
    end

endmodule
