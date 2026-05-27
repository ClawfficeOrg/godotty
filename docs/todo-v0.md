# Godotty Todo — v0.x: Developer Foundation

> Back to index: [`docs/ROADMAP.md`](ROADMAP.md)

The 0.x series builds the autonomous-development infrastructure that all future
work depends on: Ralph Loop discipline, a headless test harness, real-mode
regression CI, and a clean lint baseline. No user-visible features land here.

**Current release:** `v0.1.0` (baseline — see git tag).

---

## Phase 0.2.0 — Developer Infrastructure

**Goal:** Ralph Loop + Superpowers bootstrap and a GdUnit4 test harness that
runs headlessly on every PR (Linux + macOS).

**Status:** 🟡 In review — PRs #5 (infra bootstrap) and #6 (test harness)
are open and passing CI. Awaiting human sign-off before merge.

Completed tasks:

- [x] `0.2.1` Bootstrap Ralph Loop + Superpowers (spec 0001, PR #5).
  - AGENTS.md, `.ralph/` skeleton, `.github/skills/`, scripts (ralph_loop.sh,
    run_tests.sh, lint.sh, release.sh, install_gdunit4.sh).
  - CI: ci.yml (lint + test on Linux), dual-review.yml, release.yml.
  - ADRs 0001 + 0002.

- [x] `0.2.2` GdUnit4 test harness (spec 0002, PR #6).
  - GdUnit4 v6.1.3 (godot-gdunit-labs fork, Godot 4.6–compatible).
  - `tests/unit/terminal_manager_pwd_test.gd` — 4 mock-mode cases (GREEN).
  - `tests/unit/signal_bus_connectivity_test.gd` — 7 signal-contract cases (GREEN).
  - CI runs suite headless on Linux + macOS; hard-fails on red; uploads reports.
  - `run_tests.sh` returns exit 1 on test failure, exit 2 on misconfiguration.

**Release gate for 0.2.0:** both PRs merged to `master`, CI green on master.

---

## Phase 0.3.0 — Real-mode Regression CI

**Goal:** a nightly CI job that builds `godotty-node` from source, installs
it into `project/addons/`, and runs real PTY-backed integration tests.

**Status:** 🔵 Planned (spec 0003 is open).

**Prerequisite:** Phase 0.2.0 merged.

- [x] `0.3.1` Nightly workflow `.github/workflows/nightly-real.yml`.
  - Complexity: Medium. Suggested model: standard coding model.
  - Owned paths: `.github/workflows/nightly-real.yml`,
    `scripts/install_godotty_node.sh`.
  - Work: clone `godotty-node` at a pinned SHA, `cargo build --release`,
    install `.so` / `.dylib` into `project/addons/godotty-node/`.
    Trigger: `schedule` (nightly) + `workflow_dispatch`. Skip on PRs.
    On failure: auto-open a GitHub issue with the `bug` label.
  - Tests: the workflow itself is the test — green on first run.

- [x] `0.3.2` Real-mode integration test suite skeleton.
  - Complexity: Low-Medium. Suggested model: standard coding model.
  - Owned paths: `tests/integration/real/`, `tests/integration/real/pwd_test.gd`,
    `tests/integration/real/echo_test.gd`, `tests/integration/real/exit_code_test.gd`.
  - Work: three integration tests that require the GDExtension to be present:
    `pwd` returns a valid path, `echo hello` returns `hello`, shell exit code
    propagates. Suite must skip gracefully when addon is absent (mock mode).
  - Tests: all 3 cases GREEN in the nightly workflow; skip gracefully on PR runs.

- [ ] `0.3.3` Pin godotty-node ref in workflow env.
  - Owned paths: `.github/workflows/nightly-real.yml`.
  - Work: expose `GODOTTY_NODE_REF` as a workflow-level env var so bumping
    the pin is a one-line change. Document the bump procedure in `scripts/`.
  - Tests: changing the var causes a build from the new ref.

**Release gate for 0.3.0:** nightly job green on Linux for at least 3
consecutive nights; macOS nightly green best-effort.

---

## Phase 0.4.0 — Code Quality Cleanup

**Goal:** tighten the lint baseline established in 0.2 so the codebase is
fully gdformat-clean and gdlint-strict.

**Status:** 🔵 Planned.

**Prerequisite:** Phase 0.3.0 (or can run in parallel after 0.2.0 merges).

- [ ] `0.4.1` One-shot gdformat reformat of `project/` (excluding addons).
  - Complexity: Low. Suggested model: standard coding model.
  - Owned paths: `project/autoload/`, `project/scripts/`.
  - Work: run `gdformat` on all project GDScript files; commit the diff as
    `style(scripts): run gdformat on project source`. Re-enable
    `gdformat --check` in `scripts/lint.sh` so it stays clean.
  - Tests: `bash scripts/lint.sh` exits 0 after reformat.

- [ ] `0.4.2` Tighten gdlint rules.
  - Complexity: Low. Suggested model: standard coding model.
  - Owned paths: `.gdlintrc`, `project/autoload/`, `project/scripts/`.
  - Work: remove the `disable` exceptions added in 0.2.x one by one, fixing
    the underlying code issues rather than suppressing them. Restore stricter
    naming and class-variable order rules.
  - Tests: `bash scripts/lint.sh` exits 0 with tighter rules.

- [ ] `0.4.3` Expand unit test coverage to 80% of autoload methods.
  - Complexity: Medium. Suggested model: standard coding model.
  - Owned paths: `tests/unit/`.
  - Work: audit `terminal_manager.gd` and `signal_bus.gd` method by method;
    add test cases for all untested public methods in mock mode.
    Target: every public method has at least one happy-path test.
  - Tests: new test cases GREEN; `bash scripts/run_tests.sh tests/unit` exits 0.

**Release gate for 0.4.0:** `bash scripts/lint.sh` and
`bash scripts/run_tests.sh tests/` both exit 0 on a clean checkout.
