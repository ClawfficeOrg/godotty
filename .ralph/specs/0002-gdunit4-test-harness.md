# Spec 0002 — GdUnit4 test harness

**STATUS:** open
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

- [ ] `scripts/install_gdunit4.sh` works on macOS + Linux.
- [ ] `tests/unit/terminal_manager_pwd_test.gd` exists and passes.
- [ ] `tests/unit/signal_bus_connectivity_test.gd` exists and passes.
- [ ] `scripts/run_tests.sh` exits 0 when all green, non-zero when red.
- [ ] CI runs tests on Linux **and** macOS, both green.
- [ ] CHANGELOG entry under `[Unreleased] / Added`.
- [ ] Pinned GdUnit4 version in `scripts/install_gdunit4.sh`.

## References

- GdUnit4 — https://github.com/MikeSchulze/gdUnit4
