---
name: skills-auto-activation
description: Use when skills aren't activating reliably - covers official solutions (better descriptions, explicit requests) and advanced custom hook system for forcing skill activation based on prompt analysis
---

# Skills Auto-Activation

## Overview

Skills often don't activate automatically despite relevant keywords and context. This is a known issue in Claude Code.

**Core principle:** Make skills activate reliably through better descriptions, explicit triggers, or custom automation.

**The problem:** You've written comprehensive skills, but Claude sits there like they don't exist. Keywords match perfectly. Files are relevant. Nothing happens.

## The Problem

### What Users Experience

**Symptoms:**
- "I use the exact keywords from skill descriptions. Nothing."
- "Claude works on files that should trigger skills. Nothing."
- "Skills just sit there like expensive decorations."

**Confirmed by community:**
- GitHub Issue #9954: "Built-in skills not available, even if explicitly enabled"
- Multiple reports: "Claude knows it's supposed to use skills, but it's not reliable"
- Search results: Skills activation is "not reliable yet"

### Why It Happens

**According to Anthropic:**
1. **Vague descriptions** - "Helps with documents" won't activate
2. **Missing when-to-use context** - Description should include both "what" and "when"
3. **Settings disabled** - Code execution or Skills disabled at org level
4. **Model variability** - Stochastic nature means varying outputs

**Real cause:** Skills system relies on Claude recognizing relevance. That's not deterministic.

## When to Use

Use this skill when:
- Skills you created aren't being used automatically
- You need consistent skill activation across sessions
- You're working on large codebases with established patterns
- Manual "/use skill-name" gets tedious

**Prerequisites:**
- Skills are properly configured (name, description, SKILL.md)
- Code execution is enabled (Settings > Capabilities)
- Skills are toggled on (Settings > Capabilities)

## Solution Levels

### Level 1: Official Solutions (Start Here)

These are Anthropic's recommended approaches:

#### 1. Improve Skill Descriptions

**Bad description:**
```yaml
name: backend-dev
description: Helps with backend development
```

**Good description:**
```yaml
name: backend-dev-guidelines
description: Use when creating API routes, controllers, services, or repositories in backend - enforces TypeScript patterns, error handling with Sentry, and Prisma repository pattern
```

**Key elements:**
- **Specific keywords:** "API routes", "controllers", "services"
- **When to use:** "Use when creating..."
- **What it enforces:** Patterns, error handling, etc.

#### 2. Be Explicit in Requests

Instead of:
```
How do I create an endpoint?
```

Try:
```
Use my backend-dev-guidelines skill to create an endpoint
```

**Result:** Works, but tedious for every request.

#### 3. Check Settings

- Settings > Capabilities > Enable code execution
- Settings > Capabilities > Toggle Skills on
- For Team/Enterprise: Check org-level settings
- Verify Skills aren't greyed out

### Level 2: Skill References (Moderate Effort)

Reference skills in your CLAUDE.md file:

```markdown
## When Working on Backend

Before making changes to backend code:
1. Check `/skills/backend-dev-guidelines` for patterns
2. Follow the repository pattern for database access
3. Use Sentry for error capturing

The backend-dev-guidelines skill contains complete examples and patterns.
```

**Pros:** No custom code required
**Cons:** Claude still might not check the skill

### Level 3: Custom Hook System (Advanced)

Build a deterministic activation system using hooks.

**How it works:**
1. UserPromptSubmit hook analyzes prompt before Claude sees it
2. Matches keywords, intent patterns, file paths
3. Injects skill activation reminder into context
4. Claude sees "🎯 USE backend-dev-guidelines" before processing

**Result:** "Night and day difference" - skills go from unused to consistently used.

**For complete implementation:** See [resources/hook-implementation.md](resources/hook-implementation.md)

## The Hook-Based Solution

### Architecture

```
User submits prompt
    ↓
UserPromptSubmit hook intercepts
    ↓
Analyze prompt (keywords, intent, files)
    ↓
Check skill-rules.json for matches
    ↓
Inject activation reminder
    ↓
Claude sees: "🎯 USE these skills: ..."
    ↓
Claude loads and uses relevant skills
```

### Configuration: skill-rules.json

Define triggers for each skill:

```json
{
  "backend-dev-guidelines": {
    "type": "domain",
    "enforcement": "suggest",
    "priority": "high",
    "promptTriggers": {
      "keywords": ["backend", "controller", "service", "API", "endpoint", "route"],
      "intentPatterns": [
        "(create|add|build).*?(route|endpoint|controller|service)",
        "(how to|best practice|pattern).*?(backend|API|database)",
        "implement.*?(authentication|authorization)"
      ]
    },
    "fileTriggers": {
      "pathPatterns": ["backend/src/**/*.ts", "server/**/*.ts"],
      "contentPatterns": ["express\\.Router", "export.*Controller", "prisma\\."]
    }
  },
  "frontend-dev-guidelines": {
    "type": "domain",
    "enforcement": "suggest",
    "priority": "high",
    "promptTriggers": {
      "keywords": ["frontend", "component", "react", "UI", "layout", "page"],
      "intentPatterns": [
        "(create|build|add).*?(component|page|layout|view)",
        "(how to|pattern).*?(react|hooks|state|routing)"
      ]
    },
    "fileTriggers": {
      "pathPatterns": ["src/components/**/*.tsx", "src/pages/**/*.tsx"],
      "contentPatterns": ["import.*from ['\"]react", "export.*function.*Component"]
    }
  },
  "test-driven-development": {
    "type": "process",
    "enforcement": "suggest",
    "priority": "high",
    "promptTriggers": {
      "keywords": ["test", "TDD", "testing", "spec"],
      "intentPatterns": [
        "(write|add|create).*?(test|spec)",
        "test.*(first|before|TDD)",
        "(bug|fix).*?reproduce"
      ]
    },
    "fileTriggers": {
      "pathPatterns": ["**/*.test.ts", "**/*.spec.ts", "**/__tests__/**"],
      "contentPatterns": ["describe\\(", "it\\(", "test\\(", "expect\\("]
    }
  }
}
```

### Trigger Types

**1. Keyword Triggers**
- Simple string matching in prompt
- Case insensitive
- Good for: obvious topics

**2. Intent Pattern Triggers**
- Regex matching for actions + objects
- Catches variations: "create route", "add endpoint", "build API"
- Good for: understanding what user wants to do

**3. File Path Triggers**
- Glob patterns for file paths
- Activates when editing matching files
- Good for: context-based activation

**4. Content Pattern Triggers**
- Regex matching in file content
- Detects imports, exports, specific patterns
- Good for: technical context (this file uses React, Prisma, etc.)

### The Hook Implementation

**High-level overview:**

```javascript
#!/usr/bin/env node
// ~/.claude/hooks/user-prompt-submit/skill-activator.js

const fs = require('fs');
const path = require('path');

// Load skill rules
const rulesPath = process.env.SKILL_RULES ||
    path.join(process.env.HOME, '.claude/skill-rules.json');
const rules = JSON.parse(fs.readFileSync(rulesPath, 'utf8'));

// Read prompt from stdin
let promptData = '';
process.stdin.on('data', chunk => promptData += chunk);

process.stdin.on('end', () => {
    const prompt = JSON.parse(promptData);

    // Analyze prompt for skill matches
    const activatedSkills = analyzePrompt(prompt.text);

    if (activatedSkills.length > 0) {
        // Inject skill activation reminder
        const context = generateActivationContext(activatedSkills);

        console.log(JSON.stringify({
            decision: 'continue',
            additionalContext: context
        }));
    } else {
        console.log(JSON.stringify({ decision: 'continue' }));
    }
});

function analyzePrompt(text) {
    // Match against all skill rules
    // Return list of activated skills with priorities
}

function generateActivationContext(skills) {
    // Generate formatted reminder for Claude
    return `
🎯 SKILL ACTIVATION CHECK

Relevant skills for this prompt:
${skills.map(s => `- **${s.skill}** (${s.priority} priority)`).join('\n')}

Check if these skills should be used before responding.
`;
}
```

**For complete working implementation:** See [resources/hook-implementation.md](resources/hook-implementation.md)

## Progressive Enhancement

### Phase 1: Start Simple (Observation)

Begin with basic keyword matching:

```json
{
  "backend-dev-guidelines": {
    "promptTriggers": {
      "keywords": ["backend", "API", "controller"]
    }
  }
}
```

**Observe for a week:** Which prompts activate? Which miss?

### Phase 2: Add Intent Patterns

Add regex for common action patterns:

```json
{
  "promptTriggers": {
    "keywords": ["backend", "API"],
    "intentPatterns": [
      "(create|add).*?(route|endpoint)"
    ]
  }
}
```

**Observe:** Catches more variations?

### Phase 3: Add File Triggers

Activate based on which files you're editing:

```json
{
  "fileTriggers": {
    "pathPatterns": ["backend/**/*.ts"]
  }
}
```

**Observe:** Auto-activates when working in backend?

### Phase 4: Refine Patterns

Based on observation, refine:
- Add missed keywords
- Improve intent patterns
- Adjust file patterns
- Set appropriate priorities

## Results

### Before Hook System

- Skills sit unused despite perfect keywords
- Manual "/use skill-name" every time
- Inconsistent patterns across codebase
- Spent time fixing "creative interpretations"

### After Hook System

- Skills activate automatically and reliably
- Consistent patterns enforced
- Claude self-checks before showing code
- "Night and day difference"

**Real user report:** "Skills went from 'expensive decorations' to actually useful"

## Limitations and Considerations

### Limitations

1. **Requires hook system** - Not built into Claude Code
2. **Maintenance overhead** - skill-rules.json needs updates
3. **May over-activate** - Too many skills can overwhelm context
4. **Not perfect** - Still relies on Claude using activated skills

### Considerations

**Token usage:**
- Activation reminder adds ~50-100 tokens per prompt
- Multiple skills add more tokens
- Use priorities to limit activation

**Performance:**
- Hook adds ~100-300ms to prompt processing
- Acceptable for quality improvement
- Optimize regex patterns if slow

**Maintenance:**
- Update rules when adding new skills
- Review activation logs monthly
- Refine patterns based on misses

## Alternative Approaches

### Approach 1: MCP Integration

Use Model Context Protocol to provide skills as context:

**Pros:** Built into Claude system
**Cons:** Still not deterministic, same activation issues

### Approach 2: Custom System Prompt

Modify Claude's system prompt to always check certain skills:

**Pros:** Works without hooks
**Cons:** Limited to Pro plan, can't customize per-project

### Approach 3: Manual Discipline

Always explicitly request skill usage:

**Pros:** No setup required
**Cons:** Tedious, easy to forget, doesn't scale

### Approach 4: Skill Consolidation

Combine all guidelines into CLAUDE.md instead of separate skills:

**Pros:** Always loaded
**Cons:** Violates progressive disclosure, wastes tokens

**Recommendation:** Use hook system (Level 3) if working on large projects with established patterns. Use official solutions (Level 1) for smaller projects or when starting out.

## Common Rationalizations - STOP

| Excuse | Reality |
|--------|---------|
| "Skills should just work automatically" | They should, but they don't reliably. Workaround needed. |
| "This hook system is too complex" | Setup takes 2 hours, saves hundreds of hours of fixes. |
| "I'll just manually specify skills" | You'll forget. It gets tedious. Hook automates what's tedious. |
| "Improving descriptions will fix it" | Helps, but not deterministic. Hook makes it deterministic. |
| "This is overkill for my project" | Maybe. Start with Level 1, upgrade if needed. |

## Red Flags - STOP

**Watch for these patterns:**
- Building hook without testing Level 1 solutions first
- Over-activating skills (too many rules)
- Not maintaining skill-rules.json
- Hook takes >1 second (too slow)
- Activation text overwhelms prompt

## Integration with Other Skills

**Related skills:**
- **building-hooks** - How to build the hook system
- **using-hyper** - When to use skills generally
- **writing-skills** - Creating skills that activate well

**This skill enables:**
- Consistent enforcement of patterns
- Automatic guideline checking
- Reliable skill usage across sessions

## Quick Reference

| Level | Solution | Effort | Reliability |
|-------|----------|--------|-------------|
| 1 | Better descriptions | Low | Moderate |
| 1 | Explicit requests | Low | High (tedious) |
| 1 | Check settings | Low | Varies |
| 2 | CLAUDE.md references | Low | Moderate |
| 3 | Custom hook system | High | Very High |

## Resources

**For detailed implementation:**
- [resources/hook-implementation.md](resources/hook-implementation.md) - Complete working code
- [resources/skill-rules-examples.md](resources/skill-rules-examples.md) - Example configurations
- [resources/troubleshooting.md](resources/troubleshooting.md) - Common issues

**Official documentation:**
- [Anthropic Skills Best Practices](https://docs.claude.com/en/docs/agents-and-tools/agent-skills/best-practices)
- [Claude Code Hooks Guide](https://docs.claude.com/en/docs/claude-code/hooks-guide)

## Remember

- **Start simple** - Try Level 1 solutions first
- **Observe first** - Watch which prompts should activate skills
- **Build incrementally** - Start with keywords, add complexity
- **Maintain rules** - Update skill-rules.json as skills evolve
- **Measure impact** - Are skills actually being used more?

Skills are only valuable if they activate. Make them activate reliably.
