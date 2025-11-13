---
name: building-hooks
description: Use when creating Claude Code hooks for automation, quality checks, or workflow enhancement - covers hook patterns, composition, testing, and progressive enhancement from simple to advanced
---

# Building Claude Code Hooks

## Overview

Hooks are user-defined commands that execute at specific points in Claude Code's lifecycle, providing deterministic control over behavior.

**Core principle:** Hooks encode business rules at the application level rather than relying on LLM suggestions.

**Key insight:** Hooks run automatically with your environment's credentials, making them ideal for enforcing standards, catching errors, and automating workflows.

## When to Use

Use hooks when you need:
- **Automatic quality checks** (build verification, linting, formatting)
- **Workflow automation** (skill activation, context injection, logging)
- **Error prevention** (catching issues before they compound)
- **Consistent behavior** (formatting, conventions, standards)

**Never use hooks for:**
- Complex business logic (use tools/scripts instead)
- Slow operations that block workflow (use background jobs)
- Anything requiring LLM reasoning (hooks are deterministic)

## Hook Lifecycle Events

Claude Code provides 8 hook events:

| Event | When It Fires | Use Cases |
|-------|---------------|-----------|
| **UserPromptSubmit** | Before Claude processes prompt | Validation, context injection, skill activation |
| **Stop** | After Claude finishes responding | Build checks, formatting, quality reminders |
| **PostToolUse** | After each tool execution | Logging, tracking changes, validation |
| **PreToolUse** | Before tool execution | Permission checks, validation |
| **ToolError** | When tool fails | Error handling, fallback logic |
| **SessionStart** | New session begins | Environment setup, context loading |
| **SessionEnd** | Session closes | Cleanup, logging |
| **Error** | Unhandled error occurs | Error recovery, notifications |

**Most commonly used:** UserPromptSubmit and Stop

## Progressive Enhancement Approach

Start simple, add complexity only when needed:

### Phase 1: Observation (Non-Blocking)
Begin with hooks that observe and report without blocking:
- Log file edits (PostToolUse)
- Display reminders (Stop, non-blocking)
- Track metrics

### Phase 2: Automation (Background)
Add hooks that automate tedious tasks:
- Auto-format edited files (Stop)
- Run builds after changes (Stop)
- Inject helpful context (UserPromptSubmit)

### Phase 3: Enforcement (Blocking)
Only add blocking behavior when patterns are clear:
- Block dangerous operations (PreToolUse, blocking)
- Require fixes before continuing (Stop, blocking)
- Validate inputs (UserPromptSubmit, blocking)

**Critical:** Start with Phase 1, observe for a week, then move to Phase 2. Only add Phase 3 if absolutely necessary.

## Common Hook Patterns

### Pattern 1: Build Checker (Stop Hook)

**Problem:** Claude leaves TypeScript errors without catching them

**Solution:**
```bash
# Stop hook - runs after Claude finishes
#!/bin/bash

# Check which repos were modified
modified_repos=$(grep -h "edited" ~/.claude/edit-log.txt | cut -d: -f1 | sort -u)

# Run build on each repo
for repo in $modified_repos; do
  echo "Building $repo..."
  cd "$repo" && npm run build 2>&1 | tee /tmp/build-output.txt

  error_count=$(grep -c "error TS" /tmp/build-output.txt || echo "0")

  if [ "$error_count" -gt 0 ]; then
    if [ "$error_count" -ge 5 ]; then
      echo "⚠️  Found $error_count errors - consider using error-resolver agent"
    else
      echo "🔴 Found $error_count TypeScript errors:"
      grep "error TS" /tmp/build-output.txt
    fi
  else
    echo "✅ Build passed"
  fi
done
```

**Configuration:**
```json
{
  "event": "Stop",
  "command": "~/.claude/hooks/build-checker.sh",
  "description": "Run builds on modified repos",
  "blocking": false
}
```

**Result:** Zero errors left behind

### Pattern 2: Auto-Formatter (Stop Hook)

**Problem:** Claude produces inconsistently formatted code

**Solution:**
```bash
# Stop hook - format all edited files
#!/bin/bash

# Read edited files from log
edited_files=$(tail -20 ~/.claude/edit-log.txt | grep "^/" | sort -u)

for file in $edited_files; do
  # Determine repo and find .prettierrc
  repo_dir=$(dirname "$file")
  while [ "$repo_dir" != "/" ]; do
    if [ -f "$repo_dir/.prettierrc" ]; then
      echo "Formatting $file..."
      cd "$repo_dir" && npx prettier --write "$file"
      break
    fi
    repo_dir=$(dirname "$repo_dir")
  done
done

echo "✅ Formatting complete"
```

**Result:** All code consistently formatted automatically

### Pattern 3: Error Handling Reminder (Stop Hook)

**Problem:** Claude forgets to add error handling in risky code

**Solution:**
```bash
# Stop hook - gentle non-blocking reminder
#!/bin/bash

# Check edited files for risky patterns
edited_files=$(tail -20 ~/.claude/edit-log.txt | grep "^/")

risky_patterns=0
for file in $edited_files; do
  if grep -q "try\|catch\|async\|await\|prisma\|router\." "$file"; then
    ((risky_patterns++))
  fi
done

if [ "$risky_patterns" -gt 0 ]; then
  cat <<EOF
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 ERROR HANDLING SELF-CHECK
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

⚠️  Risky Patterns Detected
   $risky_patterns file(s) with async/try-catch/database operations

   ❓ Did you add proper error handling?
   ❓ Are errors logged/captured appropriately?

   💡 Consider: Sentry.captureException(), proper logging
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF
fi
```

**Result:** Claude self-checks without blocking workflow

### Pattern 4: Skills Auto-Activation (UserPromptSubmit Hook)

**See:** hyperpowers:skills-auto-activation skill for complete implementation

**Summary:** Analyzes prompt keywords/intent and injects skill activation reminder before Claude processes the prompt.

## Hook Composition and Ordering

When multiple hooks exist for the same event, they run in **alphabetical order** by filename.

### Naming Convention

Use numeric prefixes to control order:

```
hooks/
├── 00-log-prompt.sh           # Runs first (logging)
├── 10-inject-context.sh       # Runs second (context)
├── 20-activate-skills.sh      # Runs third (skills)
└── 99-notify.sh               # Runs last (notifications)
```

### Hook Dependencies

If Hook B depends on Hook A's output:
1. **Option 1:** Use numeric prefixes (A runs before B)
2. **Option 2:** Combine into single hook
3. **Option 3:** Use file-based communication

**Example:**
```bash
# 10-track-edits.sh writes to edit-log.txt
# 20-check-builds.sh reads from edit-log.txt
```

## Testing Hooks

### Test Strategy

**1. Test in Isolation**
```bash
# Manually trigger hook
bash ~/.claude/hooks/build-checker.sh

# Check output
echo $?  # Should be 0 for success
```

**2. Test with Mock Data**
```bash
# Create mock edit log
echo "/path/to/test/file.ts" > /tmp/test-edit-log.txt

# Run hook with test data
EDIT_LOG=/tmp/test-edit-log.txt bash ~/.claude/hooks/build-checker.sh
```

**3. Test Non-Blocking Behavior**
- Hook should exit quickly (<2 seconds)
- Should not block Claude's operation
- Should provide clear output

**4. Test Blocking Behavior**
- Verify blocking decision works correctly
- Test that reason message is helpful
- Ensure escape hatch exists (user can override)

### Debugging Hooks

**Enable logging:**
```bash
# Add to top of hook script
set -x  # Enable debug output
exec 2>~/.claude/hooks/debug.log  # Log errors
```

**Check hook execution:**
```bash
# Claude Code logs hook execution
tail -f ~/.claude/logs/hooks.log
```

**Common issues:**
- Hook timing out (>10 second default)
- Wrong working directory
- Missing environment variables
- File permissions

## Hook Configuration

### Basic Configuration

```json
{
  "event": "Stop",
  "command": "~/.claude/hooks/build-checker.sh",
  "description": "Run builds on modified repos",
  "blocking": false,
  "timeout": 5000
}
```

### Advanced Configuration

```json
{
  "event": "UserPromptSubmit",
  "command": "node ~/.claude/hooks/skill-activator.js",
  "description": "Inject skill activation based on prompt analysis",
  "blocking": false,
  "timeout": 2000,
  "env": {
    "SKILL_RULES": "~/.claude/skill-rules.json",
    "DEBUG": "false"
  }
}
```

## Security Considerations

**Hooks run with your credentials and have full system access.**

### Best Practices

1. **Review hook code carefully** - Hooks can execute any command
2. **Use absolute paths** - Don't rely on PATH
3. **Validate inputs** - Don't trust file paths blindly
4. **Limit scope** - Only access what's needed
5. **Log actions** - Track what hooks do
6. **Test thoroughly** - Especially blocking hooks

### Dangerous Patterns

❌ **Don't:**
```bash
# DANGEROUS - executes arbitrary code from log
cmd=$(tail -1 ~/.claude/edit-log.txt)
eval "$cmd"
```

✅ **Do:**
```bash
# SAFE - validates and sanitizes
file=$(tail -1 ~/.claude/edit-log.txt | grep "^/.*\.ts$")
if [ -f "$file" ]; then
  prettier --write "$file"
fi
```

## Common Rationalizations

| Excuse | Reality |
|--------|---------|
| "This hook is simple, don't need testing" | Untested hooks fail in production. Test them. |
| "Blocking is fine, I need to enforce this" | Start non-blocking, observe, then consider blocking. |
| "I'll add error handling later" | Hook errors are silent. Add handling now. |
| "The hook is slow but thorough" | Slow hooks block workflow. Optimize or run in background. |
| "I need access to everything just in case" | Minimal permissions. Only access what's needed. |

## Red Flags - STOP

**Watch for these patterns:**
- Hook takes >2 seconds (too slow)
- Blocking behavior without escape hatch
- No error handling (silent failures)
- Accessing files outside project scope
- Running commands without validation
- No logging (can't debug issues)

## Integration with Other Skills

**Related skills:**
- **hyperpowers:skills-auto-activation** - Complete skill activation hook implementation
- **hyperpowers:verification-before-completion** - Quality checks (hooks automate this)
- **hyperpowers:testing-anti-patterns** - Avoid testing anti-patterns in hooks

**Hook patterns support:**
- Automatic skill activation
- Build verification
- Code formatting
- Error prevention
- Workflow automation

## Quick Reference

| Pattern | Event | Blocking | Use Case |
|---------|-------|----------|----------|
| Build checker | Stop | No | Catch TypeScript errors |
| Auto-formatter | Stop | No | Consistent code style |
| Error reminder | Stop | No | Gentle quality nudges |
| Skill activator | UserPromptSubmit | No | Auto-activate skills |
| Edit tracker | PostToolUse | No | Track file changes |
| Permission check | PreToolUse | Yes | Prevent dangerous ops |

## Resources

**For detailed examples and patterns:**
- [resources/hook-examples.md](resources/hook-examples.md) - Complete working examples
- [resources/hook-patterns.md](resources/hook-patterns.md) - Pattern library
- [resources/testing-hooks.md](resources/testing-hooks.md) - Testing strategies

**Official documentation:**
- [Anthropic Hooks Guide](https://docs.claude.com/en/docs/claude-code/hooks-guide)

## Remember

- **Start simple** - Observation before automation before enforcement
- **Test thoroughly** - Hooks run with full system access
- **Keep fast** - <2 seconds for non-blocking hooks
- **Log everything** - You'll need it for debugging
- **Progressive enhancement** - Add complexity only when needed

Hooks are powerful. Use them to automate what should be automatic, not to replace human judgment.
