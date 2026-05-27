# Changelog

All notable changes to **godotty** are documented here.

The format is based on [Keep a Changelog 1.1.0](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning 2.0.0](https://semver.org/spec/v2.0.0.html).

Pre-1.0 versions: MINOR bumps may include breaking changes (loudly noted).

## [Unreleased]

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
