---
name: branching-and-prs
description: When to branch, how to name, when to merge
when_to_use: Before opening a PR or starting a new spec
---

# Branching & PRs — godotty

## Branch names

`<type>/<short-slug>` — type matches the dominant Conventional-Commits type
of the spec.

- `feature/<slug>` — new behavior (`feat`).
- `fix/<slug>` — bug fixes.
- `refactor/<slug>` — internal cleanup.
- `docs/<slug>` — docs-only.
- `infra/<slug>` — CI, scripts, ralph machinery.
- `release/<vX.Y.Z>` — release-cut branches.

## One spec, one branch

Each `.ralph/specs/NNNN-*.md` gets exactly one branch.

## Pull requests

PR title = the would-be merge commit subject (Conventional Commits format).
PR body must include:

- `Closes #N` (the spec issue, if any).
- `Spec: .ralph/specs/NNNN-<slug>.md`.
- A `## Acceptance` checklist mirroring the spec's.
- A `## Test evidence` section with actual `scripts/run_tests.sh` output.
  No paraphrasing.
- A `## Risks` section.

## Merge strategy

- **Merge commit** for spec-completing PRs (preserves per-iteration history).
- **Squash** for trivial single-commit fixes.
- **Never** rebase-merge a spec PR.

## Self-merge rules

A PR may be self-merged by the agent **only** if all of:

1. CI green.
2. Both Claude review and GPT-5 review post `LGTM`.
3. The change is purely internal (no public API change, no new autoload,
   no CI/release infra change, no user-visible behavior).

Otherwise: leave it for hippo.

## Cleaning up

After merge:

1. `gh pr merge --delete-branch`.
2. Local cleanup if needed.
