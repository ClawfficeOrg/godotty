# Changelog

All notable changes to **godotty** are documented here.

The format is based on [Keep a Changelog 1.1.0](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning 2.0.0](https://semver.org/spec/v2.0.0.html).

Pre-1.0 versions: MINOR bumps may include breaking changes (loudly noted).

## [Unreleased]

### Added
- **Cursor rendering in TerminalView (task 1.1.1).**
  - `project/scripts/terminal_view.gd` — added `cursor_row`/`cursor_col` public
    vars to track the primary-screen cursor position; `_update_cursor_overlay()`
    syncs the overlay position whenever the cursor moves (primary or alt screen);
    CSI H/f now updates primary-screen cursor in addition to the existing
    alternate-screen `_alt_grid` path.
  - `project/scenes/terminal.tscn` — added `CursorOverlay` (ColorRect) as a
    free-positioned child of `VBoxContainer/ScrollContainer`; floats above the
    text layer (`z_index = 1`); sized 8 × 16 px (CHAR_W × CHAR_H); semi-
    transparent block style; `mouse_filter = IGNORE`.
  - `tests/unit/terminal_view_cursor_test.gd` — 3 mock-mode unit tests:
    overlay visible at startup, cursor at origin on startup, CSI 3;5H moves
    overlay to col=4 × CHAR_W, row=2 × CHAR_H. All GREEN.
- **Erase sequences in alternate screen (task 1.0.4).**
  - `project/scripts/terminal_grid.gd` — added `erase_display(mode)` (CSI J,
    modes 0/1/2: cursor-to-end, start-to-cursor, entire display) and
    `erase_line(mode)` (CSI K, modes 0/1/2: cursor-to-end-of-line,
    start-to-cursor, entire line). Both clear affected cells to the default
    background without moving the cursor.
  - `project/scripts/terminal_view.gd` — `CSI J` now routes to
    `_alt_grid.erase_display(mode)` in alternate screen; primary screen
    retains prior full-clear behaviour. `CSI K` (previously a no-op) now
    routes to `_alt_grid.erase_line(mode)` in alternate screen.
  - `tests/unit/terminal_grid_erase_test.gd` — 12 unit tests covering all
    erase_display and erase_line modes. All GREEN.
  - `tests/unit/terminal_view_erase_test.gd` — 9 mock-mode integration
    tests sending full CSI sequences and asserting grid cell state. All GREEN.
- **Cursor positioning in alternate screen (task 1.0.3).**
  - `project/scripts/terminal_grid.gd` — added cursor state (`cursor_row`,
    `cursor_col`) and three new methods: `set_cursor(row, col)` (absolute,
    0-based, clamped), `move_cursor(delta_row, delta_col)` (relative, clamped),
    and `write_at_cursor(cell)` (writes at cursor then advances column). `resize`
    now clamps the cursor to new bounds.
  - `project/scripts/terminal_view.gd` — honours `CSI H` / `CSI f` (cursor
    home / position) and `CSI A/B/C/D` (up/down/right/left) in the alternate
    screen buffer. Regular characters written in alternate-screen mode are
    mirrored into an `_alt_grid: TerminalGrid` at the tracked cursor position.
    Added `_make_cell_from_state(ch)` helper to build a grid cell from current
    SGR state. Alternate-screen dimensions tracked via `_terminal_cols` /
    `_terminal_rows` (default 80×24); grid is resized on viewport change.
    `.gdlintrc` `max-file-lines` bumped to 700.
  - `tests/unit/terminal_grid_cursor_test.gd` — 25 unit tests covering cursor
    initial state, `set_cursor`, `move_cursor`, `write_at_cursor`, bounds-
    clamping, and resize-clamping. All GREEN.
  - `tests/unit/terminal_view_ansi_cursor_test.gd` — 25 mock-mode integration
    tests covering `CSI H`/`f`/`A`/`B`/`C`/`D` dispatch, character placement
    at cursor cell, partial-escape splitting, out-of-bounds clamping, and
    no-crash guarantee outside alternate screen. All GREEN.
- **`TerminalGrid` 2-D cell backing store (task 1.0.1).**
  - `project/scripts/terminal_grid.gd` — `RefCounted`-based class with full
    cell API: `resize(cols, rows)`, `set_cell`, `get_cell`, `clear_region`,
    `scroll_up`, `to_bbcode_line`. Each cell carries `char`, `fg`, `bg`,
    `bold`, `italic`, `underline`, `url`. Primary and alternate buffers are
    separate `TerminalGrid` instances.
  - `tests/unit/terminal_grid_test.gd` — 42 unit tests (cell round-trips,
    resize truncate/pad, out-of-bounds guards, clear_region, scroll_up,
    to_bbcode_line BBCode formatting, independent-instance isolation). All GREEN.
  - `.gdlintrc` — added `max-public-methods: 100` to accommodate GdUnit4 test
    suites that necessarily exceed the default cap of 20.
- **Alternate screen buffer support in `TerminalView` (task 1.0.2).**
  - `project/scripts/terminal_view.gd` — detects `CSI ?1049h/l` (enter/exit
    with primary buffer save/restore), `CSI ?47h/l` and `CSI ?1047h/l`
    (enter/exit without save/restore). On enter: saves primary BBCode
    accumulator and clears display. On exit with restore: restores primary
    content and scrolls to bottom. Partial escape sequences split across
    `output_ready` chunks are handled correctly via existing `_partial_escape`
    buffering. Also fixed pre-existing Godot 3-style `disconnect`/`is_connected`
    calls in `_exit_tree` and `\x` hex escape sequences to Godot 4.x
    `\uXXXX` form.
  - `tests/unit/terminal_view_alternate_screen_test.gd` — 13 mock-mode unit
    tests covering all three CSI variants, partial-escape splitting, and
    save/restore semantics. All GREEN.
- **Expanded unit test coverage to ≥80% of autoload methods (task 0.4.3).**
  - `tests/unit/terminal_manager_methods_test.gd` — 15 happy-path tests covering
    `spawn_shell`, `write_input`, `has_output`, `read_output`, and `clear` in mock mode.
  - `tests/unit/terminal_manager_grid_test.gd` — 10 happy-path tests covering
    `get_cell`, `get_dimensions`, and `resize` in mock mode.
  - `tests/unit/signal_bus_methods_test.gd` — 10 tests covering round-trip
    connections for all 5 SignalBus signals, disconnect behavior, and multiple-
    listener ordering.
  - Total unit suite: 46 test cases / 0 failures (`ALL GREEN`).

### Changed
- **Tightened gdlint rules — removed all `disable` exceptions (spec 0004, task 0.4.2).**
  - Removed all 10 `disable` exceptions from `.gdlintrc` by fixing the
    underlying code issues rather than suppressing them.
  - `terminal_manager.gd`: moved signal declarations before variable
    declarations (`class-definitions-order`); removed `else:` after `return`
    in `spawn_shell`, `has_output`, `read_output` (`no-else-return`);
    renamed local `TermClass` → `term_class` (`function-variable-name`);
    extracted `_mock_cmd_basic`, `_mock_cmd_cd`, `_mock_cmd_ls`,
    `_mock_cmd_cat`, `_mock_cmd_exit` helpers to bring `_mock_process_command`
    within the 6-return limit (`max-returns`); flattened `elif`/`else` chains
    in `_mock_cmd_ls` and `_mock_cmd_cat` (`no-elif-return`, `no-else-return`).
  - `main.gd`: prefixed unused signal-handler arg `available` → `_available`
    (`unused-argument`).
  - `terminal_view.gd`: moved `@onready` var declarations after regular
    variable declarations (`class-definitions-order`); flattened `elif`/`else`
    in `_xterm256_hex` (`no-elif-return`, `no-else-return`).
  - `bash scripts/lint.sh` → clean (exit 0) with stricter rules.


  - All `.gd` files under `project/` and `tests/` (excluding `addons/`) reformatted
    to canonical `gdformat` style.
  - `scripts/lint.sh` re-enabled `gdformat --check` so formatting is enforced on
    every future lint run.

### Added
- **Pinned godotty-node ref as one-line-bump workflow env var (spec 0003, task 0.3.3).**
  - `GODOTTY_NODE_REF` is now a workflow-level env var in
    `.github/workflows/nightly-real.yml`; bumping the pin is a single
    quoted-string change in that block.
  - `scripts/bump_godotty_node_ref.sh` — helper that edits both the workflow
    and `scripts/install_godotty_node.sh`, prints a diff, and gives copy-
    paste commit instructions.
  - `tests/ci/workflow_contains_ref_test.sh` — 10 static assertions: env var
    declared, value safe, install script references it, log step present,
    dispatch override present, refs match across files, bump script exists.
  - `tests/ci/workflow-syntax-test.sh` — validates workflow YAML parses
    cleanly (yamllint or python3 fallback).
  - `scripts/README.md` — table of all scripts and step-by-step bump procedure.
- **Real-mode integration test suite skeleton (spec 0003, task 0.3.2).**
  - `tests/integration/real/__init__.gd` (`RealIntegrationBase`) — shared base
    class providing `run_and_await()`, `_require_real_mode()`, and async
    `before_test()`/`after_test()` lifecycle hooks. Skips the whole suite
    gracefully (`pending()`) when the GDExtension is absent.
  - `tests/integration/real/pwd_test.gd` — asserts `pwd` output is a non-empty
    absolute path (starts with `/`).
  - `tests/integration/real/echo_test.gd` — asserts `echo hello` output
    contains `hello`.
  - `tests/integration/real/exit_code_test.gd` — asserts that `$?` captures
    the exit code of a sub-process (`sh -c 'exit 42'` → `42`), proving exit
    code propagation through the output stream.
- **Nightly real-mode CI workflow (spec 0003, task 0.3.1).**
  - `.github/workflows/nightly-real.yml` — scheduled (02:17 UTC nightly) +
    `workflow_dispatch` trigger. Runs on `ubuntu-latest` and `macos-latest`
    matrix. Skipped on PRs by design (no `pull_request` trigger).
  - `scripts/install_godotty_node.sh` — clones `godotty-node` at a pinned SHA
    (`GODOTTY_NODE_REF`), `cargo build --release`, installs
    `libgodotty_node.so` (Linux) or `.dylib` (macOS) into
    `project/addons/godotty-node/bin/<platform>/`.
  - On workflow failure: auto-opens a GitHub issue labelled `bug` with a link
    to the failing run.
- **GdUnit4 test harness (spec 0002).**
  - GdUnit4 v6.1.3 (Godot 4.6–compatible fork: `godot-gdunit-labs/gdUnit4`)
    is now installed by `scripts/install_gdunit4.sh` into
    `project/addons/gdUnit4/` (gitignored).
  - `tests/unit/terminal_manager_pwd_test.gd` — pins the mock-mode
    `pwd` / `cd` contract (`/home/user`, absolute paths, `..`, `~`).
  - `tests/unit/signal_bus_connectivity_test.gd` — pins the SignalBus
    signal set, signal arity, and argument names.
  - CI now runs the suite headless on **both Linux and macOS** and
    fails the build on red. Test reports uploaded as artifacts.
- `*.uid` is now gitignored (Godot 4.6 generates one per script).
- `AGENTS.md` — agent constitution defining process, principles, and hard stops.
- `.ralph/` directory — Ralph Loop state (PROMPT, specs, progress, learnings).
- `.github/skills/` — on-demand skill packs (gdscript, godot, testing, git, review, release, ralph).
- `scripts/ralph_loop.sh` — driver for the autonomous development loop.
- `scripts/run_tests.sh` — headless GdUnit4 runner.
- `scripts/lint.sh` — gdformat + gdlint + shellcheck wrapper.
- `scripts/release.sh` — semver release cutter (CHANGELOG promotion, tag, GitHub release).
- `scripts/install_gdunit4.sh` — pinned-version GdUnit4 installer (used by spec 0002).
- `.github/workflows/ci.yml` — Lint + headless test job on Linux.
- `.github/workflows/dual-review.yml` — Claude + GPT-5 PR review automation.
- `.github/workflows/release.yml` — Tag-push → GitHub release.
- `.github/agents/gpt5_reviewer.py` — GPT-5 PR review script.
- `docs/adr/0001-record-architectural-decisions.md` — ADR system bootstrap.
- `docs/adr/0002-ralph-loop-and-superpowers.md` — record of why we adopted Ralph + Superpowers.
- `.editorconfig`, `.gdlintrc` — code style baseline.

### Changed
- README rewritten to point at `AGENTS.md`, the Ralph Loop, and the dual-review process.
- `scripts/run_tests.sh` no longer soft-succeeds when Godot or GdUnit4
  is missing — it now exits 2 (misconfiguration). Failing tests exit 1.
- CI “Install GdUnit4” step is no longer optional and CI runs on both
  Linux and macOS.

### Fixed
- (none)

### Removed
- (none)

## [0.1.0] — 2025-01-XX

Baseline release after merging the terminal-demo, real-terminal-wiring,
and terminal-improvements branches.

### Added
- Mock terminal mode for development without GDExtension.
- `godotty-node` addon scaffolding with `build_extension.sh` helper.
- Real `TerminalNode2D` PTY backend wiring.
- Robust ANSI SGR parser:
  - Combined codes (`\x1b[1;32m`).
  - 256-color (`\x1b[38;5;Nm`).
  - Truecolor (`\x1b[38;2;R;G;Bm`).
  - OSC sequences (titles, hyperlinks).
  - Partial-escape buffering across PTY read chunks.
- Solarized Dark color palette.
- Keyboard shortcuts: Ctrl+C, Ctrl+L (clear), Ctrl+D (EOF).
- Command history (↑ / ↓).
- Viewport resize → terminal cols/rows propagation.

### Fixed
- `write_input` now appends `\n` so commands actually execute in the PTY.
- Ctrl+C now sends real `\x03` (SIGINT) instead of just printing `^C`.
- Focus-grab loop (RichTextLabel + ScrollContainer were stealing focus from LineEdit).
- Windows: force mock mode; portable_pty DLL init was failing.
- Removed `class_name TerminalManager` (collided with autoload of same name).

[Unreleased]: https://github.com/ClawfficeOrg/godotty/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/ClawfficeOrg/godotty/releases/tag/v0.1.0
