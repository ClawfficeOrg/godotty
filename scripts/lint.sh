#!/usr/bin/env bash
# Lint godotty's GDScript and shell.
#
# Tools (best-effort; missing tools are warned about, not fatal in CI):
#   - gdformat --check   (from gdtoolkit)
#   - gdlint              (from gdtoolkit)
#   - shellcheck          (for scripts/*.sh)
#
# Exit codes:
#   0   clean (or tools missing in CI)
#   1   lint errors
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

errors=0
warned=0

# --- gdformat ---
if command -v gdformat >/dev/null 2>&1; then
	echo "lint: gdformat --check"
	if ! gdformat --check $(find project tests -name '*.gd' -type f 2>/dev/null) 2>&1; then
		errors=$(( errors + 1 ))
	fi
else
	echo "lint: gdformat not installed (pip install gdtoolkit)" >&2
	warned=$(( warned + 1 ))
fi

# --- gdlint ---
if command -v gdlint >/dev/null 2>&1; then
	echo "lint: gdlint"
	if ! gdlint $(find project tests -name '*.gd' -type f 2>/dev/null) 2>&1; then
		errors=$(( errors + 1 ))
	fi
else
	echo "lint: gdlint not installed (pip install gdtoolkit)" >&2
	warned=$(( warned + 1 ))
fi

# --- shellcheck ---
if command -v shellcheck >/dev/null 2>&1; then
	echo "lint: shellcheck"
	if ! shellcheck scripts/*.sh 2>&1; then
		errors=$(( errors + 1 ))
	fi
else
	echo "lint: shellcheck not installed" >&2
	warned=$(( warned + 1 ))
fi

if (( errors > 0 )); then
	echo "lint: FAIL ($errors tool(s) reported errors)"
	exit 1
fi

if (( warned > 0 )) && [[ "${CI:-}" != "true" ]]; then
	echo "lint: $warned tool(s) missing — install gdtoolkit + shellcheck for full coverage"
fi

echo "lint: clean"
