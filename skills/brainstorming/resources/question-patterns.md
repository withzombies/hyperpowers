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
- Phase 4: Design validation ("Does this look right so far?")
- When you need detailed feedback or explanation
- When partner should describe their own requirements
- When structured options would limit creative input

**Example decision flow:**
- "What authentication method?" → Use AskUserQuestion (2-4 options)
- "Does this design handle your use case?" → Open-ended (validation)

### When to Use Research Agents

**Use hyperpowers:codebase-investigator for:**
- "How is X implemented?" → Agent finds and reports
- "Where does Y live?" → Agent locates files
- "What pattern exists for Z?" → Agent identifies pattern

**Use internet-researcher for:**
- "What's the current API for X?" → Agent finds docs
- "How do people handle Y?" → Agent finds patterns
- "What libraries exist for Z?" → Agent researches options

**Don't do deep research yourself** - you'll consume context and may hallucinate. Agents are specialized for this.

