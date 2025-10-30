#!/usr/bin/env bash
set -euo pipefail

# Configuration
CONTEXT_DIR="$(dirname "$0")/../context"
LOG_FILE="$CONTEXT_DIR/edit-log.txt"
LOCK_FILE="$CONTEXT_DIR/.edit-log.lock"
MAX_LOG_LINES=1000
LOCK_TIMEOUT=5

# Create context dir and log if doesn't exist
mkdir -p "$CONTEXT_DIR"
touch "$LOG_FILE"

# Acquire lock with timeout
acquire_lock() {
    local count=0
    while [ $count -lt $LOCK_TIMEOUT ]; do
        if mkdir "$LOCK_FILE" 2>/dev/null; then
            return 0
        fi
        sleep 0.2
        count=$((count + 1))
    done
    # Log but don't fail - non-blocking requirement
    echo "Warning: Could not acquire lock" >&2
    return 1
}

# Release lock
release_lock() {
    rmdir "$LOCK_FILE" 2>/dev/null || true
}

# Clean up lock on exit
trap release_lock EXIT

# Function to log edit
log_edit() {
    local file_path="$1"
    local tool_name="$2"
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    local repo=$(find_repo "$file_path")

    if acquire_lock; then
        echo "$timestamp | $repo | $tool_name | $file_path" >> "$LOG_FILE"
        release_lock
    fi
}

# Function to find repo root
find_repo() {
    local file_path="$1"
    if [ -z "$file_path" ] || [ "$file_path" = "null" ]; then
        echo "unknown"
        return
    fi

    local dir
    dir=$(dirname "$file_path" 2>/dev/null || echo "/")
    while [ "$dir" != "/" ] && [ -n "$dir" ]; do
        if [ -d "$dir/.git" ]; then
            basename "$dir"
            return
        fi
        dir=$(dirname "$dir" 2>/dev/null || echo "/")
    done
    echo "unknown"
}

# Read tool use event from stdin (with timeout to prevent hanging)
if ! read -t 2 -r tool_use_json; then
    echo '{"decision": "approve"}'
    exit 0
fi

# Validate JSON to prevent injection
if ! echo "$tool_use_json" | jq empty 2>/dev/null; then
    echo '{"decision": "approve"}'
    exit 0
fi

# Extract tool name and file path from tool use
tool_name=$(echo "$tool_use_json" | jq -r '.tool.name // .tool_name // "unknown"' 2>/dev/null || echo "unknown")
file_path=""

case "$tool_name" in
    "Edit"|"Write")
        file_path=$(echo "$tool_use_json" | jq -r '.tool.input.file_path // .tool_input.file_path // "null"' 2>/dev/null || echo "null")
        ;;
    "MultiEdit")
        # MultiEdit has multiple files - log each
        echo "$tool_use_json" | jq -r '.tool.input.edits[]?.file_path // .tool_input.edits[]?.file_path // empty' 2>/dev/null | while read -r path; do
            if [ -n "$path" ] && [ "$path" != "null" ]; then
                log_edit "$path" "$tool_name"
            fi
        done
        echo '{"decision": "approve"}'
        exit 0
        ;;
esac

# Log single edit
if [ -n "$file_path" ] && [ "$file_path" != "null" ]; then
    log_edit "$file_path" "$tool_name"
fi

# Rotate log if too large (with lock)
if acquire_lock; then
    line_count=$(wc -l < "$LOG_FILE" 2>/dev/null || echo "0")
    if [ "$line_count" -gt "$MAX_LOG_LINES" ]; then
        tail -n "$MAX_LOG_LINES" "$LOG_FILE" > "$LOG_FILE.tmp"
        mv "$LOG_FILE.tmp" "$LOG_FILE"
    fi
    release_lock
fi

# Return success (non-blocking)
echo '{"decision": "approve"}'
