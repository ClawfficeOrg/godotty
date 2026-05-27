#!/usr/bin/env bash
# cut-rc.sh — prepare a release-candidate branch/tag for godotty v3.0.0.
#
# Usage:
#   scripts/cut-rc.sh [RC_NUM]       # default RC_NUM=1
#
# What it does:
#   1. Verifies the working tree is clean.
#   2. Runs lint + unit tests to confirm green.
#   3. Creates a branch  release/v3.0.0-rc<N>  from current HEAD.
#   4. Prints the manual review checklist.
#
# It does NOT push or create a tag — the maintainer does that after review.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

RC_NUM="${1:-1}"
BRANCH="release/v3.0.0-rc${RC_NUM}"
TAG="v3.0.0-rc${RC_NUM}"

# ── 1. Clean working tree ────────────────────────────────────────────────────
if [[ -n "$(git status --porcelain)" ]]; then
	echo "cut-rc: ERROR — working tree is not clean. Commit or stash first." >&2
	exit 1
fi

echo "cut-rc: working tree clean ✓"

# ── 2. Lint ─────────────────────────────────────────────────────────────────
echo "cut-rc: running lint..."
if ! bash scripts/lint.sh; then
	echo "cut-rc: ERROR — lint failed. Fix before cutting RC." >&2
	exit 1
fi

# ── 3. Unit tests ────────────────────────────────────────────────────────────
echo "cut-rc: running unit tests..."
if ! bash scripts/run_tests.sh tests/unit; then
	echo "cut-rc: ERROR — unit tests failed. Fix before cutting RC." >&2
	exit 1
fi

# ── 4. Create RC branch ──────────────────────────────────────────────────────
if git rev-parse --verify "$BRANCH" >/dev/null 2>&1; then
	echo "cut-rc: branch $BRANCH already exists — skipping creation."
else
	git checkout -b "$BRANCH"
	echo "cut-rc: created branch $BRANCH ✓"
fi

# ── 5. Print checklist ───────────────────────────────────────────────────────
cat <<EOF

════════════════════════════════════════════════════════
  godotty v3.0.0-rc${RC_NUM} — multi-model review checklist
════════════════════════════════════════════════════════

Branch : $BRANCH
Tag    : $TAG  (create manually after review)

AUTOMATED GATES (already passed):
  [x] bash scripts/lint.sh      — clean
  [x] bash scripts/run_tests.sh tests/unit — all green

RELEASE GATE (manual verification needed):
  [ ] Open 3 tabs (Ctrl+T × 3).
  [ ] Run a different command in each tab (e.g. echo, ls, pwd).
  [ ] Confirm output is independent — no cross-tab bleed.
  [ ] Close the middle tab (Ctrl+W).
  [ ] Confirm remaining tabs continue operating normally.
  [ ] Ctrl+Tab cycles between remaining tabs.
  [ ] Tab title updates via OSC 0/2 (echo -e '\033]0;My Tab\007').

MULTI-MODEL REVIEW:
  See .github/skills/review/multi-model-checklist.md for the
  dual-review process (Claude code review + GPT-5 architecture review).

AFTER REVIEW APPROVAL:
  git tag -a $TAG -m "Release candidate ${RC_NUM} for v3.0.0"
  git push origin $BRANCH $TAG

════════════════════════════════════════════════════════
EOF
