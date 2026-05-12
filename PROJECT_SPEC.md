# Zgadnij Kto - Project Spec

This file captures the current intended direction for the FPGA game project.
It is a planning reference only; implementation should proceed module by module.

## Goal

- Hardware version of "Zgadnij Kto" / "Guess Who?".
- Two-player game on two Digilent Basys 3 boards with Artix-7 FPGA.
- Same bitstream on both boards.
- Player role selected with a switch, for example `SW[0]`:
  - `0`: player A,
  - `1`: player B.

## Hardware

- Input clock: 100 MHz Basys 3 clock.
- VGA output per board.
- Target logical resolution: 1024 x 768 or similar, not 800 x 600.
- PS/2 mouse per board.
- Board-to-board communication through PMOD.
- Reset is asynchronous, active low as `rst_n`, and must clear game state, eliminated masks, readiness,
  turn state, and communication state.

## Game Rules Owned By FPGA

- Select and store the local secret character.
- Display the character board.
- Locally eliminate and undo eliminated candidates.
- Control turns.
- Send guesses to the other board.
- Check incoming guesses against the local secret.
- Exchange guess/final-check results.
- Display win/lose/end states.

Questions are asked verbally by players. The FPGA does not parse questions.

## Screen Layout

- Logical screen: 1024 x 768.
- Character board: 6 columns x 3 rows = 18 characters.
- Character ID: `character_id = row * 6 + col`.
- Face area: 140 x 220 pixels, excluding frame.
- Proposed board constants:
  - `BOARD_COLS = 6`
  - `BOARD_ROWS = 3`
  - `FACE_W = 140`
  - `FACE_H = 220`
  - `FRAME_THICK = 4`
  - `BOARD_X = 16`
  - `BOARD_Y = 28`
- Right panel shows local selected character in a smaller preview.
- Bottom buttons:
  - `START`, later `KONIEC TURY`
  - `RESET GRY`

## Interaction

- Mouse adapter should provide:
  - `mouse_x`
  - `mouse_y`
  - `left_click_pulse`
  - `right_click_pulse`
- Click outputs must be one-cycle pulses, not held button levels.
- Before start:
  - LPM on a character selects provisional secret character.
  - START locks `local_secret_id` and sends READY.
  - Secret is not sent to the other board.
- During own turn:
  - PPM toggles local elimination of a character.
  - LPM sends a guess for that character.
  - KONIEC TURY sends TURN_END.
- During opponent turn:
  - Local elimination and guessing are disabled.
- RESET GRY is available in every state and sends RESET_GAME.

## Communication

Minimal packet types:

- `PKT_HELLO`
- `PKT_STATUS`
- `PKT_READY`
- `PKT_TURN_END`
- `PKT_GUESS`
- `PKT_FINAL_CHECK`
- `PKT_RESULT_CORRECT`
- `PKT_RESULT_WRONG`
- `PKT_RESET_GAME`
- `PKT_ACK`
- `PKT_ERROR`

Recommended packet fields:

- start byte, e.g. `8'hA5`
- packet type
- player ID
- payload, for example character ID
- sequence number
- checksum or parity

Do not synchronize `eliminated_mask`; it is local player note state.

## Main FSM States

- `S_RESET`
- `S_WAIT_LINK`
- `S_SELECT_SECRET`
- `S_LOCAL_READY`
- `S_GAME_START`
- `S_MY_TURN`
- `S_OPPONENT_TURN`
- `S_WAIT_GUESS_RESULT`
- `S_WRONG_GUESS_FEEDBACK`
- `S_FINAL_CHECK`
- `S_WIN`
- `S_LOSE`
- `S_GAME_OVER`
- `S_COMM_ERROR`

Wrong-guess feedback should last about 3 seconds. At 60 Hz, use about 180 `frame_tick` pulses.

## Rendering Strategy

- Do not store a full 1024 x 768 frame buffer.
- Render procedurally from current pixel position and game state.
- Draw board frame, cell frames, face interiors, elimination overlay, selection/guess highlights,
  status panel, buttons, text, and mouse cursor.
- Cursor should be the last visible layer.
- Use a font ROM for text, preferably without Polish characters:
  - `START`
  - `KONIEC TURY`
  - `RESET GRY`
  - `TWOJA POSTAC`
  - `TWOJA TURA`
  - `TURA RYWALA`
  - `WYGRALES`
  - `PRZEGRALES`
  - `CZEKAM NA RYWALA`
- Prefer procedural faces over large bitmaps.
- `face_traits_rom.sv` should provide traits for 18 characters.
- `face_renderer.sv` should draw one face from traits and local pixel coordinates.

## Planned RTL Folders

- `rtl/common` - shared small helpers, delays, reusable primitives.
- `rtl/top` - logical project top modules, current `top_vga`, future `top_guess_who`.
- `rtl/vga` - VGA timing, VGA interface, VGA/display constants.
- `rtl/mouse` - PS/2 mouse modules and cursor drawing wrapper.
- `rtl/render` - board, face, text, and final renderer pipeline.
- `rtl/ui` - hitboxes, button decoding, UI layout helpers.
- `rtl/game` - game FSM, game state, rules, turn handling.
- `rtl/comm` - PMOD link, packet TX/RX, communication controller.
- `rtl/assets` - ROM data or generated/static assets if needed.

## MVP Order

1. VGA board 6 x 3.
2. Mouse movement and character hitboxes.
3. Pre-start selection with blue frame.
4. START/READY and wait for opponent.
5. Turn synchronization.
6. PPM elimination toggle.
7. LPM guess and result packets.
8. Correct guess ends game.
9. Wrong guess gives 3 second red feedback, eliminates, then changes turn.
10. RESET GRY in every state.
11. Procedural face details and richer UI polish.

## Testbenches To Add

- `hitbox_decoder`
- `game_core`
- `face_traits_rom`
- `comm_controller`
- `pmod_link_tx` / `pmod_link_rx`
- simplified `board_renderer`
- top-level two-core simulation with artificial link
