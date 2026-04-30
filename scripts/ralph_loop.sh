#!/usr/bin/env bash
# Ralph Loop driver — runs the agent in a loop until done, stopped, or stuck.
#
# Usage:
#   scripts/ralph_loop.sh                 # default: up to 20 iterations
#   scripts/ralph_loop.sh --max-iter 5    # 5 iterations
#   scripts/ralph_loop.sh --dry-run       # print what would be done
#   scripts/ralph_loop.sh --reset         # clear state files (NOT specs/learnings)
#
# Env:
#   RALPH_AGENT_CMD   Command that invokes the agent. Default: "claude"
#                     The command receives PROMPT.md on stdin and runs in repo root.
#   RALPH_LOG         Log file. Default: .ralph/state/loop.log
#
# The driver itself does NOT run tests, lint, or commit. The agent does.
# This keeps the verify step honest — the agent must run, check, and commit.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

MAX_ITER="${RALPH_MAX_ITER:-20}"
DRY_RUN=0
RESET=0
AGENT_CMD="${RALPH_AGENT_CMD:-claude}"
LOG="${RALPH_LOG:-.ralph/state/loop.log}"
STOP_FILE=".ralph/state/STOP"
ITER_FILE=".ralph/state/ITERATIONS"
PROMPT_FILE=".ralph/PROMPT.md"

while [[ $# -gt 0 ]]; do
	case "$1" in
		--max-iter)   MAX_ITER="$2"; shift 2 ;;
		--max-iter=*) MAX_ITER="${1#*=}"; shift ;;
		--dry-run)    DRY_RUN=1; shift ;;
		--reset)      RESET=1; shift ;;
		-h|--help)
			grep -E '^#( |$)' "$0" | sed 's/^# \{0,1\}//'
			exit 0
			;;
		*)
			echo "unknown arg: $1" >&2; exit 2 ;;
	esac
done

mkdir -p ".ralph/state"

if [[ "$RESET" == 1 ]]; then
	rm -f "$STOP_FILE" "$ITER_FILE" "$LOG"
	echo "ralph: state reset (specs and learnings preserved)"
	exit 0
fi

if [[ ! -f "$PROMPT_FILE" ]]; then
	echo "ralph: missing $PROMPT_FILE — bootstrap incomplete" >&2
	exit 1
fi

# --- helpers ---
log() { printf '[ralph %s] %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$*" | tee -a "$LOG" >&2; }

# --- main loop ---
iter=0
consecutive_failures=0

while (( iter < MAX_ITER )); do
	iter=$(( iter + 1 ))
	echo "$iter" > "$ITER_FILE"

	if [[ -f "$STOP_FILE" ]]; then
		log "STOP file present, exiting at iteration $iter"
		exit 0
	fi

	log "iteration $iter / $MAX_ITER"

	if [[ "$DRY_RUN" == 1 ]]; then
		log "[dry-run] would invoke: $AGENT_CMD < $PROMPT_FILE"
		continue
	fi

	# Snapshot HEAD before the agent runs so we can detect "no progress".
	pre_sha="$(git rev-parse HEAD)"

	# Invoke the agent. The agent reads PROMPT.md from stdin; cwd is repo root.
	# We tee the agent's output to the log for forensics.
	if ! "$AGENT_CMD" < "$PROMPT_FILE" 2>&1 | tee -a "$LOG"; then
		log "agent invocation returned non-zero"
		consecutive_failures=$(( consecutive_failures + 1 ))
	fi

	post_sha="$(git rev-parse HEAD)"

	if [[ "$pre_sha" == "$post_sha" ]]; then
		log "no commits this iteration — possibly stuck"
		consecutive_failures=$(( consecutive_failures + 1 ))
	else
		log "progress: $pre_sha..$post_sha"
		consecutive_failures=0
	fi

	if (( consecutive_failures >= 2 )); then
		log "two consecutive failures — touching STOP and exiting"
		echo "two consecutive failures at $(date -u +%Y-%m-%dT%H:%M:%SZ)" > "$STOP_FILE"
		exit 3
	fi
done

log "max iterations ($MAX_ITER) reached"
