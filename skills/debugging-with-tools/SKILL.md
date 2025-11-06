---
name: debugging-with-tools
description: Use when encountering any bug, test failure, or unexpected behavior - systematic debugging using debuggers, internet research, and agents to find root cause before proposing fixes; never fix symptoms without understanding the problem
---

# Debugging With Tools

## Overview

Random fixes waste time and create new bugs. The fastest path to a working solution is systematic investigation using the right tools.

**Core principle:** ALWAYS use tools to understand root cause BEFORE attempting fixes. Symptom fixes are failure.

**Violating the letter of this process is violating the spirit of debugging.**

## When to Use

Use for ANY technical issue:
- Test failures
- Bugs in production or development
- Unexpected behavior
- Build failures
- Integration issues
- Performance problems

**Use this ESPECIALLY when:**
- "Just one quick fix" seems obvious
- Under time pressure (emergencies make guessing tempting)
- Error message is unclear or cryptic
- You don't fully understand the issue
- Previous fix didn't work

## The Four Phases

You MUST complete each phase before proceeding to the next.

### Phase 1: Tool-Assisted Investigation

**BEFORE attempting ANY fix, use tools to gather evidence:**

#### 1. Read Error Messages Completely

**Don't skip past errors:**
- Read entire error message, not just first line
- Read complete stack trace, all frames
- Note line numbers, file paths, error codes
- Stack traces show the exact execution path

#### 2. Search the Internet FIRST

**When error message is unclear or unfamiliar:**

**Dispatch hyperpowers:internet-researcher agent with:**
- "Search for this error: [exact error message]"
- "Find Stack Overflow discussions about: [error]"
- "Search for GitHub issues related to: [library name] + [error]"
- "Check if this is a known bug in: [dependency] version [X]"

**What to look for in results:**
- Exact match to your error
- Similar symptoms
- Known bugs in your dependency versions
- Official documentation explaining the error
- Workarounds or fixes that worked for others

**Example delegation:**
```
Error: "dyld: Symbol not found: _OBJC_CLASS_$_WKWebView"

Dispatch hyperpowers:internet-researcher with:
"Search for 'dyld Symbol not found _OBJC_CLASS_$_WKWebView'
- Check Stack Overflow solutions
- Look for iOS/macOS framework linking issues
- Find Xcode project configuration fixes"
```

#### 3. Use Debugger to Inspect State

**Before adding print statements, recommend user runs debugger:**

**IMPORTANT:** Claude cannot run interactive debuggers (lldb/gdb/DevTools) directly. Instead:
1. Guide user to run debugger with specific commands
2. OR add instrumentation that Claude CAN add (logging, assertions)
3. Ask user to share debugger output

**Recommend debugger to user:**

**For compiled languages (Rust, Swift, C++):**
```
"Let's use lldb to inspect the state at the error location.

Please run these commands:
  lldb target/debug/myapp
  (lldb) breakpoint set --file main.rs --line 42
  (lldb) run

When the breakpoint hits, run:
  (lldb) frame variable          # Shows all local variables
  (lldb) print my_variable       # Inspects specific variable
  (lldb) bt                      # Shows stack trace
  (lldb) up                      # Moves up stack frame

Please share the output, especially the values of: [list variables]"
```

**For browser JavaScript:**
```
"Let's use browser DevTools to inspect the state.

Please:
1. Open DevTools (F12)
2. Go to Sources tab
3. Set breakpoint at file.js:line 42
4. Refresh the page
5. When debugger pauses, check these variables in the Scope panel:
   - [variable names]
6. Share the values you see"
```

**Alternative: Automated debugging tools Claude CAN use:**

#### Option A: lldb Batch Mode (Claude can run this)

```bash
# Create lldb script
cat > debug-script.lldb <<'EOF'
breakpoint set --file main.rs --line 42
run
frame variable
bt
quit
EOF

# Run non-interactively
lldb -s debug-script.lldb target/debug/myapp 2>&1
```

**Or single command:**
```bash
lldb -o "breakpoint set --file main.rs --line 42" \
     -o "run" \
     -o "frame variable" \
     -o "bt" \
     -o "quit" \
     -- target/debug/myapp 2>&1
```

#### Option B: strace (Linux - system call tracing)

```bash
# Trace specific system calls
strace -e trace=open,read,write cargo test 2>&1

# Find which files are opened
strace -e trace=open cargo test 2>&1 | grep "\.env"

# See all syscalls with timestamps
strace -tt cargo test 2>&1
```

#### Option C: Add instrumentation (simplest)

```rust
// Claude can add this logging directly
fn process_request(request: &Request) {
    eprintln!("DEBUG process_request:");
    eprintln!("  request.email: {:?}", request.email);
    eprintln!("  request.name: {:?}", request.name);
    eprintln!("  is_empty: {}", request.email.is_empty());
    eprintln!("  stack: {:?}", std::backtrace::Backtrace::capture());

    // Existing code...
}
```

**Run with instrumentation:**
```bash
cargo test 2>&1 | grep "DEBUG process_request" -A 10
```

**When to use each approach:**
- **lldb batch**: Need to inspect variables at specific breakpoint
- **strace**: File access, network, process issues
- **Instrumentation**: Most flexible, Claude can add/remove easily

#### 4. Find Working Examples

**Dispatch hyperpowers:codebase-investigator to find patterns:**

```
"Find similar code that handles [feature] successfully"
"Locate working examples of [pattern] in this codebase"
"Show me how [similar component] implements [behavior]"
```

**What investigator should find:**
- Similar working code in same codebase
- How other parts handle similar situations
- Existing patterns you should follow
- Dependencies/imports/config the working code uses

**Example:**
```
Problem: WebSocket connection failing

Dispatch hyperpowers:codebase-investigator:
"Find existing WebSocket connections that work
- What configuration do they use?
- How do they handle connection errors?
- What libraries/versions do they use?"
```

#### 5. Reproduce Consistently

**Can you trigger it reliably?**
- What are the exact steps?
- Does it happen every time?
- What conditions must be present?

**If not reproducible:**
- Add more logging
- Check for race conditions
- Look for environmental differences
- DON'T guess at fixes

#### 6. Check Recent Changes

**IMPORTANT:** If your project uses pre-commit hooks that enforce passing tests, **skip this step for test failures**. All test failures are from your current changes because pre-commit hooks prevent commits with failures.

**Only when pre-commit hooks are NOT enforcing tests, or for non-test issues:**

**What changed that could cause this?**
```bash
# See recent commits
git log --oneline -20

# See what changed in relevant files
git log -p -- path/to/file.rs

# Compare working branch to broken
git diff working-branch...current-branch
```

**Also check:**
- New dependencies added
- Config file changes
- Environment variable changes
- System updates

### Phase 2: Root Cause Analysis

**Synthesize evidence from tools to understand the problem:**

#### 1. Trace Backward Through Call Stack

**When error is deep in execution:**

Use debugger or stack trace to trace backward:
- Where does invalid data originate?
- What called this with bad value?
- Keep tracing up until you find the source
- Fix at source, not at symptom

**Example stack trace analysis:**
```
Error in: database.execute()
  called by: UserRepository.save()
  called by: UserService.createUser()
  called by: API handler
  called with: email = ""  ← FOUND IT

Root cause: API handler not validating empty email
Symptom: Database complaining about empty string
Fix location: Add validation at API handler, not database layer
```

#### 2. Compare Working vs. Broken

**Use hyperpowers:codebase-investigator results:**
- What's different between working and broken?
- List every difference, however small
- Don't assume "that can't matter"
- Check configuration, imports, versions

#### 3. Review Internet Research

**From hyperpowers:internet-researcher findings:**
- Do solutions match your situation exactly?
- What root causes do others identify?
- Are there multiple explanations for this error?
- Is this a known bug in your version?

#### 4. Form Single Hypothesis

**State clearly:**
- "I think X is the root cause because Y"
- Write it down
- Be specific, not vague

**Example:**
- ❌ "Something wrong with networking"
- ✅ "WebSocket fails because WKWebView framework not linked in Xcode project, based on symbol error and Stack Overflow matches"

### Phase 3: Hypothesis Testing

**Scientific method with minimal changes:**

#### 1. Test Minimally

**Make the SMALLEST possible change to test hypothesis:**
- One variable at a time
- Don't fix multiple things at once
- Use debugger to verify intermediate state

**Example:**
```
Hypothesis: Missing framework link

Minimal test:
1. Add framework to Xcode "Link Binary with Libraries"
2. Clean build
3. Run in debugger
4. Check if symbol error gone

Don't also:
- Update other dependencies
- Change code
- Modify configuration
```

#### 2. Verify with Testing

**Option A: Ask user to verify with debugger (if interactive verification needed):**
```
"To confirm this fix works, please run the debugger:
  lldb target/debug/myapp
  (lldb) breakpoint set --file file.rs --line 42
  (lldb) run

When it hits the breakpoint, verify:
  - [Variable X] should now be [expected value]
  - [Behavior Y] should happen

Does the debugger show the fix working?"
```

**Option B: Add verification instrumentation (Claude can do this):**
```rust
fn fixed_function() {
    eprintln!("DEBUG: Entering fixed_function");
    eprintln!("  variable value: {:?}", variable);
    assert!(!variable.is_empty(), "Fix: variable should not be empty");

    // Fixed code...
}
```

**Option C: Write a test (preferred - Claude can do this):**
```rust
#[test]
fn test_fix_works() {
    let result = fixed_function();
    assert!(result.is_ok());
}
```

#### 3. Run Tests via hyperpowers:test-runner Agent

**Don't pollute context with test output:**

Dispatch hyperpowers:test-runner agent:
- "Run: cargo test"
- "Run: npm test"
- "Run: pytest"

Agent returns:
- ✓ Summary: X passed, Y failed
- Complete failure details if any
- Exit code for verification

#### 4. Decision Point

**Did it work?**
- YES → Proceed to Phase 4 (Implementation)
- NO → Form NEW hypothesis, return to Phase 2
- DON'T add more fixes on top

**If you don't understand:**
- Say "I don't understand X"
- Don't pretend to know
- Dispatch hyperpowers:internet-researcher for more research
- Ask human partner for help

### Phase 4: Proper Implementation

**After confirming hypothesis, implement properly:**

#### 1. Create Failing Test Case

**REQUIRED: Write test that reproduces the bug:**
```typescript
// RED - This test should fail before fix
test('rejects empty email', () => {
  expect(() => createUser({ email: '' }))
    .toThrow('Email cannot be empty');
});
```

**Run test via hyperpowers:test-runner agent to confirm it fails:**
- Dispatch hyperpowers:test-runner: "Run: npm test -- rejects-empty-email"
- Verify test fails with expected error
- This proves test actually tests the bug

**REQUIRED: Use Skill tool to invoke:** `hyperpowers:test-driven-development` for proper test writing

#### 2. Implement Minimal Fix

**Fix the root cause identified:**
- ONE change at a time
- Address source, not symptom
- No "while I'm here" improvements
- No bundled refactoring

#### 3. Verify Fix via hyperpowers:test-runner Agent

**Run tests without polluting context:**

Dispatch hyperpowers:test-runner agent:
- "Run full test suite: cargo test"
- Agent reports: summary + failures only
- Verify new test passes
- Verify no other tests broken

#### 4. Update bd Issue

**Track the work:**
```bash
# Update with findings
bd edit bd-123 --design "
Root cause: Missing WKWebView framework link
Solution: Added framework to Xcode project
Test: Added test_webview_loads

References:
- Stack Overflow: [URL]
- Apple docs: [URL]
"

# Close issue
bd status bd-123 --status closed
```

#### 5. If Fix Doesn't Work

**STOP and count:**
- How many fixes have you tried?
- If < 3: Return to Phase 1 with new information
- **If ≥ 3: STOP and question the architecture**

**Pattern indicating architectural problem:**
- Each fix reveals new coupling/shared state
- Fixes require "massive refactoring"
- Each fix creates new symptoms elsewhere

**STOP and discuss with human partner:**
- Is this pattern fundamentally sound?
- Should we refactor architecture vs. fixing symptoms?
- Are we "sticking with it through sheer inertia"?

This is NOT a failed hypothesis - this is wrong architecture.

## Tool Usage Summary

| Phase | Tools to Use | Purpose | Who Uses It |
|-------|-------------|---------|-------------|
| **Investigation** | hyperpowers:internet-researcher | Search error messages, find solutions | Claude (agent) |
| | lldb batch mode | Non-interactive variable inspection | Claude (bash) |
| | strace/dtrace | System call tracing | Claude (bash) |
| | Instrumentation (logging) | Add debug output | Claude (adds code) |
| | Interactive debuggers | Step through execution | User (Claude guides) |
| | hyperpowers:codebase-investigator | Find working examples | Claude (agent) |
| **Analysis** | Stack trace | Trace backward to root cause | Claude (reads) |
| | Git history | Find what changed | Claude (bash) |
| **Testing** | Test writing | Verify hypothesis with test | Claude (adds code) |
| | hyperpowers:test-runner agent | Run tests without context pollution | Claude (agent) |
| **Implementation** | hyperpowers:test-driven-development | Write proper failing test | Claude (skill) |
| | hyperpowers:test-runner agent | Verify fix, check regressions | Claude (agent) |

**Key distinction:**
- **Claude can use directly:** Agents, lldb batch mode, strace, instrumentation, tests, git, grep
- **User must use:** Interactive debuggers (lldb/gdb/DevTools when stepping through)
- **Prefer:** Automated tools (lldb batch, strace, instrumentation) over asking user

## Red Flags - STOP and Follow Process

If you catch yourself thinking:
- "Quick fix for now, investigate later"
- "Just try changing X and see if it works"
- "Skip the debugger, print statements are faster"
- "Skip the test, I'll manually verify"
- "Don't need to search, I know the answer"
- "It's probably X, let me fix that"
- "Add multiple changes, run tests"
- Proposing solutions before using debugger
- Proposing solutions before internet research
- **"One more fix attempt" (when already tried 2+)**

**ALL of these mean: STOP. Return to Phase 1.**

## Common Rationalizations - STOP

| Excuse | Reality |
|--------|---------|
| "Issue is simple, don't need debugger" | Debugger would show you're wrong in 30 seconds. |
| "Print statements are faster than debugger" | Debugger shows ALL variables, not just ones you printed. |
| "Error is obvious, don't need to search" | 5 minutes of research could save you hours. |
| "No similar code exists" | Dispatch hyperpowers:codebase-investigator to verify. |
| "Emergency, no time for process" | Systematic debugging is FASTER than guess-and-check. |
| "Just try this first, then investigate" | First fix sets the pattern. Do it right from start. |
| "I'll write test after confirming fix works" | Untested fixes don't stick. Test proves it. |
| "One more fix attempt" (after 2+ failures) | 3+ failures = architectural problem. Question design. |

## Integration with Other Skills

**This skill requires:**
- **hyperpowers:test-driven-development** - REQUIRED for creating failing test (Phase 4, Step 1)
- **hyperpowers:verification-before-completion** - REQUIRED before claiming success

**This skill uses:**
- **hyperpowers:internet-researcher agent** - Search errors, find solutions (Phase 1)
- **hyperpowers:codebase-investigator agent** - Find working patterns (Phase 1)
- **hyperpowers:test-runner agent** - Run tests without context pollution (Phase 3, Phase 4)

**Complementary skills:**
- **hyperpowers:root-cause-tracing** - Deep stack trace analysis (when needed)
- **hyperpowers:defense-in-depth** - Add validation at multiple layers after fixing

## Debugger Quick Reference

**For detailed debugger commands (lldb, gdb, DevTools, strace), see:** [resources/debugger-reference.md](resources/debugger-reference.md)

```


## Complete Debugging Example

**For a detailed debugging session walkthrough, see:** [resources/debugging-session-example.md](resources/debugging-session-example.md)
