---
name: managing-bd-tasks
description: Use for advanced bd operations beyond basic create/close - splitting tasks mid-flight, merging duplicates, changing dependencies, archiving epics, querying for metrics, managing cross-epic dependencies
---

# Managing bd Tasks

## Overview

Basic bd operations (create, show, close) are covered in other skills. This skill covers **advanced operations** for managing complex task structures and workflows.

**Core principle:** bd is your single source of truth for what work exists and its status. Keep it accurate.

## When to Use

Use this skill when you need to:
- Split a task that turned out too large
- Merge duplicate tasks discovered mid-flight
- Reorganize dependencies after work started
- Archive completed epics
- Query bd for metrics and status
- Manage cross-epic dependencies
- Bulk update multiple tasks
- Recover from bd mistakes

**For basic operations:** See skills/common-patterns/bd-commands.md

## Common Advanced Operations

### Operation 1: Splitting Tasks Mid-Flight

**When:** Task is in-progress but turns out too large for one sitting.

**Example scenario:**
```
Started bd-5: "Implement user authentication"
Realize it needs:
1. Login form (frontend)
2. Auth API endpoints (backend)
3. Session management (backend)
4. Password hashing (backend)
Each is 2-4 hours of work
```

**Process:**

#### Step 1: Create subtasks for remaining work

```bash
# bd-5 is already in-progress, we've done the login form
# Create subtasks for remaining work

bd create "Auth API endpoints" \
  --type task \
  --priority P1 \
  --design "
Implement POST /api/login and POST /api/logout endpoints.

## Success Criteria
- [ ] POST /api/login validates credentials
- [ ] Returns JWT token on success
- [ ] POST /api/logout invalidates token
- [ ] Tests pass for both endpoints
"

# Returns: bd-12

bd create "Session management" \
  --type task \
  --priority P1 \
  --design "
Implement session tracking with JWT tokens.

## Success Criteria
- [ ] JWT tokens generated on login
- [ ] Tokens validated on protected routes
- [ ] Token expiration handled
- [ ] Tests pass
"

# Returns: bd-13

bd create "Password hashing" \
  --type task \
  --priority P1 \
  --design "
Implement secure password hashing with bcrypt.

## Success Criteria
- [ ] Passwords hashed before storage
- [ ] Hash verification on login
- [ ] Salt rounds configurable
- [ ] Tests pass
"

# Returns: bd-14
```

#### Step 2: Set up dependencies

```bash
# API endpoints depend on password hashing
bd dep add bd-12 bd-14  # bd-12 depends on bd-14

# Session management depends on API endpoints
bd dep add bd-13 bd-12  # bd-13 depends on bd-12

# View the tree
bd dep tree bd-5
# Shows: bd-5 with children bd-12, bd-13, bd-14
```

#### Step 3: Update original task

```bash
# Mark what's done in bd-5, reference new tasks
bd edit bd-5 --design "
Implement user authentication.

## Status
✓ Login form completed (frontend)
✗ Remaining work split into subtasks:
  - bd-14: Password hashing (do first)
  - bd-12: Auth API endpoints (depends on bd-14)
  - bd-13: Session management (depends on bd-12)

## Success Criteria
- [x] Login form renders
- [ ] See subtasks for remaining criteria
"

# Close bd-5 since remaining work is tracked in subtasks
bd status bd-5 --status closed
```

#### Step 4: Work on subtasks in order

```bash
# Check what's ready
bd ready

# Start with bd-14 (no dependencies)
bd status bd-14 --status in-progress
# Complete bd-14...
bd status bd-14 --status closed

# Now bd-12 is unblocked
bd status bd-12 --status in-progress
# etc.
```

### Operation 2: Merging Duplicate Tasks

**When:** Discover two tasks are actually the same thing.

**Example:**
```
bd-7: "Add email validation"
bd-9: "Validate user email addresses"
^ These are duplicates
```

**Process:**

#### Step 1: Identify which task to keep

**Choose based on:**
- Which has more complete design?
- Which has more work done?
- Which has more dependencies?

**Example:** Keep bd-7 (more complete), merge bd-9 into it.

#### Step 2: Merge designs

```bash
# Read both tasks
bd show bd-7
bd show bd-9

# Combine information into bd-7
bd edit bd-7 --design "
Add email validation to user creation and update.

## Background
Originally tracked as bd-7 and bd-9 (now merged).

## Success Criteria
- [ ] Email validated on user creation
- [ ] Email validated on user update
- [ ] Validation rejects invalid formats
- [ ] Validation rejects empty strings
- [ ] Tests cover all validation cases

## Notes
Merged from bd-9: Also need to validate on update, not just creation.
"
```

#### Step 3: Move dependencies

```bash
# Check if bd-9 had dependencies
bd show bd-9 | grep -A 10 "Dependencies"

# If bd-10 depended on bd-9, update to depend on bd-7
bd dep remove bd-10 bd-9
bd dep add bd-10 bd-7
```

#### Step 4: Close duplicate with reference

```bash
bd edit bd-9 --design "
DUPLICATE: Merged into bd-7

This task was a duplicate of bd-7. All work is tracked there.
"

bd status bd-9 --status closed
```

### Operation 3: Changing Dependencies After Work Started

**When:** Realize dependencies were wrong or requirements changed.

**Example:**
```
Initially: bd-10 depends on bd-8 and bd-9
Now: bd-9 got merged, and bd-10 also needs bd-11 (new requirement)
```

**Process:**

```bash
# Remove obsolete dependency (bd-9 was merged)
bd dep remove bd-10 bd-9

# Add new dependency (newly discovered requirement)
bd dep add bd-10 bd-11  # bd-10 now depends on bd-11

# Verify new dependency tree
bd dep tree bd-1  # (if bd-10 is part of epic bd-1)

# Check what's blocking bd-10 now
bd show bd-10 | grep "Blocking"
```

**Common scenarios:**
- Discovered hidden dependency during implementation
- Requirements changed mid-flight
- Tasks got reordered for better flow
- Epic got reorganized

### Operation 4: Archiving Completed Epics

**When:** Epic complete, want to hide from default views but keep for history.

```bash
# Verify all tasks in epic are closed
bd list --parent bd-1 --status open
# Output: [empty] = all tasks closed

# Archive the epic
bd status bd-1 --status archived

# Archived epics don't show in normal listings
bd list --status open
# bd-1 won't appear

# Can still access archived epic
bd show bd-1
# Still shows full epic
```

**Use archived status for:**
- Completed epics (not actively working on)
- Old features (shipped to production)
- Historical reference (keep for learning)

**Don't use archived for:**
- Active work (use open/in-progress)
- Cancelled work (use closed with note explaining why)

### Operation 5: Querying bd for Metrics

**Common queries:**

#### Velocity (tasks completed per time period)

```bash
# Tasks closed this week
bd list --status closed | grep "closed_at" | grep "2025-10-" | wc -l

# Tasks closed by epic
bd list --parent bd-1 --status closed | wc -l
```

#### Work in Progress

```bash
# All in-progress tasks
bd list --status in-progress

# Count
bd list --status in-progress | grep "^bd-" | wc -l
```

#### Blocked vs Ready Work

```bash
# Ready to work on (unblocked)
bd ready

# Count ready tasks
bd ready | grep "^bd-" | wc -l

# All open tasks
bd list --status open | wc -l

# Blocked = open - ready
```

#### Epic Progress

```bash
# Show epic dependency tree
bd dep tree bd-1

# Count total tasks in epic
bd list --parent bd-1 | grep "^bd-" | wc -l

# Count completed tasks in epic
bd list --parent bd-1 --status closed | grep "^bd-" | wc -l

# Percentage complete
# (completed / total) * 100
```

#### Bottleneck Identification

```bash
# Find tasks that are blocking others
# (Tasks that many other tasks depend on)
for task in $(bd list --status open | grep "^bd-" | cut -d: -f1); do
  echo -n "$task: "
  bd list --status open | xargs -I {} sh -c "bd show {} | grep -q \"depends on $task\" && echo {}" | wc -l
done | sort -t: -k2 -n -r

# Shows tasks with most dependencies (top bottlenecks)
```

### Operation 6: Managing Cross-Epic Dependencies

**When:** Task in one epic depends on task in different epic.

**Example:**
```
Epic bd-1: User Management
  - bd-10: User CRUD API

Epic bd-2: Order Management
  - bd-20: Order creation
  - bd-20 needs bd-10 (user API) to work
```

**Process:**

```bash
# Add cross-epic dependency
bd dep add bd-20 bd-10
# bd-20 (in epic bd-2) depends on bd-10 (in epic bd-1)

# View bd-20's dependencies
bd show bd-20 | grep -A 5 "Blocking"
# Shows: bd-10 (from different epic)

# Check what's ready across epics
bd ready
# Won't show bd-20 until bd-10 is closed
```

**Best practices:**
- Document cross-epic dependencies clearly
- Consider if epics should be merged
- Coordinate with other developers if different people own epics

### Operation 7: Bulk Status Updates

**When:** Need to update multiple tasks at once.

**Example:** Mark all test tasks in epic as closed after test suite complete.

```bash
# Get all open test tasks in epic
bd list --parent bd-1 --status open | grep "test:" > test-tasks.txt

# Review list
cat test-tasks.txt

# Update each one
while read task_id; do
  bd status "$task_id" --status closed
done < test-tasks.txt

# Verify
bd list --parent bd-1 --status open | grep "test:"
# Should be empty
```

**Use bulk updates for:**
- Marking completed work as closed
- Reopening related tasks
- Updating priorities for sprint

**Don't use for:**
- Thoughtless status changes
- Hiding problems (closing tasks that aren't done)

### Operation 8: Recovering from Mistakes

#### Accidentally Closed Task

```bash
# Reopen it
bd status bd-15 --status open

# Or if work in progress
bd status bd-15 --status in-progress
```

#### Wrong Dependency Added

```bash
# Remove incorrect dependency
bd dep remove bd-10 bd-8

# Add correct dependency
bd dep add bd-10 bd-9
```

#### Need to Undo Design Changes

```bash
# bd doesn't have undo, but you can restore from git
# If design was in commit

git log -p -- .beads/issues.jsonl | grep -A 50 "bd-10"
# Find previous version, copy content

bd edit bd-10 --design "
[paste previous version]
"
```

#### Epic Structure Wrong

**If epic needs restructuring:**
1. Create new tasks with correct structure
2. Move work to new tasks
3. Close old tasks with reference to new ones
4. Don't delete (keep for audit trail)

## bd Best Practices

### Task Naming Conventions

**Good names:**
- `feat(auth): Implement JWT token generation`
- `fix(api): Handle empty email validation`
- `test: Add integration tests for user API`
- `refactor: Extract validation logic`

**Bad names:**
- `fix stuff` (vague)
- `implement feature` (which feature?)
- `work on backend` (what work?)

### Priority Guidelines

Use bd's priority system consistently:

- **P0:** Critical production bug (drop everything)
- **P1:** Blocking other work (do next)
- **P2:** Important feature work (normal priority)
- **P3:** Nice to have (do when time permits)
- **P4:** Someday/maybe (backlog)

### Granularity Guidelines

**Good task size:**
- 2-4 hours of focused work
- Can complete in one sitting
- Clear deliverable

**Too large:**
- Takes multiple days
- Multiple independent pieces
- Should be split

**Too small:**
- Takes 15 minutes
- Too granular to track
- Combine with related tasks

### Success Criteria Templates

Every task should have clear success criteria:

```markdown
## Success Criteria
- [ ] Specific, testable outcome
- [ ] Another specific outcome
- [ ] Tests pass
- [ ] No new warnings
```

**Not:**
```markdown
## Success Criteria
- [ ] Code works
- [ ] Tests pass
```

### Dependency Management

**Good dependency usage:**
- Technical dependency (feature B needs feature A's code)
- Clear ordering (must do A before B)
- Unblocks work (completing A unblocks B)

**Bad dependency usage:**
- "Feels like should be done first" (vague)
- No technical relationship (just preference)
- Circular dependencies (A depends on B depends on A)

## Common Rationalizations - STOP

| Excuse | Reality |
|--------|---------|
| "Task too complex to split" | Every task can be broken down. If unsure how, ask. |
| "Just close duplicate, don't merge" | Lose information. Merge designs first. |
| "Won't track this in bd" | If it's work, it's tracked. No exceptions. |
| "bd is out of date, I'll update later" | Later never comes. Update as you go. |
| "This dependency doesn't matter" | Dependencies prevent blocking. They matter. |
| "Too much overhead to split task" | More overhead to do huge task in one shot and fail. |

## Red Flags - STOP

**Watch for these patterns:**
- Multiple in-progress tasks (focus on one)
- Tasks stuck in-progress for days (blocked? split it?)
- Many open tasks with no dependencies (prioritize!)
- Epics with 20+ tasks (too large, split epic)
- Closed tasks with incomplete criteria (not done, reopen)

## Integration with Other Skills

**Related operations in other skills:**
- Basic bd commands: See skills/common-patterns/bd-commands.md
- Creating epics: writing-plans skill
- Executing tasks: executing-plans skill
- Closing tasks: verification-before-completion skill

## Quick Reference

| Operation | Command | Notes |
|-----------|---------|-------|
| Split task | Create subtasks, add dependencies, close parent | Keep parent as summary |
| Merge duplicates | Combine designs, move deps, close duplicate | Document merge in both |
| Change dependency | `bd dep remove`, then `bd dep add` | Update both tasks |
| Archive epic | `bd status bd-X --status archived` | All tasks must be closed first |
| Count progress | `bd list --parent bd-X` + `wc -l` | Compare open vs closed |
| Find bottlenecks | List deps, count blockers | Tasks blocking most others |
| Cross-epic dep | `bd dep add` works across epics | Document clearly |
| Bulk update | Loop with `bd status` | Review list first |
| Undo mistake | `bd status` to reopen/reclose | No built-in undo |

## Remember

- **bd is single source of truth** - Keep it accurate
- **Split large tasks** before they become blocking
- **Merge duplicates** don't just close
- **Dependencies enable flow** - Use them correctly
- **Track all work** - No exceptions
- **Update as you go** - Don't batch updates

Advanced bd operations keep your workflow organized and transparent.
