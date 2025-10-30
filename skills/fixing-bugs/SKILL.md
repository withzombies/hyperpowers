---
name: fixing-bugs
description: Use when you encounter a bug that needs fixing - complete workflow from bug discovery through debugging, bd issue creation, test-driven fix, verification, and closure
---

# Fixing Bugs

## Overview

Bug fixing is not just writing a fix. It's a complete workflow: reproduce, track, debug systematically, test, fix, verify, close.

**Core principle:** Every bug gets a bd issue, a regression test, and systematic investigation before fixing.

**This skill orchestrates:** hyperpowers:debugging-with-tools + hyperpowers:test-driven-development + bd workflow + hyperpowers:verification-before-completion

## When to Use

Use when you discover a bug:
- Test failure you need to fix
- Bug reported by user
- Unexpected behavior in development
- Regression from recent change
- Production issue (for non-emergencies)

**For production emergencies:** This workflow is for thorough debugging and testing. For time-critical production issues, you may need to skip some steps (like full investigation before hotfix), but still track in bd and add regression tests afterward.

## The Complete Workflow

### Step 1: Create bd Bug Issue

**Track the work from the start:**

```bash
# Create bug issue
bd create "Bug: Empty email accepted in user creation" \
  --type bug \
  --priority P1

# Returns: bd-123
```

**Document initial information:**
```bash
bd edit bd-123 --design "
## Bug Description
Empty string accepted as email in createUser API

## Reproduction Steps
1. Call POST /api/users with email=''
2. User created without validation error
3. Database rejects on save

## Expected Behavior
API should reject empty email with 400 error

## Actual Behavior
Returns 500 from database

## Environment
- Version: 1.2.3
- Platform: All
"
```

**Mark as in-progress:**
```bash
bd status bd-123 --status in-progress
```

### Step 2: Systematic Debugging

**REQUIRED: Use Skill tool to invoke:** `hyperpowers:debugging-with-tools`

**Follow all 4 phases:**

1. **Tool-Assisted Investigation**
   - Search internet for similar errors
   - Use debugger to inspect state
   - Find working examples in codebase
   - Check recent changes

2. **Root Cause Analysis**
   - Trace backward through call stack
   - Compare working vs broken
   - Form specific hypothesis

3. **Hypothesis Testing**
   - Test minimally
   - Verify with debugger
   - Run tests via hyperpowers:test-runner agent

4. **Confirm Root Cause**
   - Don't proceed until you understand WHY

**Update bd issue with findings:**
```bash
bd edit bd-123 --design "
... (previous content)

## Root Cause
API handler doesn't validate email before passing to service layer.
Service assumes validation already done.
Database constraint catches it but returns 500.

## Evidence
- Debugger showed email='' passed through unchecked
- Similar endpoints validate in handler layer (hyperpowers:codebase-investigator found pattern)
- Stack Overflow: validation should happen at API boundary

## Solution Approach
Add email validation in API handler before calling service
"
```

### Step 3: Write Failing Test (RED Phase)

**REQUIRED: Use Skill tool to invoke:** `hyperpowers:test-driven-development`

**Write test that reproduces the bug:**

```rust
#[test]
fn test_create_user_rejects_empty_email() {
    let result = create_user(UserRequest {
        name: "John".to_string(),
        email: "".to_string(), // Empty email
    });

    assert!(result.is_err());
    assert_eq!(
        result.unwrap_err().to_string(),
        "Email cannot be empty"
    );
}
```

**Verify test fails:**

Dispatch hyperpowers:test-runner agent:
- "Run: cargo test test_create_user_rejects_empty_email"
- Confirm test fails with expected reason
- This proves test actually tests the bug

**Commit the failing test:**
```bash
git add tests/user_tests.rs
git commit -m "test(bd-123): add failing test for empty email validation

Currently fails because API doesn't validate empty email.

Related to bd-123"
```

### Step 4: Implement Fix (GREEN Phase)

**Write minimal code to make test pass:**

```rust
fn create_user(req: UserRequest) -> Result<User> {
    // NEW: Validate at API boundary
    if req.email.is_empty() {
        return Err(Error::ValidationError(
            "Email cannot be empty".to_string()
        ));
    }

    // Existing service call
    user_service.create(req)
}
```

**Run test to verify fix:**

Dispatch hyperpowers:test-runner agent:
- "Run: cargo test test_create_user_rejects_empty_email"
- Confirm: ✓ Test now passes

### Step 5: Verify No Regressions

**Run full test suite via hyperpowers:test-runner agent:**

Dispatch hyperpowers:test-runner agent:
- "Run: cargo test"
- Verify: All tests pass, no new failures
- Exit code: 0

**If regressions found:**
- STOP
- Analyze why fix broke other tests
- Adjust fix
- Re-run test suite
- Don't proceed until all tests pass

### Step 6: Refactor if Needed (Still GREEN)

**Now that tests pass, clean up if needed:**

- Extract validation to reusable function?
- Similar validation needed elsewhere?
- Code duplication to remove?

**After each refactor:**
- Dispatch hyperpowers:test-runner agent: "Run: cargo test"
- Verify: Tests still pass
- Only refactor while tests are green

### Step 7: Commit Fix

**Reference bd issue in commit:**

```bash
git add src/api/users.rs
git commit -m "fix(bd-123): validate email at API boundary

Reject empty emails before calling service layer.
Returns 400 ValidationError instead of 500 database error.

Root cause: API assumed service would validate, service assumed
API had validated. Added validation at API boundary per existing
pattern found in other endpoints.

Test: test_create_user_rejects_empty_email

Fixes bd-123

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

### Step 8: Final Verification

**REQUIRED: Use Skill tool to invoke:** `hyperpowers:verification-before-completion`

**Verify everything works:**

1. **Run full test suite one more time:**
   - Dispatch hyperpowers:test-runner agent: "Run: cargo test"
   - Confirm: All tests pass, including new test
   - Check exit code: 0

2. **Run linters/formatters if project uses them:**
   - Dispatch hyperpowers:test-runner agent: "Run: cargo clippy"
   - Dispatch hyperpowers:test-runner agent: "Run: cargo fmt --check"
   - Confirm: No new warnings

3. **Manual verification if applicable:**
   - Test the actual behavior manually if needed
   - Especially for UI bugs or integration issues

### Step 9: Update and Close bd Issue

**Document the complete fix:**

```bash
bd edit bd-123 --design "
... (previous content including root cause)

## Solution Implemented
Added email validation at API handler boundary.

Code changes:
- src/api/users.rs: Added validation before service call
- tests/user_tests.rs: Added regression test

Test coverage:
- test_create_user_rejects_empty_email: Verifies rejection
- Existing tests: All still pass (verified)

References:
- Commit: [commit hash]
- Stack Overflow: [URL if used]
"
```

**Close the issue:**
```bash
bd status bd-123 --status closed
```

### Step 10: Optional Code Review

**If working in a team:**

Use hyperpowers:finishing-a-development-branch to create PR:
- PR will reference bd-123
- Code reviewer can see full context in bd issue
- Tests prove fix works

## Quick Reference Checklist

When you encounter a bug, follow this checklist:

- [ ] Create bd bug issue with reproduction steps
- [ ] Mark bd issue as in-progress
- [ ] Use hyperpowers:debugging-with-tools to find root cause
- [ ] Update bd issue with root cause and evidence
- [ ] Write failing test that reproduces bug (RED)
- [ ] Verify test fails via hyperpowers:test-runner agent
- [ ] Commit failing test
- [ ] Implement minimal fix (GREEN)
- [ ] Verify fix passes test via hyperpowers:test-runner agent
- [ ] Run full test suite via hyperpowers:test-runner agent (check regressions)
- [ ] Refactor if needed (keep tests GREEN)
- [ ] Commit fix with bd issue reference
- [ ] Final verification via hyperpowers:verification-before-completion
- [ ] Update bd issue with solution details
- [ ] Close bd issue
- [ ] Create PR if applicable (hyperpowers:finishing-a-development-branch)

## Common Rationalizations - STOP

| Excuse | Reality |
|--------|---------|
| "Bug is obvious, skip bd issue" | Tracking is how you prove you fixed it. |
| "No time for test, I'll add later" | Untested fixes come back as new bugs. |
| "Skip debugging, I know the fix" | You're fixing a symptom, not root cause. |
| "Test suite is slow, skip verification" | Regressions found now vs. in production. |
| "Small bug, don't need full workflow" | Process is same regardless of bug size. |
| "Just need quick fix, will do it right later" | "Later" never comes. Do it right now. |

## Red Flags - STOP

**Never:**
- Fix bugs without creating bd issue
- Fix bugs without writing regression test
- Skip the debugging phase
- Commit fixes without running full test suite
- Close bd issue without verification evidence

**Always:**
- Track every bug in bd
- Write failing test first
- Use hyperpowers:debugging-with-tools systematically
- Verify no regressions via hyperpowers:test-runner agent
- Document root cause in bd

## Integration with Other Skills

**This skill requires:**
- **hyperpowers:debugging-with-tools** - REQUIRED for Phase 2 (investigation)
- **hyperpowers:test-driven-development** - REQUIRED for Phase 3 & 4 (test & fix)
- **hyperpowers:verification-before-completion** - REQUIRED for Phase 8 (final verification)

**This skill uses:**
- **hyperpowers:test-runner agent** - Run tests without context pollution
- **hyperpowers:internet-researcher agent** - Via hyperpowers:debugging-with-tools
- **hyperpowers:codebase-investigator agent** - Via hyperpowers:debugging-with-tools

**This skill calls:**
- **hyperpowers:finishing-a-development-branch** - Optional for creating PR

## Example: Complete Bug Fix Session

**Scenario:** API returns 500 when email is empty

**Time: 30-45 minutes total**

### Minutes 0-5: Setup
```bash
bd create "Bug: 500 error on empty email" --type bug --priority P1
# Returns: bd-123
bd status bd-123 --status in-progress
```

### Minutes 5-20: Investigation
- Use hyperpowers:debugging-with-tools
- Dispatch hyperpowers:internet-researcher: "Search for API validation patterns"
- Use debugger: Inspect where error occurs
- Dispatch hyperpowers:codebase-investigator: "Find other validation examples"
- Find root cause: Missing validation at API boundary

```bash
bd edit bd-123 --design "Root cause: No validation at API handler..."
```

### Minutes 20-25: Write Test (RED)
```rust
#[test]
fn test_rejects_empty_email() { ... }
```

Dispatch hyperpowers:test-runner: "Run: cargo test test_rejects_empty_email"
Result: ✗ Test fails (good!)

```bash
git commit -m "test(bd-123): add failing test"
```

### Minutes 25-30: Implement Fix (GREEN)
```rust
if req.email.is_empty() { return Err(...); }
```

Dispatch hyperpowers:test-runner: "Run: cargo test test_rejects_empty_email"
Result: ✓ Test passes

### Minutes 30-35: Verify
Dispatch hyperpowers:test-runner: "Run: cargo test"
Result: ✓ All 156 tests pass, no regressions

```bash
git commit -m "fix(bd-123): validate email at API boundary"
```

### Minutes 35-40: Close
```bash
bd edit bd-123 --design "Solution: Added validation..."
bd status bd-123 --status closed
```

### Minutes 40-45: PR (optional)
Use hyperpowers:finishing-a-development-branch to create PR

**Result:** Bug fixed properly with test, tracked in bd, verified working

## Why This Matters

**Without this workflow:**
- Bugs return (no regression test)
- Fixes break other things (no verification)
- No tracking (can't prove it's fixed)
- Symptom fixes (didn't find root cause)
- Time wasted on rework

**With this workflow:**
- Bug can't return (regression test catches it)
- No new bugs introduced (full test suite verified)
- Work tracked in bd (clear history)
- Root cause fixed (systematic investigation)
- Fixed once, fixed forever

**Investment:** 30-45 minutes
**Return:** Bug stays fixed, no rework needed
