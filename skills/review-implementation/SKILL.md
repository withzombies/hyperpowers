---
name: review-implementation
description: Use after executing-plans completes all tasks to review implementation against bd spec - verifies all success criteria met, anti-patterns avoided, and nothing missed before declaring work complete
---

# Review Implementation

## Overview

Review completed implementation against bd epic specification to catch gaps before claiming completion.

**Core principle:** Implementation must match spec. Success criteria are the contract.

**Announce at start:** "I'm using the review-implementation skill to verify the implementation matches the spec."

**Context:** This runs after executing-plans completes all tasks but before finishing-a-development-branch.

**CRITICAL:** NEVER read `.beads/issues.jsonl` directly. ALWAYS use `bd show`, `bd list`, and `bd dep tree` commands to read task specifications. The bd CLI provides the correct interface.

## The Process

### Step 1: Load Epic Specification from bd

**Get the epic and all tasks:**

```bash
# Show epic
bd show bd-1

# Get all tasks in epic
bd dep tree bd-1

# List all tasks for detailed review
bd list --parent bd-1
```

**Create TodoWrite tracker with all task IDs to review.**

### Step 2: Review Each Task Against Implementation

For each task in the epic:

**A. Read task specification:**

```bash
bd show bd-3
```

**B. Identify what was supposed to be delivered:**
- Goal (what problem does this solve?)
- Success criteria (how do we know it's done?)
- Implementation checklist (what files/functions/tests?)
- Key considerations (what edge cases matter?)
- Anti-patterns (what must be avoided?)

**C. Review actual implementation:**

1. **Check files mentioned in task:**
```bash
# For each file in implementation checklist
git diff main...HEAD -- src/auth/jwt.ts
```

2. **Verify success criteria:**
   - Run verification commands from success criteria
   - Check that each criterion is actually met
   - Don't assume - verify with evidence (see verification-before-completion skill)
   - **IMPORTANT:** Use hyperpowers:test-runner agent for running tests
     - Dispatch hyperpowers:test-runner agent with command: "Run: cargo test"
     - Keeps verbose test output in agent context
     - Returns only summary + failures
     - Prevents context pollution
   - Follow verification-before-completion principles: evidence before claims, always

3. **Check anti-patterns weren't violated:**
   - Search for prohibited patterns (unwrap/expect, TODO without issue #, etc.)
   - Verify error handling follows project guidelines
   - Check that stubs were actually implemented

4. **Check key considerations were addressed:**
   - Review code for edge cases mentioned in task
   - Verify error handling for failure modes
   - Check that concerns from sre-task-refinement were addressed

**D. Record findings:**

For this task:
- ✅ **Met**: List what was successfully implemented
- ❌ **Gap**: List what's missing or incomplete
- ⚠️ **Concern**: List potential issues or anti-patterns found

**E. Mark task review as completed in TodoWrite**

### Step 3: Report Findings

After reviewing all tasks, compile findings:

**If NO gaps found:**

```markdown
## Implementation Review: APPROVED ✅

Reviewed bd-1 (<epic name>) against implementation.

### Tasks Reviewed
- bd-2: <Task Name> ✅
- bd-3: <Task Name> ✅
- bd-4: <Task Name> ✅
- bd-5: <Task Name> ✅

### Verification Summary
- All success criteria verified
- No anti-patterns detected
- All key considerations addressed
- All files implemented per spec

### Evidence
[Show key verification command outputs]

Ready to proceed to finishing-a-development-branch.
```

**If gaps found:**

```markdown
## Implementation Review: GAPS FOUND ❌

Reviewed bd-1 (<epic name>) against implementation.

### Tasks with Gaps

#### bd-3: <Task Name>
**Gaps:**
- ❌ Success criterion not met: "Pre-commit hooks pass"
  - Evidence: `cargo clippy` shows 3 warnings
- ❌ Anti-pattern violation: Found `unwrap()` in src/auth/jwt.ts:45
- ⚠️ Key consideration not addressed: "Empty input validation"
  - No check for empty payload in generateToken()

#### bd-5: <Task Name>
**Gaps:**
- ❌ Success criterion not met: "All tests passing"
  - Evidence: test_verify_expired_token is failing

### Cannot Proceed
Implementation does not match spec. Fix gaps before completing.
```

### Step 4: Gate Decision

**If APPROVED:**
- Announce: "I'm using the finishing-a-development-branch skill to complete this work."
- **REQUIRED SUB-SKILL:** Use hyper:finishing-a-development-branch

**If GAPS FOUND:**
- STOP. Do not proceed to finishing-a-development-branch
- Fix gaps or discuss with partner
- Re-run review after fixes

## Review Checklist (per task)

For each task, verify:

### Success Criteria
- [ ] Every success criterion listed in bd task is verifiable
- [ ] Each criterion has been verified with evidence (command output)
- [ ] No criteria were skipped or assumed

### Implementation Checklist
- [ ] Every file in checklist was created/modified
- [ ] Every function in checklist exists and is implemented (not stubbed)
- [ ] Every test in checklist exists and passes

### Anti-Patterns
- [ ] Searched for each prohibited pattern listed in task
- [ ] No violations found
- [ ] If violations found: documented as gap

### Key Considerations
- [ ] Each edge case mentioned has corresponding code
- [ ] Error handling for failure modes exists
- [ ] Performance/security concerns addressed

### Code Quality
- [ ] No TODOs without issue numbers
- [ ] No commented-out code
- [ ] No debug print statements
- [ ] Follows project style/conventions

## Common Rationalizations - STOP

| Excuse | Reality |
|--------|---------|
| "Tests pass, must be complete" | Tests ≠ spec. Check every success criterion. |
| "I implemented it, it's done" | Implementation ≠ spec compliance. Review evidence. |
| "No time for thorough review" | Gaps found later cost more time than review now. |
| "Looks good to me" | Your opinion ≠ evidence. Run verifications. |
| "Small gaps don't matter" | Spec is contract. All criteria must be met. |
| "Will fix in next PR" | This PR should complete this epic. Fix now. |
| "Partner will review" | You review first. Don't delegate your quality check. |

## Red Flags - STOP

**Never:**
- Skip reviewing a task "because it's simple"
- Approve without verifying every success criterion
- Ignore anti-pattern violations
- Assume key considerations were addressed
- Trust that "tests passing" means spec is met

**Always:**
- Review every task, no exceptions
- Verify with commands and evidence
- Document gaps explicitly
- Check for anti-patterns from sre-task-refinement
- Read the actual code changes

## Working with bd

### Reading Task Specifications

```bash
# Show task with full design
bd show bd-3

# The design contains:
# - Goal
# - Success Criteria (your checklist)
# - Implementation Steps (what you executed)
# - Key Considerations (edge cases to check)
# - Anti-patterns (what to search for)
```

### Verification Pattern

For each task:

1. **Read success criteria from bd:**
```bash
bd show bd-3 | grep -A 20 "Success Criteria"
```

2. **Run each verification:**

**For test commands (use hyperpowers:test-runner agent):**
- Dispatch hyperpowers:test-runner agent with: "Run: cargo test"
- Dispatch hyperpowers:test-runner agent with: "Run: cargo clippy"

**For search/analysis commands (use Bash/Grep):**
```bash
# Example criteria: "No unwrap in production code"
rg "\.unwrap\(\)" src/
```

3. **Record results:**
   - ✅ If verification passes
   - ❌ If verification fails (document what failed)

## Integration

**Called by:**
- **executing-plans** (Step 5) - After all tasks executed, before finishing

**Calls:**
- **finishing-a-development-branch** - If review approves, hand off to finish

**Uses:**
- **verification-before-completion** - All verifications follow its "evidence before claims" principle; no completion claims without fresh verification evidence

**Order:**
```
executing-plans → review-implementation → finishing-a-development-branch
                        ↓
                  (if gaps found: STOP)
```

## Why This Matters

**Common scenarios this prevents:**

1. **Incomplete implementation:**
   - Developer executes 80% of task
   - Tests pass for implemented parts
   - Success criteria includes the missing 20%
   - Review catches gap

2. **Anti-pattern violations:**
   - Code works but uses prohibited patterns
   - Would fail code review later
   - Wastes PR review time
   - Review catches early

3. **Edge cases missed:**
   - sre-task-refinement identified edge cases
   - Developer focused on happy path
   - Edge cases untested
   - Review catches before PR

4. **Spec drift:**
   - Implementation evolved during development
   - Original spec goals forgotten
   - Result doesn't solve original problem
   - Review catches misalignment

## Remember

- Spec (bd tasks) is the contract
- Implementation must fulfill contract completely
- "Working code" ≠ "spec-compliant code"
- Evidence-based review, not opinion
- Every success criterion matters
- Better to find gaps now than in PR review
