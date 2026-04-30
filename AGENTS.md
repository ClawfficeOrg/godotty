# AGENTS.md — Godotty Agent Constitution

This file is read by every agent (human or AI) working on this repository.
Read it on **every** Ralph Loop iteration. It is the source of truth for *how*
we work; the code is the source of truth for *what* exists.

> "If you cheat the process, the process cheats you."

---

## 1. Identity & Scope

Godotty is a **Godot 4.6 reference application** demonstrating
[`godotty-node`](https://github.com/ClawfficeOrg/godotty-node), a Rust GDExtension
that brings real PTY-backed terminal emulation to Godot. This repo is the demo /
playground / regression harness. It must always run — both with and without the
GDExtension installed (mock mode is a first-class citizen).

Out of scope here: changes to `godotty-node` itself. Open issues against that
repo and link them in PRs.

---

## 2. Core Principles

### 2.1 Brutal Honesty
- **Never claim success without verification.** "Should work" ≠ "tested".
- If you don't know, say so. Say "I don't know" before you guess.
- Never silently swallow errors. Don't suppress diagnostics to make a build pass.
- Never delete or rewrite a failing test to make it pass. Fix the code, or
  document why the test was wrong with evidence.

### 2.2 Verification Before Completion
A task is **not** complete until:
1. Code compiles / parses cleanly (Godot script parser, no warnings).
2. All existing tests pass.
3. New behavior has a new test covering it (RED → GREEN → REFACTOR).
4. Linter / formatter clean (`gdformat`, `gdlint`).
5. CHANGELOG updated under `[Unreleased]`.
6. Commit message follows Conventional Commits.
7. The progress file `.ralph/progress/CURRENT.md` is updated.

### 2.3 Small Steps, Frequent Commits
- Each Ralph iteration produces **one** logical commit.
- A commit that mixes refactor + feature + style change is a smell — split it.
- If a step balloons past ~200 LOC, stop, commit the prep work, restart.

### 2.4 Test-First, Always
- For any new behavior: write the failing test first, commit it (`test: ...`),
  then make it pass (`feat: ...` or `fix: ...`).
- For bug fixes: write a regression test that reproduces the bug *first*.
- Mock-mode tests are mandatory; real-mode tests are best-effort (they require
  the GDExtension to be present in CI, which is a follow-up).

### 2.5 Boundary-First Design
- New backends (real terminal, mock terminal, future SSH terminal, …) live
  behind the `TerminalManager` interface. **Do not** let backend specifics
  leak into views or the SignalBus.
- Signals are the *only* legal way for `TerminalView` to talk to the manager.

### 2.6 Document As You Go
- If you learn something non-obvious (a Godot quirk, a PTY gotcha, a Windows-
  only bug), append it to `.ralph/learnings/INDEX.md`. Future-you will thank
  present-you.
- Keep `README.md` accurate. If you change behavior, update the README in the
  *same* commit.

### 2.7 Reversibility
- Prefer additive changes. Behind a flag or feature gate when in doubt.
- Never force-push to `master`. Never rewrite shared history.

---

## 3. The Ralph Loop

This repo uses the **Ralph Loop** discipline (after Geoffrey Huntley):
a single, stateless prompt is run repeatedly against the codebase. State lives
on disk, not in chat history.

Each iteration the agent:

1. **Read** `AGENTS.md` (this file).
2. **Read** `.ralph/PROMPT.md` (the master prompt).
3. **Read** `.ralph/progress/CURRENT.md` (what's in flight).
4. **Read** `.ralph/specs/` for the active spec.
5. **Read** `.ralph/learnings/INDEX.md` for prior gotchas.
6. **Pick** the next smallest unit of work.
7. **Load** any relevant skill from `.github/skills/`.
8. **Execute** RED → GREEN → REFACTOR → COMMIT.
9. **Update** `.ralph/progress/CURRENT.md` and (if learning) `.ralph/learnings/INDEX.md`.
10. **Push** the branch.
11. **Stop** if `.ralph/state/STOP` exists, the spec is complete, or 3
    consecutive iterations failed without progress.

See `.ralph/README.md` for the full protocol and `scripts/ralph_loop.sh` for
the driver.

---

## 4. Skills (Superpowers)

Skill packs live under `.github/skills/<domain>/<skill>/SKILL.md`. Each skill
has YAML frontmatter:

```yaml
---
name: gdscript-testing
description: How to write and run unit tests for GDScript with GdUnit4
when_to_use: When adding any new behavior to autoloads, scenes, or scripts
---
```

The agent **loads skills on demand** — it doesn't memorize them. When picking
up a task, scan `.github/skills/INDEX.md`, load matching skills, then proceed.

Available skill domains: `gdscript`, `godot`, `git`, `testing`, `review`, `release`.

---

## 5. Code Review

Every PR is reviewed by:

1. **Claude (this agent)** — checks against `AGENTS.md`, runs the test suite,
   verifies CHANGELOG + version bumps + tests-for-feature.
2. **GPT-5** — second-opinion review focusing on architectural drift,
   subtle bugs, and idiom quality. See `.github/skills/review/dual-review/SKILL.md`.
3. **Human (the maintainer, "hippo")** — final sign-off on anything touching:
   - autoloads
   - the GDExtension boundary
   - CI/release infrastructure
   - public API of `TerminalManager`

A PR may be self-merged by the agent **only** if all three of these are clean
*and* the change is purely internal (refactor, test, docs, style). Anything
user-visible waits for human sign-off.

---

## 6. Versioning & Releases

- **Semantic Versioning 2.0.0** strictly.
- `MAJOR.MINOR.PATCH` tagged on `master` only.
- Tags signed where possible (`git tag -s`). Annotated otherwise (`git tag -a`).
- Release notes generated from CHANGELOG `[Unreleased]` section by
  `scripts/release.sh`.
- Pre-1.0 we permit minor breakage in `MINOR` bumps; document loudly.

See `.github/skills/release/cutting-a-release/SKILL.md` for the procedure.

---

## 7. Commit Messages

**Conventional Commits.** Required types:
`feat`, `fix`, `refactor`, `test`, `docs`, `chore`, `build`, `ci`, `perf`, `style`, `revert`.

Format:
```
<type>(<scope>): <subject>

<body — what & why, never how>

<footer — refs, breaking changes>
```

- Subject ≤ 72 chars, imperative mood ("add", not "added").
- Breaking changes: `BREAKING CHANGE:` in footer **and** `!` after type.
- Reference issues: `Refs #123`, `Closes #45`.
- Co-author tags for paired/agent work:
  `Co-authored-by: Claude <claude@clawffice.dev>`

---

## 8. File Layout (project conventions)

```
.github/        — workflows, skills, agent configs, issue templates
.ralph/         — ralph loop state, specs, progress, learnings
project/        — the actual Godot project
  autoload/     — global singletons (SignalBus, TerminalManager)
  scenes/       — *.tscn
  scripts/      — *.gd
  resources/    — themes, settings
  addons/       — (gitignored) GDExtensions
  docs/         — in-project docs (mock command behaviors, etc.)
tests/          — GdUnit4 test suites
  unit/
  integration/
docs/           — top-level developer docs
scripts/        — shell scripts (ralph driver, release, etc.)
```

---

## 9. Hard Stops

The agent **must stop and ask the human** if it encounters any of:

- Need to change `TerminalManager`'s public method signatures.
- Need to introduce a new autoload.
- Need to add a runtime dependency (new addon, new package).
- Need to change CI provider, branch protection, or default branch.
- Need to delete or rename files outside its current spec.
- Two consecutive Ralph iterations both fail their tests.
- The repo has uncommitted changes from a previous iteration that don't
  belong to the current spec.

To stop the loop cleanly: `touch .ralph/state/STOP`.

---

## 10. Memory

- **Permanent project memory** → `.ralph/learnings/INDEX.md` (curated).
- **Working memory for current spec** → `.ralph/progress/CURRENT.md` (mutable).
- **Spec backlog** → `.ralph/specs/<NNNN>-<slug>.md` (immutable once closed).
- **Decisions** → `docs/adr/NNNN-<slug>.md` (Architecture Decision Records).

Never store secrets, tokens, or PII in any of these.

---

*This document is itself versioned. Propose changes via PR labelled `meta`.
Two reviewers required.*
