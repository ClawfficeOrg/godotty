#!/usr/bin/env bash
# Static test: verify nightly-real.yml pins GODOTTY_NODE_REF as a
# workflow-level env var and that install_godotty_node.sh uses it.
#
# Exit codes:
#   0   all assertions pass
#   1   one or more assertions failed
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

WORKFLOW=".github/workflows/nightly-real.yml"
INSTALL_SCRIPT="scripts/install_godotty_node.sh"
PASS=0
FAIL=0

assert() {
	local desc="$1"
	local result="$2"
	if [[ "$result" == "0" ]]; then
		echo "  PASS: $desc"
		PASS=$(( PASS + 1 ))
	else
		echo "  FAIL: $desc"
		FAIL=$(( FAIL + 1 ))
	fi
}

echo "=== workflow_contains_ref_test ==="

# 1. Workflow file exists.
[[ -f "$WORKFLOW" ]] && r=0 || r=1
assert "workflow file exists" "$r"

# 2. GODOTTY_NODE_REF is declared at workflow env scope (indented under 'env:').
grep -qE '^env:' "$WORKFLOW" && r=0 || r=1
assert "workflow has a top-level 'env:' block" "$r"

grep -qE '^[[:space:]]{2}GODOTTY_NODE_REF:' "$WORKFLOW" && r=0 || r=1
assert "GODOTTY_NODE_REF is declared in the workflow env block (2-space indent)" "$r"

# 3. The value is a non-empty quoted string (SHA, tag, or branch).
grep -qE '^[[:space:]]{2}GODOTTY_NODE_REF:[[:space:]]*"[A-Za-z0-9_./@-]+"' "$WORKFLOW" && r=0 || r=1
assert "GODOTTY_NODE_REF value is non-empty and safe (no shell-injection chars)" "$r"

# 4. install_godotty_node.sh consumes GODOTTY_NODE_REF (not a hard-coded literal clone URL + ref).
[[ -f "$INSTALL_SCRIPT" ]] && r=0 || r=1
assert "install_godotty_node.sh exists" "$r"

grep -qE 'GODOTTY_NODE_REF' "$INSTALL_SCRIPT" && r=0 || r=1
assert "install_godotty_node.sh references GODOTTY_NODE_REF" "$r"

# 5. The workflow has a step that logs the resolved ref (traceability).
grep -qE 'Using godotty-node ref' "$WORKFLOW" && r=0 || r=1
assert "workflow has a logging step that prints the resolved ref" "$r"

# 6. The workflow_dispatch input allows overriding the ref at run time.
grep -qE 'godotty_node_ref' "$WORKFLOW" && r=0 || r=1
assert "workflow_dispatch has godotty_node_ref input for per-run override" "$r"

# 7. The ref in the workflow and the fallback default in install_godotty_node.sh match.
wf_ref="$(grep -E '^\s{2}GODOTTY_NODE_REF:\s*"' "$WORKFLOW" | \
	sed 's/.*GODOTTY_NODE_REF:[ \t]*"\([^"]*\)".*/\1/')"
sh_ref="$(grep -oE 'GODOTTY_NODE_REF:-[A-Za-z0-9_./@-]+' "$INSTALL_SCRIPT" | \
	sed 's/GODOTTY_NODE_REF:-//')"

# Robust extraction (portable grep/awk): prefer awk for quoted string extraction
wf_ref="$(awk -F'\"' '/GODOTTY_NODE_REF/ {print $2; exit}' "$WORKFLOW")"

if [[ "$wf_ref" == "$sh_ref" ]]; then r=0; else r=1; fi
assert "GODOTTY_NODE_REF in workflow ($wf_ref) matches fallback in install script ($sh_ref)" "$r"

# 8. scripts/bump_godotty_node_ref.sh exists (documents the bump procedure).
[[ -f "scripts/bump_godotty_node_ref.sh" ]] && r=0 || r=1
assert "scripts/bump_godotty_node_ref.sh exists" "$r"

echo ""
echo "Results: ${PASS} passed, ${FAIL} failed"

if (( FAIL > 0 )); then
	exit 1
fi
