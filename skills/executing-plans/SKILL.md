---
name: executing-plans
description: Use to execute bd tasks continuously - reads tasks from bd, executes ready tasks one by one, updates bd status as you go, calls hyperpowers:review-implementation when complete
---

# Executing Plans

## Overview

Read tasks from bd, execute ready tasks continuously, update bd status as you go.

**Core principle:** Continuous execution through ready tasks. All state lives in bd.

**Announce at start:** "I'm using the executing-plans skill to implement these bd tasks."

**Context:** This runs after hyperpowers:writing-plans has enhanced bd tasks with detailed implementation steps.

**CRITICAL:** NEVER read `.beads/issues.jsonl` directly. ALWAYS use `bd show`, `bd ready`, `bd list`, and `bd status` commands to interact with tasks. The bd CLI provides the correct interface.

## Review Granularity

**You can review at two levels:**

1. **Final review** (default) - Use hyperpowers:review-implementation skill after all tasks complete
   - Reviews entire implementation against epic
   - Best for catching integration issues
   - Faster overall execution

2. **Per-task review** - Use hyperpowers:code-reviewer agent after each task completes
   - Reviews each task immediately after implementation
   - Catches issues early before they cascade
   - Slower but more thorough

**User specifies:** "Review each task as we go" or "Review at the end"

If user doesn't specify, use final review (default).

## The Process

### Step 1: Load and Review Plan from bd

1. **Find the epic** (user provides epic ID or you search):
```bash
# If epic ID known
bd show bd-1

# Or search for open epics
bd list --type epic --status open
```

2. **Get all ready tasks**:
```bash
# Show tasks with no blocking dependencies
bd ready

# Or get all tasks in epic
bd dep tree bd-1
```

3. **Review first few tasks critically**:
   - Read task designs with `bd show bd-N`
   - Check if implementation steps are clear
   - Identify any questions or concerns

4. **If concerns:** Raise them with your human partner before starting

5. **If no concerns:** Create TodoWrite with task IDs and proceed

### Step 2: Execute Tasks Continuously

For each ready task from `bd ready`:

1. **Start task** - Mark as in_progress in both TodoWrite and bd:
```bash
bd status bd-3 --status in_progress
```

2. **Read implementation steps**:
```bash
bd show bd-3
```

3. **Create substep TodoWrite todos**:

   **CRITICAL:** "Checklists without TodoWrite tracking = steps get skipped. Every time." (from using-hyper skill)

   Tasks contain 4-8 implementation steps. You MUST create TodoWrite todos for ALL steps to prevent incomplete execution.

   **Example:** If bd-3 has implementation steps:
   ```
   1. Write test for validation function
   2. Run test (RED phase)
   3. Implement validation function
   4. Run test (GREEN phase)
   5. Refactor for clarity
   6. Commit changes
   ```

   Create TodoWrite with these substeps:
   ```
   - bd-3 Step 1: Write test for validation function (pending)
   - bd-3 Step 2: Run test (RED phase) (pending)
   - bd-3 Step 3: Implement validation function (pending)
   - bd-3 Step 4: Run test (GREEN phase) (pending)
   - bd-3 Step 5: Refactor for clarity (pending)
   - bd-3 Step 6: Commit changes (pending)
   ```

   **As you execute:**
   - Mark current step as in_progress
   - Mark completed steps as completed
   - This provides visible progress: "2/6 steps done" prevents premature task closure

   **Why this matters:** Without substep tracking, you'll mark tasks "complete" at 33% execution (2/6 steps done). TodoWrite visibility prevents this rationalization.

4. **Follow each step exactly**:
   - Task has detailed "Implementation Steps" section from hyperpowers:writing-plans
   - Each step is bite-sized (2-5 minutes)
   - Complete code examples provided
   - Exact commands specified
   - **When implementing new functionality:** Use hyperpowers:test-driven-development skill
     - Write test first (RED phase)
     - Watch test fail
     - Write minimal code to pass (GREEN phase)
     - Refactor while keeping tests green
   - **As you complete each substep:** Mark it as completed in TodoWrite immediately

5. **Run verifications as specified**:
   - Tests should pass as you go
   - Follow exact verification commands from task
   - **IMPORTANT:** Use hyperpowers:test-runner agent for running tests
     - Dispatch hyperpowers:test-runner agent with command: "Run: cargo test"
     - Keeps verbose test output in agent context
     - Returns only summary + failures
     - Prevents context pollution

6. **Pre-close verification checkpoint**:

   **CRITICAL GATE:** Before marking task complete, verify ALL substeps are done.

   **Check TodoWrite:**
   - Are ALL substeps marked as completed?
   - Example: bd-3 has 6 substeps, all 6 must show status "completed"

   **If substeps incomplete:**
   - ❌ DO NOT close task
   - ❌ DO NOT run `bd status bd-3 --status closed`
   - ✅ Continue execution with remaining substeps
   - ✅ Mark each substep completed as you finish it

   **If all substeps completed:**
   - ✅ Proceed to step 7 (Complete task)

   **This checkpoint prevents:**
   - Marking tasks "complete" at 2/6 steps (33% execution)
   - Rationalizing "made progress" as "task done"
   - Skipping steps 4-6 due to "continue immediately" pressure

7. **Complete task** - Mark as completed in both TodoWrite and bd:
```bash
bd status bd-3 --status closed
```

8. **Commit changes** (use hyperpowers:test-runner agent to avoid hook pollution):
   - **IMPORTANT:** Use hyperpowers:test-runner agent for commits
   - Pre-commit hooks often run tests/linters with verbose output
   - Agent captures all output, returns only summary + failures

   Dispatch hyperpowers:test-runner agent:
   ```
   Run: git add <files> && git commit -m "feat(bd-3): implement feature

   Completes bd-3: Task Name"
   ```

   If hooks fail, agent reports failures. Fix and retry commit.

9. **Optional: Per-task review** (if user requested):
   - Use hyperpowers:code-reviewer agent to review this task's implementation
   - Agent checks: implementation matches bd task, no anti-patterns, tests passing
   - Fix any issues found before proceeding

10. **Move to next task**:
```bash
bd ready  # Get next ready task
```

**Verify all substeps complete in current task, THEN continue with next ready task.**

**Do NOT continue to next task if:**
- Current task's TodoWrite substeps show incomplete steps
- You rationalize "made progress, can finish later"
- You feel pressure to "move fast"

**Only continue when:**
- ALL substeps in TodoWrite are marked completed
- Current task closed in bd
- Commit complete (if applicable)

### Step 3: Review Implementation Against Spec

After all tasks complete and verified:
- Announce: "I'm using the hyperpowers:review-implementation skill to verify the implementation matches the spec."
- **REQUIRED: Use Skill tool to invoke:** `hyperpowers:review-implementation`
- hyperpowers:review-implementation will:
  - Review each bd task's success criteria against actual implementation
  - Check for anti-pattern violations
  - Verify key considerations were addressed
  - Report gaps or approve for completion
- If approved, hyperpowers:review-implementation calls hyperpowers:finishing-a-development-branch
- If gaps found, fix them before proceeding

## When to Stop and Ask for Help

**STOP executing immediately when:**
- Hit a blocker mid-batch (missing dependency, test fails, instruction unclear)
- Plan has critical gaps preventing starting
- You don't understand an instruction
- Verification fails repeatedly

**Ask for clarification rather than guessing.**

## When to Revisit Earlier Steps

**Return to Review (Step 1) when:**
- Partner updates bd tasks based on your feedback
- Fundamental approach needs rethinking

**Don't force through blockers** - stop and ask.

## Working with bd

**For complete bd command reference, see:** `skills/common-patterns/bd-commands.md`

### Quick Reference

```bash
# Find ready tasks
bd ready

# Show task details
bd show bd-3

# Update status
bd status bd-3 --status in_progress  # Start
bd status bd-3 --status closed       # Complete

# View dependencies
bd dep tree bd-1
```

### Dependency Chain

Tasks may have dependencies. Always use `bd ready` to see what's ready to work on.

If a task is blocked, `bd ready` won't show it until its dependencies are closed.

## Remember
- Read tasks from bd, not markdown files
- Update bd status as you work (in_progress → closed)
- Follow detailed implementation steps in bd task design
- Use hyperpowers:test-driven-development skill when implementing new functionality (write test first, watch fail, implement)
- Don't skip verifications
- Reference bd task IDs in commits
- Work through ready tasks continuously using `bd ready`
- Stop when blocked, don't guess
- Review: per-task (hyperpowers:code-reviewer agent) or final (hyperpowers:review-implementation skill)
  - Per-task if user requested: "Review each task as we go"
  - Final review (default): use hyperpowers:review-implementation skill after all tasks complete
