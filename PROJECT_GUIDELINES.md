# Project Guidelines

These notes summarize the project requirements and coding rules read from the provided files on 2026-05-12.

## Source Documents

- `projekt_wymagania_2025 (1).pdf` - 3 numbered pages plus extracted trailing page separator.
- `mtm-digital-guidelines (2).pdf` - 51 numbered pages plus extracted trailing blank separator.
- `raport_template_2025 (1).docx` - 4 pages from DOCX metadata.
- `raport_template_microblaze_2025 (1).docx` - 3 pages from DOCX metadata.
- `lista_kontrolna_2025 (1).docx` - 1 page from DOCX metadata.

## Important Override

- Use asynchronous, active-low reset named `rst_n`.
- This overrides the contradictory requirement/checklist text that mentions synchronous reset.
- Sequential synthesizable logic should use the project pattern:

```systemverilog
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        /* reset registers */
    end else begin
        /* registered updates */
    end
end
```

## Project Requirements

- Main implementation language: SystemVerilog.
- Use the provided/established design patterns unless there is a documented reason not to.
- The project should use a user interface device such as mouse, keyboard, or another external input.
- VGA output should be 1024 x 768 or similar; 800 x 600 is explicitly not acceptable.
- Target project requirement mentions two Basys 3 boards with communication between them for multiplayer-style projects, unless the instructor accepts a different scope.
- Keep generated Vivado products out of the repository. Source files must be enough to run simulations and regenerate the bitstream.
- Keep the final bitstream in `results/`.
- Add project documentation under `doc/`, including checklist PDF and report PDF for submission.
- Use git throughout the project, not only for the final upload. Use branches where appropriate.
- Every module should have a header identifying the author.
- External modules may be used only when coded correctly and clearly attributed with a source link in the file header.

## Repository Layout

Expected high-level layout:

```text
project_name/
    doc/
    fpga/
        constraints/
        rtl/
        scripts/
    results/
    rtl/
    sim/
        common/
        top_fpga/
        top_rtl/
    tools/
    README.md
    .gitignore
```

Group modules inside `rtl/` subdirectories when the design grows.

## Coding Style

- Maximum line length: 120 characters.
- Indentation: 4 spaces.
- Do not indent first-level declarations/statements directly inside a module/interface/package.
- Leave a final newline at the end of each file.
- No trailing spaces.
- One module, interface, or class per file; filename should match the module/interface/class name.
- One statement per line.
- Use spaces between keywords and parentheses, e.g. `if (condition)`.
- Do not put spaces inside parentheses, e.g. `if (a == b)`.
- Use spaces around operators and after commas/semicolons in expressions.
- Use `begin`/`end` even for single statements.
- If any `if`/`else` branch needs `begin`/`end`, use `begin`/`end` for all branches.
- Put `else` on the same line as the preceding `end`.
- In combinational `case`, use `default` unless the block has complete default assignments before the `case`.
- Avoid block labels unless they materially improve clarity.

Recommended module section order:

1. Package imports.
2. Module parameters.
3. Module ports.
4. Local parameters.
5. Type definitions.
6. Local signals.
7. Continuous assignments.
8. Submodule instances.
9. Sequential and combinational blocks.

## Sequential And Combinational Logic

- Use `always_ff`, `always_comb`, and `always_latch`; generic `always` is only for simulation.
- Use nonblocking assignments `<=` in sequential logic.
- Use blocking assignments `=` in combinational logic.
- Clock signal should be named `clk` and use the rising edge.
- Reset signal should be named `rst_n`, active low, asynchronous.
- All registers should be initialized through reset.
- Do not use `initial` in synthesizable modules.

## Naming

- Use `snake_case`.
- Use lowercase names except constants/parameters, which should be uppercase.
- Use `_nxt` suffix for combinational next-state/next-value signals assigned later into registers.
- Use `_n` suffix for active-low signals.
- Use `_t` suffix for structs and enum types.
- Numeric literals should have explicit widths, e.g. `12'h0`.
- Use separators in long numbers, e.g. `32'd100_000_000`.

## Modules And Interfaces

- Put one port per line.
- Preferred port order: clock, reset, outputs, inputs.
- Parameter names should be uppercase.
- Use named port connections in instances.
- The tested module in a testbench should be named `dut`.
- Put shared parameters in packages when multiple modules use them.
- Prefer imports placed between the module name and port list for new code when practical.
- Use comments only for non-obvious logic. Prefer block comments `/* ... */` or `/** ... */`.

## FSM Pattern

- Define FSM states with a dedicated enum type.
- Keep sequential state/register updates separate from combinational next-state and output logic.
- Use default assignments in combinational blocks to avoid latches.

## Architecture And Report Expectations

- Keep modules either structural or functional when possible. Avoid mixing structural wiring and procedural behavior in the same module unless it is clearer.
- Document only the main module architecture and clock distribution in the report.
- A report block diagram is not a Vivado schematic. It should show modules and interfaces, not every signal.
- Split bidirectional interfaces into two one-way interfaces in documentation.
- Interface names should prefix their member signal names.
- Do not include global `clk` and `rst` in documented interfaces.
- Report should include git repository URL, introduction, specification, event table, architecture, implementation notes, ignored Vivado warnings with justification, resource utilization, timing margins, hardware configuration, and demo film link.
- Checklist should confirm: report PDF, checklist PDF, bitstream in `results/`, correct folder layout, clean clone build/simulation/bitstream test, Vivado version, zero errors, zero critical warnings, ordinary warning count, input interface, VGA output, resolution, reset button, and clock-generator usage.
