# bd-5 Investigation Report: PostToolUse Hook Context Tracker

**Date:** 2025-10-30
**Task:** bd-5 Phase 4: PostToolUse Hook (Context Tracker)
**Status:** Investigation Complete

---

## Executive Summary

This investigation reveals that Hyperpowers has **well-established patterns for file edit tracking and context sharing** using PostToolUse hooks. The file edit tracking pattern is documented, exemplified, and ready for implementation. However, the "context tracking" concept requires clarification on what context should be maintained and for which downstream skills.

**Key Finding:** The codebase already documents a complete "File Edit Tracker" PostToolUse hook example. bd-5 should build on this proven pattern while clarifying what additional context (beyond file paths) needs to be tracked.

---

## 1. PostToolUse Hook Documentation

### What PostToolUse Hook Does

**Location:** `/Users/ryan/src/hyper/skills/building-hooks/SKILL.md` line 37
**Timing:** Fires **after each tool execution** (Read, Write, Edit, Bash, Grep, etc.)

```
| **PostToolUse** | After each tool execution | Logging, tracking changes, validation |
```

### Input Format Received

From `/Users/ryan/src/hyper/hooks/block-beads-direct-read.py`:

```python
# PostToolUse hooks receive JSON via stdin containing:
input_data = json.load(sys.stdin)
tool_name = input_data.get("tool_name", "")      # e.g., "Read", "Edit", "Write", "Bash"
tool_input = input_data.get("tool_input", {})    # Tool-specific parameters
```

**Tool-Specific Parameters Available:**
- **Read/Grep:** `file_path` or `path` parameter
- **Write/Edit:** `file_path` parameter
- **Bash:** `command` parameter (shell commands)
- **All tools:** Access to complete tool input object

### Output Format Expected

From `/Users/ryan/src/hyper/hooks/block-beads-direct-read.py` lines 30-42:

```json
{
  "hookSpecificOutput": {
    "hookEventName": "PostToolUse",
    "permissionDecision": "deny",                    // "allow", "deny"
    "permissionDecisionReason": "explanation"       // Optional reason
  }
}
```

**For non-blocking hooks (tracking):**
```json
{
  "hookSpecificOutput": {
    "hookEventName": "PostToolUse"
  }
}
```

Or simply exit with code 0 (no output needed).

---

## 2. Existing PostToolUse Hook Implementation

### Current Hook: block-beads-direct-read.py

**File:** `/Users/ryan/src/hyper/hooks/block-beads-direct-read.py` (lines 1-49)
**Type:** PreToolUse (blocking) - validates before tool runs
**Purpose:** Prevent direct reads of `.beads/issues.jsonl` to force bd CLI usage

**Key Implementation Details:**
- Reads JSON from stdin
- Checks tool type and parameters
- Returns permission decision
- Non-blocking flow returns exit code 0

---

## 3. Complete File Edit Tracker Pattern (Proven)

### The Pattern: Documented and Ready

**Location:** `/Users/ryan/src/hyper/skills/building-hooks/resources/hook-examples.md` lines 5-92

This is a **production-ready example** of exactly what bd-5 should implement.

#### Example 1: File Edit Tracker (PostToolUse)

**Purpose:** Track which files were edited and in which repos for later analysis.

**Implementation:**
```bash
#!/bin/bash

# Configuration
LOG_FILE="$HOME/.claude/edit-log.txt"
MAX_LOG_LINES=1000

# Read tool use event from stdin
read -r tool_use_json

# Extract tool name and file path
tool_name=$(echo "$tool_use_json" | jq -r '.tool.name')
file_path=""

case "$tool_name" in
    "Edit"|"Write")
        file_path=$(echo "$tool_use_json" | jq -r '.tool.input.file_path')
        ;;
    "MultiEdit")
        # MultiEdit has multiple files - log each
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
if [ "$line_count" -gt "$MAX_LOG_LINES" ]; then
    tail -n "$MAX_LOG_LINES" "$LOG_FILE" > "$LOG_FILE.tmp"
    mv "$LOG_FILE.tmp" "$LOG_FILE"
fi

# Return success (non-blocking)
echo '{"decision": "approve"}'
```

**Log Format:**
```
2025-01-15 10:30:00 | backend | /Users/ryan/src/project/backend/service.ts
2025-01-15 10:31:15 | frontend | /Users/ryan/src/project/src/components/Button.tsx
2025-01-15 10:32:30 | backend | /Users/ryan/src/project/backend/controller.ts
```

**Configuration:**
```json
{
  "event": "PostToolUse",
  "command": "~/.claude/hooks/post-tool-use/01-track-edits.sh",
  "description": "Track file edits for build checking",
  "blocking": false,
  "timeout": 1000
}
```

### Why This Pattern Works

1. **Lightweight:** ~50 lines of code
2. **Non-blocking:** Doesn't interrupt Claude's workflow
3. **Deterministic:** Reliable tracking without ML reasoning
4. **Composable:** Other hooks can read and use the edit log
5. **Proven:** Already documented as an example in hook-examples.md

### Helper Function Pattern

From hook-examples.md lines 21-41:

```bash
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
```

---

## 4. Context Tracking Requirements Analysis

### What "Context Tracking" Could Mean

From the codebase patterns, context tracking could include:

#### A. File Edit Context (Currently Implemented)
- **What:** Which files were modified
- **How:** PostToolUse hook logs file paths
- **Where:** `~/.claude/edit-log.txt`
- **Used by:** Build checkers, formatters, verification hooks

#### B. Tool Usage Context (Not Yet Tracked)
- **What:** Which tools were used (Edit, Write, Read, Bash, etc.)
- **How:** PostToolUse hook receives tool_name
- **Where:** Could log in same edit-log.txt or separate tool-log.txt
- **Used by:** Hooks that need to know what operations happened

#### C. Operation Context (Not Yet Tracked)
- **What:** Success/failure of operations
- **How:** PostToolUse fires after tool completes (success), ToolError for failures
- **Where:** Status log file
- **Used by:** Hooks deciding whether to run verifications

#### D. Test/Build Status Context (Not Yet Tracked)
- **What:** Whether tests need to run, whether build succeeded
- **How:** PostToolUse tracks code changes; Stop hook runs tests
- **Where:** Persistent state file
- **Used by:** Skills deciding if tests are needed

### Downstream Skills That Benefit from Context

**From codebase search:**

1. **verification-before-completion skill** (lines 100)
   - Needs to know: Which tests to run, whether verification already done
   - Uses: Could read from context file instead of re-running

2. **refactoring-safely skill** (lines 115-125)
   - Needs to know: Which tests were passing before, what changed
   - Uses: Edit tracking to run relevant tests

3. **fixing-bugs skill** (lines 125-135)
   - Needs to know: Which file was edited (for regression test)
   - Uses: Current PostToolUse tracking

4. **executing-plans skill** (bd task completion)
   - Needs to know: Which tasks completed, which tests passed
   - Uses: Could read context to decide next steps

5. **Stop hook (Gentle Reminders)** - bd-6 depends on this
   - Needs to know: Which files edited, were tests run
   - Uses: Edit log and test result context

---

## 5. Hook Patterns for Context Sharing

### Pattern 1: File-Based Communication (Proven)

**From hook-patterns.md lines 532-563:**

```bash
# Hook 1: Track state
#!/bin/bash
STATE_FILE="/tmp/hook-state.json"

# Update state
jq -n \
    --arg timestamp "$(date +%s)" \
    --arg files "$files_edited" \
    '{lastRun: $timestamp, filesEdited: ($files | split(","))}' \
    > "$STATE_FILE"

echo '{"decision": "approve"}'
```

```bash
# Hook 2: Read state
#!/bin/bash
STATE_FILE="/tmp/hook-state.json"

if [ -f "$STATE_FILE" ]; then
    last_run=$(jq -r '.lastRun' "$STATE_FILE")
    files=$(jq -r '.filesEdited[]' "$STATE_FILE")

    # Use state from previous hook
    for file in $files; do
        process_file "$file"
    done
fi

echo '{"decision": "approve"}'
```

**Key Points:**
- Uses JSON files for structured data
- Hooks coordinate through shared files
- Works across multiple hook events
- Must handle file locking for concurrent access

### Pattern 2: Rotating Log Files

**From hook-examples.md lines 69-73:**

```bash
# Rotate log if too large
line_count=$(wc -l < "$LOG_FILE")
if [ "$line_count" -gt "$MAX_LOG_LINES" ]; then
    tail -n "$MAX_LOG_LINES" "$LOG_FILE" > "$LOG_FILE.tmp"
    mv "$LOG_FILE.tmp" "$LOG_FILE"
fi
```

**Best Practice:** Keep last N entries, rotate when size exceeds threshold

### Pattern 3: Environment Variable Passing

**From building-hooks.md lines 296-299:**

```json
{
  "env": {
    "SKILL_RULES": "~/.claude/skill-rules.json",
    "DEBUG": "false"
  }
}
```

**For context:** Pass context file location via environment variable

### Pattern 4: Rate Limiting (Optional)

**From hook-patterns.md lines 118-158:**

```bash
RATE_LIMIT_FILE="/tmp/hook-last-run"
MIN_INTERVAL=30  # seconds

should_run() {
    if [ ! -f "$RATE_LIMIT_FILE" ]; then
        return 0
    fi

    local last_run=$(cat "$RATE_LIMIT_FILE")
    local now=$(date +%s)
    local elapsed=$((now - last_run))

    if [ "$elapsed" -lt "$MIN_INTERVAL" ]; then
        return 1  # Skip (ran too recently)
    fi
    return 0
}
```

**Why relevant:** PostToolUse fires frequently; rate limiting prevents excessive logging.

---

## 6. Similar Implementations in Repository

### Hook Examples in Resources

**File:** `/Users/ryan/src/hyper/skills/building-hooks/resources/hook-examples.md`

- **Example 1:** File Edit Tracker (PostToolUse) - DIRECTLY APPLICABLE
- **Example 2:** Multi-Repo Build Checker (Stop) - Uses edit-log.txt
- **Example 3:** TypeScript Prettier Formatter (Stop) - Uses edit-log.txt
- **Example 4:** Skill Activation Injector (UserPromptSubmit)
- **Example 5:** Error Handling Reminder (Stop) - Uses edit-log.txt

**Pattern:** Multiple hooks read from shared `edit-log.txt` created by PostToolUse.

### Hook Patterns Library

**File:** `/Users/ryan/src/hyper/skills/building-hooks/resources/hook-patterns.md`

Contains reusable patterns for:
- File Path Validation (lines 5-41)
- Finding Project Root (lines 43-78)
- Conditional Hook Execution (lines 80-116)
- Rate Limiting (lines 118-158)
- Multi-Project Detection (lines 160-193)
- Graceful Degradation (lines 195-236)
- Parallel Execution (lines 238-294)
- Smart Caching (lines 296-348)
- Progressive Output (lines 350-388)
- **Context Injection** (lines 390-425) - RELEVANT
- Error Accumulation (lines 427-478)
- Conditional Blocking (lines 480-526)
- **Hook Coordination** (lines 528-563) - DIRECTLY RELEVANT

### Skills Auto-Activation Hook Implementation

**File:** `/Users/ryan/src/hyper/skills/skills-auto-activation/resources/hook-implementation.md`

Lines 475-522 show how to **extend hooks to check file-based triggers:**

```javascript
// Get recently edited files from Claude Code context
function getRecentFiles(prompt) {
    // Claude Code provides context about files being edited
    // This would come from the prompt context or a separate tracking mechanism
    return prompt.files || [];
}

// Check file triggers
function checkFileTriggers(files, config) {
    if (!files || files.length === 0) return false;
    if (!config.fileTriggers) return false;

    // Check path patterns
    if (config.fileTriggers.pathPatterns) {
        for (const file of files) {
            for (const pattern of config.fileTriggers.pathPatterns) {
                // Convert glob pattern to regex
                const regex = globToRegex(pattern);
                if (regex.test(file)) {
                    return true;
                }
            }
        }
    }

    return false;
}
```

**Key insight:** File-based triggers are commented as "better to check in PostToolUse hook" - validation that bd-5 is the right place.

---

## 7. Storage Location Conventions

From the codebase patterns:

### Home Directory Locations
- `~/.claude/edit-log.txt` - Edit tracking log (hook-examples.md)
- `~/.claude/hook-cache/` - Hook cache directory (hook-patterns.md line 303)
- `~/.claude/hooks/debug.log` - Hook debug output (building-hooks.md line 258)
- `~/.claude/skill-rules.json` - Skill configuration (skills-auto-activation)

### Temporary Locations
- `/tmp/hook-last-run` - Rate limiting (hook-patterns.md line 125)
- `/tmp/hook-state.json` - Hook coordination state (hook-patterns.md line 535)
- `/tmp/test-edit-log.txt` - Test log (hook-examples.md line 104)

### Recommended for bd-5
- `~/.claude/context/` - New directory for context files
- `~/.claude/context/edits.jsonl` - Structured edit tracking
- `~/.claude/context/operations.jsonl` - Operation tracking (optional)
- `~/.claude/context/test-status.json` - Test/build status (optional)

---

## 8. Findings Summary

### What Exists and Can Be Leveraged

**Checkmarks indicate confirmed, working implementations:**

```
✓ PostToolUse Hook mechanics fully documented
  - Fires after each tool execution
  - Receives tool name and parameters via JSON stdin
  - Can return permission decisions or continue
  - Non-blocking hooks just exit with code 0

✓ Complete File Edit Tracker example (production-ready)
  - Location: hook-examples.md lines 5-92
  - Tracks: file path, repository, timestamp
  - Format: Tab/pipe-separated log file
  - Integration: Used by build-checker, formatter examples

✓ Hook coordination patterns
  - File-based state sharing via JSON files
  - JSON-based structured data (jq compatible)
  - Rotating logs for size management
  - Multiple hooks reading from shared state

✓ Tool input extraction patterns
  - Read/Grep: tool_input.file_path or tool_input.path
  - Write/Edit: tool_input.file_path
  - MultiEdit: tool_input.edits[].file_path
  - Bash: tool_input.command

✓ Context injection patterns
  - UserPromptSubmit hooks can inject context
  - Stop hooks can provide reminders
  - Skills can read from context files
  - Examples in hook-patterns.md lines 390-425

✓ Repository root detection
  - Pattern in hook-patterns.md lines 43-78
  - Walks up directory tree looking for .git
  - Used to group files by project
```

### What's Missing or Unclear

```
✗ Exact scope of "context tracking" not specified
  - File edits only? Or also tool types, operation results?
  - Which downstream skills specifically need what context?
  - Should context be persistent or session-based?

✗ Context storage format not decided
  - Plain text log vs. JSON vs. JSONL?
  - Single file vs. directory of files?
  - Home directory vs. project-specific?

✗ Tool-specific tracking not yet implemented
  - Which tools to track: Edit, Write, Read, Bash, Grep, etc.?
  - Should we track failed operations (ToolError events)?
  - Should we track operation details (command text, file size, etc.)?

✗ Integration points not fully specified
  - Which skills specifically depend on this context?
  - Should tests run automatically when code changes?
  - How should Stop hook (bd-6) use this context?

✗ Error/failure tracking not addressed
  - Should PostToolUse track successful vs. failed operations?
  - Does context need to record which tests need to be run?
  - Should there be a "context dirty" flag for verification?
```

---

## 9. Design Suggestions Based on Codebase Patterns

### Recommended Implementation Architecture

**Phase 1: File Edit Tracking (Proven Pattern)**

```bash
# ~/.claude/hooks/post-tool-use/01-track-edits.sh
# Tracks: Edit, Write tool usage
# Format: ~/.claude/context/edits.jsonl (one JSON object per line)
# Fields: timestamp, tool_name, file_path, repo, status

JSON structure:
{
  "timestamp": "2025-10-30T15:30:45Z",
  "tool": "Edit",
  "file_path": "/Users/ryan/src/hyper/skills/test.md",
  "repo": "hyper",
  "status": "success"
}
```

**Why JSON Lines:**
- Structured, machine-readable
- One-entry-per-line format (append-only, no locking)
- Easy to query with jq from other hooks
- Tools can skip if context not present

**Phase 2: Operation Context (Minimal)**

```bash
# ~/.claude/context/session-state.json
# Tracks: Current session state
{
  "session_start": "2025-10-30T15:00:00Z",
  "last_edit": "2025-10-30T15:30:45Z",
  "edits_since_test": 5,
  "test_status": "unknown",
  "files_modified": [
    "/Users/ryan/src/hyper/skills/test.md",
    "/Users/ryan/src/hyper/skills/other.md"
  ]
}
```

**Phase 3: Skill Integration Points**

```
PostToolUse (bd-5) writes to:
  - ~/.claude/context/edits.jsonl
  - ~/.claude/context/session-state.json

Stop hook (bd-6) reads from:
  - ~/.claude/context/session-state.json
  - Decides which reminders to show

test-runner agent could read from:
  - ~/.claude/context/edits.jsonl
  - Know which test suites to run

verification-before-completion skill could read from:
  - ~/.claude/context/session-state.json
  - Verify tests before claiming completion
```

### Storage Location Recommendation

Create new directory structure:

```
~/.claude/context/
├── edits.jsonl              # File edits tracking (append-only)
├── session-state.json       # Current session state
├── test-results.json        # Latest test run results
└── README.md                # Documentation
```

**Rationale:**
- Centralized context management
- Separate from hooks and skill rules
- Easy to reset between sessions if needed
- Composable by multiple hooks

### Error Handling Approach

```bash
# In PostToolUse hook, graceful degradation:

# Try to write edit log
if ! echo "$edit_json" >> "$CONTEXT_FILE"; then
    # Non-blocking - log to stderr but continue
    echo "Warning: Could not write context" >&2
fi

# Always exit with success (non-blocking)
exit 0
```

**Key principle:** Context tracking should never block Claude's workflow.

---

## 10. Comparison: Design Assumptions vs. Reality

### Design Assumption (bd-5 Description)
```
"Implement hook that tracks file edits and maintains context"
```

### Reality in Codebase

| Assumption | Reality | Status |
|-----------|---------|--------|
| PostToolUse hook needed | ✓ Confirmed, complete examples exist | CORRECT |
| File edit tracking | ✓ Complete example in hook-examples.md | CORRECT |
| Log file storage | ✓ Pattern uses ~/.claude/edit-log.txt | VERIFIED |
| Non-blocking execution | ✓ All examples exit with code 0 | VERIFIED |
| Multiple hooks coordination | ✓ Patterns exist for file-based communication | VERIFIED |
| JSON data format | ✓ Examples use JSON for state files | VERIFIED |
| Tool input extraction | ✓ Patterns documented for each tool type | VERIFIED |
| Downstream consumption | + Expected (Stop hook, etc.) but no explicit implementations yet | ASSUMED |
| Context types beyond files | - Not explicitly specified in current codebase | MISSING |
| Session persistence | ? Not discussed in current hook documentation | UNCLEAR |

---

## 11. Exact File Paths and References

### Core Documentation Files

| File Path | Line Numbers | Content |
|-----------|--------------|---------|
| `/Users/ryan/src/hyper/skills/building-hooks/SKILL.md` | 37 | PostToolUse event definition |
| `/Users/ryan/src/hyper/skills/building-hooks/SKILL.md` | 100-144 | Pattern 1 & 2: Build checker, auto-formatter |
| `/Users/ryan/src/hyper/skills/building-hooks/resources/hook-examples.md` | 5-92 | **Complete File Edit Tracker example** |
| `/Users/ryan/src/hyper/skills/building-hooks/resources/hook-examples.md` | 94-203 | Build Checker using edit-log.txt |
| `/Users/ryan/src/hyper/skills/building-hooks/resources/hook-examples.md` | 205-282 | Formatter using edit-log.txt |
| `/Users/ryan/src/hyper/skills/building-hooks/resources/hook-patterns.md` | 528-563 | Hook Coordination pattern |
| `/Users/ryan/src/hyper/skills/building-hooks/resources/hook-patterns.md` | 390-425 | Context Injection pattern |
| `/Users/ryan/src/hyper/skills/building-hooks/resources/hook-patterns.md` | 43-78 | Find Project Root pattern |
| `/Users/ryan/src/hyper/skills/building-hooks/resources/testing-hooks.md` | Various | Hook testing examples |
| `/Users/ryan/src/hyper/hooks/block-beads-direct-read.py` | 12-26 | PostToolUse/PreToolUse input format |
| `/Users/ryan/src/hyper/hooks/hooks.json` | 14-24 | Current hook configuration |

### Configuration Files

| File Path | Purpose |
|-----------|---------|
| `/Users/ryan/src/hyper/hooks/hooks.json` | Current hook registration (update to add bd-5 hook) |
| `/Users/ryan/src/hyper/hooks/skill-rules.json` | Skill activation rules (read-only for bd-5) |

### Current Hook Implementation

| File Path | Type | Purpose |
|-----------|------|---------|
| `/Users/ryan/src/hyper/hooks/session-start.sh` | SessionStart | Initialize using-hyper skill |
| `/Users/ryan/src/hyper/hooks/block-beads-direct-read.py` | PreToolUse | Block direct .beads reads |

---

## 12. Risk Assessment

### Low Risk (Well-Understood Patterns)

```
✓ File edit tracking structure
  - Pattern fully documented and exemplified
  - Similar hooks already registered
  - No complex dependencies

✓ Tool input extraction
  - Examples show exact JSON path for each tool
  - Well-tested in existing block-beads-direct-read.py

✓ Non-blocking execution
  - All examples show safe exit patterns
  - No workflow interruption risk
```

### Medium Risk (Needs Clarification)

```
? Tool selection for tracking
  - Which tools beyond Edit/Write?
  - Should Bash commands be logged? (potential verbosity)
  - Should Read/Grep be tracked for dependency analysis?

? Context location and lifecycle
  - Should context be session-specific or persistent?
  - How to handle large accumulation over time?
  - When should context be reset?

? Rate limiting needs
  - PostToolUse fires frequently (every tool use)
  - Should logging be rate-limited?
  - Test if overhead becomes noticeable
```

### Higher Risk (Needs Specification)

```
✗ Downstream integration points
  - Exactly which hooks depend on this context?
  - What format do they expect?
  - Are there timing dependencies?

✗ Test/build status integration
  - Should PostToolUse coordinate with Stop hook tests?
  - How to record test results?
  - Should verification context trigger automatic test runs?
```

---

## 13. Recommended Next Steps for bd-5

### Step 1: Clarify Scope (Before Implementation)

**Questions to answer:**

1. **Tool Selection:** Which tools to track?
   - [ ] Edit (code changes)
   - [ ] Write (new files)
   - [ ] Read (dependency analysis)
   - [ ] Bash (command tracking)
   - [ ] Grep (search tracking)
   - Other?

2. **Context Types:** Beyond file paths, what context?
   - [ ] Timestamp
   - [ ] Repository detection
   - [ ] Tool name
   - [ ] Operation status (success/failure)
   - [ ] File size or content hash
   - Other?

3. **Integration Points:** Which downstream skills need this?
   - [ ] Stop hook (bd-6) - which reminders?
   - [ ] test-runner agent - test suite selection?
   - [ ] verification-before-completion - test decision?
   - [ ] executing-plans - task tracking?
   - Other?

4. **Storage Decision:**
   - [ ] Plain text log (like edit-log.txt)
   - [ ] JSON Lines format (edits.jsonl)
   - [ ] Structured JSON (session-state.json)
   - [ ] Both (complementary files)

5. **Session Lifecycle:**
   - [ ] Persist across sessions
   - [ ] Reset on SessionStart
   - [ ] Reset on SessionEnd
   - [ ] User-managed cleanup

### Step 2: Design Specification Document

Create `/Users/ryan/src/hyper/bd-5-DESIGN.md`:

```markdown
# bd-5 Design: PostToolUse Hook Context Tracker

## Goals
1. Track file edits for downstream hook consumption
2. Enable test suite selection based on changed files
3. Support gentle reminders in Stop hook
4. Enable verification skip when context indicates tests unneeded

## Implementation
- Use proven File Edit Tracker pattern from hook-examples.md
- Extend to track operation status
- Coordinate with Stop hook via shared state files

## Success Criteria
- [ ] Hook implemented and registered in hooks.json
- [ ] Tracks Edit and Write tools to ~/.claude/context/edits.jsonl
- [ ] Creates session-state.json with recent edits summary
- [ ] Tested with manual hook invocation
- [ ] Documented integration points for bd-6
```

### Step 3: Implementation (Follow Proven Pattern)

1. Copy template from hook-examples.md Example 1
2. Customize for desired tools and context types
3. Register in hooks.json
4. Test with mock tool invocations
5. Document expected output format

### Step 4: Testing Strategy

```bash
# Test 1: Mock Edit tool invocation
input='{"tool_name":"Edit","tool_input":{"file_path":"/tmp/test.ts"}}'
echo "$input" | bash ~/.claude/hooks/post-tool-use/01-track-edits.sh

# Test 2: Verify context file created
cat ~/.claude/context/edits.jsonl
cat ~/.claude/context/session-state.json

# Test 3: Check hook timing
time bash ~/.claude/hooks/post-tool-use/01-track-edits.sh < mock-input.json

# Test 4: Concurrent access
for i in {1..10}; do bash hook.sh & done
```

---

## Conclusion

The Hyperpowers codebase provides **complete, proven patterns for PostToolUse hook implementation**. The File Edit Tracker example (hook-examples.md lines 5-92) is production-ready and can serve as the direct foundation for bd-5.

**Key recommendation:** Implement bd-5 using the documented pattern, then clarify and expand context types based on specific needs of downstream skills (particularly bd-6 Stop hook and verification workflows).

The investigation found no blockers or missing infrastructure—only a need to specify the exact scope of "context" and integrate points with downstream consumers.
