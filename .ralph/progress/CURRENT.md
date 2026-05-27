# Current Working Memory

**STATUS:** blocked-on-human-merge
**SPEC:** `.ralph/specs/0003-real-terminal-ci.md` (next up)
**BRANCH:** `feature/0002-gdunit4-harness` (current; PRs pending)
**STARTED:** 2026-03-23

## Now doing

Waiting for human sign-off on:
- **PR #5** (`feature/superpowers-ralph-infra` → `master`) — Ralph Loop +
  Superpowers bootstrap (spec 0001).
- **PR #6** (`feature/0002-gdunit4-harness` → `feature/superpowers-ralph-infra`)
  — GdUnit4 test harness (spec 0002).

Once both PRs are merged, the next spec is **0003 (real-mode regression CI)**,
tracked as Phase 0.3.0 in `docs/todo-v0.md`.

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
