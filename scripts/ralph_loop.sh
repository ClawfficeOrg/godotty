#!/bin/sh
# ralph_loop — autonomous task loop for the Godotty repository.
#
# Usage:
#   ./scripts/ralph_loop.sh                    # loop through all open tasks
#   ./scripts/ralph_loop.sh 1.0.1              # single task
#   ./scripts/ralph_loop.sh --minutes=30       # loop for up to 30 minutes
#   ./scripts/ralph_loop.sh --hours=2          # loop for up to 2 hours
#   ./scripts/ralph_loop.sh --dry-run          # print what would be done
#   ./scripts/ralph_loop.sh --reset            # clear state files
#
# Models:
#   gpt-5-mini        — planning, self-review, commit messages (cheap)
#   claude-sonnet-4.6 — all GDScript / actual implementation (quality-critical)
#
# Stopping gracefully:
#   touch .ralph/state/STOP            # sentinel file
#   kill -TERM $(cat /tmp/ralph.pid)   # or SIGTERM the process
#   Ctrl-C
#
# Requires: copilot CLI logged in, git, a clean working tree.
# The human has given blanket commit+push permission while this runs.

set -e

REPO_ROOT="$(git -C "$(dirname "$0")" rev-parse --show-toplevel)"
SKILL="$REPO_ROOT/.ralph/PROMPT.md"
LOG="$REPO_ROOT/.ralph/state/loop.log"
CHEAP_MODEL="gpt-5-mini"
CODE_MODEL="claude-sonnet-4.6"
STOP_FILE="$REPO_ROOT/.ralph/state/STOP"

# ── colours ─────────────────────────────────────────────────────────────────
CYAN=$(tput setaf 6 2>/dev/null || true)
GREEN=$(tput setaf 2 2>/dev/null || true)
YELLOW=$(tput setaf 3 2>/dev/null || true)
RED=$(tput setaf 1 2>/dev/null || true)
RESET=$(tput sgr0 2>/dev/null || true)

log()  { printf '%s\n' "${CYAN}[ralph]${RESET} $*"; }
good() { printf '%s\n' "${GREEN}[ralph]${RESET} $*"; }
warn() { printf '%s\n' "${YELLOW}[ralph]${RESET} $*"; }
die()  { printf '%s\n' "${RED}[ralph]${RESET} $*" >&2; exit 1; }

# ── argument parsing ─────────────────────────────────────────────────────────
SINGLE_TASK=""
DURATION_SECS=0
DRY_RUN=0
RESET=0

for _arg in "$@"; do
    case "$_arg" in
        --minutes=*)
            _mins="${_arg#--minutes=}"
            case "$_mins" in ''|*[!0-9]*) die "--minutes requires a positive integer";; esac
            DURATION_SECS=$((DURATION_SECS + _mins * 60))
            ;;
        --hours=*)
            _hrs="${_arg#--hours=}"
            case "$_hrs" in ''|*[!0-9]*) die "--hours requires a positive integer";; esac
            DURATION_SECS=$((DURATION_SECS + _hrs * 3600))
            ;;
        --dry-run) DRY_RUN=1 ;;
        --reset)   RESET=1 ;;
        -h|--help)
            grep -E '^#( |$)' "$0" | sed 's/^# \{0,1\}//'
            exit 0
            ;;
        -*)
            die "Unknown flag: $_arg"
            ;;
        *)
            [ -z "$SINGLE_TASK" ] || die "Too many positional arguments — only one task id is allowed"
            SINGLE_TASK="$_arg"
            ;;
    esac
done

mkdir -p "$REPO_ROOT/.ralph/state"

if [ "$RESET" -eq 1 ]; then
    rm -f "$STOP_FILE" "$REPO_ROOT/.ralph/state/ITERATIONS" "$LOG"
    echo "ralph: state reset (specs and learnings preserved)"
    exit 0
fi

START_TIME="$(date +%s)"
if [ "$DURATION_SECS" -gt 0 ]; then
    DEADLINE=$((START_TIME + DURATION_SECS))
else
    DEADLINE=0
fi

# ── sanity checks ────────────────────────────────────────────────────────────
[ -f "$SKILL" ] || die "skill file missing: $SKILL"
command -v copilot >/dev/null 2>&1 || die "copilot CLI not found in PATH"

cd "$REPO_ROOT"

if ! git diff --quiet || ! git diff --cached --quiet; then
    die "working tree is dirty — commit or stash changes before running ralph"
fi

# ── PID + signal / sentinel stop ────────────────────────────────────────────
RALPH_PID_FILE="/tmp/ralph.pid"
STOP_SENTINEL="$STOP_FILE"
STOP_REQUESTED=0

printf '%d\n' $$ > "$RALPH_PID_FILE"
trap 'rm -f "$RALPH_PID_FILE"' EXIT
trap 'STOP_REQUESTED=1; warn "Stop signal received — will exit after the current task."' INT TERM

log "PID $$ written to $RALPH_PID_FILE"
log "To stop gracefully: kill -TERM \$(cat $RALPH_PID_FILE)  or  touch $STOP_FILE"

if [ "$DURATION_SECS" -gt 0 ]; then
    _human="$(( DURATION_SECS / 3600 ))h $(( (DURATION_SECS % 3600) / 60 ))m"
    log "Time limit: ${_human}"
fi

# ── helpers ──────────────────────────────────────────────────────────────────

all_todo_lines() {
    for _f in "$REPO_ROOT/docs"/todo-v*.md; do
        [ -f "$_f" ] && cat "$_f" || true
    done
}

# Usage: invoke_copilot "$PROMPT" [extra copilot args...]
invoke_copilot() {
    _prompt="$1"; shift
    _pf="$(mktemp)"
    printf '%s' "$_prompt" > "$_pf"
    cat "$_pf" | copilot "$@" 2>/dev/null
    rm -f "$_pf"
}

next_task() {
    all_todo_lines \
        | grep -m1 "^\- \[ \] \`[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\`" \
        | sed "s/^- \[ \] \`\([^\`]*\)\`.*/\1/" || true
}

task_block() {
    _tid="$1"
    all_todo_lines | awk -v tid="$_tid" '
        BEGIN { pat = "^- \\[.\\] `" tid "`" }
        $0 ~ pat      { found=1; print; next }
        found && /^- \[.\] `[0-9]/ { exit }
        found         { print }
    '
}

ralph_log() {
    mkdir -p "$(dirname "$LOG")"
    printf '\n## %s\n\n%s\n' "$(date '+%Y-%m-%d %H:%M')" "$1" >> "$LOG"
}

deadline_reached() {
    [ "$DEADLINE" -gt 0 ] && [ "$(date +%s)" -ge "$DEADLINE" ]
}

stop_requested() {
    [ "$STOP_REQUESTED" -eq 1 ] && return 0
    if [ -f "$STOP_SENTINEL" ]; then
        warn "Stop sentinel found — consuming it."
        rm -f "$STOP_SENTINEL"
        STOP_REQUESTED=1
        return 0
    fi
    return 1
}

# ── task execution ────────────────────────────────────────────────────────────
run_task() {
    TASK_ID="$1"
    TASK_BLOCK_TEXT="$(task_block "$TASK_ID")"
    SKILL_TEXT="$(cat "$SKILL")"
    AGENTS_TEXT="$(cat "$REPO_ROOT/AGENTS.md")"
    LEARNINGS_TEXT="$(cat "$REPO_ROOT/.ralph/learnings/INDEX.md" 2>/dev/null || true)"

    [ -n "$TASK_BLOCK_TEXT" ] || die "Task ${TASK_ID} not found in any docs/todo-v*.md"

    BRANCH="task-${TASK_ID}"

    # Create task branch off current HEAD
    git checkout -b "$BRANCH"
    git push -u origin "$BRANCH" 2>/dev/null || true

    # ── Step 1: gpt-5-mini produces a written plan ───────────────────────────
    log "Step 1/3 — planning with ${CHEAP_MODEL}"

    PLAN="$(invoke_copilot "You are an expert Godot 4.6 / GDScript engineer planning a task for the Godotty repository.
Read the skill file, AGENTS.md, and the task block carefully. Write a numbered
implementation plan. Do NOT write any code. Output plain text only.

TASK ID: ${TASK_ID}

TASK BLOCK:
${TASK_BLOCK_TEXT}

SKILL FILE (the Ralph process guide):
${SKILL_TEXT}

AGENTS.md (project constitution):
${AGENTS_TEXT}

LEARNINGS (known Godot/GdUnit4 gotchas):
${LEARNINGS_TEXT}

Produce:
1. A numbered list of files to create or edit (path + one-sentence purpose).
2. A numbered list of tests to write (name + what it proves).
3. Any blockers or Godot quirks to flag before coding starts." \
        --model "$CHEAP_MODEL" \
        --allow-all-tools --no-ask-user -s \
        --add-dir "$REPO_ROOT" 2>&1)"

    log "Plan ready."

    # ── Step 2: claude-sonnet-4.6 implements ────────────────────────────────
    log "Step 2/3 — implementing with ${CODE_MODEL}"

    invoke_copilot "You are Ralph, the autonomous task agent for the Godotty repository.
Implement task ${TASK_ID} in full, following every rule in the skill file and AGENTS.md below.
Write all GDScript files, then verify by running:
  bash scripts/lint.sh
  bash scripts/run_tests.sh tests/unit
Fix any lint or test failures until both pass clean.
Do not commit yet. When finished print exactly: IMPLEMENTATION_DONE

TASK ID: ${TASK_ID}

TASK BLOCK:
${TASK_BLOCK_TEXT}

PLAN:
${PLAN}

SKILL FILE:
${SKILL_TEXT}

AGENTS.md:
${AGENTS_TEXT}

LEARNINGS:
${LEARNINGS_TEXT}" \
        --model "$CODE_MODEL" \
        --allow-all \
        --no-ask-user \
        --add-dir "$REPO_ROOT" \
        2>&1 | tee /tmp/ralph-impl-"$TASK_ID".log

    # ── Step 3: gpt-5-mini self-reviews the diff ─────────────────────────────
    log "Step 3/3 — self-review with ${CHEAP_MODEL}"

    DIFF="$(git diff HEAD 2>&1 | head -600)"

    invoke_copilot "You are reviewing a GDScript implementation for the Godotty repository.
Work through the self-review checklist in the skill file.
For each item write PASS or FAIL and a one-line reason.
For any FAIL item: open the file and fix it now before printing REVIEW_DONE.
Do not skip any checklist item.

TASK ID: ${TASK_ID}

GIT DIFF (up to 600 lines):
${DIFF}

SKILL FILE (contains the checklist):
${SKILL_TEXT}

After fixing all failures print exactly: REVIEW_DONE" \
        --model "$CHEAP_MODEL" \
        --allow-all \
        --no-ask-user \
        --add-dir "$REPO_ROOT" \
        2>&1 | tee /tmp/ralph-review-"$TASK_ID".log

    # ── Commit with retry ────────────────────────────────────────────────────
    log "Committing task ${TASK_ID}"

    COMMIT_MSG="$(invoke_copilot "Write a git commit message for task ${TASK_ID} in the Godotty repository.
Format: first line is a Conventional Commit: type(scope): description (≤72 chars).
Then a blank line. Then one paragraph: what was done and why.
Output only the commit message text, no markdown fences.
Task: ${TASK_BLOCK_TEXT}" \
        --model "$CHEAP_MODEL" \
        --allow-all-tools --no-ask-user -s \
        --add-dir "$REPO_ROOT" 2>&1)"

    COMMIT_ATTEMPTS=0
    MAX_ATTEMPTS=3
    COMMIT_LOG_FILE="/tmp/ralph-commit-${TASK_ID}.log"

    while [ $COMMIT_ATTEMPTS -lt $MAX_ATTEMPTS ]; do
        COMMIT_ATTEMPTS=$((COMMIT_ATTEMPTS + 1))
        log "Commit attempt ${COMMIT_ATTEMPTS}/${MAX_ATTEMPTS}"

        git add -A
        if git commit -m "$COMMIT_MSG" >"$COMMIT_LOG_FILE" 2>&1; then
            cat "$COMMIT_LOG_FILE"
            good "Commit succeeded."
            break
        fi

        if grep -q "nothing to commit" "$COMMIT_LOG_FILE" 2>/dev/null; then
            cat "$COMMIT_LOG_FILE"
            good "Working tree already clean."
            break
        fi

        cat "$COMMIT_LOG_FILE"
        warn "Commit failed on attempt ${COMMIT_ATTEMPTS}."

        if [ $COMMIT_ATTEMPTS -eq $MAX_ATTEMPTS ]; then
            ralph_log "BLOCKED on task ${TASK_ID}: commit still failing after ${MAX_ATTEMPTS} attempts."
            git checkout master >/dev/null 2>&1
            git branch -D "$BRANCH" >/dev/null 2>&1 || true
            die "Giving up on ${TASK_ID} after ${MAX_ATTEMPTS} commit attempts."
        fi

        HOOK_OUT="$(cat "$COMMIT_LOG_FILE")"
        log "Asking ${CODE_MODEL} to fix failures…"
        invoke_copilot "The commit for task ${TASK_ID} in the Godotty repository failed.
Fix every failure shown below. Change only what is required to pass.
When done print exactly: FIXES_DONE

Failure output:
${HOOK_OUT}" \
            --model "$CODE_MODEL" \
            --allow-all \
            --no-ask-user \
            --add-dir "$REPO_ROOT" \
            2>&1 | tee /tmp/ralph-fix-"$TASK_ID"-"$COMMIT_ATTEMPTS".log
    done

    git push origin HEAD

    # Merge task branch back to master and delete it
    git checkout master
    git merge --no-ff "$BRANCH" -m "chore: merge task ${TASK_ID}"
    git push origin master
    git branch -d "$BRANCH"
    git push origin --delete "$BRANCH" 2>/dev/null || true

    good "Task ${TASK_ID} done and merged to master."
    ralph_log "DONE: task ${TASK_ID} committed and merged."
}

# ── main loop ────────────────────────────────────────────────────────────────
log "Starting Ralph Loop — models: cheap=${CHEAP_MODEL}  code=${CODE_MODEL}"

if [ "$DRY_RUN" -eq 1 ]; then
    NEXT="$(next_task)"
    if [ -n "$SINGLE_TASK" ]; then
        log "[dry-run] would run single task: $SINGLE_TASK"
    elif [ -n "$NEXT" ]; then
        log "[dry-run] next open task: $NEXT"
    else
        log "[dry-run] no open tasks found"
    fi
    exit 0
fi

if [ -n "$SINGLE_TASK" ]; then
    stop_requested && exit 0
    deadline_reached && { warn "Deadline reached before starting."; exit 0; }
    log "Single-task mode: ${SINGLE_TASK}"
    run_task "$SINGLE_TASK"
    exit 0
fi

# Multi-task loop
while true; do
    stop_requested && { log "Stopping gracefully."; exit 0; }
    deadline_reached && { warn "Time limit reached."; exit 0; }
    [ -f "$STOP_SENTINEL" ] && { log "STOP file found, exiting."; exit 0; }

    TASK="$(next_task)"
    if [ -z "$TASK" ]; then
        good "No open tasks remaining. Ralph is done."
        exit 0
    fi

    log "Next task: ${TASK}"
    run_task "$TASK"

    stop_requested && { log "Stopping gracefully after task."; exit 0; }
    deadline_reached && { warn "Time limit reached after task."; exit 0; }
done
