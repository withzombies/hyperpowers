---
name: executing-plans
description: Use to execute bd tasks iteratively - reads epic, executes task, reviews learnings, creates next task, repeats until success criteria met
---

<skill_overview>
Execute bd tasks iteratively: Load epic → Execute task → Review learnings → Create next task → Repeat until success criteria met. Epic requirements are immutable, tasks adapt to reality.
</skill_overview>

<rigidity_level>
LOW FREEDOM - Follow exact process: load epic, execute task, review, create next task.

Epic requirements are immutable. Tasks adapt to discoveries. Do not skip review or close tasks without verification.
</rigidity_level>

<quick_reference>

| Step | Command | Purpose |
|------|---------|---------|
| **Load Epic** | `bd show bd-1` | Read immutable requirements once at start |
| **Find Task** | `bd ready` | Get next ready task to execute |
| **Start Task** | `bd update bd-2 --status in_progress` | Mark task active |
| **Track Substeps** | TodoWrite for each implementation step | Prevent incomplete execution |
| **Close Task** | `bd close bd-2` | Mark task complete after verification |
| **Review** | Re-read epic, check learnings | Adapt next task to reality |
| **Create Next** | `bd create "Task N"` | Based on learnings, not assumptions |
| **Final Check** | Use `review-implementation` skill | Verify all success criteria before closing epic |

**Critical:** Epic = contract (immutable). Tasks = discovery (adapt to reality).

</quick_reference>

<when_to_use>
**Use after hyperpowers:writing-plans creates epic and first task.**

Symptoms you need this:
- bd epic exists with tasks ready to execute
- Need to implement features iteratively
- Requirements clear, but implementation path will adapt
- Want continuous learning between tasks
</when_to_use>

<the_process>

## 1. Load Epic Context (Once at Start)

Before executing ANY task, load the epic into context:

```bash
bd list --type epic --status open  # Find epic
bd show bd-1                       # Load epic details
```

**Extract and keep in mind:**
- Requirements (IMMUTABLE)
- Success criteria (validation checklist)
- Anti-patterns (FORBIDDEN shortcuts)
- Approach (high-level strategy)

**Why:** Requirements prevent watering down when blocked.

## 2. Execute Current Ready Task

```bash
bd ready                           # Find next task
bd update bd-2 --status in_progress # Start it
bd show bd-2                       # Read details
```

**CRITICAL - Create TodoWrite for ALL substeps:**

Tasks contain 4-8 implementation steps. Create TodoWrite todos for each to prevent incomplete execution:

```
- bd-2 Step 1: Write test (pending)
- bd-2 Step 2: Run test RED (pending)
- bd-2 Step 3: Implement function (pending)
- bd-2 Step 4: Run test GREEN (pending)
- bd-2 Step 5: Refactor (pending)
- bd-2 Step 6: Commit (pending)
```

**Execute steps:**
- Use `test-driven-development` when implementing features
- Mark each substep completed immediately after finishing
- Use `test-runner` agent for verifications

**Pre-close verification:**
- Check TodoWrite: All substeps completed?
- If incomplete: Continue with remaining substeps
- If complete: Close task and commit

```bash
bd close bd-2  # After ALL substeps done
```

## 3. Review Against Epic and Create Next Task

**CRITICAL:** After each task, adapt plan based on reality.

**Review questions:**
1. What did we learn?
2. Discovered any blockers, existing functionality, limitations?
3. Does this move us toward epic success criteria?
4. What's next logical step?
5. Any epic anti-patterns to avoid?

**Re-read epic:**
```bash
bd show bd-1  # Keep requirements fresh
```

**Three cases:**

**A) Next task still valid** → Proceed to Step 2

**B) Next task now redundant** (plan invalidation allowed):
```bash
bd delete bd-4  # Remove wasteful task
# Or update: bd update bd-4 --title "New work" --design "..."
```

**C) Need new task** based on learnings:
```bash
bd create "Task N: [Next Step Based on Reality]" \
  --type feature \
  --design "## Goal
[Deliverable based on what we learned]

## Context
Completed bd-2: [discoveries]

## Implementation
[Steps reflecting current state, not assumptions]

## Success Criteria
- [ ] Specific outcomes
- [ ] Tests passing"

bd dep add bd-N bd-1 --type parent-child
bd dep add bd-N bd-2 --type blocks
```

## 4. Check Epic Success Criteria

```bash
bd show bd-1  # Check success criteria
```

- ALL criteria met? → Step 5 (final validation)
- Some missing? → Step 2 (next task)

## 5. Final Validation and Closure

When all success criteria appear met:

1. **Run full verification** (tests, hooks, manual checks)

2. **REQUIRED - Use review-implementation skill:**
```
Use Skill tool: hyperpowers:review-implementation
```

Review-implementation will:
- Check each requirement met
- Verify each success criterion satisfied
- Confirm no anti-patterns used
- If approved: Calls `finishing-a-development-branch`
- If gaps: Create tasks, return to Step 2

3. **Only close epic after review approves**

</the_process>

<examples>

<example>
<scenario>Developer closes task without completing all substeps, claims "mostly done"</scenario>

<code>
bd-2 has 6 implementation steps.

TodoWrite shows:
- ✅ bd-2 Step 1: Write test
- ✅ bd-2 Step 2: Run test RED
- ✅ bd-2 Step 3: Implement function
- ⏸️ bd-2 Step 4: Run test GREEN (pending)
- ⏸️ bd-2 Step 5: Refactor (pending)
- ⏸️ bd-2 Step 6: Commit (pending)

Developer thinks: "Function works, I'll close bd-2 and move on"
Runs: bd close bd-2
</code>

<why_it_fails>
Steps 4-6 skipped:
- Tests not verified GREEN (might have broken other tests)
- Code not refactored (leaves technical debt)
- Changes not committed (work could be lost)

"Mostly done" = incomplete task = will cause issues later.
</why_it_fails>

<correction>
**Pre-close verification checkpoint:**

Before closing ANY task:
1. Check TodoWrite: All substeps completed?
2. If incomplete: Continue with remaining substeps
3. Only when ALL ✅: bd close bd-2

**Result:** Task actually complete, tests passing, code committed.
</correction>
</example>

<example>
<scenario>Developer discovers planned task is redundant, executes it anyway "because it's in the plan"</scenario>

<code>
bd-4 says: "Implement token refresh middleware"

While executing bd-2, developer discovers:
- Token refresh middleware already exists in auth/middleware/refresh.ts
- Works correctly, has tests
- bd-4 would duplicate existing code

Developer thinks: "bd-4 is in the plan, I should do it anyway"
Proceeds to implement duplicate middleware
</code>

<why_it_fails>
**Wasteful execution:**
- Duplicates existing functionality
- Creates maintenance burden (two implementations to keep in sync)
- Violates DRY principle
- Wastes time on redundant work

**Why it happens:** Treating tasks as immutable instead of epic.
</why_it_fails>

<correction>
**Plan invalidation is allowed:**

1. Verify the discovery:
```bash
# Check existing code
cat auth/middleware/refresh.ts
# Confirm it works
npm test -- refresh.spec.ts
```

2. Delete redundant task:
```bash
bd delete bd-4
```

3. Document why:
```
bd update bd-2 --design "...

Discovery: Token refresh middleware already exists (auth/middleware/refresh.ts).
Verified working with tests. bd-4 deleted as redundant."
```

4. Create new task if needed (maybe "Integrate existing refresh middleware" instead)

**Result:** Plan adapts to reality. No wasted work.
</correction>
</example>

<example>
<scenario>Developer hits blocker, waters down epic requirement to "make it easier"</scenario>

<code>
Epic bd-1 anti-patterns say:
"FORBIDDEN: Using mocks for database integration tests. Must use real test database."

Developer encounters:
- Real database setup is complex
- Mocking would make tests pass quickly

Developer thinks: "This is too hard, I'll use mocks just for now and refactor later"

Adds TODO: // TODO: Replace mocks with real DB later
</code>

<why_it_fails>
**Violates epic anti-pattern:**
- Epic explicitly forbids mocks for integration tests
- "Later" never happens (TODO remains forever)
- Tests don't verify actual integration
- Defeats purpose of integration testing

**Why it happens:** Rationalizing around blockers instead of solving them.
</why_it_fails>

<correction>
**When blocked, re-read epic:**

1. Re-read epic requirements and anti-patterns:
```bash
bd show bd-1
```

2. Check if solution violates anti-pattern:
- Using mocks? YES, explicitly forbidden

3. Don't rationalize. Instead:

**Option A - Research:**
```bash
bd create "Research: Real DB test setup for [project]" \
  --design "Find how this project sets up test databases.
Check existing test files for patterns.
Document setup process that meets anti-pattern requirements."
```

**Option B - Ask user:**
"Blocker: Test DB setup complex. Epic forbids mocks for integration.
Is there existing test DB infrastructure I should use?"

**Result:** Epic requirements maintained. Blocker solved properly.
</correction>
</example>

</examples>

<critical_rules>

## Rules That Have No Exceptions

1. **Epic requirements are immutable** → Never water down when blocked
   - If blocked: Research solution or ask user
   - Never violate anti-patterns to "make it easier"

2. **All substeps must be completed** → Never close task with pending substeps
   - Check TodoWrite before closing
   - "Mostly done" = incomplete = will cause issues

3. **Plan invalidation is allowed** → Delete redundant tasks
   - If discovered existing functionality: Delete duplicate task
   - If discovered blocker: Update or delete invalid task
   - Document what you found and why

4. **Review before closing epic** → Use review-implementation skill
   - Tasks done ≠ success criteria met
   - All criteria must be verified before closing

## Common Excuses

All of these mean: Re-read epic, check anti-patterns, ask for help:
- "This requirement is too hard"
- "I'll come back to this later"
- "Let me fake this to make tests pass"
- "Existing task is wasteful, but it's planned"
- "All tasks done, epic must be complete"

</critical_rules>

<verification_checklist>

Before closing each task:
- [ ] ALL TodoWrite substeps completed (no pending)
- [ ] Tests passing (use test-runner agent)
- [ ] Changes committed
- [ ] Task actually done (not "mostly")

Before closing epic:
- [ ] ALL success criteria met (check epic)
- [ ] review-implementation skill used and approved
- [ ] No anti-patterns violated
- [ ] All tasks closed

</verification_checklist>

<integration>

**This skill calls:**
- writing-plans (creates epic and first task before this runs)
- test-driven-development (when implementing features)
- test-runner (for running tests without output pollution)
- review-implementation (final validation before closing epic)
- finishing-a-development-branch (after review approves)

**This skill is called by:**
- User (via /hyperpowers:execute-plan command)
- After writing-plans creates epic

**Agents used:**
- hyperpowers:test-runner (run tests, return summary only)

</integration>

<resources>

**bd command reference:**
- See [bd commands](../common-patterns/bd-commands.md) for complete command list

**When stuck:**
- Hit blocker → Re-read epic, check anti-patterns, research or ask
- Don't understand instruction → Stop and ask (never guess)
- Verification fails repeatedly → Check epic anti-patterns, ask for help
- Tempted to skip steps → Check TodoWrite, complete all substeps

</resources>
