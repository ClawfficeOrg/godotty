# Spec 0001 — Superpowers + Ralph Loop infrastructure

**STATUS:** in-progress
**OWNER:** Claude (bootstrap, hand-authored)
**OPENED:** 2025-01-XX
**CLOSED:** —
**LABELS:** infra · meta · docs

## Problem / Motivation

After memory corruption in OpenClaw fragmented several Clawffice projects,
we need to re-establish godotty as an autonomously-developable codebase
where an LLM agent can keep moving forward with minimal human babysitting.

The chosen disciplines are **Ralph Loop** (Geoffrey Huntley — stateless,
disk-backed, RED→GREEN→REFACTOR loop) and **Superpowers** (Jesse Vincent —
on-demand skill packs in markdown).

This spec is the **bootstrap**. It is itself the first thing produced by
the loop's manual hand-cranking. After it is closed, every subsequent spec
can be picked up and executed by the loop with no further bootstrapping.

## Goals (in scope)

- `AGENTS.md` at the repo root — the rules.
- `.ralph/` skeleton: README, PROMPT, specs/, progress/, learnings/, state/.
- `.github/skills/` skeleton with INDEX and one skill per domain we'll need
  in the next 90 days: gdscript-style, gdscript-testing, godot-headless,
  conventional-commits, dual-review, cutting-a-release, ralph-loop-iteration.
- Driver script `scripts/ralph_loop.sh` (bash; macOS + Linux).
- Helper scripts: `scripts/run_tests.sh`, `scripts/lint.sh`, `scripts/release.sh`.
- CI workflow `.github/workflows/ci.yml` (lint + headless test on Linux).
- CI workflow `.github/workflows/dual-review.yml` (Claude + GPT-5 review on PR).
- `CHANGELOG.md` started under Keep-A-Changelog.
- `.editorconfig`, GDScript formatter config, gdlint config.
- This spec file, marked `closed` upon merge.

## Non-goals

- Actually wiring up the GDExtension to CI (that's spec 0003).
- Writing the GdUnit4 test harness installer in this PR (spec 0002).
- Real terminal regression tests (spec 0004+).
- Touching any application code in `project/`.

## Design sketch

### State model

The agent's memory is **on disk**, never in chat history. Three layers:

1. **Constitution** (`AGENTS.md`) — rules. Rarely changes.
2. **Specs** (`.ralph/specs/NNNN-*.md`) — the backlog. Append-only; closed
   specs are not deleted, they become history.
3. **Progress + learnings** (`.ralph/progress/`, `.ralph/learnings/`) —
   working memory and accumulated wisdom.

The PROMPT.md is what's fed to the model every iteration, plus the agent
re-reads everything else itself.

### Skill loading

Skills live at `.github/skills/<domain>/<skill>/SKILL.md`. Each has YAML
frontmatter: `name`, `description`, `when_to_use`. The agent scans the
INDEX, loads only relevant skills, executes. This keeps context windows
small and skills composable.

### Review

CI fires a `dual-review.yml` workflow on every PR that:

1. Runs Claude as reviewer with the `dual-review` skill loaded.
2. Runs GPT-5 (via API) as a second reviewer with the same skill.
3. Posts both reviews as PR comments.
4. The human merges (or asks for changes) based on the synthesis.

### Driver

`scripts/ralph_loop.sh`:

- Parses flags: `--max-iter N`, `--dry-run`, `--reset`.
- Each iteration: invokes the agent (Claude Code or compatible) with
  `.ralph/PROMPT.md` as the instructions and the repo as cwd.
- Bails on `.ralph/state/STOP`, on N reached, or on 2 consecutive failures.
- Writes its own log to `.ralph/state/loop.log`.

The driver does **not** itself run tests — the agent does. This keeps the
"verify" step inside the loop and forces honest reporting.

## Acceptance criteria

- [x] `AGENTS.md` exists at repo root.
- [x] `.ralph/README.md`, `.ralph/PROMPT.md` exist and reference each other.
- [x] `.ralph/progress/CURRENT.md` exists with `STATUS: active`.
- [x] `.ralph/learnings/INDEX.md` seeded with at least the 5 known gotchas
      from prior commits.
- [x] `.ralph/specs/_template.md` exists.
- [x] `.ralph/specs/0001-*.md` (this file) exists and will be marked closed
      on merge.
- [x] `.github/skills/INDEX.md` exists.
- [x] At least one skill exists under each of: `gdscript`, `godot`, `git`,
      `testing`, `review`, `release`.
- [x] `scripts/ralph_loop.sh`, `scripts/run_tests.sh`, `scripts/lint.sh`,
      `scripts/release.sh` exist and are executable.
- [x] `.github/workflows/ci.yml` exists.
- [x] `.github/workflows/dual-review.yml` exists.
- [x] `CHANGELOG.md` exists with `[Unreleased]` and the v0.1.0 baseline.
- [x] `README.md` updated to point to `AGENTS.md` and the Ralph Loop docs.
- [x] PR opened, labelled `infra`, `meta`, `agent-friendly`, awaiting human
      and GPT-5 review.

## Risks & open questions

- **Q:** Which CLI does the driver invoke? **A:** Pluggable via env var
  `RALPH_AGENT_CMD` (default: `claude`). Codex/Cursor/etc. can be swapped in.
- **Q:** Where does the GPT-5 review run? **A:** GitHub Actions with a
  repo secret `OPENAI_API_KEY`. The workflow is non-blocking on missing key
  (it just skips and notes "GPT-5 review skipped: no key").
- **R:** GdUnit4 isn't installed yet, so `scripts/run_tests.sh` exits 0
  with a "no tests configured" notice in CI. Spec 0002 fixes this.

## References

- Geoffrey Huntley — *Ralph Wiggum as a Software Engineer*
- Jesse Vincent / Obra — Superpowers / claude-skills
- Keep A Changelog 1.1.0 — https://keepachangelog.com
- Conventional Commits 1.0.0 — https://www.conventionalcommits.org
- SemVer 2.0.0 — https://semver.org
