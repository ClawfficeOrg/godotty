---
name: conventional-commits
description: Conventional Commits 1.0.0 cheat sheet for godotty
when_to_use: Every commit. Every. Single. One.
---

# Conventional Commits — godotty

## Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

- **type** — required. One of: `feat`, `fix`, `refactor`, `test`, `docs`,
  `chore`, `build`, `ci`, `perf`, `style`, `revert`.
- **scope** — optional, recommended. Examples: `manager`, `view`, `signals`,
  `mock`, `ansi`, `ralph`, `ci`, `release`.
- **subject** — imperative, ≤72 chars, no trailing period.
- **body** — wrap at 72. Explain **what** and **why**, never **how**.
- **footer** — `BREAKING CHANGE: ...`, `Refs #...`, `Closes #...`,
  `Co-authored-by: ...`.

## Bumping rules (semver)

| Commit type        | Bumps             |
|--------------------|-------------------|
| `feat`             | MINOR             |
| `fix` / `perf`     | PATCH             |
| `!` or `BREAKING`  | MAJOR             |
| Everything else    | nothing           |

## Examples

✅ Good
```
feat(manager): add resize(cols, rows) to TerminalManager

The terminal view now drives cols/rows on viewport resize. The manager
forwards to TerminalNode2D when in real mode and is a no-op in mock mode.

Refs #12
```

```
fix(view): grab focus deferred after output append

RichTextLabel append_text steals focus from LineEdit. Calling
input_field.call_deferred("grab_focus") inside _on_output_ready
restores it on the next frame.

Closes #18
```

```
feat(manager)!: rename spawn_shell() -> start_shell()

BREAKING CHANGE: spawn_shell renamed to start_shell for parity with
TerminalNode2D's API. Callers must update.
```

❌ Bad

- `WIP` — no type
- `update stuff` — vague
- `feat: Added support for foo.` — past tense, trailing period
- `fix: fix the bug` — what bug? why?

## Multiple changes

Split the commit. A Ralph iteration produces one commit. If yours doesn't
fit, your iteration is too big.

## Co-authoring

```
Co-authored-by: Claude <claude@clawffice.dev>
Co-authored-by: GPT-5 <gpt5@clawffice.dev>
```
