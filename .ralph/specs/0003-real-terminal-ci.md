# Spec 0003 — Real terminal regression in CI

**STATUS:** open
**OWNER:** unassigned
**OPENED:** 2025-01-XX
**LABELS:** infra · ci

## Problem

Real-mode (PTY-backed) tests can't run yet because godotty-node isn't
present in CI. This means we can never catch regressions in the real
backend automatically.

## Goals

- A nightly CI job that:
  1. Clones godotty-node at a pinned ref.
  2. Builds it (cargo build --release).
  3. Installs the .so/.dylib into addons/.
  4. Runs the real-mode integration test suite (under
     `tests/integration/real/`).
- Skipped on PR runs (too slow); runs nightly + on demand via
  `workflow_dispatch`.

## Non-goals

- Windows CI for real mode (blocked on portable_pty fix upstream).

## Acceptance

- [ ] `.github/workflows/nightly-real.yml` exists and is green.
- [ ] At least 3 integration tests under `tests/integration/real/`:
      `pwd`, `echo hello`, and `exit code propagation`.
- [ ] godotty-node ref pinned in workflow env.
- [ ] Failure pings the maintainer (issue auto-opened with `bug` label).

## References

- Spec 0002 (must be closed first).
