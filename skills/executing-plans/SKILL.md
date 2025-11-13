---
name: executing-plans
description: Use to execute bd tasks iteratively - reads epic requirements, executes ready task, reviews learnings, creates next task based on reality, repeats until epic success criteria met
---

# Executing Plans (Iterative)

## Overview

Execute bd tasks iteratively: Load epic → Execute task → Review learnings → Create next task → Repeat until success criteria met.

**Core principle:** Epic requirements are immutable. Tasks adapt to reality discovered during execution.

**Announce at start:** "I'm using the executing-plans skill to implement this epic iteratively."

**Context:** Run this after hyperpowers:writing-plans creates epic and first task.

**CRITICAL:** Use bd commands (bd show, bd ready, bd list, bd update, bd close) to interact with tasks.

## Epic = Contract, Tasks = Discovery

**Epic (immutable):**
- Requirements that MUST be met
- Success criteria that validate completion
- Anti-patterns that are FORBIDDEN

**Tasks (iterative):**
- Created one at a time based on current reality
- Each task reflects learnings from previous tasks
- Epic success criteria determine when done

## The Process

### Step 1: Load Epic Context (Once at Start)

Before executing ANY task, load the epic into context:

```bash
# Find the epic
bd list --type epic --status open

# Load epic details
bd show bd-1
```

**Extract and keep in mind:**
- Requirements (IMMUTABLE)
- Success criteria (validation checklist)
- Anti-patterns (FORBIDDEN shortcuts)
- Approach (high-level strategy)

**Why:** You need to remember the contract throughout execution. Requirements prevent watering down when blocked.

### Step 2: Execute Current Ready Task

1. **Find next ready task:**
```bash
bd ready
```

2. **Start task:**
```bash
bd update bd-2 --status in_progress
bd show bd-2
```

3. **Create substep TodoWrite todos:**

   **CRITICAL:** Tasks contain 4-8 implementation steps. Create TodoWrite todos for ALL steps to prevent incomplete execution.

   Example - if bd-2 has steps:
   ```
   1. Write test for validation function
   2. Run test (RED phase)
   3. Implement validation function
   4. Run test (GREEN phase)
   5. Refactor for clarity
   6. Commit changes
   ```

   Create TodoWrite:
   ```
   - bd-2 Step 1: Write test (pending)
   - bd-2 Step 2: Run test RED (pending)
   - bd-2 Step 3: Implement function (pending)
   - bd-2 Step 4: Run test GREEN (pending)
   - bd-2 Step 5: Refactor (pending)
   - bd-2 Step 6: Commit (pending)
   ```

4. **Follow each step exactly:**
   - Use hyperpowers:test-driven-development when implementing new functionality
   - Mark each substep completed immediately after finishing
   - Run verifications using hyperpowers:test-runner agent

5. **Pre-close verification checkpoint:**

   Before marking task complete, verify ALL substeps done:
   - Check TodoWrite: All substeps completed?
   - If incomplete: Continue with remaining substeps
   - If complete: Proceed to step 6

6. **Complete task:**
```bash
bd close bd-2
```

7. **Commit changes** (use hyperpowers:test-runner agent):
```bash
# Via test-runner agent to avoid hook pollution
Run: git add <files> && git commit -m "feat(bd-2): implement feature

Completes bd-2: Task Name"
```

### Step 3: Review Against Epic and Create Next Task

**CRITICAL:** After each task completion, adapt the plan based on reality.

**Review questions:**
1. What did we learn executing this task?
2. Did we discover any blockers, existing functionality, or limitations?
3. Does this move us toward epic success criteria?
4. What's the next logical step to meet epic requirements?
5. Are there any epic anti-patterns we need to avoid in next task?

**Re-read the epic** to keep requirements fresh:
```bash
bd show bd-1
```

**Check for plan invalidation discoveries:**

If you discovered:
- **Existing functionality** that makes next planned task redundant
- **Blocker** that requires different approach
- **Architectural mismatch** that invalidates assumptions

Then you must adapt the plan, NOT execute wasteful/invalid tasks.

**Three cases:**

#### Case A: Next Task Still Valid

If `bd ready` shows a task that's still valid given learnings:
- Proceed to Step 2 with that task
- Example: Planned task matches current reality

#### Case B: Next Task Now Redundant (Plan Invalidation)

If you discover planned task is redundant:

**Example:**
- bd-4 says "implement token refresh middleware"
- You discover during bd-2: refresh middleware already exists
- bd-4 is feasible but wasteful (duplicates existing code)

**Action:**
1. Verify the discovery (check existing code)
2. Delete or update the redundant task:
```bash
bd delete bd-4
# Or update to different work:
bd update bd-4 --title "Verify token refresh integration" --design "..."
```
3. Create new task if needed based on actual requirements
4. Document what you found and why task changed

**Do NOT:**
- Execute wasteful duplicate code
- Assume planned task must be done because it exists
- Skip without documenting

#### Case C: Need New Task Based on Learnings

If no ready task exists, or existing tasks need context from learnings:

**Create next task** based on:
- Learnings from task just completed
- Current state of codebase
- What's still needed to meet epic success criteria
- Epic anti-patterns (what to avoid)

```bash
bd create "Task N: [Next Logical Step]" \
  --type feature \
  --priority [match-epic] \
  --design "## Goal
[Specific deliverable based on current reality]

## Context
Completed bd-2: [what we learned]
[What changed from original assumptions]

## Implementation
[Detailed steps reflecting current state]

## Tests (TDD)
[Test cases based on actual implementation]

## Success Criteria
- [ ] [Specific outcomes]
- [ ] Tests passing
- [ ] Pre-commit hooks passing"

bd dep add bd-N bd-1 --type parent-child  # Link to epic
bd dep add bd-N bd-[prev] --type blocks   # Sequence after previous
```

**Key:** This task reflects reality, not outdated assumptions.

### Step 4: Check Epic Success Criteria

After each task, check if epic is complete:

```bash
bd show bd-1
```

**Are ALL success criteria met?**
- If NO → Return to Step 2 (next task)
- If YES → Proceed to Step 5 (final validation)

### Step 5: Final Validation and Closure

When all epic success criteria appear met:

1. **Run full verification:**
   - All tests passing
   - Pre-commit hooks passing
   - Manual testing of success criteria

2. **Review against epic:**
   - Announce: "I'm using the hyperpowers:review-implementation skill to verify the implementation matches the spec."
   - **REQUIRED: Use Skill tool to invoke:** `hyperpowers:review-implementation`
   - hyperpowers:review-implementation will:
     - Check each requirement (IMMUTABLE) is met
     - Verify each success criterion (MUST ALL BE TRUE) is satisfied
     - Confirm no anti-patterns (FORBIDDEN) were used
   - If approved, hyperpowers:review-implementation calls hyperpowers:finishing-a-development-branch
   - If gaps found, create tasks to fix them and return to Step 2

3. **Only close epic after review approves**

## Handling Blockers

**When you hit a blocker:**

1. **Re-read epic requirements and anti-patterns:**
```bash
bd show bd-1
```

2. **Check if your solution violates any anti-pattern:**

3. **If yes:**
   - Do NOT rationalize or work around
   - Create task: "Research solution for [blocker] that meets [requirement]"
   - OR ask user: "Blocker [X] prevents requirement [Y]. Is there flexibility here?"

4. **If no:**
   - Document blocker in current task
   - Mark task as blocked
   - Stop and ask for help

**NEVER:**
- Force through blockers
- Water down epic requirements to make task easier
- Violate anti-patterns because "it's too hard"

## Maintaining Epic Requirements (Anti-Rationalization)

**Common rationalization patterns when hitting blockers:**

| Rationalization | Prevention |
|-----------------|------------|
| "This requirement is too hard" | Re-read anti-patterns. Is your shortcut forbidden? |
| "I'll come back to this later" | Epic requires it NOW. TODOs for core integration forbidden. |
| "Let me fake this to make tests pass" | Check anti-patterns. Mocking often forbidden for integration. |
| "Existing task is wasteful, but it's planned" | Plan invalidation is allowed. Delete redundant tasks. |
| "All tasks done, epic must be complete" | Tasks done ≠ success criteria met. Run review-implementation. |

**Enforcement:**
- When blocked, re-read epic BEFORE deciding approach
- Check if solution violates anti-patterns
- If yes: Research/ask, do NOT rationalize
- If no: Document and escalate

## When to Stop and Ask

**Stop immediately when:**
- Hit blocker preventing task completion
- Discover requirements conflict
- Don't understand an instruction
- Verification fails repeatedly
- Tempted to violate epic anti-pattern

**Ask for clarification. Never guess.**

## Summary

- Load epic requirements once (immutable contract)
- Execute tasks one at a time (iterative)
- After each task: Review learnings, check epic, create next task
- Delete redundant tasks (plan invalidation allowed)
- Maintain epic requirements (no watering down)
- Stop when blocked (ask for help)
- Only close epic after review-implementation approves

**Key difference from batch:** Tasks adapt to reality. Epic stays constant.
