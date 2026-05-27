#!/usr/bin/env bash
# Static test: verify workflow YAML files parse cleanly and use valid syntax.
#
# Uses yamllint if available; falls back to python3 yaml.safe_load if not.
# Either tool must pass for the test to succeed.
#
# Exit codes:
#   0   YAML is valid
#   1   YAML parse error
#   2   no YAML validation tool available
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

WORKFLOW=".github/workflows/nightly-real.yml"

echo "=== workflow-syntax-test ==="

if [[ ! -f "$WORKFLOW" ]]; then
	echo "FAIL: workflow file not found: $WORKFLOW"
	exit 1
fi

if command -v yamllint >/dev/null 2>&1; then
	echo "Using yamllint"
	# Relax line-length rule — GHA workflow lines can be long.
	if yamllint -d '{extends: relaxed, rules: {line-length: {max: 160}}}' "$WORKFLOW"; then
		echo "PASS: $WORKFLOW is valid YAML (yamllint)"
		exit 0
	else
		echo "FAIL: $WORKFLOW has YAML errors (yamllint)"
		exit 1
	fi
elif command -v python3 >/dev/null 2>&1; then
	echo "Using python3 yaml.safe_load"
	if python3 -c "import yaml, sys; yaml.safe_load(open('$WORKFLOW'))"; then
		echo "PASS: $WORKFLOW is valid YAML (python3)"
		exit 0
	else
		echo "FAIL: $WORKFLOW has YAML errors (python3)"
		exit 1
	fi
else
	echo "SKIP: no YAML validation tool available (install yamllint or python3+pyyaml)"
	exit 2
fi
