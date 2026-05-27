#!/usr/bin/env bash
# Run the godotty test suite (GdUnit4, headless).
#
# Usage:
#   scripts/run_tests.sh                    # all tests
#   scripts/run_tests.sh tests/unit         # subset
#   scripts/run_tests.sh tests/unit/foo.gd  # single file
#
# Env:
#   GODOT          Path to Godot 4 binary. Default: godot4 (then godot)
#   PROJECT_DIR    Project directory. Default: project
#   GDUNIT4_PATH   Path to GdUnit4 addon. Default: project/addons/gdUnit4
#
# Exit codes:
#   0   all tests pass
#   1   tests failed
#   2   misconfiguration (no godot, no gdunit, etc.)
#   100 GdUnit4 reported test failures (mapped from CmdTool exit code)
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

GODOT="${GODOT:-}"
PROJECT_DIR="${PROJECT_DIR:-project}"
GDUNIT4_PATH="${GDUNIT4_PATH:-${PROJECT_DIR}/addons/gdUnit4}"

# Locate Godot
if [[ -z "$GODOT" ]]; then
	for cand in godot4 godot Godot4 Godot; do
		if command -v "$cand" >/dev/null 2>&1; then
			GODOT="$cand"
			break
		fi
	done
fi

if [[ -z "$GODOT" ]] || ! command -v "$GODOT" >/dev/null 2>&1; then
	echo "run_tests: cannot find Godot 4 binary. Set \$GODOT or install godot4." >&2
	# Soft-success in CI when Godot isn't installed yet (spec 0001 tolerates this).
	if [[ "${CI:-}" == "true" ]]; then
		echo "run_tests: CI=true and no godot — emitting NO-OP success."
		exit 0
	fi
	exit 2
fi

if [[ ! -d "$GDUNIT4_PATH" ]]; then
	echo "run_tests: GdUnit4 not installed at $GDUNIT4_PATH"
	echo "           run scripts/install_gdunit4.sh (spec 0002), or set GDUNIT4_PATH"
	if [[ ! -d "tests" ]] || [[ -z "$(find tests -name '*_test.gd' -type f 2>/dev/null)" ]]; then
		echo "run_tests: no tests configured yet — emitting NO-OP success (spec 0001)."
		exit 0
	fi
	exit 2
fi

# Cold-start import (Godot's first-time UID generation)
"$GODOT" --headless --path "$PROJECT_DIR" --import >/dev/null 2>&1 || true

# Build target list
TARGETS=("$@")
if (( ${#TARGETS[@]} == 0 )); then
	TARGETS=("tests")
fi

# GdUnit4 expects -a for "add tests", -c for "continue on failure", -rd for results dir.
RESULTS_DIR="${RESULTS_DIR:-build/test-results}"
mkdir -p "$RESULTS_DIR"

# Map test paths into the project's view: GdUnit4 wants project-relative paths,
# but we put tests/ at the repo root. Symlink trick:
LINK="$PROJECT_DIR/tests"
if [[ ! -e "$LINK" ]]; then
	ln -s "../tests" "$LINK"
fi

set +e
"$GODOT" --headless --path "$PROJECT_DIR" \
	-s "addons/gdUnit4/bin/GdUnitCmdTool.gd" \
	-a "${TARGETS[@]}" \
	-rd "../$RESULTS_DIR"
rc=$?
set -e

case "$rc" in
	0)   echo "run_tests: ALL GREEN"; exit 0 ;;
	100) echo "run_tests: TESTS FAILED (GdUnit4 exit 100)"; exit 1 ;;
	*)   echo "run_tests: Godot exit $rc"; exit "$rc" ;;
esac
