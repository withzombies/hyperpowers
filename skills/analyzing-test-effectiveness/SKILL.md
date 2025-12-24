---
name: analyzing-test-effectiveness
description: Use to audit test quality with Google Fellow SRE scrutiny - identifies tautological tests, coverage gaming, weak assertions, missing corner cases. Creates bd epic with tasks for improvements, then runs SRE task refinement on each.
---

<skill_overview>
Audit test suites for real effectiveness, not vanity metrics. Identify tests that provide false confidence (tautological, mock-testing, line hitters) and missing corner cases. Create bd epic with tracked tasks for improvements. Run SRE task refinement on each task before execution.
</skill_overview>

<rigidity_level>
MEDIUM FREEDOM - Follow the 5-phase analysis process exactly. Categorization criteria (RED/YELLOW/GREEN) are rigid. Corner case discovery adapts to the specific codebase. Output format is flexible but must include all sections.
</rigidity_level>

<quick_reference>
| Phase | Action | Output |
|-------|--------|--------|
| 1. Inventory | List all test files and functions | Test catalog |
| 2. Categorize | Apply RED/YELLOW/GREEN criteria to each test | Categorized tests |
| 3. Corner Cases | Identify missing edge cases per module | Gap analysis |
| 4. Prioritize | Rank by business criticality | Priority matrix |
| 5. bd Issues | Create epic + tasks, run SRE refinement | Tracked improvement plan |

**Core Questions for Each Test:**
1. What bug would this catch? (If none → RED)
2. Could code break while test passes? (If yes → YELLOW or RED)
3. Real scenario or implementation detail? (Detail → fragile)
4. Meaningful assertion? (`!= nil` → weak)

**bd Integration (MANDATORY):**
- Create bd epic for test quality improvement
- Create bd tasks for: remove RED, strengthen YELLOW, add corner cases
- Run hyperpowers:sre-task-refinement on all tasks
- Link tasks to epic with dependencies

**Mutation Testing Validation:**
- Java: Pitest (`mvn org.pitest:pitest-maven:mutationCoverage`)
- JS/TS: Stryker (`npx stryker run`)
- Python: mutmut (`mutmut run`)
</quick_reference>

<when_to_use>
**Use this skill when:**
- Production bugs appear despite high test coverage
- Suspecting coverage gaming or tautological tests
- Before major refactoring (ensure tests catch regressions)
- Onboarding to unfamiliar codebase (assess test quality)
- After hyperpowers:review-implementation flags test quality issues
- Planning test improvement initiatives

**Don't use when:**
- Writing new tests (use hyperpowers:test-driven-development)
- Debugging test failures (use hyperpowers:debugging-with-tools)
- Just need to run tests (use hyperpowers:test-runner agent)
</when_to_use>

<the_process>
## Announcement

**Announce:** "I'm using hyperpowers:analyzing-test-effectiveness to audit test quality with Google Fellow SRE-level scrutiny."

---

## Phase 1: Test Inventory

**Goal:** Create complete catalog of tests to analyze.

```bash
# Find all test files (adapt pattern to language)
fd -e test.ts -e spec.ts -e _test.go -e Test.java -e test.py .

# Or use grep to find test functions
rg "func Test|it\(|test\(|def test_|@Test" --type-add 'test:*test*' -t test

# Count tests per module
for dir in src/*/; do
  count=$(rg -c "func Test|it\(" "$dir" 2>/dev/null | wc -l)
  echo "$dir: $count tests"
done
```

**Create inventory TodoWrite:**
```
- Analyze tests in src/auth/
- Analyze tests in src/api/
- Analyze tests in src/parser/
[... one per module]
```

---

## Phase 2: Categorize Each Test

For each test, apply these criteria:

### RED FLAGS - Must Remove or Replace

**2.1 Tautological Tests** (pass by definition)

```typescript
// ❌ RED: Verifies non-optional return is not nil
test('builder returns value', () => {
  const result = new Builder().build();
  expect(result).not.toBeNull(); // Always passes - return type guarantees this
});

// ❌ RED: Verifies enum has cases (compiler checks this)
test('status enum has values', () => {
  expect(Object.values(Status).length).toBeGreaterThan(0);
});

// ❌ RED: Duplicates implementation
test('add returns sum', () => {
  expect(add(2, 3)).toBe(2 + 3); // Tautology: testing 2+3 == 2+3
});
```

**Detection patterns:**
```bash
# Find != nil / != null on non-optional types
rg "expect\(.*\)\.not\.toBeNull|assertNotNull|!= nil" tests/

# Find enum existence checks
rg "Object\.values.*length|cases\.count" tests/

# Find tests with no meaningful assertions
rg -l "expect\(" tests/ | xargs -I {} sh -c 'grep -c "expect" {} | grep -q "^1$" && echo {}'
```

**2.2 Mock-Testing Tests** (test the mock, not production)

```typescript
// ❌ RED: Only verifies mock was called, not actual behavior
test('service fetches data', () => {
  const mockApi = { fetch: jest.fn().mockResolvedValue({ data: [] }) };
  const service = new Service(mockApi);
  service.getData();
  expect(mockApi.fetch).toHaveBeenCalled(); // Tests mock, not service logic
});

// ❌ RED: Mock determines test outcome
test('processor handles data', () => {
  const mockParser = { parse: jest.fn().mockReturnValue({ valid: true }) };
  const result = processor.process(mockParser);
  expect(result.valid).toBe(true); // Just returns what mock returns
});
```

**Detection patterns:**
```bash
# Find tests that only verify mock calls
rg "toHaveBeenCalled|verify\(mock|\.called" tests/

# Find heavy mock setup
rg -c "mock|Mock|jest\.fn|stub" tests/ | sort -t: -k2 -nr | head -20
```

**2.3 Line Hitters** (execute without asserting)

```typescript
// ❌ RED: Calls function, doesn't verify outcome
test('processor runs', () => {
  const processor = new Processor();
  processor.run(); // No assertion - just verifies no crash
});

// ❌ RED: Assertion is trivial
test('config loads', () => {
  const config = loadConfig();
  expect(config).toBeDefined(); // Too weak - doesn't verify correct values
});
```

**Detection patterns:**
```bash
# Find tests with 0-1 assertions
rg -l "test\(|it\(" tests/ | while read f; do
  assertions=$(rg -c "expect|assert" "$f" 2>/dev/null || echo 0)
  tests=$(rg -c "test\(|it\(" "$f" 2>/dev/null || echo 1)
  ratio=$((assertions / tests))
  [ "$ratio" -lt 2 ] && echo "$f: low assertion ratio ($assertions assertions, $tests tests)"
done
```

**2.4 Evergreen/Liar Tests** (always pass)

```typescript
// ❌ RED: Catches and ignores exceptions
test('parser handles input', () => {
  try {
    parser.parse(input);
    expect(true).toBe(true); // Always passes
  } catch (e) {
    // Swallowed - test passes even on exception
  }
});

// ❌ RED: Test setup bypasses code under test
test('validator validates', () => {
  const validator = new Validator({ skipValidation: true }); // Oops
  expect(validator.validate(badInput)).toBe(true);
});
```

### YELLOW FLAGS - Must Strengthen

**2.5 Happy Path Only**

```typescript
// ⚠️ YELLOW: Only tests valid input
test('parse valid json', () => {
  const result = parse('{"name": "test"}');
  expect(result.name).toBe('test');
});
// Missing: empty string, malformed JSON, deeply nested, unicode, huge payload
```

**2.6 Weak Assertions**

```typescript
// ⚠️ YELLOW: Assertion too weak
test('fetch returns data', () => {
  const result = await fetch('/api/users');
  expect(result).not.toBeNull(); // Should verify actual content
  expect(result.length).toBeGreaterThan(0); // Should verify exact count or specific items
});
```

**2.7 Partial Coverage**

```typescript
// ⚠️ YELLOW: Tests success, not failure
test('create user succeeds', () => {
  const user = createUser({ name: 'test', email: 'test@example.com' });
  expect(user.id).toBeDefined();
});
// Missing: duplicate email, invalid email, missing fields, database error
```

### GREEN FLAGS - Keep and Expand

**2.8 Behavior Verification**

```typescript
// ✅ GREEN: Verifies specific behavior with exact values
test('calculateTotal applies discount correctly', () => {
  const cart = new Cart([{ price: 100, quantity: 2 }]);
  cart.applyDiscount('SAVE20');
  expect(cart.total).toBe(160); // 200 - 20% = 160
});
```

**2.9 Edge Case Coverage**

```typescript
// ✅ GREEN: Tests boundary conditions
test('username rejects empty string', () => {
  expect(() => new User({ username: '' })).toThrow(ValidationError);
});

test('username handles unicode', () => {
  const user = new User({ username: '日本語ユーザー' });
  expect(user.username).toBe('日本語ユーザー');
});
```

**2.10 Error Path Testing**

```typescript
// ✅ GREEN: Verifies error handling
test('fetch returns specific error on 404', () => {
  mockServer.get('/api/user/999').reply(404);
  await expect(fetchUser(999)).rejects.toThrow(UserNotFoundError);
});
```

---

## Phase 3: Corner Case Discovery

For each module, identify missing corner case tests:

### Input Validation Corner Cases

| Category | Examples | Tests to Add |
|----------|----------|--------------|
| Empty values | `""`, `[]`, `{}`, `null` | test_empty_X_rejected/handled |
| Boundary values | 0, -1, MAX_INT, MAX_LEN | test_boundary_X_handled |
| Unicode | RTL, emoji, combining chars, null byte | test_unicode_X_preserved |
| Injection | SQL: `'; DROP`, XSS: `<script>`, cmd: `; rm` | test_injection_X_escaped |
| Malformed | truncated JSON, invalid UTF-8, wrong type | test_malformed_X_error |

### State Corner Cases

| Category | Examples | Tests to Add |
|----------|----------|--------------|
| Uninitialized | Use before init, double init | test_uninitialized_X_error |
| Already closed | Use after close, double close | test_closed_X_error |
| Concurrent | Parallel writes, read during write | test_concurrent_X_safe |
| Re-entrant | Callback calls same method | test_reentrant_X_safe |

### Integration Corner Cases

| Category | Examples | Tests to Add |
|----------|----------|--------------|
| Network | timeout, connection refused, DNS fail | test_network_X_timeout |
| Partial response | truncated, corrupted, slow | test_partial_response_handled |
| Rate limiting | 429, quota exceeded | test_rate_limit_handled |
| Service errors | 500, 503, malformed response | test_service_error_handled |

### Resource Corner Cases

| Category | Examples | Tests to Add |
|----------|----------|--------------|
| Exhaustion | OOM, disk full, max connections | test_resource_X_graceful |
| Contention | file locked, resource busy | test_contention_X_handled |
| Permissions | access denied, read-only | test_permission_X_error |

**For each module, create corner case checklist:**

```markdown
### Module: src/auth/

**Covered Corner Cases:**
- [x] Empty password rejected
- [x] SQL injection in username escaped

**Missing Corner Cases (MUST ADD):**
- [ ] Unicode username preserved after roundtrip
- [ ] Concurrent login attempts don't corrupt session
- [ ] Password with null byte handled
- [ ] Very long password (10KB) rejected gracefully
- [ ] Login rate limiting enforced

**Priority:** HIGH (auth is business-critical)
```

---

## Phase 4: Prioritize by Business Impact

### Priority Matrix

| Priority | Criteria | Action Timeline |
|----------|----------|-----------------|
| P0 - Critical | Auth, payments, data integrity | This sprint |
| P1 - High | Core business logic, user-facing features | Next sprint |
| P2 - Medium | Internal tools, admin features | Backlog |
| P3 - Low | Utilities, non-critical paths | As time permits |

**Rank modules:**
```markdown
1. P0: src/auth/ - 5 RED tests, 12 missing corner cases
2. P0: src/payments/ - 2 RED tests, 8 missing corner cases
3. P1: src/api/ - 8 RED tests, 15 missing corner cases
4. P2: src/admin/ - 3 RED tests, 6 missing corner cases
```

---

## Phase 5: Create bd Issues and Improvement Plan

**CRITICAL:** All findings MUST be tracked in bd and go through SRE task refinement.

### Step 5.1: Create bd Epic for Test Quality Improvement

```bash
bd create "Test Quality Improvement: [Module/Project]" \
  --type epic \
  --priority 1 \
  --design "$(cat <<'EOF'
## Goal
Improve test effectiveness by removing tautological tests, strengthening weak tests, and adding missing corner case coverage.

## Success Criteria
- [ ] All RED tests removed or replaced with meaningful tests
- [ ] All YELLOW tests strengthened with proper assertions
- [ ] All P0 missing corner cases covered
- [ ] Mutation score ≥80% for P0 modules

## Scope
[Summary of modules analyzed and findings]

## Anti-patterns
- ❌ Adding tests that only check `!= nil`
- ❌ Adding tests that verify mock behavior
- ❌ Adding happy-path-only tests
- ❌ Leaving tautological tests "for coverage"
EOF
)"
```

### Step 5.2: Create bd Tasks for Each Category

**Task 1: Remove Tautological Tests (Immediate)**

```bash
bd create "Remove tautological tests from [module]" \
  --type task \
  --priority 0 \
  --design "$(cat <<'EOF'
## Goal
Remove tests that provide false confidence by passing regardless of code correctness.

## Tests to Remove
[List each RED test with file:line]
- tests/auth.test.ts:45 - testUserExists (tautological: verifies non-optional != nil)
- tests/auth.test.ts:67 - testEnumHasCases (tautological: compiler checks this)

## Success Criteria
- [ ] All listed tests deleted
- [ ] No new tautological tests introduced
- [ ] Test suite still passes
- [ ] Coverage may decrease (this is expected and good)

## Anti-patterns
- ❌ Keeping tests "just in case"
- ❌ Replacing with equally meaningless tests
- ❌ Adding coverage-only tests to compensate
EOF
)"
```

**Task 2: Strengthen Weak Tests (This Sprint)**

```bash
bd create "Strengthen weak assertions in [module]" \
  --type task \
  --priority 1 \
  --design "$(cat <<'EOF'
## Goal
Replace weak assertions with meaningful ones that catch real bugs.

## Tests to Strengthen
[List each YELLOW test with current vs recommended assertion]
- tests/parser.test.ts:34 - testParse
  - Current: `expect(result).not.toBeNull()`
  - Strengthen: `expect(result).toEqual(expectedAST)`

- tests/validator.test.ts:56 - testValidate
  - Current: `expect(isValid).toBe(true)` (happy path only)
  - Add edge cases: empty input, unicode, max length

## Success Criteria
- [ ] All weak assertions replaced with exact value checks
- [ ] Edge cases added to happy-path-only tests
- [ ] Each test documents what bug it catches

## Anti-patterns
- ❌ Replacing `!= nil` with `!= undefined` (still weak)
- ❌ Adding edge cases without meaningful assertions
EOF
)"
```

**Task 3: Add Missing Corner Cases (Per Module)**

```bash
bd create "Add missing corner case tests for [module]" \
  --type task \
  --priority 1 \
  --design "$(cat <<'EOF'
## Goal
Add tests for corner cases that could cause production bugs.

## Corner Cases to Add
[List each with the bug it prevents]
- test_empty_password_rejected - prevents auth bypass
- test_unicode_username_preserved - prevents encoding corruption
- test_concurrent_login_safe - prevents session corruption

## Implementation Checklist
- [ ] Write failing test first (RED)
- [ ] Verify test fails for the right reason
- [ ] Test catches the specific bug listed
- [ ] Test has meaningful assertion (not just `!= nil`)

## Success Criteria
- [ ] All corner case tests written and passing
- [ ] Each test documents the bug it catches in test name/comment
- [ ] No tautological tests added

## Anti-patterns
- ❌ Writing test that passes immediately (didn't test anything)
- ❌ Testing mock behavior instead of production code
- ❌ Happy path only (defeats the purpose)
EOF
)"
```

### Step 5.3: Run SRE Task Refinement

**MANDATORY:** After creating bd tasks, run SRE task refinement:

```
Announce: "I'm using hyperpowers:sre-task-refinement to review these test improvement tasks."

Use Skill tool: hyperpowers:sre-task-refinement
```

Apply all 8 categories to each task, especially:
- **Category 8 (Test Meaningfulness)**: Verify the proposed tests actually catch bugs
- **Category 6 (Edge Cases)**: Ensure corner cases are comprehensive
- **Category 3 (Success Criteria)**: Ensure criteria are measurable

### Step 5.4: Link Tasks to Epic

```bash
# Link all tasks as children of epic
bd dep add bd-2 bd-1 --type parent-child
bd dep add bd-3 bd-1 --type parent-child
bd dep add bd-4 bd-1 --type parent-child

# Set dependencies (remove before strengthen before add)
bd dep add bd-3 bd-2  # strengthen depends on remove
bd dep add bd-4 bd-3  # add depends on strengthen
```

### Step 5.5: Validation Task

```bash
bd create "Validate test improvements with mutation testing" \
  --type task \
  --priority 1 \
  --design "$(cat <<'EOF'
## Goal
Verify test improvements actually catch more bugs using mutation testing.

## Validation Commands
```bash
# Java
mvn org.pitest:pitest-maven:mutationCoverage

# JavaScript/TypeScript
npx stryker run

# Python
mutmut run

# .NET
dotnet stryker
```

## Success Criteria
- [ ] P0 modules: ≥80% mutation score
- [ ] P1 modules: ≥70% mutation score
- [ ] No surviving mutants in critical paths (auth, payments)

## If Score Below Target
- Identify surviving mutants
- Create additional tasks to add tests that kill them
- Re-run validation
EOF
)"
```

---

## Output Format

```markdown
# Test Effectiveness Analysis: [Project Name]

## Executive Summary

| Metric | Count | % |
|--------|-------|---|
| Total tests analyzed | N | 100% |
| RED (remove/replace) | N | X% |
| YELLOW (strengthen) | N | X% |
| GREEN (keep) | N | X% |
| Missing corner cases | N | - |

**Overall Assessment:** [CRITICAL / NEEDS WORK / ACCEPTABLE / GOOD]

## Detailed Findings

### RED Tests (Must Remove/Replace)

#### Tautological Tests
| Test | File:Line | Problem | Action |
|------|-----------|---------|--------|

#### Mock-Testing Tests
| Test | File:Line | Problem | Action |
|------|-----------|---------|--------|

#### Line Hitters
| Test | File:Line | Problem | Action |
|------|-----------|---------|--------|

#### Evergreen Tests
| Test | File:Line | Problem | Action |
|------|-----------|---------|--------|

### YELLOW Tests (Must Strengthen)

#### Weak Assertions
| Test | File:Line | Current | Recommended |
|------|-----------|---------|-------------|

#### Happy Path Only
| Test | File:Line | Missing Edge Cases |
|------|-----------|-------------------|

### GREEN Tests (Exemplars)

[List 3-5 tests that exemplify good testing practices for this codebase]

## Missing Corner Cases by Module

### [Module: name] - Priority: P0
| Corner Case | Bug Risk | Recommended Test |
|-------------|----------|------------------|

[Repeat for each module]

## bd Issues Created

### Epic
- **bd-N**: Test Quality Improvement: [Project Name]

### Tasks
| bd ID | Task | Priority | Status |
|-------|------|----------|--------|
| bd-N | Remove tautological tests from [module] | P0 | Created |
| bd-N | Strengthen weak assertions in [module] | P1 | Created |
| bd-N | Add missing corner case tests for [module] | P1 | Created |
| bd-N | Validate with mutation testing | P1 | Created |

### Dependency Tree
```
bd-1 (Epic: Test Quality Improvement)
├── bd-2 (Remove tautological tests)
├── bd-3 (Strengthen weak assertions) ← depends on bd-2
├── bd-4 (Add corner case tests) ← depends on bd-3
└── bd-5 (Validate with mutation testing) ← depends on bd-4
```

## SRE Task Refinement Status

- [ ] All tasks reviewed with hyperpowers:sre-task-refinement
- [ ] Category 8 (Test Meaningfulness) applied to each task
- [ ] Success criteria are measurable
- [ ] Anti-patterns specified

## Next Steps

1. Run `bd ready` to see tasks ready for implementation
2. Implement tasks using hyperpowers:executing-plans
3. Run validation task to verify improvements
```
</the_process>

<examples>
<example>
<scenario>High coverage but production bugs keep appearing</scenario>

<code>
# Test suite stats
Coverage: 92%
Tests: 245 passing

# Yet production issues:
- Auth bypass via empty password
- Data corruption on concurrent updates
- Crash on unicode usernames
</code>

<why_it_fails>
- Coverage measures execution, not assertion quality
- Tests likely tautological or weak assertions
- Corner cases (empty, concurrent, unicode) not tested
- High coverage created false confidence
</why_it_fails>

<correction>
**Run test effectiveness analysis:**

Phase 1 - Inventory:
```bash
fd -e test.ts src/
# Found: auth.test.ts, user.test.ts, data.test.ts
```

Phase 2 - Categorize:
```markdown
### auth.test.ts
| Test | Category | Problem |
|------|----------|---------|
| testAuthWorks | RED | Only checks `!= null` |
| testLoginFlow | YELLOW | Happy path only, no empty password |
| testTokenExpiry | GREEN | Verifies exact error |

### data.test.ts
| Test | Category | Problem |
|------|----------|---------|
| testDataSaves | RED | No assertion, just calls save() |
| testConcurrentWrites | MISSING | Not tested at all |
```

Phase 3 - Corner cases:
```markdown
### auth module (P0)
Missing:
- [ ] test_empty_password_rejected
- [ ] test_unicode_username_preserved
- [ ] test_concurrent_login_safe
```

Phase 5 - Plan:
```markdown
### Immediate
- Remove testAuthWorks (tautological)
- Remove testDataSaves (line hitter)

### This Sprint
- Add test_empty_password_rejected
- Add test_concurrent_writes_safe
- Strengthen testLoginFlow with edge cases
```

**Result:** Production bugs prevented by meaningful tests.
</correction>
</example>

<example>
<scenario>Mock-heavy test suite that breaks on every refactor</scenario>

<code>
# Every refactor breaks 50+ tests
# But bugs slip through to production

test('service processes data', () => {
  const mockDb = jest.fn().mockReturnValue({ data: [] });
  const mockCache = jest.fn().mockReturnValue(null);
  const mockLogger = jest.fn();
  const mockValidator = jest.fn().mockReturnValue(true);

  const service = new Service(mockDb, mockCache, mockLogger, mockValidator);
  service.process({ id: 1 });

  expect(mockDb).toHaveBeenCalled();
  expect(mockValidator).toHaveBeenCalled();
  // Tests mock wiring, not actual behavior
});
</code>

<why_it_fails>
- Tests verify mock setup, not production behavior
- Changing implementation breaks tests without bugs
- Real bugs (validation logic, data handling) not caught
- "Mocks mocking mocks" anti-pattern
</why_it_fails>

<correction>
**Categorize as RED - mock-testing:**

```markdown
### service.test.ts
| Test | Category | Problem | Action |
|------|----------|---------|--------|
| testServiceProcesses | RED | Only verifies mocks called | Replace with integration test |
| testServiceValidates | RED | Mock determines outcome | Test real validator |
| testServiceCaches | RED | Tests mock cache | Use real cache with test data |
```

**Replacement strategy:**

```typescript
// ❌ Before: Tests mock wiring
test('service validates', () => {
  const mockValidator = jest.fn().mockReturnValue(true);
  const service = new Service(mockValidator);
  expect(mockValidator).toHaveBeenCalled();
});

// ✅ After: Tests real behavior
test('service rejects invalid data', () => {
  const service = new Service(new RealValidator());
  const result = service.process({ id: -1 }); // Invalid ID
  expect(result.error).toBe('INVALID_ID');
});

test('service accepts valid data', () => {
  const service = new Service(new RealValidator());
  const result = service.process({ id: 1, name: 'test' });
  expect(result.success).toBe(true);
  expect(result.data.name).toBe('test');
});
```

**Result:** Tests verify behavior, not implementation. Refactoring doesn't break tests. Real bugs caught.
</correction>
</example>
</examples>

<critical_rules>
## Rules That Have No Exceptions

1. **Every test must answer: "What bug does this catch?"** → If no answer, it's RED
2. **Tautological tests must be removed** → They provide false confidence
3. **Mock-testing tests must be replaced** → Test production code, not mocks
4. **Corner cases must be identified** → Empty, unicode, concurrent, error paths
5. **Business-critical modules are P0** → Auth, payments, data integrity first
6. **Mutation testing validates improvements** → Coverage alone is vanity metric
7. **All findings tracked in bd** → Create epic + tasks for every issue found
8. **SRE refinement on all tasks** → Run hyperpowers:sre-task-refinement before execution

## Common Excuses

All of these mean: **STOP. The test is probably RED or YELLOW.**

- "It's just a smoke test" (Smoke tests without assertions are useless)
- "Coverage requires it" (Coverage gaming = false confidence)
- "It worked before" (Past success doesn't mean it catches bugs)
- "Mocks make it faster" (Fast but useless is still useless)
- "Edge cases are rare" (Rare bugs in auth/payments are critical)
- "We'll add assertions later" (Tests without assertions aren't tests)
- "It's testing the happy path" (Happy path only = half a test)
- "I'll just fix these without bd" (Untracked work = forgotten work)
- "SRE refinement is overkill for test fixes" (Test tasks need same rigor as feature tasks)
- "Can skip bd for small fixes" (Small fixes become large when untracked)
</critical_rules>

<verification_checklist>
Before completing analysis:

**Per module:**
- [ ] All tests categorized (RED/YELLOW/GREEN)
- [ ] RED tests have specific removal/replacement actions
- [ ] YELLOW tests have specific strengthening actions
- [ ] Corner cases identified (empty, unicode, concurrent, error)
- [ ] Priority assigned (P0/P1/P2/P3)

**Overall:**
- [ ] Executive summary with counts and percentages
- [ ] Detailed findings table for each category
- [ ] Missing corner cases documented per module

**bd Integration (MANDATORY):**
- [ ] Created bd epic for test quality improvement
- [ ] Created bd tasks for each category (remove, strengthen, add)
- [ ] Linked tasks to epic with parent-child relationships
- [ ] Set task dependencies (remove → strengthen → add → validate)
- [ ] Ran hyperpowers:sre-task-refinement on ALL tasks
- [ ] Created validation task with mutation testing

**SRE Refinement Verification:**
- [ ] Category 8 (Test Meaningfulness) applied to each task
- [ ] Success criteria are measurable (not "tests work")
- [ ] Anti-patterns specified for each task
- [ ] No placeholder text in task designs

**Validation:**
- [ ] Would removing RED tests lose any bug-catching ability? (No = correct)
- [ ] Would strengthening YELLOW tests catch more bugs? (Yes = correct)
- [ ] Would adding corner cases catch known production bugs? (Yes = correct)
</verification_checklist>

<integration>
**This skill is called by:**
- hyperpowers:review-implementation (when test quality issues flagged)
- User request to audit test quality
- Before major refactoring efforts

**This skill calls (MANDATORY):**
- hyperpowers:sre-task-refinement (for ALL bd tasks created)
- hyperpowers:test-runner agent (to run tests during analysis)
- hyperpowers:test-effectiveness-analyst agent (for detailed analysis)

**This skill creates:**
- bd epic for test quality improvement
- bd tasks for removing, strengthening, and adding tests
- bd validation task with mutation testing

**Workflow chain:**
```
analyzing-test-effectiveness
    ↓ (creates bd issues)
sre-task-refinement (on each task)
    ↓ (refines tasks)
executing-plans (implements tasks)
    ↓ (runs validation)
review-implementation (verifies quality)
```

**This skill informs:**
- hyperpowers:sre-task-refinement (test specifications in plans)
- hyperpowers:test-driven-development (what makes a good test)

**Mutation testing tools:**
- Java: [Pitest](https://pitest.org/) (`mvn org.pitest:pitest-maven:mutationCoverage`)
- JS/TS: [Stryker](https://stryker-mutator.io/) (`npx stryker run`)
- Python: mutmut (`mutmut run`)
- .NET: Stryker.NET (`dotnet stryker`)
</integration>

<resources>
**Research sources:**
- [Google Testing Blog: Code Coverage Best Practices](https://testing.googleblog.com/2020/08/code-coverage-best-practices.html)
- [Software Testing Anti-patterns](https://blog.codepipes.com/testing/software-testing-antipatterns.html)
- [Tautological Tests](https://randycoulman.com/blog/2016/12/20/tautological-tests/)
- [Mutation Testing Guide](https://mastersoftwaretesting.com/testing-fundamentals/types-of-testing/mutation-testing)
- [Codecov: Beyond Coverage Metrics](https://about.codecov.io/blog/measuring-the-effectiveness-of-test-suites-beyond-code-coverage-metrics/)
- [Google SRE: Testing Reliability](https://sre.google/sre-book/testing-reliability/)

**Key insight from Google:** "Coverage mainly tells you about code that has no tests: it doesn't tell you about the quality of testing for the code that's 'covered'."

**When stuck:**
- Test seems borderline RED/YELLOW → Ask: "If I delete this test, what bug could slip through?" If none, it's RED.
- Unsure if assertion is weak → Ask: "Could the code return wrong value while assertion passes?" If yes, strengthen.
- Unsure if corner case matters → Ask: "Has this ever caused a production bug, anywhere?" If yes, test it.
</resources>
