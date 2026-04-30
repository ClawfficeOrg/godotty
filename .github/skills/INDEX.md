# Skills Index

Skills are loaded **on demand**, not memorized. Before starting a task,
the agent scans this index, picks the relevant skills, reads them in full,
then executes.

A "skill" is a tight, opinionated piece of how-to writing. It is not
documentation. It tells you what to *do* and what to *not do*, in order.

## Skill format

Every skill lives at `.github/skills/<domain>/<skill>/SKILL.md`. It begins
with YAML frontmatter:

```yaml
---
name: <unique-skill-name>
description: <one-line, plain English>
when_to_use: <one-line, "when X, load this">
---
```

## Index

### Domain: `gdscript`
- **gdscript-style** — house style for `.gd` files (naming, types, layout).
  *When to use:* before writing or modifying any `.gd` file.

### Domain: `godot`
- **godot-headless** — run Godot from the command line for tests / CI.
  *When to use:* writing CI, debugging a test runner, or scripting a build.
- **godot-autoload-quirks** — surprising behaviors of singletons & class_name.
  *When to use:* touching anything in `project/autoload/`.
- **godot-signals** — signal patterns and the SignalBus contract.
  *When to use:* adding or modifying signals.

### Domain: `testing`
- **gdscript-testing** — write a GdUnit4 test, mock-mode patterns, fixtures.
  *When to use:* whenever you add behavior. Always.

### Domain: `git`
- **conventional-commits** — Conventional Commits 1.0.0 cheat sheet for godotty.
  *When to use:* every commit. Every. Single. One.
- **branching-and-prs** — when to branch, how to name, when to merge.
  *When to use:* before opening a PR.

### Domain: `review`
- **dual-review** — Claude + GPT-5 review protocol (what each looks for).
  *When to use:* preparing or responding to a PR review.

### Domain: `release`
- **cutting-a-release** — semver + tagging + CHANGELOG promotion.
  *When to use:* when the human (or agent, with approval) cuts a release.

### Domain: `ralph`
- **ralph-loop-iteration** — the canonical RED→GREEN→REFACTOR cycle.
  *When to use:* every Ralph loop iteration.
- **writing-a-spec** — how to author a `.ralph/specs/` file.
  *When to use:* opening a new spec.
