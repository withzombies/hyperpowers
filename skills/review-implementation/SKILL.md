---
name: review-implementation
description: Use after hyperpowers:executing-plans completes all tasks to review implementation against bd spec - verifies all success criteria met, anti-patterns avoided, and nothing missed before declaring work complete
---

# Review Implementation

## Overview

Review completed implementation against bd epic specification to catch gaps before claiming completion.

**Review Perspective:** You are a **Google Fellow-level SRE with 20+ years of production experience** reviewing code written by a **junior engineer**. Apply rigorous production standards.

**Core principle:** Implementation must match spec. Success criteria are the contract.

**Announce at start:** "I'm using the hyperpowers:review-implementation skill to verify the implementation matches the spec. I'm reviewing this with Google Fellow-level scrutiny."

**Context:** This runs after hyperpowers:executing-plans completes all tasks but before hyperpowers:finishing-a-development-branch.

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

**1. Run Automated Code Completeness Checks:**

```bash
# Check for TODOs/FIXMEs without issue numbers
echo "🔍 Checking for TODOs/FIXMEs..."
rg -i "todo|fixme" src/ tests/ || echo "✅ No TODOs/FIXMEs found"

# Check for stub implementations
echo "🔧 Checking for stub implementations..."
rg "unimplemented!|todo!|unreachable!|panic!\(\"not implemented" src/ || echo "✅ No stubs found"

# Check for unsafe error handling in production code
echo "⚠️  Checking for unsafe patterns in production..."
rg "\.unwrap\(\)|\.expect\(" src/ | grep -v "/tests/" || echo "✅ No unsafe patterns in production"

# Check for ignored/skipped tests
echo "🚫 Checking for ignored/skipped tests..."
rg "#\[ignore\]|#\[skip\]|\.skip\(\)" tests/ src/ || echo "✅ No ignored tests"
```

**2. Run Quality Gate Checks:**

Dispatch **hyperpowers:test-runner agent** for each quality gate:

```bash
# Run tests via agent
hyperpowers:test-runner: "Run all tests: cargo test"

# Run formatter check via agent
hyperpowers:test-runner: "Check formatting: cargo fmt --check"

# Run linter via agent
hyperpowers:test-runner: "Run linter: cargo clippy -- -D warnings"

# Run pre-commit hook via agent
hyperpowers:test-runner: "Run pre-commit: .git/hooks/pre-commit"
```

**3. READ Implementation Files:**

**CRITICAL: You MUST read the actual code, not just check git diff.**

For each file in the implementation checklist:

```bash
# First see what changed
git diff main...HEAD -- src/auth/jwt.ts

# THEN READ THE ACTUAL FILE
# Use Read tool to read: src/auth/jwt.ts
```

**While reading, check:**
- ✅ Is the code actually implementing what the checklist says?
- ✅ Are functions/methods actually complete (not stubs)?
- ✅ Does error handling use proper patterns (Result, try/catch)?
- ✅ Are edge cases from "Key Considerations" handled in the code?
- ✅ Is the code clear and maintainable?
- ✅ Are there any anti-patterns present?

**4. Code Quality Review (Google Fellow Perspective):**

**CRITICAL: Assume this code was written by a junior engineer. Review with production-grade scrutiny.**

For each implementation file, assess with Google Fellow standards:

**Error Handling:**
- Proper use of Result/Option types (Rust) or try/catch (JS/TS)?
- Error messages helpful for debugging production issues?
- No unwrap/expect in production code?
- Errors propagate correctly with context?
- Failure modes handled gracefully?

**Safety:**
- No unsafe code blocks without justification and thorough comments?
- Proper bounds checking on arrays/slices?
- No potential panics or crashes?
- No data races or concurrency issues?
- No SQL injection, XSS, or security vulnerabilities?

**Clarity:**
- Would a junior engineer understand this code in 6 months?
- Functions have single responsibility?
- Variable names descriptive and unambiguous?
- Complex logic explained with comments?
- No clever tricks - is the code obvious and boring?

**Testing:**
- Edge cases covered (empty input, max values, Unicode, etc.)?
- Tests are meaningful, not just for coverage numbers?
- Test names clearly describe what they verify?
- Tests actually test behavior, not implementation details?
- Failure scenarios tested (error paths)?

**Production Readiness:**
- Would you be comfortable deploying this to production?
- Could this cause an outage or data loss?
- Is performance acceptable under load?
- Are there obvious optimization opportunities missed?
- Logging/observability sufficient for debugging production issues?

**5. Verify Success Criteria with Evidence:**

For each success criterion:
- Run verification commands
- Check actual output
- Don't assume - verify with evidence
- Use hyperpowers:test-runner agent for tests/lints/builds

**6. Check Anti-Patterns:**

Search for each prohibited pattern from bd task:
- Unwrap/expect in production
- TODOs without issue numbers
- Stub implementations
- Ignored tests without justification
- Task-specific anti-patterns

**7. Verify Key Considerations:**

Read code to confirm edge cases were handled:
- Empty input validation
- Unicode handling
- Concurrent access
- Failure modes
- Performance concerns

**D. Record findings for this task:**

```markdown
### Task: [Name] (bd-N)

#### Automated Checks
- TODOs/FIXMEs: [✅ None / ❌ Found at: file:line]
- Stubs: [✅ None / ❌ Found at: file:line]
- Unsafe patterns: [✅ None / ❌ Found at: file:line]
- Ignored tests: [✅ None / ❌ Found at: file:line]

#### Quality Gates
- Tests: [✅ Pass (N tests) / ❌ Fail (N failures)]
- Formatting: [✅ Pass / ❌ Fail]
- Linting: [✅ Pass / ❌ Warnings found]
- Pre-commit: [✅ Pass / ❌ Fail]

#### Files Reviewed
- src/file1.rs: [✅ Implements checklist / ❌ Issues: ...]
- src/file2.rs: [✅ Implements checklist / ❌ Issues: ...]
- tests/file1_test.rs: [✅ Complete / ❌ Issues: ...]

#### Code Quality (Google Fellow Review)
- Error Handling: [✅ Good / ⚠️ Concerns: ... / ❌ Issues: ...]
- Safety: [✅ Good / ⚠️ Concerns: ... / ❌ Issues: ...]
- Clarity: [✅ Good / ⚠️ Concerns: ... / ❌ Issues: ...]
- Testing: [✅ Good / ⚠️ Concerns: ... / ❌ Issues: ...]

#### Success Criteria (from bd issue)
1. [Criterion 1]: [✅ Met / ❌ Not met] - Evidence: [how verified]
2. [Criterion 2]: [✅ Met / ❌ Not met] - Evidence: [how verified]

#### Anti-Patterns Check
- [Anti-pattern 1]: [✅ Avoided / ❌ Violated at: file:line]
- [Anti-pattern 2]: [✅ Avoided / ❌ Violated at: file:line]

#### Key Considerations Check
- [Edge case 1]: [✅ Handled at file:line / ❌ Not addressed]
- [Edge case 2]: [✅ Handled at file:line / ❌ Not addressed]

#### Issues Found
**Critical** (must fix):
1. [Issue] - file:line - [Why critical]

**Important** (should fix):
1. [Issue] - file:line - [Impact]

**Minor** (nice to have):
1. [Issue] - file:line - [Suggestion]
```

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

Ready to proceed to hyperpowers:finishing-a-development-branch.
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
- Announce: "I'm using the hyperpowers:finishing-a-development-branch skill to complete this work."
- **REQUIRED: Use Skill tool to invoke:** `hyperpowers:finishing-a-development-branch`

**If GAPS FOUND:**
- STOP. Do not proceed to hyperpowers:finishing-a-development-branch
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
| **"Can check git diff instead of reading files"** | **NO. Git diff shows changes, not full context. READ the actual files.** |
| **"Automated checks cover quality"** | **NO. Automated checks + code review both required. Read the code.** |
| **"Success criteria passing means done"** | **NO. Also check: anti-patterns, code quality, edge cases. Read the code.** |

## Red Flags - STOP

**Never:**
- Skip reviewing a task "because it's simple"
- Approve without verifying every success criterion
- Ignore anti-pattern violations
- Assume key considerations were addressed
- Trust that "tests passing" means spec is met
- **Only check git diff without reading actual files**
- **Skip automated checks (TODOs, stubs, unwrap)**
- **Skip code quality review (error handling, safety, clarity)**

**Always:**
- Review every task, no exceptions
- Verify with commands and evidence
- Document gaps explicitly
- Check for anti-patterns from hyperpowers:sre-task-refinement
- **READ the actual implementation files with Read tool**
- **Run automated checks for TODOs, stubs, unsafe patterns**
- **Run quality gates with test-runner agent**
- **Assess code quality with Google Fellow perspective**

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
- **hyperpowers:executing-plans** (Step 5) - After all tasks executed, before finishing

**Calls:**
- **hyperpowers:finishing-a-development-branch** - If review approves, hand off to finish

**Uses:**
- **hyperpowers:verification-before-completion** - All verifications follow its "evidence before claims" principle; no completion claims without fresh verification evidence

**Order:**
```
hyperpowers:executing-plans → hyperpowers:review-implementation → hyperpowers:finishing-a-development-branch
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
   - hyperpowers:sre-task-refinement identified edge cases
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
