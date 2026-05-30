# Guess Who - remaining work

This file summarizes what is still missing or worth checking before the final
submission/demo of the Basys 3 Guess Who project.

## Current working scope

- VGA target is 1024 x 768 through the 65 MHz clock domain.
- The game board uses 6 columns, 3 rows and 18 characters.
- Mouse clicks are converted to one-cycle left/right click pulses.
- The local game FSM supports secret selection, READY, turn ownership,
  local elimination toggle, guesses, final checks, win/lose states and game reset.
- PMOD UART packets carry HELLO, READY, TURN_END, GUESS, FINAL_CHECK,
  RESULT_CORRECT, RESULT_WRONG and RESET_GAME.
- The local secret is not sent at game start; only guess/final-check results are
  sent back.
- UART result packets now include the guessed character id as payload, and the
  receiver accepts a result only for the pending guess/final-check id.
- Reset button release is debounced, and reset deassertion is synchronized for
  the 65 MHz and 100 MHz clock domains.
- UART source files copied from the example project are grouped under
  `rtl/comm/uart`, the project UART wrapper is in `rtl/comm`, and debounce is in
  `rtl/common`.
- Cursor assets are generated under `rtl/assets/cursors`: `pointer_b` for normal
  movement, `pointer_toon_b` over hitboxes, and
  `busy_hourglass_outline_detail` while waiting in `S_OPPONENT_TURN`.

## Hardware reminders

- Use the same bitstream on both Basys 3 boards.
- Set `SW[0] = 0` on one board and `SW[0] = 1` on the other board before both
  players press `START`.
- `BTNC` is the physical reset button. Project RTL uses active-low asynchronous
  reset internally as `rst_n`; the button release is debounced and synchronized.
- Current UART link uses PMOD header JA, not JB.
- `JA2` is UART TX. Connect it to the other board's `JA3`.
- `JA3` is UART RX. Connect it to the other board's `JA2`.
- Connect PMOD ground between boards. Without common GND the UART link may look
  random even if TX/RX are crossed correctly.
- `JA1` mirrors the pixel clock for observation/test use. It is not required for
  gameplay communication.
- Header JB is currently unused. If the link is moved to JB, update
  `fpga/constraints/top_basys3.xdc`, the report, this file and the hardware
  test notes together.
- Connect each board to its own VGA display or to one display at a time during
  bring-up. The expected video mode is 1024 x 768.
- Connect a PS/2 mouse through the Basys 3 USB HID/PS2 connector on each board.
- Program both boards, wait for VGA output, check `SW[0]`, then press `BTNC` if
  one board appears to be stuck in an old state.
- Cursor ROMs use RGB444 `000` as transparency. If a future cursor needs visible
  black pixels, change the transparency key or regenerate assets with a different
  transparent color.


## Added simulation coverage

- `sim/common_primitives` checks `delay`, `debounce`, `mod_m_counter` and `fifo`.
- `sim/uart_core` checks direct UART TX/RX serialization and decoding.
- `sim/hitbox_decoder` checks all 18 character cells, START, RESET and ignored
  outside-board clicks.
- `sim/mouse_adapter` checks coordinate synchronization, screen clamping and
  one-cycle click pulses.
- `sim/render_modules` checks key pixels from background, UI, board overlays,
  text, face rendering, face traits, font ROM and mouse cursor overlay.
- `sim/pmod_comm_controller` checks UART packets and rejects result packets whose
  payload id does not match the pending guess/final-check.
- `sim/two_board_game` checks two game FSMs connected through UART end to end.

## Missing before final submission

- Test the game on two physical Basys 3 boards with crossed PMOD UART wires:
  board A `JA2` to board B `JA3`, board B `JA2` to board A `JA3`, plus common GND.
- Confirm on hardware that both `SW[0]` player IDs are different before starting.
- Create the final `doc/report.pdf`.
- Create the final `doc/checklist.pdf`.
- Add the demo video link to the report.
- Add or complete a `doc/` directory if the final course package requires all
  documentation there.
- Document copied UART/debounce source attribution in the report, including that
  the project uses an adapted UART example wrapped by `uart_byte_link.sv`.
- Keep `results/warning_summary.log` clean after future RTL changes. The current
  build is expected to report `CLEAR :)` for synthesis and implementation.
- Run a clean-clone verification in a fresh directory: simulations, bitstream,
  and final file layout.

## Missing or optional RTL improvements

- Add a communication timeout and use `S_COMM_ERROR` if the other board stops
  sending valid packets for a long time.
- Add ACK/retry handling if the physical UART link proves unreliable. The current
  protocol validates checksum and player id but does not retransmit lost packets.
- Add a visible on-screen status for waiting states, for example `CZEKAM NA RYWALA`,
  `TWOJA TURA` and `TURA RYWALA`.
- Add deeper negative UART tests for malformed raw packets, for example bad
  checksum and same-player packets injected at the byte-stream level.
- Consider using `S_GAME_OVER` explicitly after `S_WIN`/`S_LOSE` if the UI should
  separate result display from a stable end state. The current design keeps
  stable `S_WIN` and `S_LOSE` states until reset.

## Verification commands to keep using

```bash
. env.sh
run_simulation.sh -a
generate_bitstream.sh
```

After bitstream generation, check:

```bash
cat results/warning_summary.log
```

The desired final state is zero errors, zero critical warnings and only warnings
that are understood and described in the report.
