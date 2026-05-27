# Godotty Todo — v4.x: Advanced Features

> Back to index: [`docs/ROADMAP.md`](ROADMAP.md)

The 4.x series adds the advanced terminal features that WezTerm and Kitty
users rely on: clickable hyperlinks, shell integration for CWD tracking and
semantic command zones, mouse event pass-through for TUI apps, proper
wide-character support, and inline image rendering.

**Prerequisite:** all of Phase 3.x stable. These features require the
full grid renderer (Phase 1.0), resize (Phase 1.2), and shell integration
depends on OSC parsing maturity built up across 1.x–2.x.

**Note:** Phases 4.0 and 4.1 are largely independent and can be parallelized.
Phases 4.2–4.4 are independent of each other.

---

## Phase 4.0.0 — Hyperlinks (OSC 8)

**Goal:** parse OSC 8 hyperlink sequences, render URLs as clickable BBCode
links, and open them in the system browser.

**Prerequisite:** Phase 1.0 (grid with `url` cell attribute).

- [ ] `4.0.1` Parse OSC 8 sequences in `TerminalView`.
  - Complexity: Low-Medium. Suggested model: standard coding model.
  - Owned paths: `project/scripts/terminal_view.gd`.
  - Work: extend the OSC handler in `_ansi_to_bbcode` to recognize
    `OSC 8 ; params ; URI BEL` (enable hyperlink) and `OSC 8 ;; BEL`
    (end hyperlink). Store the active URL in `_current_url: String`.
    While non-empty, set the `url` attribute on cells written to the grid.
  - Tests: OSC 8 sequence sets `_current_url`; OSC 8 ;; clears it.

- [ ] `4.0.2` Render hyperlinks as `[url]` BBCode.
  - Complexity: Low. Suggested model: standard coding model.
  - Owned paths: `project/scripts/terminal_view.gd`.
  - Work: in `TerminalGrid.to_bbcode_line`, wrap cells whose `url` is
    non-empty in `[url=<uri>]...[/url]`. Ensure the link color is
    distinguishable from normal text (underline + theme `color_hyperlink`).
  - Tests: cell with url renders BBCode url tag; plain cell does not.

- [ ] `4.0.3` Mouse hover highlights hyperlink; click opens browser.
  - Complexity: Low-Medium. Suggested model: standard coding model.
  - Owned paths: `project/scripts/terminal_view.gd`.
  - Work: `RichTextLabel` emits `meta_hover_started` / `meta_hover_ended`
    when the cursor enters/leaves a `[url]` region. Change cursor shape
    to `POINTING_HAND`. On `meta_clicked(meta)`, call
    `OS.shell_open(meta)`.
  - Tests: meta_clicked with "https://example.com" calls `OS.shell_open`.

- [ ] `4.0.4` Mock-mode test for OSC 8 rendering.
  - Complexity: Low. Suggested model: standard coding model.
  - Owned paths: `tests/unit/hyperlink_test.gd`.
  - Work: emit an OSC 8 sequence via `SignalBus.output_ready`; assert
    the rendered BBCode contains `[url=...]`; assert a second
    `OSC 8 ;;` sequence closes the link tag.
  - Tests: all cases GREEN.

**Release gate for 4.0.0:** `ls --hyperlink=auto` in a hyperlink-capable
shell outputs clickable paths; clicking a path opens it in the file manager.

---

## Phase 4.1.0 — Shell Integration (OSC 7 + OSC 133)

**Goal:** parse shell-emitted OSC 7 (working directory) and OSC 133 (semantic
zones for prompt / command / output) to show the CWD in the tab title and
enable jump-to-prompt navigation.

**Prerequisite:** Phase 3.0.0 (tabs for CWD display); Phase 4.0.0 (OSC
parsing pattern established).

- [ ] `4.1.1` Parse OSC 7 (working directory notification).
  - Complexity: Low. Suggested model: standard coding model.
  - Owned paths: `project/scripts/terminal_view.gd`,
    `project/autoload/signal_bus.gd` (add `cwd_changed(path: String)`).
  - Work: OSC 7 carries `file://hostname/path`. Extract the path component.
    Emit `SignalBus.cwd_changed(path)`. Wire shell integration snippet
    (bash/zsh/fish) in `docs/shell-integration.md` so users know how
    to emit the sequence from their shell.
    **Hard-stop if adding a signal to SignalBus changes public API** —
    consult AGENTS.md §9.
  - Tests: OSC 7 sequence emits correct path via signal.

- [ ] `4.1.2` Display CWD in tab title and status bar.
  - Complexity: Low. Suggested model: standard coding model.
  - Owned paths: `project/scripts/terminal_view.gd`,
    `project/scenes/terminal.tscn`.
  - Work: subscribe to `SignalBus.cwd_changed`; truncate to last 2 path
    components; update the active tab label and a right-aligned status
    bar `Label` at the bottom of `TerminalView`.
  - Tests: emit `cwd_changed("/home/user/projects")`; status bar shows
    "~/projects".

- [ ] `4.1.3` Parse OSC 133 semantic zones.
  - Complexity: Medium. Suggested model: flagship model.
  - Owned paths: `project/scripts/terminal_view.gd`,
    `project/scripts/terminal_grid.gd`.
  - Work: OSC 133 codes: `A` (prompt start), `B` (command start / prompt
    end), `C` (command end / output start), `D;exit_code` (output end).
    Track zone type per grid row. Visually differentiate zones: faint
    left-border line on prompt rows, subtle bg tint on output rows.
  - Tests: A/B/C/D sequences set correct zone metadata on grid rows.

- [ ] `4.1.4` Jump-to-prompt navigation.
  - Complexity: Low. Suggested model: standard coding model.
  - Owned paths: `project/scripts/terminal_view.gd`.
  - Work: Ctrl+Shift+Up scrolls to the previous prompt row (zone type A);
    Ctrl+Shift+Down scrolls to the next one. Integrated with `TerminalKeymap`.
  - Tests: 3 prompt zones in scrollback; Ctrl+Shift+Up from bottom
    navigates to third, then second, then first.

- [ ] `4.1.5` Command duration in right-status.
  - Complexity: Low. Suggested model: standard coding model.
  - Owned paths: `project/scripts/terminal_view.gd`.
  - Work: record timestamps on `C` (command end) and `D` (output end)
    zones. Display `3.2s` in the status bar for the most recent completed
    command. Reset on next prompt.
  - Tests: C zone recorded at T; D zone at T+3.2; status shows "3.2s".

**Release gate for 4.1.0:** with the shell integration snippet active in
bash/zsh, the tab title updates on `cd`; jump-to-prompt works; command
duration visible after each command.

---

## Phase 4.2.0 — Mouse Reporting (TUI App Support)

**Goal:** pass mouse events from Godot into the terminal as escape sequences,
enabling full mouse support in ncurses apps, `vim`, `ranger`, etc.

**Prerequisite:** Phase 1.2.0 (resize/grid, accurate pixel-to-cell math).

- [ ] `4.2.1` Track mouse reporting mode state.
  - Complexity: Low. Suggested model: standard coding model.
  - Owned paths: `project/scripts/terminal_view.gd`.
  - Work: handle DEC private mode sequences:
    `CSI ?9h` (X10 mouse, button-press only),
    `CSI ?1000h` (normal — press + release),
    `CSI ?1002h` (button event — motion while pressed),
    `CSI ?1003h` (any event — all motion).
    Corresponding `l` sequences to disable.
    Track `_mouse_reporting_mode: int` (0 = off, 9, 1000, 1002, 1003).
    Also track `CSI ?1006h` (SGR extended mouse encoding).
  - Tests: each enable sequence sets correct mode; disable clears it.

- [ ] `4.2.2` Translate `InputEventMouse` to terminal sequences.
  - Complexity: Medium. Suggested model: flagship model.
  - Owned paths: `project/scripts/terminal_view.gd`.
  - Work: in `_input`, when `_mouse_reporting_mode > 0`, intercept
    `InputEventMouseButton` and `InputEventMouseMotion`. Compute
    cell (col, row) from pixel position. Encode as X10 or SGR escape
    sequences depending on mode. Send via `TerminalManager.write_input`.
  - Tests: left-click at cell (3, 5) in normal mode emits
    `\x1b[M\x20\x24\x26`; SGR mode emits `\x1b[<0;4;6M`.

- [ ] `4.2.3` Wheel scroll → scroll sequences.
  - Complexity: Very Low. Suggested model: standard coding model.
  - Owned paths: `project/scripts/terminal_view.gd`.
  - Work: `MOUSE_BUTTON_WHEEL_UP` → button 64 (X10) or `<64;col;rowM`
    (SGR); `WHEEL_DOWN` → button 65. Only when mouse reporting is active
    (otherwise scroll the scrollback normally).
  - Tests: wheel event in reporting mode emits correct sequence.

**Release gate for 4.2.0:** `vim` mouse clicks position the cursor;
`ranger` / `mc` panel selection works; scrolling in `less` works via
mouse wheel.

---

## Phase 4.3.0 — Unicode & Wide Characters

**Goal:** correctly handle Unicode characters with a display width > 1
(CJK ideographs, full-width forms, emoji, Nerd Font glyphs) so they
occupy the right number of cells and don't corrupt alignment.

**Prerequisite:** Phase 1.0.0 (cell grid).

- [ ] `4.3.1` Unicode character width lookup.
  - Complexity: Medium. Suggested model: flagship model.
  - Owned paths: `project/scripts/unicode_width.gd`,
    `tests/unit/unicode_width_test.gd`.
  - Work: implement `wcwidth(codepoint: int) -> int` in GDScript using the
    Unicode East Asian Width property tables. Wide = 2, narrow = 1,
    zero-width combiners / joiners = 0. Derive the table from Unicode 15
    data at build time (a static dictionary is fine at this scale).
  - Tests: `wcwidth(0x4E2D)` (CJK) → 2; `wcwidth(0x41)` (A) → 1;
    `wcwidth(0x200D)` (ZWJ) → 0.

- [ ] `4.3.2` Write wide characters as double-width cells in `TerminalGrid`.
  - Complexity: Medium. Suggested model: flagship model.
  - Owned paths: `project/scripts/terminal_grid.gd`.
  - Work: when writing a character with `wcwidth == 2`, occupy two
    consecutive columns with the same glyph (first cell stores the char;
    second stores a sentinel `WIDE_CONT`). Cursor advances by 2.
    Erase of a wide cell erases both halves.
  - Tests: write CJK char at col 3; col 4 is WIDE_CONT; cursor at col 5.

- [ ] `4.3.3` Render wide cells correctly in `TerminalView`.
  - Complexity: Low. Suggested model: standard coding model.
  - Owned paths: `project/scripts/terminal_view.gd`.
  - Work: in `to_bbcode_line`, skip WIDE_CONT sentinel cells. Ensure the
    BBCode font and Godot's `RichTextLabel` lay out the glyph correctly
    (Nerd Font glyphs at 2× cell width). Document known limitations.
  - Tests: CJK string renders with correct visual width (no column shift).

- [ ] `4.3.4` Zero-width combiner composition.
  - Complexity: Low. Suggested model: standard coding model.
  - Owned paths: `project/scripts/terminal_grid.gd`.
  - Work: when `wcwidth == 0`, append the combiner to the preceding cell's
    `char` string rather than advancing the cursor or occupying a new cell.
  - Tests: base char + combining accent → single cell; cursor doesn't advance.

**Release gate for 4.3.0:** `echo "日本語"` displays without column drift;
`python3 -c "print('🎉 ' * 5)"` displays correctly; Nerd Font icon in a
powerline prompt occupies exactly one column.

---

## Phase 4.4.0 — Image Protocol (iTerm2 + Sixel)

**Goal:** render inline images in the terminal output, enabling tools like
`imgcat`, `viu`, and terminal-native plots (gnuplot Sixel, etc.).

**Prerequisite:** Phase 1.0.0 (grid), Phase 4.0.0 (OSC parsing pattern).

**Note:** this is a long-term phase. Sixel is lower priority than iTerm2
Inline Image Protocol (more widely used by modern tools). Detailed
breakdown deferred until Phase 4.3.0 ships.

Planned scope:

- [ ] `4.4.1` iTerm2 Inline Image Protocol (OSC 1337;File=...).
  - Parse `OSC 1337;File=inline=1;width=N;height=N:<base64 data> BEL`.
  - Decode the base64 payload to a PNG/JPEG/GIF byte array.
  - Create an `ImageTexture` from the decoded bytes and render it as a
    `TextureRect` child of `TerminalView` at the current cursor position.
  - Width/height attributes in cells → pixel size via `char_width` /
    `line_height`.
  - Tests: known 1×1 PNG sequence decodes and renders a TextureRect node.

- [ ] `4.4.2` GIF animation support.
  - For GIF payloads, use Godot's `AnimatedTexture` or a frame-by-frame
    `Timer`+`TextureRect` approach to animate the image.

- [ ] `4.4.3` Sixel graphics (best-effort).
  - Parse DCS Sixel (`DCS <Pq> ; <color-spec> <sixel-data> ST`).
  - Convert sixel data to an `Image` and render as a `TextureRect`.
  - Scope limited to the most common subset used by gnuplot and `chafa`.

- [ ] `4.4.4` Image cleanup on scroll / clear.
  - Images that scroll off screen must be freed (avoid memory leak).
  - `CSI 2J` clears all in-viewport images.

**Release gate for 4.4.0:** `imgcat some_image.png` (from the iTerm2
shell integration) renders the image inline; image scrolls with the
scrollback buffer; `clear` removes it.
