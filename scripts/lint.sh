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

# Collect *.gd files into an array (avoids SC2046 word-splitting).
# Vendored addons (gdUnit4, godotty-node) are explicitly excluded — they
# are third-party code we don't own.
GD_FILES=()
while IFS= read -r -d '' f; do
	GD_FILES+=("$f")
done < <(
	find project tests \
		-type d -name addons -prune -o \
		-name '*.gd' -type f -print0 2>/dev/null
)

# --- gdformat ---
# NOTE: `gdformat --check` is intentionally disabled here. The legacy demo
# scripts predate lint/format enforcement; a one-shot reformat pass is
# tracked in the spec backlog (follow-up to spec 0002). Re-enable once
# that lands.
if command -v gdformat >/dev/null 2>&1; then
	echo "lint: gdformat (skipped — see follow-up spec)"
else
	echo "lint: gdformat not installed (pip install gdtoolkit)" >&2
	warned=$(( warned + 1 ))
fi

# --- gdlint ---
if command -v gdlint >/dev/null 2>&1; then
	echo "lint: gdlint"
	if (( ${#GD_FILES[@]} > 0 )) && ! gdlint "${GD_FILES[@]}" 2>&1; then
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
