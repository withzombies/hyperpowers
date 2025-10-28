---
name: finishing-a-development-branch
description: Use when implementation is complete and all tests pass - closes bd epic, presents integration options (merge/PR/keep/discard), executes choice, and cleans up
---

# Finishing a Development Branch

## Overview

Close bd epic, verify tests, present integration options, execute choice, clean up.

**Core principle:** Close bd epic → Verify tests → Present options → Execute choice → Clean up.

**Announce at start:** "I'm using the finishing-a-development-branch skill to complete this work."

**Context:** Called after review-implementation approves the implementation (which runs after executing-plans).

**CRITICAL:** NEVER read `.beads/issues.jsonl` directly. ALWAYS use `bd show`, `bd list`, and `bd status` commands to interact with tasks. The bd CLI provides the correct interface.

## The Process

### Step 1: Close bd Epic

**Verify all tasks are closed:**

```bash
# Show tasks in epic
bd dep tree bd-1

# Check if any tasks still open
bd list --status open --parent bd-1
```

**If any tasks still open:**
```
Cannot close epic bd-1: N tasks still open:
- bd-3: Task Name (status: in_progress)
- bd-5: Task Name (status: open)

Complete all tasks before finishing.
```

Stop. Don't proceed to Step 2.

**If all tasks closed, close the epic:**

```bash
bd status bd-1 --status closed
```

### Step 2: Verify Tests

**Before presenting options, verify tests pass using hyperpowers:test-runner agent:**

**IMPORTANT:** Use hyperpowers:test-runner agent to avoid context pollution from verbose test output.

Dispatch hyperpowers:test-runner agent:
```
Run: cargo test
(or: npm test / pytest / go test ./...)
```

Agent returns concise report with summary + failures only.

**If tests fail:**
```
Tests failing (<N> failures). Must fix before completing:

[Show failures]

Cannot proceed with merge/PR until tests pass.
```

Stop. Don't proceed to Step 3.

**If tests pass:** Continue to Step 3.

### Step 3: Determine Base Branch

```bash
# Try common base branches
git merge-base HEAD main 2>/dev/null || git merge-base HEAD master 2>/dev/null
```

Or ask: "This branch split from main - is that correct?"

### Step 4: Present Options

Present exactly these 4 options:

```
Implementation complete. What would you like to do?

1. Merge back to <base-branch> locally
2. Push and create a Pull Request
3. Keep the branch as-is (I'll handle it later)
4. Discard this work

Which option?
```

**Don't add explanation** - keep options concise.

### Step 5: Execute Choice

#### Option 1: Merge Locally

```bash
# Switch to base branch
git checkout <base-branch>

# Pull latest
git pull

# Merge feature branch
git merge <feature-branch>

# Verify tests on merged result
<test command>

# If tests pass
git branch -d <feature-branch>
```

Then: Cleanup worktree (Step 6)

#### Option 2: Push and Create PR

**First, get epic info for PR:**

```bash
# Show epic to get title and tasks
bd show bd-1
bd dep tree bd-1
```

**Then create PR:**

```bash
# Push branch
git push -u origin <feature-branch>

# Create PR with bd epic reference
gh pr create --title "feat: <epic-name>" --body "$(cat <<'EOF'
## Epic

Closes bd-<N>: <Epic Title>

## Summary
<2-3 bullets of what was implemented from epic>

## Tasks Completed
- bd-2: <Task Name>
- bd-3: <Task Name>
- bd-4: <Task Name>

## Test Plan
- [ ] All tests passing
- [ ] <additional verification steps from epic>
EOF
)"
```

Then: Cleanup worktree (Step 6)

#### Option 3: Keep As-Is

Report: "Keeping branch <name>. Worktree preserved at <path>."

**Don't cleanup worktree.**

#### Option 4: Discard

**Confirm first:**
```
This will permanently delete:
- Branch <name>
- All commits: <commit-list>
- Worktree at <path>

Type 'discard' to confirm.
```

Wait for exact confirmation.

If confirmed:
```bash
git checkout <base-branch>
git branch -D <feature-branch>
```

Then: Cleanup worktree (Step 6)

### Step 6: Cleanup Worktree

**For Options 1, 2, 4:**

Check if in worktree:
```bash
git worktree list | grep $(git branch --show-current)
```

If yes:
```bash
git worktree remove <worktree-path>
```

**For Option 3:** Keep worktree.

## Quick Reference

| Option | Merge | Push | Keep Worktree | Cleanup Branch |
|--------|-------|------|---------------|----------------|
| 1. Merge locally | ✓ | - | - | ✓ |
| 2. Create PR | - | ✓ | ✓ | - |
| 3. Keep as-is | - | - | ✓ | - |
| 4. Discard | - | - | - | ✓ (force) |

## Common Mistakes

**Skipping test verification**
- **Problem:** Merge broken code, create failing PR
- **Fix:** Always verify tests before offering options

**Open-ended questions**
- **Problem:** "What should I do next?" → ambiguous
- **Fix:** Present exactly 4 structured options

**Automatic worktree cleanup**
- **Problem:** Remove worktree when might need it (Option 2, 3)
- **Fix:** Only cleanup for Options 1 and 4

**No confirmation for discard**
- **Problem:** Accidentally delete work
- **Fix:** Require typed "discard" confirmation

## Red Flags

**Never:**
- Proceed with failing tests
- Merge without verifying tests on result
- Delete work without confirmation
- Force-push without explicit request

**Always:**
- Verify tests before offering options
- Present exactly 4 options
- Get typed confirmation for Option 4
- Clean up worktree for Options 1 & 4 only

## Integration

**Called by:**
- **review-implementation** (Step 4) - After implementation review approves

**Call chain:**
```
executing-plans → review-implementation → finishing-a-development-branch
                        ↓
                  (if gaps: STOP)
```

**Works with:**
- **bd** - Closes epic, references epic/tasks in PRs
