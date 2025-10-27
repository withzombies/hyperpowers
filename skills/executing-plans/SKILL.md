---
name: executing-plans
description: Use to execute bd tasks continuously - reads tasks from bd, executes ready tasks one by one, updates bd status as you go, calls review-implementation when complete
---

# Executing Plans

## Overview

Read tasks from bd, execute ready tasks continuously, update bd status as you go.

**Core principle:** Continuous execution through ready tasks. All state lives in bd.

**Announce at start:** "I'm using the executing-plans skill to implement these bd tasks."

**Context:** This runs after writing-plans has enhanced bd tasks with detailed implementation steps.

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

3. **Follow each step exactly**:
   - Task has detailed "Implementation Steps" section from writing-plans
   - Each step is bite-sized (2-5 minutes)
   - Complete code examples provided
   - Exact commands specified

4. **Run verifications as specified**:
   - Tests should pass as you go
   - Follow exact verification commands from task

5. **Complete task** - Mark as completed in both TodoWrite and bd:
```bash
bd status bd-3 --status closed
```

6. **Reference bd task in commits**:
```bash
git commit -m "feat(bd-3): implement feature

Completes bd-3: Task Name
"
```

7. **Move to next task**:
```bash
bd ready  # Get next ready task
```

Continue with next ready task immediately. No pausing for feedback between tasks.

### Step 3: Review Implementation Against Spec

After all tasks complete and verified:
- Announce: "I'm using the review-implementation skill to verify the implementation matches the spec."
- **REQUIRED SUB-SKILL:** Use hyper:review-implementation
- review-implementation will:
  - Review each bd task's success criteria against actual implementation
  - Check for anti-pattern violations
  - Verify key considerations were addressed
  - Report gaps or approve for completion
- If approved, review-implementation calls hyper:finishing-a-development-branch
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
- Don't skip verifications
- Reference bd task IDs in commits
- Work through ready tasks continuously using `bd ready`
- Stop when blocked, don't guess
- After all tasks complete: use review-implementation skill
