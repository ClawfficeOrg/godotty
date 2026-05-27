---
name: dual-review
description: Claude + GPT-5 review protocol — what each looks for, how they synthesize
when_to_use: Preparing or responding to a PR review
---

# Dual Review — Claude + GPT-5

Every PR receives **two** automated reviews plus a human sign-off where
required (see `AGENTS.md` §5). The two reviewers are deliberately given
**different lenses** so they don't redundantly notice the same things.

## Reviewer 1: Claude

Lens: **Process compliance + concrete behavior.**

Checklist:

1. **CHANGELOG** has a new entry under `[Unreleased]` matching the diff.
2. **Tests** exist for any new behavior; failing-first commit visible
   in branch history.
3. **Conventional Commits** format on every commit.
4. **AGENTS.md compliance** — no Hard Stops bypassed; no autoload changes
   without sign-off.
5. **README** updated if user-visible behavior changed.
6. **Docs/learnings** — if a non-obvious quirk was hit, was it added to
   `.ralph/learnings/INDEX.md`?
7. **Test evidence section** in PR body has actual output.
8. CI green.

Output format:

```markdown
## Claude review — <PR title>

### Process
- [x] CHANGELOG entry present
- [x] Tests added (RED commit: <sha>)
- [ ] README updated   ← ❌ missing for user-visible change

### Behavior spot-checks
- ...

### Verdict: REQUEST_CHANGES (1 process gap)
```

Verdicts: `LGTM`, `LGTM with nits`, `REQUEST_CHANGES`.

## Reviewer 2: GPT-5

Lens: **Architectural drift + idiom quality + subtle bugs.**

Checklist:

1. **Boundary integrity** — does the change leak backend specifics into
   views, or vice versa?
2. **Idiom** — Godot 4 vs Godot 3 patterns; type elision.
3. **Edge cases** — empty input, unicode, very long input, partial reads.
   Walk through them.
4. **Tests adequacy** — do tests actually cover the change, or merely exist?
5. **Naming** — does the symbol name match what the code does?
6. **Premature abstraction** — class/interface added with one impl?

Output:

```markdown
## GPT-5 review — <PR title>

### Architectural
- ...

### Idiom & types
- ...

### Edge cases I tried
- empty string input ✅ handled
- unicode in command ⚠️ untested

### Verdict: LGTM with nits
```

## Synthesis

If both say `LGTM` (or `LGTM with nits`), the agent may merge under the
self-merge rules.

If they **disagree**, the agent MUST:
1. Post a `## Synthesis` comment summarizing each reviewer's points.
2. Add the `needs-human` label.
3. Stop and wait.

## Workflow

`.github/workflows/dual-review.yml` runs on every PR. If `OPENAI_API_KEY` is
not set in the repo, the GPT-5 step prints "GPT-5 review skipped: no key"
and exits 0. Claude review still runs.
