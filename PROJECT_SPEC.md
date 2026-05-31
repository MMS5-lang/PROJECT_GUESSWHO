# Guess Who on Basys 3 - consolidated project specification

This document is the single consolidated project note for the FPGA Guess Who
game. It replaces the earlier overlapping spec and guideline files, while
keeping `README.md` as the usage guide and `PROJECT_REMAINING_WORK.md` as the
final task checklist. The text below combines the game specification, hardware
assumptions, RTL architecture, coding rules, verification expectations and final
submission notes without repeating the same requirements in several files.

## Project Goal

The project implements a hardware version of Guess Who for two Digilent Basys 3
boards with Artix-7 FPGAs. Both boards run the same bitstream. Each player uses
one board, one VGA display and one PS/2 mouse. Players ask questions verbally;
the FPGA does not parse natural language. The FPGA owns the visual board, local
secret selection, local elimination notes, turn control, guesses, final checks,
game reset and the communication link between the two boards.

The player role is selected with `SW[0]`. One board must use `SW[0] = 0`, the
other must use `SW[0] = 1`. Player 0 starts after both players are ready. The
local secret character is never sent to the other board at game start; the board
that receives a guess compares the guessed ID with its own secret and sends back
only a result packet.

## Hardware Platform

The target board is Digilent Basys 3. The input clock is the 100 MHz board clock.
The design uses the clock wizard to generate the display/game clocks, including
the 65 MHz clock domain used for 1024 x 768 VGA timing. The user interface is a
PS/2 mouse connected to the Basys 3 USB HID/PS2 connector. VGA output goes to the
standard Basys 3 VGA connector. Board-to-board communication uses PMOD UART on
header JA.

Current PMOD UART wiring is:

- `JA2` is UART TX.
- `JA3` is UART RX and has pull-up enabled in the XDC.
- `JA1` mirrors the pixel clock for observation/test use and is not part of the
  gameplay link.
- Board A `JA2` must connect to board B `JA3`.
- Board B `JA2` must connect to board A `JA3`.
- The two boards must share PMOD ground.
- Header JB is not used by the current design. If communication is moved to JB,
  the XDC, documentation and hardware checklist must be updated together.

The reset button is Basys 3 `BTNC`. Internally, project RTL uses asynchronous,
active-low reset named `rst_n`. External helper blocks with active-high reset
inputs, for example the copied debounce module or the VHDL mouse controller, are
adapted at the boundary.

## Screen And Game Layout

The target display is 1024 x 768 or a very close resolution. The game board has
6 columns and 3 rows, for 18 total characters. The character ID is always:

```systemverilog
character_id = row * BOARD_COLS + col;
```

Valid character IDs are `0` through `17`. Use 5 bits for character IDs because
that fits the UART payload cleanly and leaves simple room for range checks.

The screen contains a large 6 x 3 board on the left and a right-side control
column with the local secret preview panel and the game buttons below it. The
right panel shows only the local player's selected secret. It must never show or
infer the opponent's secret. The main action button is `START` before the game
starts and `KONIEC TURY` during a local turn. `RESET GRY` is available from
every game state.

Rendering is procedural. The design does not store a full frame buffer. Renderer
modules use the current VGA pixel coordinates, game state and masks to draw the
background, UI, faces, board overlays, text and mouse cursor. The cursor is the
last visible layer. Text should avoid Polish characters on screen, so strings
such as `WYBIERZ SWOJA POSTAC`, `POCZEKAJ NA RYWALA`, `CZEKAM NA WYNIK`,
`NIEPOPRAWNA POSTAC`, `WYGRALES`, `PRZEGRALES`, `TWOJA POSTAC`, `START`,
`KONIEC TURY` and `RESET GRY` are preferred. Do not duplicate local/opponent
turn text on screen; the normal/hover cursor marks an interactive local turn,
and the hourglass cursor marks waiting for the opponent.

Cursor graphics are stored as RGB444 ROM data under `rtl/assets/cursors`.
`pointer_b` is the normal cursor outside interactive hitboxes. `pointer_toon_b`
is used while the cursor is over a board cell, the start/end-turn button or the
reset button. `busy_hourglass_outline_detail` is used during `S_OPPONENT_TURN`,
when the local player is waiting for the opponent to finish. The cursor renderer
treats RGB444 `000` pixels as transparent, so black should not be used as a
visible cursor color unless transparency handling is changed.

## User Interaction

Mouse signals are adapted into screen coordinates and one-cycle click pulses:
`mouse_x`, `mouse_y`, `left_click_pulse` and `right_click_pulse`. Do not use a
held mouse button level as a game event. The hitbox decoder maps clicks to a
character field, the start/end-turn button, the reset button or ignored space.

Before `START`, a left click on a character selects the provisional local secret.
The selected field is highlighted, and the selected face appears in the right
panel. The player may change this choice until pressing `START`. Pressing
`START` locks the secret as `local_secret_id`, sets local readiness and sends a
`READY` packet. The game starts only when both local and remote readiness are
true.

During the local turn, a right click toggles local elimination of a character.
Eliminations are private notes and are not synchronized to the opponent. A left
click sends a `GUESS(character_id)` packet. Pressing `KONIEC TURY` sends
`TURN_END` and gives the turn to the opponent. During the opponent's turn, local
elimination and guessing clicks are ignored.

If only one non-eliminated candidate remains after local eliminations, the game
may send `FINAL_CHECK(remaining_id)`. A correct guess or final check leads to
`S_WIN` on the guessing board and `S_LOSE` on the opponent board. A wrong normal
guess shows red feedback for about three seconds, eliminates that guessed
character locally and gives the turn to the opponent.

`RESET GRY` works in every state. It sends `RESET_GAME`, clears readiness,
secret selection, eliminated masks, last guess state, feedback and turn state,
then returns both boards to secret selection.

## Communication Protocol

The current communication block uses an adapted UART byte link from the provided
example project, wrapped by `uart_byte_link.sv` and controlled by
`pmod_comm_controller.sv`. The controller sends periodic `HELLO` packets and
sets `link_ready` after receiving a valid packet from the opposite player ID.

The packet format is six bytes:

```text
byte 0: start byte 8'hA5
byte 1: packet type
byte 2: player ID
byte 3: payload, usually character ID
byte 4: sequence number
byte 5: XOR checksum over bytes 0..4
```

Supported packet meanings are `HELLO`, `STATUS`, `READY`, `TURN_END`, `GUESS`,
`FINAL_CHECK`, `RESULT_CORRECT`, `RESULT_WRONG`, `RESET_GAME`, `ACK` and
`ERROR`. The minimum gameplay path uses `HELLO`, `READY`, `TURN_END`, `GUESS`,
`FINAL_CHECK`, `RESULT_CORRECT`, `RESULT_WRONG` and `RESET_GAME`. Result packets
carry the guessed/final-check character ID, and the receiver accepts a result
only if that payload matches the currently pending request.

The protocol validates the start byte, type range, player ID, opposite player
identity and checksum. It does not currently retransmit lost packets. ACK/retry
and communication timeout handling are optional improvements if the physical
UART link proves unreliable.

## Game State Machine

The game FSM lives in `game_core.sv`. The current state set includes reset,
link wait, secret selection, local ready, game start, local turn, opponent turn,
wait for guess result, wrong guess feedback, final check, win, lose, game over
and communication error states. State names are defined in `guess_who_pkg.sv`.

The most important rules are:

- Reset clears all game registers.
- The game waits for a valid communication link before normal play.
- Secret selection is local and may be changed before `START`.
- Readiness is exchanged through UART.
- Player 0 starts once both boards are ready.
- Only the local-turn state accepts elimination, guesses and end-turn clicks.
- Incoming guesses are checked against the local secret and answered immediately.
- Correct result ends the game.
- Wrong normal guess gives timed feedback and changes the turn.
- Reset packets and reset clicks are honored from every state.
- Local eliminated masks are never sent to the other board.

## RTL Architecture

The top-level FPGA wrapper is `top_basys3.sv`. It contains the clock wizard,
reset debounce/release handling, reset synchronization for clock domains, PMOD
pin wiring and the logical game top. The logical top is `top_vga.sv`, which is
mostly structural. It wires VGA timing, PS/2 mouse controller, mouse adapter,
hitbox decoder, UART/PMOD controller, game core, renderers, text renderer and
mouse cursor.

Important RTL folders are:

- `rtl/common` for reusable primitives such as delay, debounce adapter usage and
  reset synchronization.
- `rtl/game` for game constants, enums and FSM logic.
- `rtl/comm` for PMOD UART communication and packet control.
- `rtl/comm/uart` for copied/adapted UART example source files.
- `rtl/vga` for timing and display interface definitions.
- `rtl/mouse` for PS/2 and cursor logic.
- `rtl/ui` for hitbox decoding and UI layout helpers.
- `rtl/render` for board, UI and face rendering.
- `rtl/text` for font ROM and text rendering.
- `rtl/assets` for ROM data used by procedural/asset-based rendering, including
  face parts and cursor images.
- `fpga/constraints` for Basys 3 pin and timing constraints.
- `fpga/rtl` for board-specific generated or copied wrapper/IP sources.
- `sim` for module and integration testbenches.
- `tools` for shell scripts that run simulations, bitstream generation,
  programming, cleaning and warning summaries.

## Reset And Clocking Rules

The project reset convention is asynchronous, active low and named `rst_n`.
Sequential RTL should use this form:

```systemverilog
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        q <= '0;
    end else begin
        q <= q_nxt;
    end
end
```

Do not convert project RTL to synchronous reset. Do not initialize synthesizable
registers with `initial`. For FPGA-level reset release, the board wrapper may
assert reset asynchronously and release it synchronously per clock domain. This
keeps the project-level `rst_n` convention while avoiding unsafe release timing.

Use the clock wizard for generated clocks. Do not create new clocks with random
RTL dividers. Use clock enables for slow events. Synchronize signals that cross
clock domains, especially mouse/PS2 signals and reset release paths.

## Coding Style

Use SystemVerilog as the main RTL language. Existing VHDL PS/2 modules may be
used if isolated behind clear wrappers or boundary logic. Keep one module,
interface or package per file, and make the filename match the module/interface
or package name. Use `snake_case` for signals and module names. Use uppercase
for parameters and localparams. Use `_nxt` for combinational next values, `_n`
for active-low signals and `_t` for enum or struct types. Use named port
connections in instances.

Use `always_ff`, `always_comb` and `always_latch` in RTL; generic `always` is for
testbenches. Use nonblocking assignments in sequential logic and blocking
assignments in combinational logic. Give combinational logic complete default
assignments to avoid latches. Use explicit-width literals such as `12'h000` and
separators in long numbers such as `65_000_000`. Keep line length reasonable,
indent with four spaces, remove trailing spaces and leave a final newline.

The top modules should stay structural. Game rules belong in `game_core`; packet
handling belongs in `pmod_comm_controller`; drawing belongs in renderer modules.
Do not pack the entire design into one top-level file. External code must be
clearly attributed in file headers and in the final report.

## Verification

The repository contains focused testbenches and integration tests. Keep using:

```bash
. env.sh
run_simulation.sh -a
generate_bitstream.sh
cat results/warning_summary.log
```

The expected final state is zero Vivado errors, zero critical warnings and a
clean warning summary. If a warning remains, it must be understood and justified
in the report. Testbenches should check behavior, not only compile. Important
coverage includes common primitives, UART TX/RX, hitbox decoding, mouse adapter,
rendering modules, game FSM behavior, PMOD packet handling and a two-board game
simulation connected through UART.

Before final submission, test a clean clone in a fresh directory. The clean clone
should run simulations, generate the bitstream and produce the same source file
layout without relying on generated Vivado products already present in the old
workspace.

## Final Report And Course Deliverables

The final `doc` directory should contain at least `report.pdf` and
`checklist.pdf` if required by the course package. The report should include the
repository URL, project introduction, game specification, event table,
architecture, clock distribution, reset convention, hardware wiring, external
source attribution, implementation notes, resource utilization, timing margins,
warnings with justification and a demo video link.

The report block diagram should show modules and interfaces, not every single
wire. Bidirectional physical interfaces should be documented as clear transmit
and receive directions. Global `clk` and `rst_n` do not need to be drawn as full
data interfaces. The hardware section should explicitly mention Basys 3,
1024 x 768 VGA, PS/2 mouse, `SW[0]` player selection, `BTNC` reset and PMOD JA
UART wiring.

The demo should show both boards if possible: link setup, different `SW[0]`
values, secret selection, readiness, turn behavior, local elimination, a guess,
result feedback, win/lose behavior and reset.

## Practical Rules To Preserve

Keep the board size at 6 x 3. Keep `N_CHARACTERS = 18`. Keep character IDs as
`row * 6 + col`. Do not send the local secret at start. Do not synchronize
elimination masks. Treat `RESET_GAME` as valid from every state. Keep the same
bitstream usable on both boards. Keep generated Vivado products out of Git. Keep
the scripts portable through Git Bash on Windows and Bash on Linux. Keep the
hardware notes in `PROJECT_REMAINING_WORK.md` up to date whenever pins or
connectors change.
