# Current Working Memory

**STATUS:** active
**SPEC:** `.ralph/specs/0001-superpowers-and-ralph-loop.md`
**BRANCH:** `feature/superpowers-ralph-infra`
**STARTED:** 2025-01-XX (set by first iteration)

## Now doing

(Empty — next agent: pick the next bullet from the spec's "Acceptance" list
that is not already checked, and start the RED → GREEN → REFACTOR cycle.)

## Done this session

- (Bootstrap, hand-authored by Claude) Repo hygiene: merged PR #3 + #4,
  retired stale branches, fixed default branch, tagged v0.1.0.
- (Bootstrap) Created `AGENTS.md`, `.ralph/` skeleton, `.github/skills/` skeleton.
- (Bootstrap) Wrote spec 0001 (this self-bootstrapping spec).

## Blocked / questions for the human

(None. If you write something here, also `touch .ralph/state/STOP` so the
loop pauses for review.)

## Notes & scratchpad

- Driver script lives at `scripts/ralph_loop.sh`. Test it with `--dry-run`
  before letting it loose.
- Tests use **GdUnit4**. Headless run via `scripts/run_tests.sh`.
- The first real autonomous iteration should be: write the failing
  `TerminalManagerTest` for mock-mode `pwd` and make it green. This proves
  the whole loop works end-to-end.
