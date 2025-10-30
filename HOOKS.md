# Hyperpowers Hooks Documentation

## Overview

Hyperpowers uses Claude Code's hooks system to provide intelligent, context-aware assistance throughout your development workflow. Hooks automatically enhance your experience without requiring manual intervention.

## Hook Types

### UserPromptSubmit Hook

**File:** `hooks/user-prompt-submit/10-skill-activator.js`
**Purpose:** Analyzes prompts and suggests relevant skills
**Input:** `{"text": "user prompt text"}`
**Output:** `{"decision": "approve", "additionalContext": "skill suggestions"}`

**How it works:**
1. You type a prompt (e.g., "I want to write a test for the login function")
2. Hook analyzes prompt against patterns in `hooks/skill-rules.json`
3. Returns top 3 matching skills sorted by priority
4. Skill suggestions appear before Claude responds

**Example output:**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🎯 SKILL ACTIVATION CHECK
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Relevant skills for this prompt:

🔴 **test-driven-development** (critical priority, process)

Before responding, check if any of these skills should be used.
Use the Skill tool to activate: `Skill command="hyperpowers:<skill-name>"`
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**Configuration:**
- Edit `hooks/skill-rules.json` to adjust skill triggers
- Add keywords or intent patterns for your skills
- Set `DEBUG_HOOKS=true` environment variable for troubleshooting

### PostToolUse Hook

**File:** `hooks/post-tool-use/01-track-edits.sh`
**Purpose:** Tracks file edits for context awareness
**Input:** `{"tool": {"name": "Edit", "input": {"file_path": "..."}}}`
**Output:** `{"decision": "approve"}`

**How it works:**
1. Intercepts Edit and Write tool usage
2. Logs timestamp, repo, tool name, and file path
3. Stores in `hooks/context/edit-log.txt`
4. Automatically rotates log at 1000 lines

**Context Storage:**
- **Log file:** `hooks/context/edit-log.txt`
- **Format:** `timestamp | repo | tool | filepath`
- **Example:** `2025-10-30 15:35:05 | hyper | Edit | /Users/ryan/src/hyper/test.txt`

**Utility functions** (in `hooks/utils/context-query.sh`):
- `get_recent_edits [since_timestamp]` - Query edits since timestamp
- `get_session_files [session_start]` - Get unique files edited in session
- `was_file_edited <file_path> [since]` - Check if specific file was edited
- `get_repo_stats [since]` - Get edit counts by repo

### Stop Hook

**File:** `hooks/stop/10-gentle-reminders.sh`
**Purpose:** Shows context-aware reminders after Claude responds
**Input:** `{"text": "claude's response"}` (optional)
**Output:** Brief reminders to stdout

**How it works:**
1. Reads Claude's response and session context
2. Checks for relevant reminder patterns:
   - Source files edited without test files → TDD reminder
   - User claims "done/complete" with edits → Verification reminder
   - 3+ files edited → Commit reminder
3. Shows maximum 5 lines of non-intrusive output

**Example output:**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
💭 Remember: Write tests first (TDD)
✅ Before claiming complete: Run tests
💾 Consider: 5 files edited - commit?
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Installation

Hooks are automatically activated when the Hyperpowers plugin is installed.

**Prerequisites:**
- Node.js (for UserPromptSubmit hook)
- Bash (for PostToolUse and Stop hooks)
- jq (for JSON processing)

**Verify installation:**
```bash
ls hooks/
# Should show: hooks.json, user-prompt-submit/, post-tool-use/, stop/, utils/, context/
```

## Troubleshooting

### Skill activator not working

**Symptoms:** No skill suggestions appear when typing prompts

**Debug steps:**
```bash
# 1. Enable debug mode
export DEBUG_HOOKS=true

# 2. Test manually
echo '{"text": "I want to write a test"}' | node hooks/user-prompt-submit/10-skill-activator.js

# 3. Check skill rules exist
cat hooks/skill-rules.json | jq 'keys'

# 4. Verify Node.js is installed
node --version
```

### Context not tracking

**Symptoms:** Edit log is empty or not updating

**Debug steps:**
```bash
# 1. Check log file exists
ls -la hooks/context/edit-log.txt

# 2. Test manually
echo '{"tool": {"name": "Edit", "input": {"file_path": "/test.ts"}}}' | \
  bash hooks/post-tool-use/01-track-edits.sh

# 3. Verify log was written
cat hooks/context/edit-log.txt

# 4. Check permissions
ls -la hooks/context/
```

### Reminders not showing

**Symptoms:** No reminders after Claude responds

**Debug steps:**
```bash
# 1. Add some edits to context
echo "$(date +"%Y-%m-%d %H:%M:%S") | hyper | Edit | src/main.ts" > hooks/context/edit-log.txt

# 2. Test manually
echo '{"text": "All done!"}' | bash hooks/stop/10-gentle-reminders.sh

# 3. Check for bash errors
bash -x hooks/stop/10-gentle-reminders.sh <<< '{"text": "Done"}'
```

### General debugging

**Check hooks.json is valid:**
```bash
jq . hooks/hooks.json
```

**View hook execution (if available in Claude Code):**
- Check Claude Code logs for hook errors
- Look for hook timeout messages

## Customization

### Adjusting skill triggers

Edit `hooks/skill-rules.json` to add or modify skill activation patterns:

```json
{
  "my-custom-skill": {
    "type": "workflow",
    "enforcement": "suggest",
    "priority": "high",
    "promptTriggers": {
      "keywords": ["deploy", "release", "ship"],
      "intentPatterns": [
        "(deploy|release|ship).*?(prod|production)",
        "prepare.*?(release|deployment)"
      ]
    }
  }
}
```

**Pattern tips:**
- Use lowercase keywords (matching is case-insensitive)
- Intent patterns are regex (use `.*?` for non-greedy matching)
- Test patterns on [regex101.com](https://regex101.com) first
- Priority: `critical` > `high` > `medium` > `low`

### Adjusting reminder thresholds

Edit `hooks/stop/10-gentle-reminders.sh`:

```bash
# Change commit reminder threshold (default: 3 files)
if [ "$FILE_COUNT" -ge 5 ]; then  # Now triggers at 5 files
    SHOW_COMMIT_REMINDER=true
fi
```

### Disabling specific hooks

**Option 1:** Remove from `hooks/hooks.json`

```json
{
  "hooks": {
    "UserPromptSubmit": [...],
    "PostToolUse": [...],
    // "Stop": [...]  ← Commented out or removed
  }
}
```

**Option 2:** Rename hook file

```bash
mv hooks/stop/10-gentle-reminders.sh hooks/stop/10-gentle-reminders.sh.disabled
```

### Adding custom hooks

1. Create hook script in appropriate directory
2. Make executable: `chmod +x hooks/<type>/<name>.sh`
3. Add to `hooks/hooks.json`
4. Test manually before relying on it

See [building-hooks skill](skills/building-hooks/SKILL.md) for detailed guidance.

## Performance

All hooks are designed to be fast and non-blocking:

- **UserPromptSubmit:** <100ms per prompt (typical: ~29ms)
- **PostToolUse:** <10ms per edit
- **Stop:** <50ms per response (typical: ~22ms)

If hooks are slow, check:
- Large skill-rules.json file (>50KB)
- Slow regex patterns (catastrophic backtracking)
- Network calls (should never happen)
- Large edit log (should auto-rotate at 1000 lines)

## Architecture

### Hook execution flow

```
User types prompt
    ↓
UserPromptSubmit hook runs
    ↓
Skill suggestions added to context
    ↓
Claude processes prompt
    ↓
Claude uses Edit/Write tools
    ↓
PostToolUse hook logs edits
    ↓
Claude returns response
    ↓
Stop hook checks context
    ↓
Reminders shown (if relevant)
```

### File locking

PostToolUse hook uses directory-based locking to prevent race conditions:
- Creates `.edit-log.lock` directory atomically
- Timeout after 5 seconds (non-blocking)
- Automatically cleaned up on exit

### Log rotation

Edit log automatically rotates when exceeding 1000 lines:
- Keeps most recent 1000 lines
- Prevents unbounded disk usage
- Happens during PostToolUse hook execution

## FAQ

**Q: Can I disable all hooks?**
A: Yes, remove all entries from `hooks/hooks.json` or rename the `hooks/` directory.

**Q: Do hooks slow down Claude Code?**
A: No, hooks are designed to be fast (<100ms) and run in the background.

**Q: Can hooks fail and block me?**
A: No, all hooks are non-blocking and always return `{"decision": "approve"}` even on error.

**Q: How do I add my own skills to the activator?**
A: Edit `hooks/skill-rules.json` to add your skill with keywords and patterns.

**Q: Can I see what patterns matched?**
A: Yes, set `DEBUG_HOOKS=true` to see match reasons in hook output.

**Q: Are hooks project-specific or global?**
A: Hooks are part of the Hyperpowers plugin, so they work in all projects where the plugin is active.

## See Also

- [building-hooks skill](skills/building-hooks/SKILL.md) - Guide for creating custom hooks
- [skills-auto-activation skill](skills/skills-auto-activation/SKILL.md) - Advanced skill activation patterns
- [README.md](README.md) - Main Hyperpowers documentation
