# Ralph Loop — Operational Manual

This directory is the **state of the autonomous development loop** for godotty.
It is the agent's only memory between iterations. Treat every file here as
load-bearing.

## What is the Ralph Loop?

A **stateless loop**. The same prompt (`PROMPT.md`) is given to the agent
every iteration. The agent gets context only from files on disk:

- `AGENTS.md` (repo root) — the rules.
- `.ralph/PROMPT.md` — the master instructions for this iteration.
- `.ralph/specs/` — feature specs (the backlog).
- `.ralph/progress/CURRENT.md` — what is in flight right now.
- `.ralph/learnings/INDEX.md` — non-obvious things learned.
- `.ralph/state/STOP` — if exists, the loop halts.

The driver (`scripts/ralph_loop.sh`) re-invokes the agent until either:
- All specs are complete, or
- `.ralph/state/STOP` exists, or
- A configurable max iteration count is reached, or
- Two consecutive iterations fail.

## Directory layout

```
.ralph/
├── README.md            ← this file
├── PROMPT.md            ← master prompt, read every iteration
├── specs/               ← work backlog (one file per feature)
│   ├── 0001-superpowers-and-ralph-loop.md  (this PR)
│   ├── 0002-gdunit4-test-harness.md
│   ├── 0003-real-terminal-ci.md
│   └── ...
├── progress/
│   ├── CURRENT.md       ← live working memory; mutable
│   └── archive/         ← snapshot-on-completion of CURRENT.md per spec
├── learnings/
│   └── INDEX.md         ← non-obvious things; append-only
└── state/
    ├── STOP             ← (optional, gitignored) tells the loop to halt
    └── ITERATIONS       ← (optional, gitignored) iteration counter
```

## How to add work

1. Pick the next number `NNNN` (zero-padded, monotonic).
2. Create `.ralph/specs/NNNN-<slug>.md` from `specs/_template.md`.
3. Commit it (`docs(spec): add NNNN-<slug>`).
4. The next loop iteration will pick it up if `CURRENT.md` is empty.

## How to stop the loop

```sh
touch .ralph/state/STOP
```

To resume: delete the file.

## How to wipe the loop (dangerous)

`scripts/ralph_loop.sh --reset` archives `progress/CURRENT.md` and clears
state files. **Never** wipes specs or learnings.

## Why this works

- Conversation history is **lossy**. Files are not.
- The agent that starts iteration N does not remember iteration N-1's reasoning;
  it only sees the *artifacts* (commits, updated CURRENT.md, learnings).
  This forces the agent to leave good breadcrumbs — for itself and for humans.
- A single failing test cannot be hand-waved away across a context window
  refresh: it's still red on disk.
