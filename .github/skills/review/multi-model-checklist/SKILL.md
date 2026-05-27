---
name: multi-model-review
description: >
  How to run the dual-model review pass for godotty PRs and RC cuts.
  Claude handles code correctness; GPT-5 handles architecture and idiom.
when_to_use: >
  When opening a PR that touches autoloads, the GDExtension boundary, or
  any user-visible feature. Always run for RC cuts.
---

# Multi-Model Review Checklist

## Model Assignments

| Concern | Model | What to look for |
|---------|-------|-----------------|
| Code correctness, GDScript idioms, test coverage, AGENTS.md compliance | **Claude Sonnet 4.6** | Off-by-one, unhandled edge cases, missing disconnect, lint violations |
| Architectural drift, subtle logic bugs, API design | **GPT-5** | Boundary leaks, signal misuse, naming consistency, pre-1.0 API stability |

## PR Review Workflow

1. **Claude code-review pass** (`.github/workflows/dual-review.yml`)
   - Runs automatically on every PR via CI.
   - Checks: tests green, lint clean, CHANGELOG updated, tests-for-feature present.
   - Posts a review comment with a pass/fail summary.

2. **GPT-5 architecture pass** (`.github/agents/gpt5_reviewer.py`)
   - Triggered manually or via workflow dispatch for RC PRs.
   - Focus: does the change respect `AGENTS.md §9` Hard Stops?
     Does it widen or narrow the `TerminalManager` public surface?

3. **Human sign-off** (maintainer @hippo)
   - Required for anything user-visible or touching autoloads / CI.
   - For purely internal changes (refactor, test, docs) the agent may
     self-merge if both model passes are clean.

## RC-Specific Checklist

Before tagging an RC:

- [ ] `bash scripts/lint.sh` exits 0.
- [ ] `bash scripts/run_tests.sh tests/unit` exits 0, all green.
- [ ] `CHANGELOG.md` has an `[Unreleased]` entry for every merged task.
- [ ] `docs/todo-v3.md` marks all Phase 3.0.x tasks `[x]`.
- [ ] Release gate verified manually (see `scripts/cut-rc.sh` output).
- [ ] Claude review comment on the RC PR is "✅ all checks pass".
- [ ] GPT-5 review comment on the RC PR is "✅ no architectural concerns".
- [ ] @hippo has approved the PR.

## Release Gate for v3.0.0

Open three tabs, run different commands in each, close the middle tab.
Tabs must be fully independent. Ctrl+Tab must cycle.

Detailed steps:
1. Launch godotty. Press Ctrl+T twice to open two more tabs (3 total).
2. In tab 1 run: `echo hello_tab1` — confirm output stays in tab 1.
3. Switch to tab 2 (Ctrl+Tab). Run: `pwd` — confirm output stays in tab 2.
4. Switch to tab 3 (Ctrl+Tab). Run: `ls` — confirm output stays in tab 3.
5. Switch back to tab 2. Press Ctrl+W to close it.
6. Confirm tab 1 and tab 3 still display their prior output unchanged.
7. Press Ctrl+Tab — confirm focus moves between tab 1 and tab 3.
8. In tab 1 run: `echo -e '\033]0;My Shell\007'` — confirm tab title updates.
