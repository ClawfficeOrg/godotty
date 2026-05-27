# Current Working Memory

**STATUS:** ready-for-review
**SPEC:** `.ralph/specs/0002-gdunit4-test-harness.md`
**BRANCH:** `feature/0002-gdunit4-harness`
**STARTED:** 2026-03-23

## Now doing

Spec 0002 — GdUnit4 test harness. All acceptance items checked. PR will
target `feature/superpowers-ralph-infra` (depends on bootstrap PR #5
landing first).

## Done this session

- Pinned GdUnit4 to **v6.1.3** from `godot-gdunit-labs/gdUnit4` (the
  Godot 4.6–compatible fork). Replaced the broken v5.0.5 pin.
- Fixed `scripts/run_tests.sh`:
  - Pass `--ignoreHeadlessMode` to the CmdTool (Godot 4.6 headless).
  - Removed the spec-0001 "soft-success when no Godot / no GdUnit4"
    bypass paths. Tests now hard-fail on misconfiguration (exit 2) and
    on test failure (exit 1).
- Wrote `tests/unit/terminal_manager_pwd_test.gd` (4 cases, GREEN).
- Wrote `tests/unit/signal_bus_connectivity_test.gd` (7 cases, GREEN) —
  asserts signal arity via `get_signal_list` instead of using
  `monitor_signals(SignalBus)`, which corrupts autoloads in v6.1.x.
- CI: hard-installs GdUnit4, runs the suite headless on **Linux + macOS**,
  uploads test reports as artifacts.
- Gitignored `*.uid` (Godot 4.6) and `project/addons/gdUnit4/`.
- CHANGELOG `[Unreleased] / Added` updated.
- 5 new entries in `.ralph/learnings/INDEX.md`.

## Verified locally

- `bash scripts/run_tests.sh tests/unit` → 11 cases / 0 failures / `ALL GREEN`.
- Sanity check with a deliberately failing test → `EXIT: 1`. Red propagates.

## Done in earlier sessions (kept for context)

- (Bootstrap, hand-authored by Claude) Repo hygiene: merged PR #3 + #4,
  retired stale branches, fixed default branch, tagged v0.1.0.
- (Bootstrap) Created `AGENTS.md`, `.ralph/` skeleton, `.github/skills/`
  skeleton. PR #5 open against `master`.
- (Bootstrap) Wrote spec 0001 (the self-bootstrapping spec).

## Blocked / questions for the human

(None. If you write something here, also `touch .ralph/state/STOP` so the
loop pauses for review.)

## Notes & scratchpad

- Bootstrap PR #5 must land before spec 0002's PR can merge to `master`
  cleanly. The 0002 PR is opened against `feature/superpowers-ralph-infra`
  so the diff stays focused on test-harness changes.
- Spec 0003 (real-mode CI) is unblocked once `godotty-node` ships
  pre-built artifacts or a clean cross-compile path.
- Driver script lives at `scripts/ralph_loop.sh`. Test it with `--dry-run`
  before letting it loose.
