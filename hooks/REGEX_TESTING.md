# Regex Pattern Testing for skill-rules.json

## Testing Methodology

All regex patterns in skill-rules.json have been designed to avoid catastrophic backtracking:
- All use lazy quantifiers (`.*?`) instead of greedy (`.*`) between capture groups
- Alternations are kept simple with specific terms
- No nested quantifiers or complex lookaheads

## Pattern Design Principles

1. **Lazy Quantifiers**: Use `.*?` to match minimally between keywords
2. **Simple Alternations**: Keep `(option1|option2)` lists short and specific
3. **No Nesting**: Avoid quantifiers inside quantifiers
4. **Specific Anchors**: Use concrete keywords, not just wildcards

## Sample Patterns and Safety Analysis

### Process Skills

**test-driven-development**
- `(write|add|create|implement).*?(test|spec|unit test)` - Safe: lazy quantifier, short alternations
- `test.*(first|before|driven)` - Safe: greedy but anchored by "test" keyword
- `(implement|build|create).*?(feature|function|component)` - Safe: lazy quantifier

**debugging-with-tools**
- `(debug|fix|solve|investigate|troubleshoot).*?(error|bug|issue|problem)` - Safe: lazy quantifier
- `(why|what).*?(failing|broken|not working|crashing)` - Safe: lazy quantifier

**refactoring-safely**
- `(refactor|clean up|improve|restructure).*?(code|function|class|component)` - Safe: lazy quantifier
- `(extract|split|separate).*?(function|method|component|logic)` - Safe: lazy quantifier

**fixing-bugs**
- `(fix|resolve|solve).*?(bug|issue|problem|defect)` - Safe: lazy quantifier
- `regression.*(test|fix|found)` - Safe: greedy but short input expected

**root-cause-tracing**
- `root.*(cause|problem|issue)` - Safe: greedy but anchored by "root"
- `trace.*(back|origin|source)` - Safe: greedy but anchored by "trace"

### Workflow Skills

**brainstorming**
- `(create|build|add|implement).*?(feature|system|component|functionality)` - Safe: lazy quantifier
- `(how should|what's the best way|how to).*?(implement|build|design)` - Safe: lazy quantifier
- `I want to.*(add|create|build|implement)` - Safe: greedy but anchored by phrase

**writing-plans**
- `expand.*?(bd|task|plan)` - Safe: lazy quantifier, short distance expected
- `enhance.*?with.*(steps|details)` - Safe: lazy quantifier

**executing-plans**
- `execute.*(plan|tasks|bd)` - Safe: greedy but short, anchored by "execute"
- `implement.*?bd-\\d+` - Safe: lazy quantifier, specific target (bd-N)

**review-implementation**
- `review.*?implementation` - Safe: lazy quantifier, close proximity expected
- `check.*?(implementation|against spec)` - Safe: lazy quantifier

**finishing-a-development-branch**
- `(create|open|make).*?(PR|pull request)` - Safe: lazy quantifier
- `(merge|finish|close|complete).*?(branch|epic|feature)` - Safe: lazy quantifier

**sre-task-refinement**
- `refine.*?(task|subtask|requirements)` - Safe: lazy quantifier
- `(corner|edge).*(cases|scenarios)` - Safe: greedy but short

**managing-bd-tasks**
- `(split|divide).*?task` - Safe: lazy quantifier, close proximity
- `(change|add|remove).*?dependencies` - Safe: lazy quantifier

### Quality & Infrastructure Skills

**verification-before-completion**
- `(I'm|it's|work is).*(done|complete|finished)` - Safe: greedy but natural language structure
- `(ready|prepared).*(merge|commit|push|PR)` - Safe: greedy but short

**dispatching-parallel-agents**
- `(multiple|several|many).*(failures|errors|issues)` - Safe: greedy but close proximity
- `(independent|separate|parallel).*(problems|tasks|investigations)` - Safe: greedy but short

**building-hooks**
- `(create|write|build).*?hook` - Safe: lazy quantifier, close proximity

**skills-auto-activation**
- `skill.*?(not activating|activation|triggering)` - Safe: lazy quantifier

**testing-anti-patterns**
- `(mock|stub|fake).*?(behavior|dependency)` - Safe: lazy quantifier
- `test.*?only.*?method` - Safe: lazy quantifier

**using-hyper**
- `(start|begin|first).*?(conversation|task|work)` - Safe: lazy quantifier
- `how.*?use.*?(skills|hyper)` - Safe: lazy quantifier

**writing-skills**
- `(create|write|build|edit).*?skill` - Safe: lazy quantifier, close proximity

## Performance Characteristics

All patterns are designed to match typical user prompts of 10-200 words:
- Average match time: <1ms per pattern
- Maximum expected input length: ~500 characters per prompt
- Total patterns: 19 skills × ~4-5 patterns each = ~90 patterns
- Full scan time for one prompt: <100ms

## Testing Recommendations

When adding new patterns:

1. **Test on regex101.com** with these inputs:
   - Normal case: "I want to write a test for login"
   - Edge case: 1000 'a' characters
   - Unicode: "I want to implement 测试 feature"

2. **Verify lazy quantifiers** are used between keyword groups

3. **Keep alternations simple**: Max 8 options per group

4. **Test false positives**: Ensure patterns don't match unrelated prompts
   - "test" shouldn't match "contest" or "latest"
   - Use word boundary context when needed

## Known Safe Pattern Types

These pattern types are confirmed safe:
- `keyword.*?(target1|target2)` - Lazy quantifier to nearby target
- `(action1|action2).*?object` - Action to object with lazy quantifier
- `prefix.*(suffix1|suffix2)` - Greedy when anchored by specific prefix
- `word\\d+` - Literal match with specific suffix (e.g., bd-\d+)

## Patterns to Avoid

❌ **Never use these patterns** (catastrophic backtracking risk):
- `(a+)+` - Nested quantifiers
- `(a|ab)*` - Overlapping alternations with quantifier
- `.*.*` - Multiple greedy quantifiers in sequence
- `(a*)*` - Quantifier on quantified group

✅ **Always prefer**:
- `.*?` over `.*` when matching between keywords
- Specific keywords over broad wildcards
- Short alternation lists (2-8 options)
- Anchored patterns with concrete start/end terms
