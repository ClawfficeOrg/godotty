# Current Working Memory

**STATUS:** in-progress
**SPEC:** `.ralph/specs/0003-real-terminal-ci.md`
**BRANCH:** `feature/0003-real-terminal-ci` (target)
**STARTED:** 2026-05-27

## Now doing

Task `1.0.1` — DONE. `TerminalGrid` 2-D cell backing store implemented.
- `project/scripts/terminal_grid.gd` — `RefCounted` class with `resize`,
  `set_cell`, `get_cell`, `clear_region`, `scroll_up`, `to_bbcode_line`.
- `tests/unit/terminal_grid_test.gd` — 42 tests, ALL GREEN.
- `.gdlintrc` — `max-public-methods: 100` added for test-suite compatibility.
- `docs/todo-v1.md` — task 1.0.1 marked `[x]`.
- `CHANGELOG.md` — entry added under `[Unreleased] / Added`.
- `bash scripts/lint.sh` → clean. `bash scripts/run_tests.sh tests/unit` → 88/88 GREEN.

## Done this session (continued)

- Task `0.4.2` — tighten gdlint rules:
  - `.gdlintrc` — removed all 10 `disable` exceptions.
  - `project/autoload/terminal_manager.gd` — signals before vars, guard-clause
    style, `TermClass`→`term_class`, extracted 5 `_mock_cmd_*` helpers to
    satisfy `max-returns`, flattened `elif`/`else` in ls/cat handlers.
  - `project/scripts/main.gd` — `available`→`_available` for unused-arg rule.
  - `project/scripts/terminal_view.gd` — @onready vars after regular vars,
    flattened `_xterm256_hex` if-chain.
  - `bash scripts/lint.sh` → clean (exit 0).
  - `bash scripts/run_tests.sh tests/unit` → 11/11 GREEN.

- Task `0.4.1` — one-shot gdformat reformat complete; `gdformat --check` re-enabled in lint.
  - `project/autoload/signal_bus.gd`, `terminal_manager.gd` — reformatted.
  - `project/scripts/main.gd`, `terminal_view.gd` — reformatted.
  - `tests/integration/real/__init__.gd`, `echo_test.gd`, `exit_code_test.gd`, `pwd_test.gd` — reformatted.
  - `scripts/lint.sh` — re-enabled `gdformat --check`.
  - `bash scripts/lint.sh` → clean (exit 0).
  - `bash scripts/run_tests.sh tests/unit` → 11/11 GREEN.

- `tests/integration/real/__init__.gd` (`RealIntegrationBase`) — async base
  class with `run_and_await()`, `_require_real_mode()`, lifecycle hooks.
- `tests/integration/real/pwd_test.gd` — pwd returns absolute path.
- `tests/integration/real/echo_test.gd` — echo hello contains "hello".
- `tests/integration/real/exit_code_test.gd` — exit code 42 propagates via $?.
- Task `0.3.3` — `GODOTTY_NODE_REF` workflow env pinning:
  - `scripts/bump_godotty_node_ref.sh` — one-line bump helper.
  - `tests/ci/workflow_contains_ref_test.sh` — 10 static assertions.
  - `tests/ci/workflow-syntax-test.sh` — YAML parse check.
  - `scripts/README.md` — scripts table + bump procedure docs.
- `bash scripts/lint.sh` → clean.
- `bash scripts/run_tests.sh tests/unit` → 11/11 GREEN.

## Done this session (2026-05-27)

- Created the project roadmap, modelled after Zoid's `todo.md` structure:
  - `docs/ROADMAP.md` — master index with WezTerm inspiration map.
  - `docs/todo-v0.md` — in-flight infra + CI work (phases 0.2–0.4).
  - `docs/todo-v1.md` — terminal emulation quality (alternate screen,
    cursor, resize, paste, clipboard) — 16 task cards.
  - `docs/todo-v2.md` — UX & appearance (themes, fonts, search,
    keybindings, visual tuning) — 16 task cards.
  - `docs/todo-v3.md` — multiplexing (tabs, split panes, session
    persistence) — intent + scope; detail deferred until v2 stable.
  - `docs/todo-v4.md` — advanced features (hyperlinks OSC 8, shell
    integration OSC 7/133, mouse reporting, wide chars, images) —
    18 task cards.

## Done in earlier sessions (kept for context)

- (Bootstrap, hand-authored by Claude) Repo hygiene: merged PR #3 + #4,
  retired stale branches, fixed default branch, tagged v0.1.0.
- (Bootstrap) Created `AGENTS.md`, `.ralph/` skeleton, `.github/skills/`
  skeleton. PR #5 open against `master`.
- (Spec 0002) Pinned GdUnit4 to **v6.1.3** from `godot-gdunit-labs/gdUnit4`
  (the Godot 4.6–compatible fork). Replaced the broken v5.0.5 pin.
- (Spec 0002) Fixed `scripts/run_tests.sh`: `--ignoreHeadlessMode`, hard-fail
  on misconfiguration (exit 2) and test failure (exit 1).
- (Spec 0002) Wrote `tests/unit/terminal_manager_pwd_test.gd` (4 cases, GREEN).
- (Spec 0002) Wrote `tests/unit/signal_bus_connectivity_test.gd` (7 cases, GREEN).
- (Spec 0002) CI: hard-installs GdUnit4, runs the suite headless on
  **Linux + macOS**, uploads test reports as artifacts.
- (Spec 0002) Gitignored `*.uid` (Godot 4.6) and `project/addons/gdUnit4/`.
- CHANGELOG `[Unreleased] / Added` updated.
- 5 new entries in `.ralph/learnings/INDEX.md`.

## Verified locally

- `bash scripts/run_tests.sh tests/unit` → 11 cases / 0 failures / `ALL GREEN`.
- Sanity check with a deliberately failing test → `EXIT: 1`. Red propagates.

## Blocked / questions for the human

**Waiting on human merge of PR #5 and PR #6.**

These touch meta infra, CI and policies (AGENTS.md hard-stops). After
merge, start spec 0003 on a new branch `feature/0003-real-terminal-ci`.

## Next steps after PRs merge

1. Start `feature/0003-real-terminal-ci`.
2. Implement `0.3.1` — `.github/workflows/nightly-real.yml` (nightly build
   of godotty-node, headless integration tests).
3. Implement `0.3.2` — three real-mode integration tests in
   `tests/integration/real/`.
4. Implement `0.3.3` — pin godotty-node ref as `GODOTTY_NODE_REF` env var.

See `docs/todo-v0.md` phase 0.3.0 for full task cards.

## Notes & scratchpad

- Bootstrap PR #5 must land before spec 0002's PR can merge to `master`
  cleanly. The 0002 PR is opened against `feature/superpowers-ralph-infra`
  so the diff stays focused on test-harness changes.
- Spec 0003 (real-mode CI) is unblocked once `godotty-node` ships
  pre-built artifacts or a clean cross-compile path.
- Driver script lives at `scripts/ralph_loop.sh`. Test it with `--dry-run`
  before letting it loose.
- Full roadmap is now at `docs/ROADMAP.md`. WezTerm inspiration map
  is in the roadmap master index.
