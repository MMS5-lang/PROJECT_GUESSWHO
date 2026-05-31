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
- `sim/cursor_modes` checks normal, hover and busy cursor mode selection and
  writes three cursor preview BMP files into `results`.
- `sim/pmod_comm_controller` checks UART packets and rejects result packets whose
  payload id does not match the pending guess/final-check.
- `sim/two_board_game` checks two game FSMs connected through UART end to end.

## Strict project assessment

The project is in a solid simulation-and-bitstream state, but it is not yet a
fully proven hardware demo. The RTL structure is now much cleaner than before:
board-specific files are under `fpga`, logical game/video code is under `rtl`,
tests are grouped under `sim`, UART example code is isolated under
`rtl/comm/uart`, and generated cursor assets are separated under
`rtl/assets/cursors`. The current simulation suite is broad enough to catch many
logic regressions, and the build currently reaches a clean warning summary.

The biggest weakness is hardware proof. A design can pass all current XSim tests
and still fail in front of two real Basys 3 boards because of PMOD wiring, baud
timing tolerance, PS/2 mouse behavior, monitor compatibility, or reset timing.
Do not treat the project as finished until the two-board physical demo is tested
from power-up several times.

The second weakness is communication robustness. UART packets have checksum and
player-id filtering, but there is no ACK/retry layer, no timeout recovery, no
visible `S_COMM_ERROR` path in normal gameplay, and no user-friendly indication
that the other board disappeared. For a lab demo this may be acceptable; for a
more reliable project this is the first RTL area I would improve.

The third weakness is verification depth around real external interfaces. The
project tests the adapted mouse coordinates, click pulses, UART packet handling
and two-board logical flow, but it does not simulate realistic PS/2 traffic into
`MouseCtl`, noisy PMOD/UART wires, malformed byte streams at every packet byte,
or random resets during active communication. The tests are good for module
logic, not exhaustive hardware abuse.

The fourth weakness is UI/game feedback. The game is playable in principle, but
the screen should make every state obvious without needing someone to know the
FSM. Waiting states, link status, whose turn it is, selected secret lock-in,
wrong guess feedback and final win/lose/reset states should be visually checked
on real VGA. The cursor modes help, but they do not replace clear state text.

The fifth weakness is final packaging. `results/` is ignored by Git, which is
good for day-to-day development, but the final course package may require the
bitstream in `results`. If the repository itself must contain the final
bitstream, add a narrow `.gitignore` exception only for `results/top_basys3.bit`
instead of committing random generated frames and logs.

What I would add if there was more time:

- A hardware bring-up checklist with exact steps: program both boards, set
  different `SW[0]`, reset both boards, verify HELLO/link readiness, select
  secrets, perform one wrong guess, one correct guess and reset.
- A communication watchdog that enters `S_COMM_ERROR` after many frames without
  valid packets from the other board.
- ACK/retry or at least repeated command transmission for important packets such
  as READY, GUESS, FINAL_CHECK, RESULT and RESET_GAME.
- On-screen link/turn/status text that makes `S_WAIT_LINK`, `S_LOCAL_READY`,
  `S_MY_TURN`, `S_OPPONENT_TURN`, `S_WAIT_GUESS_RESULT`, `S_WIN` and `S_LOSE`
  impossible to confuse.
- A test that injects corrupted UART bytes directly below `pmod_comm_controller`,
  not only valid high-level packets.
- A visual regression test that compares generated cursor/renderer images
  against golden images, not only selected pixels and visible-pixel counts.
- A reset stress test that resets during UART transmit, during result wait and
  during wrong-guess feedback.
- A small note in the final report explaining why RGB444 `000` is transparent
  for cursor ROMs and why visible black cursor pixels would need a different key.
- A final clean-clone test on another directory or machine before submission,
  because local Vivado build products can hide missing source-file references.

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
