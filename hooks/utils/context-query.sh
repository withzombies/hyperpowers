#!/usr/bin/env bash
set -euo pipefail

CONTEXT_DIR="$(dirname "$0")/../context"
LOG_FILE="$CONTEXT_DIR/edit-log.txt"

# Get files edited since timestamp
get_recent_edits() {
    local since="${1:-}"

    if [ ! -f "$LOG_FILE" ]; then
        return 0
    fi

    if [ -z "$since" ]; then
        cat "$LOG_FILE" 2>/dev/null || true
    else
        awk -v since="$since" -F '|' '$1 >= since' "$LOG_FILE" 2>/dev/null || true
    fi
}

# Get unique files edited in current session
get_session_files() {
    local session_start="${1:-}"

    get_recent_edits "$session_start" | \
        awk -F '|' '{gsub(/^[ \t]+|[ \t]+$/, "", $4); print $4}' | \
        sort -u
}

# Check if specific file was edited
was_file_edited() {
    local file_path="$1"
    local since="${2:-}"

    get_recent_edits "$since" | grep -q "$(printf '%q' "$file_path")" 2>/dev/null
}

# Get edit count by repo
get_repo_stats() {
    local since="${1:-}"

    get_recent_edits "$since" | \
        awk -F '|' '{gsub(/^[ \t]+|[ \t]+$/, "", $2); print $2}' | \
        sort | uniq -c | sort -rn
}

# Clear log (for testing)
clear_log() {
    if [ -f "$LOG_FILE" ]; then
        > "$LOG_FILE"
    fi
}
