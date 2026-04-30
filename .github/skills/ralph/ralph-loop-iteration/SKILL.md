---
name: ralph-loop-iteration
description: The canonical RED → GREEN → REFACTOR cycle, exactly as godotty does it
when_to_use: Every Ralph loop iteration
---

# Ralph Loop — Single Iteration

## Pre-flight (30 seconds)

- `git status` — clean? If not, the previous iteration left a mess.
  `BLOCKED:` it in `CURRENT.md`, `touch .ralph/state/STOP`, exit.
- `git pull --ff-only` — up to date with origin?
- Read `AGENTS.md`, `.ralph/PROMPT.md`, `.ralph/progress/CURRENT.md`,
  `.ralph/learnings/INDEX.md`.

## Pick the unit

From the active spec's Acceptance list, the **first unchecked item** is
your target. Too big? Add a follow-up checkbox right beneath it and tackle
the smaller half first.

Write the chosen unit into `CURRENT.md` under `## Now doing` with a timestamp.

## RED (15 min max)

Write a test that captures the desired behavior. Run it.

```sh
scripts/run_tests.sh tests/unit/<your_test>.gd
```

It must fail, and you must understand **why**.

Commit:

    test(<scope>): <one-line failure description>

## GREEN (≤ 30 min)

Smallest possible source change to make the test pass. Don't refactor.
Don't fix adjacent issues.

```sh
scripts/run_tests.sh                    # ALL tests
scripts/lint.sh
```

Commit:

    feat(<scope>): <subject>            # or fix(scope): ...

## REFACTOR (optional, 10 min max)

Only if duplication or muddled abstraction now jumps out at you.

Tests still green. Commit:

    refactor(<scope>): <subject>

## Document (5 min)

- `CHANGELOG.md` `[Unreleased]` updated.
- `README.md` if user-visible.
- `.ralph/learnings/INDEX.md` if a quirk was hit.
- `.ralph/progress/CURRENT.md`: move unit from `Now doing` to `Done`.

Commit:

    docs(<scope>): update changelog and progress for <unit>

## Push

```sh
git push -u origin HEAD
```

## Maybe-PR

If the spec's Acceptance list is now fully checked:

1. Move `CURRENT.md` to `.ralph/progress/archive/<spec-id>.md`.
2. Set spec `STATUS: closed`, fill `CLOSED:` date.
3. Re-create `CURRENT.md` from idle template (`STATUS: idle`).
4. Commit those, push.
5. `gh pr create --title "<conv-commit subject>" --body-file <body>`.
6. Apply labels: `agent-authored`, plus the spec's domain labels.

## Exit

Print a one-line summary. Exit 0. The driver loops.
