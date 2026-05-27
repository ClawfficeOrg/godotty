# Godotty Todo — v1.x: Terminal Emulation Quality

> Back to index: [`docs/ROADMAP.md`](ROADMAP.md)

The 1.x series closes the gap between Godotty's current ANSI-text renderer
and a proper VT100/xterm-compatible terminal emulator. These features are the
prerequisite for interactive TUI programs (vim, htop, tmux) working correctly
inside a Godot window.

**Prerequisite:** Phase 0.4.0 (clean lint + test baseline) merged to `master`.

**Note on the grid renderer:** phases 1.0–1.1 both benefit from — but do not
strictly require — a cell-grid backing store. A preparatory task (`1.0.1`)
adds a minimal `TerminalGrid` class that later phases extend. If the grid
proves complex, stub it with a line-buffer fallback and revisit.

---

## Phase 1.0.0 — Alternate Screen Buffer

**Goal:** support the alternate screen buffer (CSI ?1049h / ?1049l) so
full-screen TUI apps like `vim`, `htop`, `less`, and `man` can launch, run,
and exit without corrupting the scrollback history.

**Prerequisite:** Phase 0.4.0.

- [ ] `1.0.1` `TerminalGrid` backing store.
  - Complexity: Medium. Suggested model: flagship model.
  - Owned paths: `project/scripts/terminal_grid.gd`,
    `tests/unit/terminal_grid_test.gd`.
  - Work: a GDScript class (not autoload) that stores a 2-D array of cells.
    Each cell: `{ char: String, fg: Color, bg: Color, bold: bool, italic: bool,
    underline: bool, url: String }`. Methods: `resize(cols, rows)`,
    `set_cell(row, col, cell)`, `get_cell(row, col)`, `clear_region(...)`,
    `scroll_up(n)`, `to_bbcode_line(row)` (for TerminalView rendering).
    Primary buffer and alternate buffer are separate `TerminalGrid` instances.
  - Tests: cell round-trips; resize truncates/pads; scroll_up shifts rows.

- [ ] `1.0.2` Alternate screen enter/exit in `TerminalView`.
  - Complexity: Medium. Suggested model: standard coding model.
  - Owned paths: `project/scripts/terminal_view.gd`.
  - Work: detect `CSI ?1049h` (enter alternate screen) and `CSI ?1049l`
    (exit). On enter: save primary buffer state, switch `output_display`
    to render the alternate grid. On exit: restore primary buffer and
    scroll to bottom.
    Also handle `CSI ?47h` / `CSI ?47l` (simpler alternate screen without
    save/restore) and `CSI ?1047h` / `CSI ?1047l`.
  - Tests (mock): emit the CSI sequence via `SignalBus.output_ready`; assert
    that `TerminalView` switches buffers; emit exit sequence; assert primary
    content restored.

- [ ] `1.0.3` Cursor positioning in alternate screen.
  - Complexity: Low-Medium. Suggested model: standard coding model.
  - Owned paths: `project/scripts/terminal_view.gd`,
    `project/scripts/terminal_grid.gd`.
  - Work: honour `CSI H` / `CSI f` (cursor home / position) and `CSI A/B/C/D`
    (cursor move up/down/right/left) when writing into the grid. Write
    characters at the tracked cursor position rather than appending lines.
  - Tests: cursor moves to (3, 5); subsequent character lands at that cell.

- [ ] `1.0.4` Erase sequences in alternate screen.
  - Complexity: Low. Suggested model: standard coding model.
  - Owned paths: `project/scripts/terminal_view.gd`,
    `project/scripts/terminal_grid.gd`.
  - Work: `CSI 2J` (erase display), `CSI K` (erase line variants 0/1/2).
    Clear the relevant cells in the current grid to the default background.
  - Tests: fill grid; send `CSI 2J`; assert all cells blanked.

**Release gate for 1.0.0:** `vim --noplugin` launches, edits a file, and
exits cleanly, leaving the scrollback history intact. Verified manually.

---

## Phase 1.1.0 — Cursor Tracking & Styles

**Goal:** render the terminal cursor visually and respond to cursor-style
escape sequences. Users expect a visible cursor that matches their shell
theme.

**Prerequisite:** Phase 1.0.0 (`TerminalGrid` exists).

- [ ] `1.1.1` Cursor rendering in `TerminalView`.
  - Complexity: Low-Medium. Suggested model: standard coding model.
  - Owned paths: `project/scripts/terminal_view.gd`,
    `project/scenes/terminal.tscn`.
  - Work: overlay a `ColorRect` (block cursor) or `Line2D` (underline / bar)
    at the tracked cursor position. Position updates every frame when the
    grid changes. Use a `CanvasItem` child of `OutputDisplay`'s parent so
    it floats above the text layer.
  - Tests: cursor node visible at position (0,0) on startup; moves after
    `CSI 3;5H`.

- [ ] `1.1.2` Cursor style via DECSCUSR (`CSI Ps SP q`).
  - Complexity: Low. Suggested model: standard coding model.
  - Owned paths: `project/scripts/terminal_view.gd`.
  - Work: parse `CSI 0/1/2 SP q` (block, blinking block), `CSI 3/4 SP q`
    (underline, blinking underline), `CSI 5/6 SP q` (bar, blinking bar).
    Update the cursor overlay shape accordingly.
  - Tests: style sequence changes cursor overlay type.

- [ ] `1.1.3` Cursor blink.
  - Complexity: Low. Suggested model: standard coding model.
  - Owned paths: `project/scripts/terminal_view.gd`.
  - Work: `TerminalSettings.cursor_blink_rate` (seconds, default 0.5).
    Use a `Timer` to toggle cursor visibility. Blinking stops when the
    terminal does not have focus.
  - Tests: cursor visible → hidden → visible cycle at configured rate.

- [ ] `1.1.4` Cursor hide/show (`CSI ?25l` / `CSI ?25h`).
  - Complexity: Very Low. Suggested model: standard coding model.
  - Owned paths: `project/scripts/terminal_view.gd`.
  - Work: track DEC private mode 25 state; hide/show cursor overlay.
  - Tests: `CSI ?25l` makes cursor invisible; `CSI ?25h` restores it.

**Release gate for 1.1.0:** cursor visually tracks shell prompt position;
blinking cursor works; `vim` cursor-shape changes reflect correctly.

---

## Phase 1.2.0 — Resize & SIGWINCH

**Goal:** the terminal resizes when the Godot window or panel resizes, and
the shell process receives SIGWINCH so it can reflow its output.

**Prerequisite:** Phase 1.0.0 (grid exists for reflow).

- [ ] `1.2.1` Calculate columns and rows from `TerminalView` pixel size.
  - Complexity: Low. Suggested model: standard coding model.
  - Owned paths: `project/scripts/terminal_view.gd`.
  - Work: on `_on_viewport_resize` (already connected), compute
    `cols = floor(width / char_width)` and `rows = floor(height / line_height)`.
    Expose a `TerminalSettings.font_size` to derive `char_width` / `line_height`.
    Emit `SignalBus.terminal_resized(cols, rows)`.
  - Tests: resize viewport to known size; signal fires with correct cols/rows.

- [ ] `1.2.2` Propagate resize to `TerminalManager` and godotty-node.
  - Complexity: Low. Suggested model: standard coding model.
  - Owned paths: `project/autoload/terminal_manager.gd`.
  - Work: connect `SignalBus.terminal_resized` in `TerminalManager`; call
    `_real_terminal.resize(cols, rows)` (method already stubbed). In mock
    mode: update `_mock_cols` / `_mock_rows` state variables.
  - Tests (mock): emit resize signal; assert TerminalManager state updated.

- [ ] `1.2.3` Grid reflow on resize.
  - Complexity: Medium. Suggested model: flagship model.
  - Owned paths: `project/scripts/terminal_grid.gd`.
  - Work: when `resize(cols, rows)` is called, reflow existing lines that
    are longer than `cols` onto multiple rows (wrap). Rows that are shorter
    just gain blank cells. Scrollback position adjusts to keep the most
    recent line visible.
  - Tests: 80-col grid reflows to 40-col; long lines wrap; scrollback offset
    adjusted.

**Release gate for 1.2.0:** drag the Godot window corner to resize; `bash`
responds with a new `$COLUMNS` value; `htop` redraws at the new dimensions.

---

## Phase 1.3.0 — Bracketed Paste Mode

**Goal:** when the shell has enabled bracketed paste (`CSI ?2004h`), wrap
pasted text in the start/end markers. This prevents pasted newlines from
being interpreted as command submission.

**Prerequisite:** Phase 1.1.0.

- [ ] `1.3.1` Track bracketed paste mode state.
  - Complexity: Very Low. Suggested model: standard coding model.
  - Owned paths: `project/scripts/terminal_view.gd`.
  - Work: detect `CSI ?2004h` (enable) and `CSI ?2004l` (disable).
    Store `_bracketed_paste_mode: bool` on `TerminalView`.
  - Tests: state toggles correctly with each sequence.

- [ ] `1.3.2` Wrap clipboard paste in markers when mode is active.
  - Complexity: Low. Suggested model: standard coding model.
  - Owned paths: `project/scripts/terminal_view.gd`.
  - Work: in the paste handler (Ctrl+Shift+V from Phase 1.4.0, or call it
    a stub here), prefix with `\x1b[200~` and suffix with `\x1b[201~`
    when `_bracketed_paste_mode` is true. Send the full string as one
    `write_input` call.
  - Tests: paste in bracketed-paste-on state; output wrapped; paste in
    off state; output bare.

**Release gate for 1.3.0:** `bash` paste test — enable bracketed mode
manually via `bind 'set enable-bracketed-paste on'`; paste multi-line
text; no premature command execution.

---

## Phase 1.4.0 — Mouse Selection & Clipboard

**Goal:** users can click-drag to select text, copy it, and paste from
the system clipboard. This is the most-requested basic UX feature in
terminal emulators.

**Prerequisite:** Phase 1.0.0 (grid for cell-accurate selection).

- [ ] `1.4.1` Click-drag text selection in `TerminalView`.
  - Complexity: High. Suggested model: flagship model.
  - Owned paths: `project/scripts/terminal_view.gd`,
    `project/scripts/terminal_grid.gd`.
  - Work: handle `InputEventMouseButton` (left press → selection start)
    and `InputEventMouseMotion` (drag → selection end). Compute grid cell
    from pixel position using `char_width` / `line_height`. Render
    selection as a highlight `ColorRect` overlay on the selected cells.
    Store `_selection_start: Vector2i` and `_selection_end: Vector2i`.
  - Tests: mouse-down at (0,0), drag to (0,5); assert 5 cells selected.

- [ ] `1.4.2` Copy selection to clipboard.
  - Complexity: Low. Suggested model: standard coding model.
  - Owned paths: `project/scripts/terminal_view.gd`.
  - Work: on double-click (select word) or when selection is non-empty,
    Ctrl+Shift+C (and Ctrl+Insert) copies selected text from the grid to
    `DisplayServer.clipboard_set(text)`.
  - Tests: select "hello"; Ctrl+Shift+C; assert clipboard contains "hello".

- [ ] `1.4.3` Paste from clipboard.
  - Complexity: Low. Suggested model: standard coding model.
  - Owned paths: `project/scripts/terminal_view.gd`.
  - Work: Ctrl+Shift+V (and Shift+Insert) reads `DisplayServer.clipboard_get()`
    and sends it via `TerminalManager.write_input(text)`. Respects bracketed
    paste mode (Phase 1.3.0).
  - Tests: set clipboard to "hello world"; Ctrl+Shift+V; assert write_input
    called with "hello world".

- [ ] `1.4.4` Right-click context menu.
  - Complexity: Low. Suggested model: standard coding model.
  - Owned paths: `project/scripts/terminal_view.gd`,
    `project/scenes/terminal.tscn`.
  - Work: `InputEventMouseButton` with `MOUSE_BUTTON_RIGHT` opens a
    `PopupMenu` with items: **Copy** (if selection), **Paste**, **Clear**.
    Selecting each fires the equivalent action.
  - Tests: right-click emits popup; Copy disabled when no selection;
    Copy enabled when text selected.

**Release gate for 1.4.0:** select text with the mouse, copy with
Ctrl+Shift+C, paste into another app — content matches. Paste from
another app works. Right-click menu functional.
