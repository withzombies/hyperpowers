---
name: brainstorming
description: Use when creating or developing anything, before writing code or implementation plans - refines rough ideas into fully-formed designs through structured Socratic questioning, alternative exploration, and incremental validation
---

# Brainstorming Ideas Into Designs

## Overview

Transform rough ideas into fully-formed designs through structured questioning and alternative exploration.

**Core principle:** Ask questions to understand, explore alternatives, present design incrementally for validation.

**Announce at start:** "I'm using the brainstorming skill to refine your idea into a design."

## Quick Reference

| Phase | Key Activities | Tool Usage | Output |
|-------|---------------|------------|--------|
| **1. Understanding** | Ask questions (one at a time) | AskUserQuestion for choices, agents for research | Purpose, constraints, criteria |
| **2. Exploration** | Propose 2-3 approaches | AskUserQuestion for approach selection, agents for patterns | Architecture options with trade-offs |
| **3. Design Presentation** | Present in 200-300 word sections | Open-ended questions | Complete design with validation |
| **4. Break into Subtasks** | Break design into 4-8 hour subtasks | Conceptual breakdown | Subtask descriptions drafted |
| **5. Create bd Issues** | Create epic/features/tasks in bd | bd CLI commands | All issues created and linked |
| **6. Refine and Validate** | Review and improve all issues | sre-task-refinement skill | Plan approved or revision needed |
| **7. Enhance bd Tasks** | Expand tasks with detailed implementation steps | writing-plans skill | Enhanced bd issues |

## The Process

**REQUIRED: Create TodoWrite tracker at start**

Use TodoWrite to create todos for each phase:

- Phase 1: Understanding (MUST invoke AskUserQuestion 3+ times, gather purpose/constraints/criteria)
- Phase 2: Exploration (2-3 approaches proposed and evaluated)
- Phase 3: Design Presentation (design validated in sections)
- Phase 4: Break into Subtasks (subtasks conceptually defined)
- Phase 5: Create bd Issues (all issues created and linked in bd)
- Phase 6: Refine and Validate (plan reviewed and approved by sre-task-refinement)
- Phase 7: Enhance bd Tasks (tasks expanded with detailed implementation steps)

Mark each phase as in_progress when working on it, completed when finished.

## Research Agents

**DO NOT perform deep research yourself. Delegate to specialized agents.**

### When to Use codebase-investigator

**Use @agent-codebase-investigator when you need to:**
- Understand how existing features are implemented
- Find where specific functionality lives in the codebase
- Identify existing patterns to follow
- Verify assumptions about codebase structure
- Check if a feature already exists

**Example delegation:**
```
Question: "How is authentication currently implemented?"
Action: Dispatch codebase-investigator with: "Find authentication implementation, including file locations, patterns used, and dependencies"
```

### When to Use internet-researcher

**Use @agent-internet-researcher when you need to:**
- Find current API documentation for external services
- Research library capabilities and best practices
- Compare technology options
- Understand current community recommendations
- Find code examples and patterns from documentation

**Example delegation:**
```
Question: "What's the recommended way to handle file uploads with this framework?"
Action: Dispatch internet-researcher with: "Find current best practices for file uploads in [framework], including official docs and common patterns"
```

### Research Protocol

**If codebase pattern exists:**
1. Use codebase-investigator to find it
2. Unless pattern is clearly unwise, assume it's the correct approach
3. Design should follow existing patterns for consistency

**If no codebase pattern exists:**
1. Use internet-researcher to find external patterns
2. Present 2-3 approaches from research in Phase 2
3. Let user choose which pattern to adopt

**If agent can't find answer:**
- Redirect question to user via AskUserQuestion
- Explain what was searched and not found
- Present as a design decision for user to make

**Be persistent with agents:**
- If first query doesn't yield results, refine the question
- Try alternative search terms or approaches
- Don't give up after one attempt

### Phase 1: Understanding

**CRITICAL: You CANNOT skip this phase. Questions reveal hidden constraints even with detailed requests.**

**Before asking questions:**

1. **Investigate current state** - DON'T do this yourself:
   - Dispatch codebase-investigator to verify project structure
   - Ask investigator to find existing architecture and patterns
   - Ask investigator to identify constraints from current codebase
   - Review investigator's findings before proceeding

2. **Then gather requirements - MANDATORY:**
   - Mark Phase 1 as in_progress in TodoWrite
   - **YOU MUST invoke AskUserQuestion tool at least 3 times**
   - DO NOT output text claiming you asked questions
   - DO NOT proceed without actual tool invocations
   - Ask ONE question at a time to refine the idea
   - **Use AskUserQuestion tool** when you have multiple choice options
   - **Use agents** when you need to verify technical information
   - Gather: Purpose, constraints, success criteria

**If you catch yourself thinking:**
- "The user's request is detailed enough"
- "I have context from codebase-investigator"
- "I can infer what they want"
- "This is straightforward, don't need questions"

**STOP. You are rationalizing. USE THE AskUserQuestion TOOL.**

**Phase 1 Completion Checklist:**
- [ ] AskUserQuestion tool invoked at least 3 times
- [ ] Purpose clearly understood
- [ ] Constraints identified
- [ ] Success criteria gathered
- [ ] Mark Phase 1 as completed in TodoWrite

**Verification:** Look at your message history. Do you see `<invoke name="AskUserQuestion">`?
- If YES → Continue to Phase 2
- If NO → You skipped Phase 1. Go back and ask questions now.

**Example using AskUserQuestion:**
```
Question: "Where should the authentication data be stored?"
Options:
  - "Session storage" (clears on tab close, more secure)
  - "Local storage" (persists across sessions, more convenient)
  - "Cookies" (works with SSR, compatible with older approach)
```

**When to delegate vs ask user:**
- "Where is auth implemented?" → codebase-investigator
- "What auth library should we use?" → internet-researcher (if not in codebase)
- "Do you want JWT or sessions?" → AskUserQuestion (design decision)

### Phase 2: Exploration

**Before proposing approaches:**

1. **Research existing patterns** - DON'T do this yourself:
   - Dispatch codebase-investigator: "Find similar features and patterns used"
   - If similar feature exists, base one approach on that pattern
   - If no codebase pattern, dispatch internet-researcher: "Find recommended approaches for [problem]"
   - Review research findings before proposing

2. **Then propose approaches:**
   - Mark Phase 2 as in_progress in TodoWrite
   - Propose 2-3 different approaches based on research
   - At least one approach should follow codebase patterns (if they exist)
   - For each: Core architecture, trade-offs, complexity assessment
   - **Use AskUserQuestion tool** to present approaches as structured choices
   - Mark Phase 2 as completed when approach is selected

**Example using AskUserQuestion:**
```
Question: "Which architectural approach should we use?"
Options:
  - "Event-driven with message queue" (matches existing notification system, scalable, complex setup)
  - "Direct API calls with retry logic" (simple, synchronous, easier to debug)
  - "Hybrid with background jobs" (balanced, moderate complexity, best of both)
```

**Research integration:**
- If codebase has pattern → Present it as primary option (unless unwise)
- If no codebase pattern → Present internet research findings
- If research yields nothing → Ask user for direction

### Phase 3: Design Presentation

- Mark Phase 3 as in_progress in TodoWrite
- Present in 200-300 word sections
- Cover: Architecture, components, data flow, error handling, testing
- **Use agents if you need to verify technical details during presentation**
- Ask after each section: "Does this look right so far?" (open-ended)
- Use open-ended questions here to allow freeform feedback
- Mark Phase 3 as completed when all sections validated

### Phase 4: Break into Subtasks

After the design has been validated, we need to break it into 4-8 hour subtasks.

- Mark Phase 4 as in_progress in TodoWrite
- Break design into discrete subtasks (4-8 hours each)
- For each subtask, draft:
  - **Goal**: 1-2 sentences describing what this delivers
  - **Effort Estimate**: 4-8 hours (if >8 hours, break down further)
  - **Success Criteria**: 3+ specific, testable criteria
  - **Implementation Checklist**: Specific files, functions, tests
  - **Key Considerations**: Error handling, edge cases, dependencies
  - **Anti-patterns**: Specific things to avoid for this subtask
- If a phase would be >16 hours, plan to break it into child subtasks
- Mark Phase 4 as completed when all subtasks drafted

### Phase 5: Create bd Issues

Now create all the issues in `bd`. Start with the epic or feature, then add the phases/subtasks and link them appropriately.

- Mark Phase 5 as in_progress in TodoWrite

### Workflow

#### 1. Initialize bd (if not already done)
```bash
bd init --prefix bd
```

#### 2. Create Parent Epic for Feature
```bash
bd create "Feature: [Feature Name]" \
  --type epic \
  --priority [0-4] \
  --design "## Goal
[1-2 sentences: what business problem does this solve?]

## Success Criteria
- [ ] All phases complete
- [ ] Integration tests passing
- [ ] Documentation updated
- [ ] Pre-commit hooks pass

## Phases
Will be created as child issues with parent-child dependencies."
```

Note the epic issue ID returned (e.g., `bd-1`).

#### 3. Create Phase Issues

**IMPORTANT**: If a phase is estimated >16 hours, break it into 4-8 hour subtasks instead of one large phase.

For each phase (3-5 phases), create an issue:

```bash
bd create "Phase N: [Descriptive Name]" \
  --type feature \
  --priority [0-4] \
  --design "## Goal
[One sentence: what specific deliverable this phase produces]

## Effort Estimate
[4-8 hours for subtasks, up to 16 hours for phases]
If >16 hours, STOP and break into subtasks (see 'Breaking Down Large Phases' below)

## Success Criteria (must be testable/verifiable)
- [ ] All functions/modules listed below are fully implemented (no stubs, no TODOs)
- [ ] Tests written and passing: [list specific test names]
- [ ] Pre-commit hooks pass (cargo fmt, cargo clippy, cargo test)
- [ ] No pattern matches for: TODO, FIXME, unimplemented!, todo!()
- [ ] [Specific behavioral criteria - e.g., 'ES handler processes 1000 events/sec']
- [ ] [Integration criteria - e.g., 'Works with existing notify-based scanner']

## Implementation Approach

### 1. Study Existing Code
[Point to 2-3 similar implementations in the codebase to learn from]

Use the web to search how other products implement the feature requested

### 2. Write Tests First (TDD)
[Specific test cases to write before implementation]

### 3. Implementation Checklist (be exhaustive)
- [ ] File path:line - function_name() - [exactly what it must do, not just 'implement']
- [ ] File path:line - struct_name - [what fields, what traits]
- [ ] Test file:line - test_name() - [what scenario it tests]
- [ ] Documentation: [what docs need updating]

### 4. Key Considerations
- **Error Handling**: [Specific error cases - use proper error handling patterns for your language]
- **Edge Cases**: [Empty input, large input, concurrent access, etc.]
- **Code Quality**: [Follow language best practices and safety guidelines from CLAUDE.md]
- **Dependencies**: [Prefer dependency injection over global state]

## Anti-patterns to Avoid (Project-Specific)
- ❌ No stub implementations (empty functions, language-specific stub markers, placeholder returns)
- ❌ No TODOs/FIXMEs without bd issue numbers
- ❌ No unsafe error handling patterns in production code
- ❌ No skipped/ignored tests without issue numbers
- ❌ No panic/crash patterns in production code
- ❌ Use safe array/collection access patterns (bounds checking)
- ❌ No 'we'll do this later' - either do it or don't include it
- ❌ [Phase-specific anti-patterns]
- Don't assume backwards compatibility is desired.

## Rollback Plan
- If this phase fails: [how to revert without breaking main]

## Commit Message Template
feat(module): Brief description of phase N

- Bullet point of what was added/changed
- Why this change was needed

Implements phase N of [feature name] (closes [issue-id])

## Before Moving to Next Phase
- [ ] All tests passing
- [ ] Code formatted ([format-command])
- [ ] Linter passes ([lint-command])
- [ ] Pre-commit hooks pass (.git/hooks/pre-commit)
- [ ] Code committed"
```

#### 4. Breaking Down Large Phases

If a phase is estimated >16 hours, create subtasks instead:

```bash
# Example: Phase 2 is 50 hours - break into 7 subtasks
bd create "Scanner 1: Vehicle Identifiers" --type task --priority 1 \
  --design "[6-8 hour task design - see Phase issue template above]"
# Returns bd-6

bd create "Scanner 2: Medical Device IDs" --type task --priority 1 \
  --design "[4-6 hour task design - see Phase issue template above]"
# Returns bd-7

# ... create all subtasks ...

# Link subtasks to parent phase with parent-child relationship
# Remember: bd dep add <CHILD> <PARENT> --type parent-child
bd dep add bd-6 bd-3 --type parent-child  # Subtask bd-6 is child of Phase bd-3
bd dep add bd-7 bd-3 --type parent-child  # Subtask bd-7 is child of Phase bd-3
# ... link all subtasks ...

# Optionally add sequential dependencies between subtasks if needed
# Remember: bd dep add <LATER> <EARLIER> (later depends on earlier)
bd dep add bd-7 bd-6  # bd-7 depends on bd-6 (do bd-6 FIRST, then bd-7)
                         # Result: bd ready will show bd-6, not bd-7
```

#### 5. Link Dependencies Between Phases

**CRITICAL: Argument Order for `bd dep add`**

The syntax is: `bd dep add [issue-id] [depends-on-id]` meaning "issue-id DEPENDS ON depends-on-id"

**For blocking dependencies (default):**
- First arg = The dependent (blocked task - starts later)
- Second arg = The dependency (blocker - must complete first)
- Mental model: "LATER depends on EARLIER" or "LATER is blocked by EARLIER"

**For parent-child relationships:**
- First arg = The child (contained item)
- Second arg = The parent (container)
- Mental model: "CHILD belongs to PARENT"

```bash
# Link phases to epic using parent-child (for hierarchy visualization)
# Syntax: bd dep add [child-id] [parent-id] --type parent-child
bd dep add bd-2 bd-1 --type parent-child  # Phase bd-2 is child of Epic bd-1
bd dep add bd-3 bd-1 --type parent-child  # Phase bd-3 is child of Epic bd-1
bd dep add bd-4 bd-1 --type parent-child  # Phase bd-4 is child of Epic bd-1
bd dep add bd-5 bd-1 --type parent-child  # Phase bd-5 is child of Epic bd-1

# Add blocking dependencies for sequential phases
# Remember: bd dep add <LATER> <EARLIER> (later depends on earlier)
# "bd-3 depends on bd-2" means Phase 2 (bd-3) can't start until Phase 1 (bd-2) finishes

bd dep add bd-3 bd-2  # Phase 2 (bd-3) depends on Phase 1 (bd-2) → Do bd-2 first
bd dep add bd-4 bd-3  # Phase 3 (bd-4) depends on Phase 2 (bd-3) → Do bd-3 first
bd dep add bd-5 bd-4  # Phase 4 (bd-5) depends on Phase 3 (bd-4) → Do bd-4 first

# WRONG EXAMPLES (common mistakes):
# ❌ bd dep add bd-2 bd-3  # This would make Phase 1 depend on Phase 2! (backwards)
# ❌ bd dep add bd-4 bd-5  # This would make Phase 3 depend on Phase 4! (backwards)

# Verification: After adding dependencies, run:
# bd ready  # Should show only bd-2 (Phase 1), not later phases

# NOTE: parent-child relationships don't create blocking semantics.
# This means epics will show in `bd ready` even though they're not workable.
# When using `bd ready`, filter out epics and focus on actual tasks/phases.
```

#### 6. View Dependency Tree
```bash
bd dep tree bd-1  # View tree for parent epic
```

#### 7. Find Ready Work
```bash
bd ready  # Shows tasks with no blocking dependencies

# NOTE: bd ready may show epics even though they're not workable items.
# Epics are containers - work on their child phases/tasks instead.
# Focus on tasks with type 'task' or 'feature', not 'epic'.
```

**After creating all issues:**
- Run `bd dep tree [epic-id]` to verify structure
- Run `bd ready` to confirm dependency chain is correct
- Mark Phase 5 as completed in TodoWrite


### Phase 6: Refine and Validate

Now have the plan reviewed by an SRE perspective to catch issues before implementation.

- Mark Phase 6 as in_progress in TodoWrite
- Announce: "I'm using the sre-task-refinement skill to review the plan."
- **REQUIRED SUB-SKILL:** Use hyper:sre-task-refinement
- sre-task-refinement will:
  - Review all issues for completeness
  - Check task granularity (no task >16 hours)
  - Verify junior-engineer implementability
  - Identify missing edge cases
  - Update issues with improvements via `bd update`
  - Provide approval or request revisions
- If major revisions needed, re-run hyper:sre-task-refinement
- Mark Phase 6 as completed when plan is approved


### Phase 7: Enhance bd Tasks

Now expand the approved bd tasks with detailed step-by-step implementation instructions.

- Mark Phase 7 as in_progress in TodoWrite
- Announce: "I'm using the writing-plans skill to enhance the bd tasks with detailed steps."
- **REQUIRED SUB-SKILL:** Use hyper:writing-plans
- writing-plans will:
  - Read the epic and all tasks from bd
  - Verify codebase state for each task
  - Expand implementation checklists into detailed steps with complete code
  - Validate each task expansion with user before updating bd
  - Update each bd issue with enhanced design using `bd update`
  - Offer execution choice (executing-plans skill)
- Mark Phase 7 as completed when all bd tasks are enhanced

**After Phase 7:**
- bd issues contain complete execution-ready instructions
- User can execute using hyper:executing-plans
- All implementation details live in bd (no separate markdown files)

**Complete workflow:**
```
brainstorming (Phases 1-7)
    ↓
executing-plans (executes bd tasks, updates status)
    ↓
review-implementation (verifies against spec)
    ↓
finishing-a-development-branch (closes epic, creates PR)
```

## Question Patterns

### When to Use AskUserQuestion Tool

**Use AskUserQuestion for:**
- Phase 1: Clarifying questions with 2-4 clear options
- Phase 2: Architectural approach selection (2-3 alternatives)
- Any decision with distinct, mutually exclusive choices
- When options have clear trade-offs to explain
- When agent research yields no answer (present as open decision)

**Benefits:**
- Structured presentation of options with descriptions
- Clear trade-off visibility for partner
- Forces explicit choice (prevents vague "maybe both" responses)

### When to Use Open-Ended Questions

**Use open-ended questions for:**
- Phase 3: Design validation ("Does this look right so far?")
- When you need detailed feedback or explanation
- When partner should describe their own requirements
- When structured options would limit creative input

**Example decision flow:**
- "What authentication method?" → Use AskUserQuestion (2-4 options)
- "Does this design handle your use case?" → Open-ended (validation)

### When to Use Research Agents

**Use codebase-investigator for:**
- "How is X implemented?" → Agent finds and reports
- "Where does Y live?" → Agent locates files
- "What pattern exists for Z?" → Agent identifies pattern

**Use internet-researcher for:**
- "What's the current API for X?" → Agent finds docs
- "How do people handle Y?" → Agent finds patterns
- "What libraries exist for Z?" → Agent researches options

**Don't do deep research yourself** - you'll consume context and may hallucinate. Agents are specialized for this.

## When to Revisit Earlier Phases

```dot
digraph revisit_phases {
    rankdir=LR;
    "New constraint revealed?" [shape=diamond];
    "Partner questions approach?" [shape=diamond];
    "Requirements unclear?" [shape=diamond];
    "Return to Phase 1" [shape=box, style=filled, fillcolor="#ffcccc"];
    "Return to Phase 2" [shape=box, style=filled, fillcolor="#ffffcc"];
    "Continue forward" [shape=box, style=filled, fillcolor="#ccffcc"];

    "New constraint revealed?" -> "Return to Phase 1" [label="yes"];
    "New constraint revealed?" -> "Partner questions approach?" [label="no"];
    "Partner questions approach?" -> "Return to Phase 2" [label="yes"];
    "Partner questions approach?" -> "Requirements unclear?" [label="no"];
    "Requirements unclear?" -> "Return to Phase 1" [label="yes"];
    "Requirements unclear?" -> "Continue forward" [label="no"];
}
```

**You can and should go backward when:**
- Partner reveals new constraint during Phase 2 or 3 → Return to Phase 1
- Validation shows fundamental gap in requirements → Return to Phase 1
- Partner questions approach during Phase 3 → Return to Phase 2
- Something doesn't make sense → Go back and clarify
- Agent research reveals constraint you didn't know → Reassess phase

**Don't force forward linearly** when going backward would give better results.

## Common Rationalizations - STOP

These are violations of the skill requirements:

| Excuse | Reality |
|--------|---------|
| "Idea is simple, can skip exploring alternatives" | Always propose 2-3 approaches. Comparison reveals issues. |
| "Partner knows what they want, can skip questions" | Questions reveal hidden constraints. Always ask. |
| "Request is detailed, don't need AskUserQuestion" | MUST invoke tool 3+ times. Output text is not asking. |
| "I'll present whole design at once for efficiency" | Incremental validation catches problems early. |
| "Checklist is just a suggestion" | Create TodoWrite todos. Track progress properly. |
| "Design doc structure doesn't matter" | sre-task-refinement expects structured issues. Follow the structure. |
| "I can research this quickly myself" | Use agents. You'll hallucinate or consume excessive context. |
| "Agent didn't find it on first try, must not exist" | Be persistent. Refine query and try again. |
| "This is small, don't need worktree" | If implementing, use worktree. Isolation prevents mistakes. |
| "Partner said yes, can skip refinement phase" | sre-task-refinement catches critical gaps. Always run Phase 6. |
| "I know this codebase, don't need investigator" | You don't know current state. Always verify. |
| "Obvious solution, skip research" | Codebase may have established pattern. Check first. |

**All of these mean: STOP. Follow the requirements exactly.**

**For more common rationalizations, see:** `skills/common-patterns/common-rationalizations.md`

## Key Principles

| Principle | Application |
|-----------|-------------|
| **One question at a time** | YOU MUST ask single questions in Phase 1, use AskUserQuestion for choices |
| **Delegate research** | YOU MUST use agents for codebase and internet research, never do it yourself |
| **Be persistent with agents** | If agent doesn't find answer, refine query and try again before asking user |
| **Follow existing patterns** | If codebase pattern exists and is reasonable, design must follow it |
| **Structured choices** | YOU MUST use AskUserQuestion tool for 2-4 options with trade-offs |
| **YAGNI ruthlessly** | Remove unnecessary features from all designs |
| **Explore alternatives** | YOU MUST propose 2-3 approaches before settling |
| **Incremental validation** | Present design in sections, validate each - never all at once |
| **TodoWrite tracking** | YOU MUST create TodoWrite todos at start, update as you progress |
| **Phase structure required** | Design document MUST include discrete implementation phases (≤8 recommended) |
| **Flexible progression** | Go backward when needed - flexibility > rigidity |
