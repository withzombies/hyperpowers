# bd-5 Quick Reference: PostToolUse Hook Context Tracker

## What is PostToolUse Hook?

**Timing:** Fires AFTER each tool execution (Edit, Write, Read, Bash, Grep)
**Input:** JSON via stdin with tool_name and tool_input
**Output:** Optional decision (allow/deny/continue) or exit 0

---

## Complete Working Example (Ready to Use)

**Source:** `/Users/ryan/src/hyper/skills/building-hooks/resources/hook-examples.md` (lines 5-92)

```bash
#!/bin/bash
LOG_FILE="$HOME/.claude/edit-log.txt"

# Function to find repo root
find_repo() {
    local dir=$(dirname "$1")
    while [ "$dir" != "/" ]; do
        if [ -d "$dir/.git" ]; then
            basename "$dir"
            return
        fi
        dir=$(dirname "$dir")
    done
    echo "unknown"
}

# Function to log edit
log_edit() {
    local file_path="$1"
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    local repo=$(find_repo "$file_path")
    echo "$timestamp | $repo | $file_path" >> "$LOG_FILE"
}

# Read tool use event from stdin
read -r tool_use_json
tool_name=$(echo "$tool_use_json" | jq -r '.tool.name')
file_path=""

case "$tool_name" in
    "Edit"|"Write")
        file_path=$(echo "$tool_use_json" | jq -r '.tool.input.file_path')
        ;;
    "MultiEdit")
        echo "$tool_use_json" | jq -r '.tool.input.edits[].file_path' | while read -r path; do
            log_edit "$path"
        done
        exit 0
        ;;
esac

# Log single edit
if [ -n "$file_path" ] && [ "$file_path" != "null" ]; then
    log_edit "$file_path"
fi

# Rotate log if too large
line_count=$(wc -l < "$LOG_FILE")
if [ "$line_count" -gt 1000 ]; then
    tail -n 1000 "$LOG_FILE" > "$LOG_FILE.tmp"
    mv "$LOG_FILE.tmp" "$LOG_FILE"
fi

exit 0
```

---

## Tool Input Format (What You Receive)

```python
# From stdin as JSON:
{
    "tool_name": "Edit",      # "Edit", "Write", "Read", "Bash", "Grep", etc.
    "tool_input": {
        "file_path": "/path/to/file.ts",
        # Other tool-specific params
    }
}
```

**For different tools:**
- Read/Grep: Use `tool_input.path` or `tool_input.file_path`
- Edit/Write: Use `tool_input.file_path`
- MultiEdit: Use `tool_input.edits[].file_path`
- Bash: Use `tool_input.command`

---

## Log Output Format

```
2025-10-30 15:30:45 | hyper | /Users/ryan/src/hyper/skills/test.md
2025-10-30 15:31:12 | hyper | /Users/ryan/src/hyper/hooks/hook.sh
2025-10-30 15:32:00 | project2 | /Users/ryan/project2/src/main.py
```

Columns: `timestamp | repo | file_path`

---

## Hook Registration (hooks.json)

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PLUGIN_ROOT}/hooks/track-edits.sh"
          }
        ]
      }
    ]
  }
}
```

---

## Context Sharing Pattern

**Hook 1 (PostToolUse) writes:**
```bash
~/.claude/context/edits.jsonl
~/.claude/context/session-state.json
```

**Hook 2 (Stop) reads:**
```bash
#!/bin/bash
if [ -f ~/.claude/context/edits.jsonl ]; then
    tail -20 ~/.claude/context/edits.jsonl | jq -r '.file_path'
fi
```

---

## Clarifications Needed for Full Implementation

1. **Which tools to track?**
   - Edit, Write (definitely)
   - Read, Bash, Grep? (optional)

2. **What context to track?**
   - File path (yes)
   - Timestamp (yes)
   - Repo name (yes)
   - Tool name (yes)
   - Operation status (success/failure)? (optional)

3. **Where to store?**
   - `~/.claude/edit-log.txt` (simple, proven)
   - `~/.claude/context/edits.jsonl` (structured)
   - Both (complementary)

4. **Integration points?**
   - Stop hook reminders (bd-6)
   - Test suite selection
   - Verification context
   - Other?

---

## Key Files to Reference

| Purpose | File | Lines |
|---------|------|-------|
| Complete example | hook-examples.md | 5-92 |
| Hook patterns | hook-patterns.md | 528-563 (coordination) |
| Building hooks skill | SKILL.md | 30-43 (PostToolUse definition) |
| Current hooks | hooks.json | All |
| Hook input format | block-beads-direct-read.py | 12-26 |

---

## Implementation Checklist

- [ ] Decide on tools to track (Edit, Write, ...)
- [ ] Decide on context types (timestamp, repo, ...)
- [ ] Decide on storage format (log vs. JSON)
- [ ] Decide on storage location (~/.claude/edit-log.txt vs. context/)
- [ ] Implement hook from proven pattern
- [ ] Register in hooks.json
- [ ] Test with manual tool invocations
- [ ] Document for downstream hooks
- [ ] Integrate with bd-6 (Stop hook)

---

## Performance Notes

- **PostToolUse fires frequently** - use rate limiting if needed
- **Log rotation** - keep last N lines to prevent growth
- **Non-blocking execution** - always exit with 0 (don't block Claude)
- **File access** - use append-only (`) for thread safety

---

## Related Epic Context

**bd-4:** UserPromptSubmit Hook (Skill Activator) - DEPENDENCY
**bd-5:** PostToolUse Hook (Context Tracker) - THIS TASK
**bd-6:** Stop Hook (Gentle Reminders) - BLOCKS ON THIS

Flow: bd-5 creates context → bd-6 consumes context for reminders
