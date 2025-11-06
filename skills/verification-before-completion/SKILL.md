---
name: verification-before-completion
description: Use when about to claim work is complete, fixed, or passing, before committing or creating PRs - requires running verification commands and confirming output before making any success claims; evidence before assertions always
---

# Verification Before Completion

## Overview

Claiming work is complete without verification is dishonesty, not efficiency.

**Core principle:** Evidence before claims, always.

**Violating the letter of this rule is violating the spirit of this rule.**

## The Iron Law

```
NO COMPLETION CLAIMS WITHOUT FRESH VERIFICATION EVIDENCE
```

If you haven't run the verification command in this message, you cannot claim it passes.

## Pre-Commit Hook Assumption

**IMPORTANT:** If your project uses pre-commit hooks that enforce passing tests:

```
ALL test failures are from your current changes
ALL lint errors are from your current changes
DO NOT check if errors were "pre-existing"
```

**Why:** Pre-commit hooks guarantee the previous commit passed all checks. If a test fails now, it's because of changes made since the last commit.

**Never do this:**
- ❌ Check out previous commits to see if errors existed before
- ❌ Run `git checkout <sha> && pytest` to verify errors are new
- ❌ Claim errors are "pre-existing" when pre-commit hooks enforce quality

**Always do this:**
- ✅ Read the error message
- ✅ Fix the error directly
- ✅ Run tests to verify the fix

Checking git history for errors wastes time when pre-commit hooks enforce quality standards.

## The Gate Function

```
BEFORE claiming any status or expressing satisfaction:

1. IDENTIFY: What command proves this claim?
2. RUN: Execute the FULL command (fresh, complete)
   - For tests/pre-commit/commits: Use hyperpowers:test-runner agent to avoid context pollution
   - Agent captures verbose output, returns only summary + failures
3. READ: Full output, check exit code, count failures
4. VERIFY: Does output confirm the claim?
   - If NO: State actual status with evidence
   - IF YES: State claim WITH evidence
5. ONLY THEN: Make the claim

Skip any step = lying, not verifying
```

**Using the hyperpowers:test-runner agent:**
- Dispatch hyperpowers:test-runner agent with the command: "Run: cargo test"
- Agent runs command, captures all output in its context
- Returns concise report: summary stats + failure details only
- Prevents context pollution from verbose test/hook output

## Common Failures

| Claim | Requires | Not Sufficient |
|-------|----------|----------------|
| Tests pass | Test command output: 0 failures | Previous run, "should pass" |
| Linter clean | Linter output: 0 errors | Partial check, extrapolation |
| Build succeeds | Build command: exit 0 | Linter passing, logs look good |
| Bug fixed | Test original symptom: passes | Code changed, assumed fixed |
| Regression test works | Red-green cycle verified | Test passes once |
| Agent completed | VCS diff shows changes | Agent reports "success" |
| Requirements met | Line-by-line checklist | Tests passing |

## Red Flags - STOP

- Using "should", "probably", "seems to"
- Expressing satisfaction before verification ("Great!", "Perfect!", "Done!", etc.)
- About to commit/push/PR without verification
- Trusting agent success reports
- Relying on partial verification
- Thinking "just this once"
- Tired and wanting work over
- **ANY wording implying success without having run verification**

## Rationalization Prevention

| Excuse | Reality |
|--------|---------|
| "Should work now" | RUN the verification |
| "I'm confident" | Confidence ≠ evidence |
| "Just this once" | No exceptions |
| "Linter passed" | Linter ≠ compiler |
| "Agent said success" | Verify independently |
| "I'm tired" | Exhaustion ≠ excuse |
| "Partial check is enough" | Partial proves nothing |
| "Different words so rule doesn't apply" | Spirit over letter |

## Key Patterns

**Tests:**
```
✅ [Run test command] [See: 34/34 pass] "All tests pass"
❌ "Should pass now" / "Looks correct"
```

**Regression tests (TDD Red-Green):**
```
✅ Write → Run (pass) → Revert fix → Run (MUST FAIL) → Restore → Run (pass)
❌ "I've written a regression test" (without red-green verification)
```

**Commits (with pre-commit hooks):**
```
✅ [Dispatch hyperpowers:test-runner: "Run: git commit -m 'message'"] [Agent reports: hooks passed] "Commit created"
❌ "git commit" (dumps 947+ lines of test output into context)
❌ "Committing changes" (without waiting for hook results)
```

**Build:**
```
✅ [Run build] [See: exit 0] "Build passes"
❌ "Linter passed" (linter doesn't check compilation)
```

**Requirements:**
```
✅ Re-read plan → Create checklist → Verify each → Report gaps or completion
❌ "Tests pass, phase complete"
```

**Agent delegation:**
```
✅ Agent reports success → Check VCS diff → Verify changes → Report actual state
❌ Trust agent report
```

**bd task completion:**
```
✅ Check success criteria → Run verification commands → All pass → Close task
❌ "Implemented bd-3" (without verifying success criteria)
```

**bd epic completion:**
```
✅ [Run: bd list --status open --parent bd-1] [See: 0 results] "All tasks closed"
❌ "Epic complete" (without verifying all tasks actually closed)
```

## Working with bd

### Before Closing a Task

**From bd task design:**
```markdown
## Success Criteria
- [ ] All functions fully implemented (no stubs, no TODOs)
- [ ] Tests written and passing: test_generate_token, test_verify_token
- [ ] Pre-commit hooks pass (cargo fmt, cargo clippy, cargo test)
```

**Your verification:**
1. **Run each verification command**:
```bash
# Check for TODOs
rg "TODO|FIXME|todo!|unimplemented!" src/
# Output: [nothing] ✅

# Run specific tests
cargo test test_generate_token test_verify_token
# Output: test result: ok. 2 passed ✅

# Run pre-commit hooks
cargo fmt --check && cargo clippy && cargo test
# Output: [all pass] ✅
```

2. **THEN close task**:
```bash
bd status bd-3 --status closed
```

### Before Closing an Epic

**Verify all child tasks closed:**
```bash
bd list --status open --parent bd-1
# Output: [empty] ✅

bd dep tree bd-1
# Output: shows all tasks as closed ✅
```

**THEN close epic**:
```bash
bd status bd-1 --status closed
```

## Why This Matters

From 24 failure memories:
- your human partner said "I don't believe you" - trust broken
- Undefined functions shipped - would crash
- Missing requirements shipped - incomplete features
- Time wasted on false completion → redirect → rework
- Violates: "Honesty is a core value. If you lie, you'll be replaced."

## When To Apply

**ALWAYS before:**
- ANY variation of success/completion claims
- ANY expression of satisfaction
- ANY positive statement about work state
- Committing, PR creation, task completion
- Moving to next task
- Delegating to agents

**Rule applies to:**
- Exact phrases
- Paraphrases and synonyms
- Implications of success
- ANY communication suggesting completion/correctness

## The Bottom Line

**No shortcuts for verification.**

Run the command. Read the output. THEN claim the result.

This is non-negotiable.
