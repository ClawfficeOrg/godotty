#!/usr/bin/env bash
# Bump the pinned godotty-node ref in nightly-real.yml.
#
# Usage:
#   scripts/bump_godotty_node_ref.sh <new-ref>
#
# <new-ref> must be a full 40-character SHA, a tag, or a branch name
# from ClawfficeOrg/godotty-node.
#
# What it does:
#   1. Validates the new ref is non-empty.
#   2. Edits the GODOTTY_NODE_REF value in both:
#        .github/workflows/nightly-real.yml   (workflow env block)
#        scripts/install_godotty_node.sh      (fallback default)
#   3. Prints the diff for review (does NOT commit or push).
#
# Manual bump procedure (one-line):
#   bash scripts/bump_godotty_node_ref.sh <new-ref>
#   git add .github/workflows/nightly-real.yml scripts/install_godotty_node.sh
#   git commit -m "chore(ci): bump godotty-node ref to <new-ref>"
#   git push
#
# Verification after pushing:
#   1. Go to Actions → "Nightly Real-mode CI" → Run workflow.
#   2. Check the "Resolve godotty-node ref" step in the run log; it must
#      print: "Using godotty-node ref: <new-ref>".
#   3. Confirm the build-and-test job completes green.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

WORKFLOW_FILE=".github/workflows/nightly-real.yml"
INSTALL_SCRIPT="scripts/install_godotty_node.sh"

# ── Validate argument ──────────────────────────────────────────────────────────
if [[ $# -ne 1 ]] || [[ -z "${1:-}" ]]; then
	echo "Usage: $0 <new-ref>" >&2
	echo "  <new-ref>: SHA, tag, or branch name from ClawfficeOrg/godotty-node" >&2
	exit 1
fi

NEW_REF="$1"

# Reject refs that look like they could cause shell injection (must be
# alphanumeric, dashes, underscores, dots, forward slashes, or @).
if ! [[ "$NEW_REF" =~ ^[A-Za-z0-9_./@-]+$ ]]; then
	echo "bump_godotty_node_ref: invalid ref format: $NEW_REF" >&2
	exit 1
fi

# ── Extract the current ref from the workflow ──────────────────────────────────
if [[ ! -f "$WORKFLOW_FILE" ]]; then
	echo "bump_godotty_node_ref: workflow file not found: $WORKFLOW_FILE" >&2
	exit 1
fi

OLD_REF="$(awk -F'\"' '/GODOTTY_NODE_REF/ {print $2; exit}' "$WORKFLOW_FILE")"

if [[ -z "$OLD_REF" ]]; then
	echo "bump_godotty_node_ref: could not find GODOTTY_NODE_REF in $WORKFLOW_FILE" >&2
	exit 1
fi

if [[ "$OLD_REF" == "$NEW_REF" ]]; then
	echo "bump_godotty_node_ref: already pinned to $NEW_REF — nothing to do"
	exit 0
fi

echo "bump_godotty_node_ref: $OLD_REF  →  $NEW_REF"

# ── Patch nightly-real.yml ─────────────────────────────────────────────────────
# Replace only the workflow env block line (indented, quoted value).
sed -i.bak \
	"s|  GODOTTY_NODE_REF: \"${OLD_REF}\"|  GODOTTY_NODE_REF: \"${NEW_REF}\"|" \
	"$WORKFLOW_FILE"
rm -f "${WORKFLOW_FILE}.bak"

# ── Patch install_godotty_node.sh fallback default ───────────────────────────
if [[ -f "$INSTALL_SCRIPT" ]]; then
	sed -i.bak \
		"s|GODOTTY_NODE_REF:-${OLD_REF}|GODOTTY_NODE_REF:-${NEW_REF}|" \
		"$INSTALL_SCRIPT"
	rm -f "${INSTALL_SCRIPT}.bak"
fi

# ── Show diff ──────────────────────────────────────────────────────────────────
echo ""
echo "--- diff ---"
git --no-pager diff -- "$WORKFLOW_FILE" "$INSTALL_SCRIPT" || true
echo "--- end diff ---"
echo ""
echo "Review the diff above, then:"
echo "  git add $WORKFLOW_FILE $INSTALL_SCRIPT"
echo "  git commit -m \"chore(ci): bump godotty-node ref to ${NEW_REF}\""
echo "  git push"
