---
name: brainstorming
description: Use when creating or developing anything, before writing code - refines rough ideas into bd epics with immutable requirements and first task ready for iterative execution
---

# Brainstorming Ideas Into bd Plans

## Overview

Turn rough ideas into validated designs stored as bd epics with immutable requirements.

The epic becomes your contract - requirements and success criteria that guide execution. Tasks are created iteratively as you learn, not upfront.

**Announce at start:** "I'm using the brainstorming skill to refine your idea into a design."

## The Process

### 1. Understanding the Idea

**Check current project state first:**
- Recent commits, existing docs, codebase structure
- Use `hyperpowers:codebase-investigator` to understand existing patterns
- Use `hyperpowers:internet-researcher` for external API/library documentation

**Ask questions one at a time to refine the idea:**
- Prefer multiple choice questions when possible (easier to answer)
- Focus on understanding: purpose, constraints, success criteria
- Gather enough context to propose approaches

**Example questions:**
- "What problem does this solve for users?"
- "Are there existing implementations we should follow?"
- "What's the most important success criterion?"

### 2. Exploring Approaches

**Research first:**
- If similar feature exists: dispatch `hyperpowers:codebase-investigator` to find patterns
- If new integration: dispatch `hyperpowers:internet-researcher` for best practices
- Review research findings before proposing

**Propose 2-3 different approaches with trade-offs:**
- At least one approach should follow codebase patterns (if they exist)
- For each: core architecture, trade-offs, complexity assessment
- Lead with your recommended option and explain why
- Present conversationally or use AskUserQuestion for structured choice

**Example:**
```
Based on the existing auth/ pattern, I recommend:

1. **OAuth via passport.js** (matches existing pattern in auth/passport-config.ts)
   - Pros: Consistent with codebase, well-tested library
   - Cons: Requires OAuth provider setup

2. **Custom JWT implementation**
   - Pros: Full control, lightweight
   - Cons: Security complexity, no existing pattern

3. **Auth0 integration**
   - Pros: Managed service, easy setup
   - Cons: External dependency, cost

I recommend option 1 (passport.js) because it follows the existing pattern and is already partially set up.
```

### 3. Presenting the Design

**Once you understand what you're building, present the design:**
- Break it into sections of 200-300 words
- Ask after each section: "Does this look right so far?"
- Cover: architecture, components, data flow, error handling, testing
- Be ready to go back and clarify if something doesn't make sense

**Present findings from research:**
- "Based on codebase investigation: auth/ uses passport.js..."
- "API docs show the OAuth flow requires..."
- Show how design builds on existing code

## Creating the bd Epic

**After design is validated**, create bd epic as immutable contract:

```bash
bd create "Feature: [Feature Name]" \
  --type epic \
  --priority [0-4] \
  --design "## Requirements (IMMUTABLE)
[What MUST be true when complete - be specific]
- Requirement 1: [concrete, testable requirement]
- Requirement 2: [concrete, testable requirement]
- Requirement 3: [concrete, testable requirement]

## Success Criteria (MUST ALL BE TRUE)
- [ ] Criterion 1 (objective, testable - e.g., 'Integration tests pass')
- [ ] Criterion 2 (objective, testable - e.g., 'Works with existing User model')
- [ ] All tests passing
- [ ] Pre-commit hooks passing

## Anti-Patterns (FORBIDDEN)
- ❌ [Specific shortcut that violates requirements]
- ❌ [Rationalization to prevent - e.g., 'NO mocking core behavior in tests']
- ❌ [Pattern to avoid - e.g., 'NO localStorage for tokens (violates security)']

## Approach
[2-3 paragraph summary of chosen approach from exploration]

## Architecture
[Key components, data flow, integration points]

## Context
[Links to similar implementations: file.ts:123]
[External docs consulted]
[Agent research findings]"
```

**Key: The anti-patterns section prevents watering down requirements when blockers occur.**

**Example anti-patterns:**
- ❌ NO localStorage tokens (violates httpOnly security requirement)
- ❌ NO new user model (must integrate with existing db/models/user.ts)
- ❌ NO mocking OAuth in integration tests (defeats validation)
- ❌ NO TODO stubs for core authentication flow

## Creating First Task Only

**Create ONLY the first actionable task, not full task tree:**

```bash
bd create "Task 1: [Specific Deliverable]" \
  --type feature \
  --priority [match-epic] \
  --design "## Goal
[What this task delivers - one clear outcome]

## Implementation
[Detailed step-by-step for this task]

1. Study existing code
   [Point to 2-3 similar implementations]

2. Write tests first (TDD)
   [Specific test cases for this task]

3. Implementation checklist
   - [ ] file.ts:line - function_name() - [exactly what it does]
   - [ ] test.ts:line - test_name() - [what scenario it tests]

## Success Criteria
- [ ] [Specific, measurable outcome]
- [ ] Tests passing
- [ ] Pre-commit hooks passing"

bd dep add bd-2 bd-1 --type parent-child  # Link to epic
```

**Why only one task?**
- Subsequent tasks are created iteratively by executing-plans
- Each new task reflects learnings from previous task
- Avoids brittle task trees that break when assumptions change

## Handoff to Execution

After epic and first task are created:

```
"Epic bd-1 is ready with immutable requirements and success criteria.
First task bd-2 is ready to execute.

Ready to start implementation? I'll use executing-plans to work through this iteratively.

The executing-plans skill will:
1. Execute the current task
2. Review what was learned against the epic requirements
3. Create the next task based on current reality
4. Repeat until all epic success criteria are met

This approach avoids brittle upfront planning - each task adapts to what we learn."
```

## Key Principles

- **One question at a time** - Don't overwhelm with multiple questions
- **Multiple choice preferred** - Easier to answer than open-ended when possible
- **Delegate research** - Use agents for codebase and internet research
- **YAGNI ruthlessly** - Remove unnecessary features from all designs
- **Explore alternatives** - Propose 2-3 approaches before settling
- **Incremental validation** - Present design in sections, validate each
- **Be flexible** - Go back and clarify when something doesn't make sense
- **Epic is contract** - Requirements are immutable, tasks adapt to reality
- **Anti-patterns prevent shortcuts** - Explicit forbidden patterns stop rationalization

## When to Use Research Agents

**Use hyperpowers:codebase-investigator when:**
- Understanding how existing features work
- Finding where specific functionality lives
- Identifying patterns to follow
- Verifying assumptions about codebase structure
- Checking if feature already exists

**Use hyperpowers:internet-researcher when:**
- Finding current API documentation
- Researching library capabilities and best practices
- Comparing technology options
- Understanding community recommendations
- Finding code examples from official docs

**Research protocol:**
1. If codebase pattern exists → Use it (unless clearly unwise)
2. If no codebase pattern → Research external patterns
3. If research yields nothing → Ask user for direction

## Handling Additional Context

**If user provides additional context mid-brainstorming:**

1. Acknowledge: "Thanks for the additional context about [X]"
2. Determine impact:
   - Changes requirements? → Return to understanding
   - Changes approach? → Return to exploring
   - Just clarification? → Continue current step
3. Continue naturally from there

**No need for complex phase tracking** - trust the flow.

## Example: OAuth Authentication

### Understanding (Questions)
- "What OAuth provider: Google, Microsoft, both?"
- "Token storage: cookies, localStorage, sessionStorage?"
- "Session duration requirement?"

**Research:**
- Dispatch codebase-investigator: "Find existing auth implementation"
- Findings: Passport.js already in use at auth/passport-config.ts

### Exploring (Approaches)

"Based on codebase investigation showing passport.js, I recommend:

1. **Extend existing passport setup** (recommended)
   - Add google-oauth20 strategy to auth/passport-config.ts
   - Use existing cookie-session middleware
   - Matches codebase pattern

2. **Custom OAuth implementation**
   - Direct OAuth2 calls
   - Full control but more complex

I recommend option 1 because it leverages existing auth/ setup."

### Design Presentation

"Here's the authentication flow architecture:

1. User clicks 'Login with Google'
2. Redirect to Google OAuth consent
3. Callback to /auth/google/callback with auth code
4. Exchange code for tokens via passport
5. Store encrypted in httpOnly cookies
6. Set 24h expiry with refresh

Does this look right so far?"

[Continue with components, error handling, testing...]

### Epic Creation

```bash
bd create "Feature: OAuth2 Authentication" --type epic --design "
## Requirements (IMMUTABLE)
- Users authenticate via Google OAuth2
- Tokens stored in httpOnly cookies
- Session expires after 24h inactivity
- Integrates with existing User model in db/models/user.ts

## Success Criteria
- [ ] Login flow redirects to Google and back
- [ ] Access tokens stored in httpOnly cookies
- [ ] Token refresh works automatically
- [ ] Integration tests pass without mocking OAuth
- [ ] Works with existing /api/me endpoint
- [ ] All tests passing
- [ ] Pre-commit hooks passing

## Anti-Patterns (FORBIDDEN)
- ❌ NO localStorage tokens (violates httpOnly requirement)
- ❌ NO new user model (must use existing)
- ❌ NO mocking OAuth in integration tests
- ❌ NO skipping token refresh (explicit requirement)

## Approach
Extend existing passport.js setup in auth/passport-config.ts...

## Architecture
- passport-google-oauth20 strategy
- cookie-session middleware for token storage
- Auto-refresh middleware for 24h sessions

## Context
- Existing pattern: auth/passport-config.ts
- API docs: https://developers.google.com/identity/protocols/oauth2
"
# Returns bd-1
```

### First Task

```bash
bd create "Setup OAuth provider configuration" --type feature --design "
## Goal
Configure Google OAuth2 credentials and passport strategy

## Implementation
1. Study auth/passport-config.ts for existing pattern
2. Add google-oauth20 strategy configuration
3. Store client ID/secret in .env (no secrets in code)
4. Configure callback URL (needs HTTPS for production)

## Tests (TDD)
- test/auth/oauth-provider.test.ts
  - Can redirect to Google consent screen
  - Callback receives authorization code
  - No secrets exposed in client code

## Success Criteria
- [ ] OAuth redirect works to Google
- [ ] Callback configured correctly
- [ ] No secrets in code (all in .env)
- [ ] Tests passing
"
# Returns bd-2

bd dep add bd-2 bd-1 --type parent-child
```

### Handoff

"Epic bd-1 ready with immutable requirements. First task bd-2 ready.

Ready to start? I'll use executing-plans to work iteratively - it will execute bd-2, then create the next task based on what we learn."

---

**This skill creates the design and structure. The executing-plans skill handles iterative implementation.**
