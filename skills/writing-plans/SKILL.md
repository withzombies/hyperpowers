---
name: writing-plans
description: Use to expand bd task implementation checklists into detailed step-by-step instructions - enhances bd tasks with exact file paths, complete code examples, and verification commands for engineers with zero codebase context. Can work on single tasks or multiple tasks.
---

# Writing Plans

## Overview

Enhance bd tasks with comprehensive implementation details assuming the engineer has zero context for our codebase. Expand implementation checklists into explicit steps: which files to touch, complete code examples, exact test commands, verification steps. Everything stays in bd - no separate markdown files.

Assume they are a junior developer who knows almost nothing about our toolset or problem domain. Assume they don't know good test design very well.

**Announce at start:** "I'm using the hyperpowers:writing-plans skill to expand bd task(s) with detailed implementation steps."

**Context:** This can run after hyperpowers:sre-task-refinement approves bd issues, or anytime you want to expand tasks with more detail.

**Input:** One or more bd task IDs (e.g., bd-2, or bd-2 through bd-5)

**Output:** Enhanced bd issues with detailed implementation steps

**CRITICAL:** NEVER read `.beads/issues.jsonl` directly. ALWAYS use `bd show`, `bd list`, and `bd edit` commands to interact with tasks. The bd CLI provides the correct interface.

## Flexible Scope

**You can enhance:**
- **Single task:** "Expand bd-2 with implementation steps"
- **Multiple tasks:** "Expand bd-2 through bd-5"
- **Entire epic:** "Expand all tasks in bd-1"

**No artificial limits.** Work on as many or as few tasks as makes sense for the situation.

## Before Starting

**REQUIRED: Identify scope and verify codebase state**

### 1. Identify Tasks to Expand

**User specifies scope in one of these ways:**
- Explicit task list: "Expand bd-2, bd-3, bd-5"
- Range: "Expand bd-2 through bd-8"
- Epic: "Expand all tasks in bd-1"
- Single: "Expand bd-2"

**If user says "expand all tasks in bd-1":**

```bash
# View complete dependency tree
bd dep tree bd-1

# This shows all child tasks/phases
```

Make note of all task IDs to expand.

**If user provides range or explicit list:** Use those task IDs directly.

### 2. Codebase Verification

**YOU MUST verify current codebase state before writing ANY task.**

**DO NOT verify codebase yourself. Use hyperpowers:codebase-investigator agent.**

**Provide the agent with bd issue assumptions so it can report discrepancies:**

For each task in the epic, read the implementation checklist and file references, then dispatch hyperpowers:codebase-investigator agent with:
- "bd-3 assumes these files exist: [list with expected paths from bd issue]"
- "Verify each file exists and report any differences from these assumptions"
- "bd-3 says [feature] is implemented in [location]. Verify this is accurate"
- "bd-3 expects [dependency] version [X]. Check actual version installed"

**Example query to agent:**
```
Assumptions from bd-3 (Phase 1: Setup Auth):
- Auth service should be in src/services/auth.ts with login() and logout() functions
- User model in src/models/user.ts with email and password fields
- Test file at tests/services/auth.test.ts
- Uses bcrypt dependency for password hashing

Verify these assumptions and report:
1. What exists vs what bd-3 expects
2. Any structural differences (different paths, functions, exports)
3. Any missing or additional components
4. Current dependency versions
```

Review investigator findings and note any differences from bd task assumptions.

**Based on investigator report, NEVER write:**
- "Update `index.js` if exists"
- "Modify `config.py` (if present)"
- "Create or update `types.ts`"

**Based on investigator report, ALWAYS write:**
- "Create `src/auth.ts`" (investigator confirmed doesn't exist)
- "Modify `src/index.ts:45-67`" (investigator confirmed exists, checked line numbers)
- "No changes needed to `config.py`" (investigator confirmed already correct)

**If codebase state differs from bd task assumptions:** Document the difference and adjust the implementation plan accordingly. The bd issue may have been written before recent codebase changes.

## Bite-Sized Step Granularity

**Each step is one action (2-5 minutes):**
- "Write the failing test" - step
- "Run it to make sure it fails" - step
- "Implement the minimal code to make the test pass" - step
- "Run the tests and make sure they pass" - step
- "Commit" - step

**Note:** These steps follow the hyperpowers:test-driven-development skill's RED-GREEN-REFACTOR cycle. When writing implementation steps for new functionality, reference the TDD workflow.

These detailed steps will be added to each bd task's design.

## Task-by-Task User Validation

**CRITICAL: Validate EACH expanded task with user BEFORE updating bd issue.**

**Step 0: Create TodoWrite tracker**

After identifying scope, create a TodoWrite todo list with one item per bd task you'll expand:

```markdown
- [ ] bd-2: [Task Title]
- [ ] bd-3: [Task Title]
- [ ] bd-4: [Task Title]
...
```

Mark each task as in_progress when working on it, completed when user approves expansion.

**For single-task expansions:** Still use TodoWrite with one item for consistency.

**Workflow for EACH task:**

1. **Mark task as in_progress** in TodoWrite
2. **Read current task design from bd** using `bd show bd-3`
3. **Verify codebase state** for files mentioned in this task:
   - Dispatch hyperpowers:codebase-investigator with bd task assumptions
   - Review investigator findings for discrepancies
4. **Draft expanded implementation steps** (in memory, not in bd yet) based on actual codebase state
5. **Present expansion to user** - CRITICAL: Show the complete expanded design BEFORE asking for approval:

**YOU MUST output the complete task expansion in your message text FIRST:**

```markdown
**bd-[N]: [Task Title]**

**From bd issue:**
- Goal: [From bd show bd-N]
- Effort estimate: [From bd issue]
- Success criteria: [From bd issue]

**Codebase verification findings:**
- ✓ bd-[N] assumption confirmed: [what matched]
- ✗ bd-[N] assumption incorrect: [what issue said] - ACTUALLY: [reality]
- + Found additional: [unexpected things discovered]
- ✓ Dependency confirmed: [library@version]

**Implementation steps based on actual codebase state:**

### Step Group 1: [Component Name]

**Files:**
- Create: `exact/path/to/file.py`
- Modify: `exact/path/to/existing.py:123-145`
- Test: `tests/exact/path/to/test.py`

**Step 1: Write the failing test**
[Complete code example]

**Step 2: Run test to verify it fails**
[Exact command and expected output]

**Step 3: Write minimal implementation**
[Complete code example]

**Step 4: Run test to verify it passes**
[Exact command and expected output]

**Step 5: Commit**
[Exact git commands with reference to bd issue]

[Continue for all step groups in this task...]
```

**THEN use AskUserQuestion with:**

**Options:**
- "Approved - proceed to next task"
- "Needs revision - [describe changes]"
- "Other"

**DO NOT ask for approval without showing the complete task expansion first. The user needs to SEE the expanded design before approving it.**

6. **If approved:**
   - Update bd issue with expanded design using `bd update bd-3 --design "..."`
   - Mark task as completed in TodoWrite
   - Continue to next task
7. **If needs revision:**
   - Keep as in_progress
   - Revise based on feedback
   - Present again
8. **After ALL tasks expanded and updated in bd:**
   - All bd issues now contain detailed implementation steps
   - Epic is ready for execution
   - Offer execution choice (hyperpowers:executing-plans skill)

**DO NOT update bd issues until each task expansion is user-validated.**

This prevents going off track early and wasting effort on wrong implementation details.

## CRITICAL: No Placeholder Text

**NEVER EVER write meta-references in the design field. Examples of FORBIDDEN text:**

❌ `[Full implementation steps as detailed above - includes all 6 step groups with complete code examples]`
❌ `[Implementation steps as specified in the success criteria]`
❌ `[Complete code examples will be added here]`
❌ `[See above for detailed steps]`
❌ `[As detailed in the implementation checklist]`

**These are COMPLETELY UNACCEPTABLE because:**
1. The bd task is the source of truth - there is no "above" to reference
2. The executor (human or Claude) has zero context and needs ACTUAL steps
3. Placeholders defeat the entire purpose of task refinement
4. This violates the core principle of "exact instructions for zero-context engineer"

**ALWAYS write actual content:**

✅ Write the complete step-by-step instructions with actual code
✅ Include all code examples in full
✅ Specify exact file paths and commands
✅ No shortcuts, no references to non-existent content

**If you catch yourself writing a meta-reference: STOP. Delete it. Write the actual content.**

## Expanded Task Structure (in bd issue after enhancement)

The expanded design you add to bd issues should follow this structure:

```markdown
## Goal
[Original goal from bd issue - keep this]

## Effort Estimate
[Original estimate - keep this]

## Success Criteria
[Original criteria - keep this]

## Implementation Steps (ADDED BY writing-plans)

### Step Group 1: [Component Name]

**Files:**
- Create: `exact/path/to/file.py`
- Modify: `exact/path/to/existing.py:123-145`
- Test: `tests/exact/path/to/test.py`

**Step 1: Write the failing test**

```python
def test_specific_behavior():
    result = function(input)
    assert result == expected
```

**Step 2: Run test to verify it fails**

Run: `pytest tests/path/test.py::test_name -v`
Expected: FAIL with "function not defined"

**Step 3: Write minimal implementation**

```python
def function(input):
    return expected
```

**Step 4: Run test to verify it passes**

Run: `pytest tests/path/test.py::test_name -v`
Expected: PASS

**Step 5: Commit (use hyperpowers:test-runner agent)**

```bash
# Use test-runner agent to avoid pre-commit hook pollution
Dispatch hyperpowers:test-runner agent: "Run: git add tests/path/test.py src/path/file.py && git commit -m 'feat(bd-[N]): add specific feature

Implements step group 1 of bd-[N]
'"
```

### Step Group 2: [Next Component]

[Continue with additional step groups...]

## Key Considerations
[Original considerations - keep these]

## Anti-patterns
[Original anti-patterns - keep these]
```

**Important:** Preserve all original sections from hyperpowers:sre-task-refinement, and add the detailed "Implementation Steps" section.

## Working with bd

### Reading Epic and Tasks

```bash
# Show epic details
bd show bd-1

# View complete dependency tree for epic
bd dep tree bd-1

# List all tasks in epic (alternative method)
bd list --parent bd-1

# Show individual task design
bd show bd-3
```

### Understanding Task Design Structure

Each bd task contains:
- **Goal**: 1-2 sentence objective
- **Effort Estimate**: Expected hours
- **Success Criteria**: Testable checkboxes
- **Implementation Checklist**: Files, functions, tests
- **Key Considerations**: Edge cases, error handling
- **Anti-patterns**: Things to avoid

Your job is to expand the **Implementation Checklist** into detailed step-by-step code and commands.

### Updating bd Issues with Expanded Steps

After user approves an expansion, update the bd issue:

```bash
bd update bd-3 --design "$(cat <<'EOF'
## Goal
Implement user authentication with JWT tokens

## Effort Estimate
6-8 hours

## Success Criteria
- [ ] JWT tokens generated with proper claims
- [ ] Tokens verified with signature validation
- [ ] All tests passing
- [ ] No unsafe error handling

## Implementation Steps (ADDED BY writing-plans)

### Step Group 1: JWT Token Generation

**Files:**
- Create: src/auth/jwt.ts
- Test: tests/auth/jwt.test.ts

**Step 1: Write the failing test**

\`\`\`typescript
import { generateToken } from '../src/auth/jwt';

test('generates valid JWT token', () => {
  const token = generateToken({ userId: '123', email: 'test@example.com' });
  expect(token).toBeDefined();
  expect(typeof token).toBe('string');
});
\`\`\`

**Step 2: Run test to verify it fails**

Run: `npm test tests/auth/jwt.test.ts`
Expected: FAIL with "generateToken is not defined"

**Step 3: Write minimal implementation**

\`\`\`typescript
import jwt from 'jsonwebtoken';

export function generateToken(payload: Record<string, any>): string {
  return jwt.sign(payload, process.env.JWT_SECRET!, { expiresIn: '24h' });
}
\`\`\`

**Step 4: Run test to verify it passes**

Run: `npm test tests/auth/jwt.test.ts`
Expected: PASS

**Step 5: Commit (use hyperpowers:test-runner agent)**

\`\`\`bash
# Use test-runner agent to avoid pre-commit hook pollution
Dispatch hyperpowers:test-runner agent: "Run: git add src/auth/jwt.ts tests/auth/jwt.test.ts && git commit -m 'feat(bd-3): add JWT token generation

Implements step group 1 of bd-3: User Authentication
'"
\`\`\`

[Continue with step groups for verifyToken, middleware...]

## Key Considerations
[Original from hyperpowers:sre-task-refinement]

## Anti-patterns
[Original from hyperpowers:sre-task-refinement]
EOF
)"
```

## Common Rationalizations - STOP

These are violations of the skill requirements:

| Excuse | Reality |
|--------|---------|
| "File probably exists, I'll say 'update if exists'" | Use hyperpowers:codebase-investigator. Write definitive instruction. |
| "bd issue mentioned this file, must be there" | Codebase changes. Use investigator to verify current state. |
| "I can quickly verify files myself" | Use hyperpowers:codebase-investigator. Saves context and prevents hallucination. |
| "User can figure out if file exists during execution" | Your job is exact instructions. No ambiguity. |
| "Task validation slows me down" | Going off track wastes far more time. Validate each task. |
| "I'll batch all tasks then validate at end" | Early mistake cascades to all later tasks. Validate incrementally. |
| "I'll just ask for approval, user can see the plan" | Output complete task expansion in message BEFORE AskUserQuestion. User must see it. |
| "Plan looks complete enough to ask" | Show ALL step groups with ALL steps and code. Then ask. |
| "Too many tasks, should suggest splitting" | No artificial limits. Work on as many tasks as user specifies. |
| "Single task is too small for this skill" | Single task expansion is valid. Use the skill. |
| "**CRITICAL: I'll use placeholder text and fill in later**" | **NO. Write actual implementation steps NOW. NEVER use "[detailed above]", "[as specified]", or similar meta-references.** |
| "Design field is too long, use placeholder" | Length doesn't matter. Write complete content. Placeholder defeats entire purpose of task refinement. |

**All of these mean: STOP. Follow the requirements exactly.**

## Requirements Checklist

**Before starting:**
- [ ] Identify scope from user (single task, range, epic, or explicit list)
- [ ] If epic: Get all tasks (`bd dep tree bd-1`)
- [ ] Create TodoWrite with all task IDs to expand

**For each task:**
- [ ] Mark task as in_progress in TodoWrite
- [ ] Read task design (`bd show bd-N`)
- [ ] Dispatch hyperpowers:codebase-investigator with bd task assumptions
- [ ] Write complete step groups with exact paths and code based on investigator findings
- [ ] Output complete task expansion in message text (verification findings + all step groups with all steps)
- [ ] THEN use AskUserQuestion to get approval
- [ ] Mark task as completed in TodoWrite

**For each step:**
- [ ] Exact file paths with line numbers for modifications
- [ ] Complete code (never "add validation" without code)
- [ ] Exact commands with expected output
- [ ] No conditional instructions ("if exists", "if needed")
- [ ] Commit messages reference bd task ID

**After updating each bd task (MANDATORY VERIFICATION):**
- [ ] Run `bd show bd-N` to read back the design field
- [ ] Verify NO placeholder text like "[detailed above]", "[as specified]", "[will be added]"
- [ ] Verify ALL step groups are fully written with actual code examples
- [ ] Verify ALL steps have complete commands and expected output
- [ ] If ANY placeholder found: STOP, rewrite with actual content, update bd again

**After all tasks approved:**
- [ ] All bd issues updated with detailed implementation steps
- [ ] Verify updates with `bd show bd-N` for each task
- [ ] Offer execution choice

## Execution Handoff

After all bd issues are enhanced with detailed steps, offer execution choice:

**"All bd tasks enhanced with detailed implementation steps. Ready for execution. Two options:**

**1. Execute in this session** - Use hyperpowers:executing-plans to work through enhanced bd tasks

**2. Execute in separate session** - Open new session, use hyperpowers:executing-plans there

**Which approach?"**

**If Execute in this session:**
- **REQUIRED: Use Skill tool to invoke:** `hyperpowers:executing-plans`
- Read tasks from bd
- Follow detailed implementation steps
- Update task status as work progresses

**If Execute in separate session:**
- Guide them to open new session
- **REQUIRED: New session uses Skill tool to invoke:** `hyperpowers:executing-plans`
- bd issues contain everything needed for execution
