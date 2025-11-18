---
name: review-implementation
description: Use after hyperpowers:executing-plans completes all tasks - verifies implementation against bd spec, all success criteria met, anti-patterns avoided
---

<skill_overview>
Review completed implementation against bd epic to catch gaps before claiming completion; spec is contract, implementation must fulfill contract completely.
</skill_overview>

<rigidity_level>
LOW FREEDOM - Follow the 4-step review process exactly. Review with Google Fellow-level scrutiny. Never skip automated checks, quality gates, or code reading. No approval without evidence for every criterion.
</rigidity_level>

<quick_reference>
| Step | Action | Deliverable |
|------|--------|-------------|
| 1 | Load bd epic + all tasks | TodoWrite with tasks to review |
| 2 | Review each task (automated checks, quality gates, read code, verify criteria) | Findings per task |
| 3 | Report findings (approved / gaps found) | Review decision |
| 4 | Gate: If approved → finishing-a-development-branch, If gaps → STOP | Next action |

**Review Perspective:** Google Fellow-level SRE with 20+ years experience reviewing junior engineer code.
</quick_reference>

<when_to_use>
- hyperpowers:executing-plans completed all tasks
- Before claiming work is complete
- Before hyperpowers:finishing-a-development-branch
- Want to verify implementation matches spec

**Don't use for:**
- Mid-implementation (use hyperpowers:executing-plans)
- Before all tasks done
- Code reviews of external PRs (this is self-review)
</when_to_use>

<the_process>
## Step 1: Load Epic Specification

**Announce:** "I'm using hyperpowers:review-implementation to verify implementation matches spec. Reviewing with Google Fellow-level scrutiny."

**Get epic and tasks:**

```bash
bd show bd-1          # Epic specification
bd dep tree bd-1      # Task tree
bd list --parent bd-1 # All tasks
```

**Create TodoWrite tracker:**

```
TodoWrite todos:
- Review bd-2: Task Name
- Review bd-3: Task Name
- Review bd-4: Task Name
- Compile findings and make decision
```

---

## Step 2: Review Each Task

For each task:

### A. Read Task Specification

```bash
bd show bd-3
```

Extract:
- Goal (what problem solved?)
- Success criteria (how verify done?)
- Implementation checklist (files/functions/tests)
- Key considerations (edge cases)
- Anti-patterns (prohibited patterns)

---

### B. Run Automated Code Completeness Checks

```bash
# TODOs/FIXMEs without issue numbers
rg -i "todo|fixme" src/ tests/ || echo "✅ None"

# Stub implementations
rg "unimplemented!|todo!|unreachable!|panic!\(\"not implemented" src/ || echo "✅ None"

# Unsafe patterns in production
rg "\.unwrap\(\)|\.expect\(" src/ | grep -v "/tests/" || echo "✅ None"

# Ignored/skipped tests
rg "#\[ignore\]|#\[skip\]|\.skip\(\)" tests/ src/ || echo "✅ None"
```

---

### C. Run Quality Gates (via test-runner agent)

**IMPORTANT:** Use hyperpowers:test-runner agent to avoid context pollution.

```
Dispatch hyperpowers:test-runner: "Run: cargo test"
Dispatch hyperpowers:test-runner: "Run: cargo fmt --check"
Dispatch hyperpowers:test-runner: "Run: cargo clippy -- -D warnings"
Dispatch hyperpowers:test-runner: "Run: .git/hooks/pre-commit"
```

---

### D. Read Implementation Files

**CRITICAL:** READ actual files, not just git diff.

```bash
# See changes
git diff main...HEAD -- src/auth/jwt.ts

# THEN READ FULL FILE
Read tool: src/auth/jwt.ts
```

**While reading, check:**
- ✅ Code implements checklist items (not stubs)
- ✅ Error handling uses proper patterns (Result, try/catch)
- ✅ Edge cases from "Key Considerations" handled
- ✅ Code is clear and maintainable
- ✅ No anti-patterns present

---

### E. Code Quality Review (Google Fellow Perspective)

**Assume code written by junior engineer. Apply production-grade scrutiny.**

**Error Handling:**
- Proper use of Result/Option or try/catch?
- Error messages helpful for production debugging?
- No unwrap/expect in production?
- Errors propagate with context?
- Failure modes graceful?

**Safety:**
- No unsafe blocks without justification?
- Proper bounds checking?
- No potential panics?
- No data races?
- No SQL injection, XSS vulnerabilities?

**Clarity:**
- Would junior understand in 6 months?
- Single responsibility per function?
- Descriptive variable names?
- Complex logic explained?
- No clever tricks - obvious and boring?

**Testing:**
- Edge cases covered (empty, max, Unicode)?
- Tests meaningful, not just coverage?
- Test names describe what verified?
- Tests test behavior, not implementation?
- Failure scenarios tested?

**Production Readiness:**
- Comfortable deploying to production?
- Could cause outage or data loss?
- Performance acceptable under load?
- Logging sufficient for debugging?

---

### F. Verify Success Criteria with Evidence

For EACH criterion in bd task:
- Run verification command
- Check actual output
- Don't assume - verify with evidence
- Use hyperpowers:test-runner for tests/lints

**Example:**

```
Criterion: "All tests passing"
Command: cargo test
Evidence: "127 tests passed, 0 failures"
Result: ✅ Met

Criterion: "No unwrap in production"
Command: rg "\.unwrap\(\)" src/
Evidence: "No matches"
Result: ✅ Met
```

---

### G. Check Anti-Patterns

Search for each prohibited pattern from bd task:

```bash
# Example anti-patterns from task
rg "\.unwrap\(\)" src/  # If task prohibits unwrap
rg "TODO" src/          # If task prohibits untracked TODOs
rg "\.skip\(\)" tests/  # If task prohibits skipped tests
```

---

### H. Verify Key Considerations

Read code to confirm edge cases handled:
- Empty input validation
- Unicode handling
- Concurrent access
- Failure modes
- Performance concerns

**Example:** Task says "Must handle empty payload" → Find validation code for empty payload.

---

### I. Record Findings

```markdown
### Task: bd-3 - Implement JWT authentication

#### Automated Checks
- TODOs: ✅ None
- Stubs: ✅ None
- Unsafe patterns: ❌ Found `.unwrap()` at src/auth/jwt.ts:45
- Ignored tests: ✅ None

#### Quality Gates
- Tests: ✅ Pass (127 tests)
- Formatting: ✅ Pass
- Linting: ❌ 3 warnings
- Pre-commit: ❌ Fails due to linting

#### Files Reviewed
- src/auth/jwt.ts: ⚠️ Contains `.unwrap()` at line 45
- tests/auth/jwt_test.rs: ✅ Complete

#### Code Quality
- Error Handling: ⚠️ Uses unwrap instead of proper error propagation
- Safety: ✅ Good
- Clarity: ✅ Good
- Testing: ✅ Good

#### Success Criteria
1. "All tests pass": ✅ Met - Evidence: 127 tests passed
2. "Pre-commit passes": ❌ Not met - Evidence: clippy warnings
3. "No unwrap in production": ❌ Not met - Evidence: Found at jwt.ts:45

#### Anti-Patterns
- "NO unwrap in production": ❌ Violated at src/auth/jwt.ts:45

#### Issues
**Critical:**
1. unwrap() at jwt.ts:45 - violates anti-pattern, must use proper error handling

**Important:**
2. 3 clippy warnings block pre-commit hook
```

---

### J. Mark Task Reviewed (TodoWrite)

---

## Step 3: Report Findings

After reviewing ALL tasks:

**If NO gaps:**

```markdown
## Implementation Review: APPROVED ✅

Reviewed bd-1 (OAuth Authentication) against implementation.

### Tasks Reviewed
- bd-2: Configure OAuth provider ✅
- bd-3: Implement token exchange ✅
- bd-4: Add refresh logic ✅

### Verification Summary
- All success criteria verified
- No anti-patterns detected
- All key considerations addressed
- All files implemented per spec

### Evidence
- Tests: 127 passed, 0 failures (2.3s)
- Linting: No warnings
- Pre-commit: Pass
- Code review: Production-ready

Ready to proceed to hyperpowers:finishing-a-development-branch.
```

**If gaps found:**

```markdown
## Implementation Review: GAPS FOUND ❌

Reviewed bd-1 (OAuth Authentication) against implementation.

### Tasks with Gaps

#### bd-3: Implement token exchange
**Gaps:**
- ❌ Success criterion not met: "Pre-commit hooks pass"
  - Evidence: cargo clippy shows 3 warnings
- ❌ Anti-pattern violation: Found `.unwrap()` at src/auth/jwt.ts:45
- ⚠️ Key consideration not addressed: "Empty payload validation"
  - No check for empty payload in generateToken()

#### bd-4: Add refresh logic
**Gaps:**
- ❌ Success criterion not met: "All tests passing"
  - Evidence: test_verify_expired_token failing

### Cannot Proceed
Implementation does not match spec. Fix gaps before completing.
```

---

## Step 4: Gate Decision

**If APPROVED:**
```
Announce: "I'm using hyperpowers:finishing-a-development-branch to complete this work."

Use Skill tool: hyperpowers:finishing-a-development-branch
```

**If GAPS FOUND:**
```
STOP. Do not proceed to finishing-a-development-branch.
Fix gaps or discuss with partner.
Re-run review after fixes.
```
</the_process>

<examples>
<example>
<scenario>Developer only checks git diff, doesn't read actual files</scenario>

<code>
# Review process
git diff main...HEAD  # Shows changes

# Developer sees:
+ function generateToken(payload) {
+   return jwt.sign(payload, secret);
+ }

# Approves based on diff
"Looks good, token generation implemented ✅"

# Misses: Full context shows no validation
function generateToken(payload) {
  // No validation of payload!
  // No check for empty payload (key consideration)
  // No error handling if jwt.sign fails
  return jwt.sign(payload, secret);
}
</code>

<why_it_fails>
- Git diff shows additions, not full context
- Missed that empty payload not validated (key consideration)
- Missed that error handling missing (quality issue)
- False approval - gaps exist but not caught
- Will fail in production when empty payload passed
</why_it_fails>

<correction>
**Correct review process:**

```bash
# See changes
git diff main...HEAD -- src/auth/jwt.ts

# THEN READ FULL FILE
Read tool: src/auth/jwt.ts
```

**Reading full file reveals:**
```javascript
function generateToken(payload) {
  // Missing: empty payload check (key consideration from bd task)
  // Missing: error handling for jwt.sign failure
  return jwt.sign(payload, secret);
}
```

**Record in findings:**
```
⚠️ Key consideration not addressed: "Empty payload validation"
- No check for empty payload in generateToken()
- Code at src/auth/jwt.ts:15-17

⚠️ Error handling: jwt.sign can throw, not handled
```

**What you gain:**
- Caught gaps that git diff missed
- Full context reveals missing validation
- Quality issues identified before production
- Spec compliance verified, not assumed
</correction>
</example>

<example>
<scenario>Developer assumes tests passing means done</scenario>

<code>
# Run tests
cargo test
# Output: 127 tests passed

# Developer concludes
"Tests pass, implementation complete ✅"

# Proceeds to finishing-a-development-branch

# Misses:
- bd task has 5 success criteria
- Only checked 1 (tests pass)
- Anti-pattern: unwrap() present (prohibited)
- Key consideration: Unicode handling not tested
- Linter has warnings (blocks pre-commit)
</code>

<why_it_fails>
- Tests passing ≠ spec compliance
- Didn't verify all success criteria
- Didn't check anti-patterns
- Didn't verify key considerations
- Pre-commit will fail (blocks merge)
- Ships code violating anti-patterns
</why_it_fails>

<correction>
**Correct review checks ALL criteria:**

```markdown
bd task has 5 success criteria:
1. "All tests pass" ✅ - Evidence: 127 passed
2. "Pre-commit passes" ❌ - Evidence: clippy warns (3 warnings)
3. "No unwrap in production" ❌ - Evidence: Found at jwt.ts:45
4. "Unicode handling tested" ⚠️ - Need to verify test exists
5. "Rate limiting implemented" ⚠️ - Need to check code

Result: 1/5 criteria verified met. GAPS EXIST.
```

**Run additional checks:**
```bash
# Check criterion 2
cargo clippy
# 3 warnings found ❌

# Check criterion 3
rg "\.unwrap\(\)" src/
# src/auth/jwt.ts:45 ❌

# Check criterion 4
rg "unicode" tests/
# No matches ⚠️ Need to verify
```

**Decision: GAPS FOUND, cannot proceed**

**What you gain:**
- Verified ALL criteria, not just tests
- Caught anti-pattern violations
- Caught pre-commit blockers
- Prevented shipping non-compliant code
- Spec contract honored completely
</correction>
</example>

<example>
<scenario>Developer rationalizes skipping rigor for "simple" task</scenario>

<code>
bd task: "Add logging to error paths"

# Developer thinks: "Simple task, just added console.log"
# Skips:
- Automated checks (assumes no issues)
- Code quality review (seems obvious)
- Full success criteria verification

# Approves quickly:
"Logging added ✅"

# Misses:
- console.log used instead of proper logger (anti-pattern)
- Only added to 2 of 5 error paths (incomplete)
- No test verifying logs actually output (criterion)
- Logs contain sensitive data (security issue)
</code>

<why_it_fails>
- "Simple" tasks have hidden complexity
- Skipped rigor catches exactly these issues
- Incomplete implementation (2/5 paths)
- Security vulnerability shipped
- Anti-pattern not caught
- Failed success criterion (test logs)
</why_it_fails>

<correction>
**Follow full review process:**

```bash
# Automated checks
rg "console\.log" src/
# Found at error-handler.ts:12, 15 ⚠️

# Read bd task
bd show bd-5

# Success criteria:
# 1. "All error paths logged"
# 2. "No sensitive data in logs"
# 3. "Test verifies log output"

# Check criterion 1
grep -n "throw new Error" src/
# 5 locations found
# Only 2 have logging ❌ Incomplete

# Check criterion 2
Read tool: src/error-handler.ts
# Logs contain password field ❌ Security issue

# Check criterion 3
rg "test.*log" tests/
# No matches ❌ Test missing
```

**Decision: GAPS FOUND**
- Incomplete (3/5 error paths missing logs)
- Security issue (logs password)
- Anti-pattern (console.log instead of logger)
- Missing test

**What you gain:**
- "Simple" task revealed multiple gaps
- Security vulnerability caught pre-production
- Rigor prevents incomplete work shipping
- All criteria must be met, no exceptions
</correction>
</example>
</examples>

<critical_rules>
## Rules That Have No Exceptions

1. **Review every task** → No skipping "simple" tasks
2. **Run all automated checks** → TODOs, stubs, unwrap, ignored tests
3. **Read actual files with Read tool** → Not just git diff
4. **Verify every success criterion** → With evidence, not assumptions
5. **Check all anti-patterns** → Search for prohibited patterns
6. **Apply Google Fellow scrutiny** → Production-grade code review
7. **If gaps found → STOP** → Don't proceed to finishing-a-development-branch

## Common Excuses

All of these mean: **STOP. Follow full review process.**

- "Tests pass, must be complete" (Tests ≠ spec, check all criteria)
- "I implemented it, it's done" (Implementation ≠ compliance, verify)
- "No time for thorough review" (Gaps later cost more than review now)
- "Looks good to me" (Opinion ≠ evidence, run verifications)
- "Small gaps don't matter" (Spec is contract, all criteria matter)
- "Will fix in next PR" (This PR completes this epic, fix now)
- "Can check diff instead of files" (Diff shows changes, not context)
- "Automated checks cover it" (Checks + code review both required)
- "Success criteria passing means done" (Also check anti-patterns, quality, edge cases)

</critical_rules>

<verification_checklist>
Before approving implementation:

**Per task:**
- [ ] Read bd task specification completely
- [ ] Ran all automated checks (TODOs, stubs, unwrap, ignored tests)
- [ ] Ran all quality gates via test-runner agent (tests, format, lint, pre-commit)
- [ ] Read actual implementation files with Read tool (not just diff)
- [ ] Reviewed code quality with Google Fellow perspective
- [ ] Verified every success criterion with evidence
- [ ] Checked every anti-pattern (searched for prohibited patterns)
- [ ] Verified every key consideration addressed in code

**Overall:**
- [ ] Reviewed ALL tasks (no exceptions)
- [ ] TodoWrite tracker shows all tasks reviewed
- [ ] Compiled findings (approved or gaps)
- [ ] If approved: all criteria met for all tasks
- [ ] If gaps: documented exactly what missing

**Can't check all boxes?** Return to Step 2 and complete review.
</verification_checklist>

<integration>
**This skill is called by:**
- hyperpowers:executing-plans (Step 5, after all tasks executed)

**This skill calls:**
- hyperpowers:finishing-a-development-branch (if approved)
- hyperpowers:test-runner agent (for quality gates)

**This skill uses:**
- hyperpowers:verification-before-completion principles (evidence before claims)

**Call chain:**
```
hyperpowers:executing-plans → hyperpowers:review-implementation → hyperpowers:finishing-a-development-branch
                         ↓
                   (if gaps: STOP)
```

**CRITICAL:** Use bd commands (bd show, bd list, bd dep tree), never read `.beads/issues.jsonl` directly.
</integration>

<resources>
**Detailed guides:**
- [Code quality standards by language](resources/quality-standards.md)
- [Common anti-patterns to check](resources/anti-patterns-reference.md)
- [Production readiness checklist](resources/production-checklist.md)

**When stuck:**
- Unsure if gap critical → If violates criterion, it's a gap
- Criteria ambiguous → Ask user for clarification before approving
- Anti-pattern unclear → Search for it, document if found
- Quality concern → Document as gap, don't rationalize away
</resources>
