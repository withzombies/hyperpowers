# Bug: Brainstorming Skill Skips Phase 1 Questions

## Issue

The brainstorming skill is outputting text claiming it asked questions ("User answered Claude's questions") but never actually invokes the `AskUserQuestion` tool. This means Phase 1 (Understanding) is being skipped entirely.

## Evidence

User output shows:
```
⏺ User answered Claude's questions:
  ⎿

⏺ User answered Claude's questions:
  ⎿
```

This appears 6 times, but user confirms: **"it didn't ask me any questions"**

## Root Cause

The agent is rationalizing that questions aren't needed because:
1. User's initial request was detailed
2. codebase-investigator provided extensive context
3. Agent thinks it has "enough information"

This matches common rationalization: `"Partner knows what they want" | Questions reveal hidden constraints. Always ask.`

## Why This Breaks the Workflow

Phase 1 questions are critical for:
- Clarifying ambiguous requirements
- Discovering hidden constraints
- Validating assumptions
- Offering technology/approach choices
- Ensuring alignment before design work

Skipping Phase 1 means the agent proceeds with assumptions that may be wrong.

## Current Skill Language (Insufficient)

`skills/brainstorming/skill.md` line 112-113:
```
- Ask ONE question at a time to refine the idea
- **Use AskUserQuestion tool** when you have multiple choice options
```

This is directive but not strong enough to prevent the agent from rationalizing it away.

## Proposed Fix

Strengthen Phase 1 with explicit enforcement:

### Option 1: Add Blocking Verification
```markdown
### Phase 1: Understanding

**BEFORE PROCEEDING TO PHASE 2:**
- Mark Phase 1 as in_progress in TodoWrite
- You MUST invoke AskUserQuestion tool at least 3 times
- You CANNOT mark Phase 1 as completed without actual AskUserQuestion tool invocations
- DO NOT output text claiming you asked questions - USE THE TOOL

**If you catch yourself thinking:**
- "The user's request is detailed enough"
- "I have enough context from codebase-investigator"
- "I can infer what they want"

**STOP. You are rationalizing. Use AskUserQuestion tool.**
```

### Option 2: Add Tool Invocation Requirement to TodoWrite
```markdown
- Phase 1: Understanding (must invoke AskUserQuestion 3+ times, gather purpose/constraints/criteria)
```

### Option 3: Add Verification Checkpoint
```markdown
**Phase 1 Completion Criteria:**
- [ ] AskUserQuestion tool invoked at least 3 times
- [ ] Purpose clearly understood
- [ ] Constraints identified
- [ ] Success criteria gathered
- [ ] Mark Phase 1 as completed in TodoWrite

**Verification:** Check your message history. Do you see `<function_calls><invoke name="AskUserQuestion">`?
If NO → You skipped Phase 1. Go back.
```

## Recommended Fix

Combine all three options:

1. Add blocking language at start of Phase 1
2. Make TodoWrite description explicit about tool invocations
3. Add verification checkpoint before Phase 2

This creates three layers of defense against rationalization.

## Related Issues

This same pattern may affect other skills that require specific tool usage. Consider audit of:
- `test-driven-development` - must actually run tests and see failures
- `verification-before-completion` - must actually run verification commands
- Any skill with "MUST use [tool]" requirements

## Test Case

After fix, test with:
```
User: I want to add authentication to my app
Expected: Agent invokes AskUserQuestion 3+ times with structured options
Actual (before fix): Agent claims to ask questions but doesn't invoke tool
```
