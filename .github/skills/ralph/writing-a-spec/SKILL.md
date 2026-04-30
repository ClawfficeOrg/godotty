---
name: writing-a-spec
description: How to author a .ralph/specs/ file
when_to_use: Opening a new spec
---

# Writing a Spec

A spec is the **contract** between human intent and agent execution.
A good spec is unambiguous, testable, and small enough to be done in
roughly 1–10 Ralph iterations.

## Numbering

Pick the next unused number, zero-padded to 4: `0042-<slug>.md`.
Slugs are lowercase-kebab.

## Sections (use `_template.md`)

1. **Header**: STATUS, OWNER, OPENED, CLOSED, LABELS.
2. **Problem / Motivation**: what hurts; why now.
3. **Goals**: bullets. *In* scope.
4. **Non-goals**: bullets. Explicitly *out* of scope.
5. **Design sketch**: a few paragraphs. Note boundary choices.
6. **Acceptance criteria**: a checklist where each item ≈ 1 commit.
7. **Risks & open questions**: things that might go wrong.
8. **References**: prior PRs, related specs, external docs.

## Sizing

- 5–15 acceptance items is the sweet spot.
- > 20 items: split.
- < 3 items: probably a `chore`, skip the spec, just open a PR.

## Style

- Imperative, present-tense bullets.
- Concrete file paths, not vague references.
- "When …, then …" is great.
- Constrain *boundaries*, not *internals*.

## Lifecycle

```
[ created ] -> [ open ] -> [ in-progress ] -> [ closed ]
```

Closed specs stay in the repo forever.

## Anti-patterns

- ❌ "Improve performance" — unmeasurable.
- ❌ "Refactor X" with no specified target shape.
- ❌ Mixing infra + feature work.
- ❌ Acceptance items like "code review passes" — that's process, not product.
