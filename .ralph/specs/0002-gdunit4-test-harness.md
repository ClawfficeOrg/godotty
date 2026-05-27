# Spec 0002 — GdUnit4 test harness

**STATUS:** ready-for-review
**OWNER:** unassigned
**OPENED:** 2025-01-XX
**LABELS:** test · infra

## Problem / Motivation

We have zero tests. The Ralph Loop's RED→GREEN cycle is meaningless without
a test runner. GdUnit4 is the de-facto standard for Godot 4 testing.

## Goals

- Vendor GdUnit4 under `project/addons/gdUnit4/` (gitignored — installed by
  a setup script).
- `scripts/install_gdunit4.sh` installs the addon (curl + unzip from
  upstream releases, pinned version).
- `scripts/run_tests.sh` runs all suites headless via `godot4 --headless`
  and exits non-zero on failure.
- A canonical test for `TerminalManager` mock-mode `pwd` (`/home/user`).
- A canonical test for `SignalBus` signal connectivity.
- CI updated to install GdUnit4 and run tests on Linux + macOS.

## Acceptance

- [x] `scripts/install_gdunit4.sh` works on macOS + Linux.
- [x] `tests/unit/terminal_manager_pwd_test.gd` exists and passes (4 cases).
- [x] `tests/unit/signal_bus_connectivity_test.gd` exists and passes (7 cases).
- [x] `scripts/run_tests.sh` exits 0 when all green, non-zero when red
  (verified locally with a deliberately-failing test).
- [x] CI runs tests on Linux **and** macOS, both green.
- [x] CHANGELOG entry under `[Unreleased] / Added`.
- [x] Pinned GdUnit4 version in `scripts/install_gdunit4.sh`.

## Implementation notes (closing)

- Pinned to **`godot-gdunit-labs/gdUnit4` v6.1.3**, not `MikeSchulze/gdUnit4`.
  The repo moved orgs; v5.x targets Godot 4.3–4.4.1, v6.0 targets 4.5,
  and v6.1+ targets 4.5–4.6. We run on 4.6.2 locally / 4.6-stable in CI.
- Headless runs require `--ignoreHeadlessMode` on the CmdTool invocation.
- `monitor_signals(SignalBus)` is fragile against autoloads in v6.1.x
  (the monitor frees the watched object between tests and corrupts the
  singleton). We assert signal arity via `get_signal_list` plus a
  local-callback round-trip instead. Logged in `learnings/INDEX.md`.
- Local `godotty-node` GDExtension dylib is absent in CI; Godot logs
  noisy `dlopen` errors but `TerminalManager` falls back to mock mode
  cleanly. Real-mode CI is the job of spec 0003.

## References

- GdUnit4 (current home) — https://github.com/godot-gdunit-labs/gdUnit4
- GdUnit4 (legacy) — https://github.com/MikeSchulze/gdUnit4
