---
name: refactoring-safely
description: Use when refactoring code without breaking functionality - test-preserving transformations in small steps, running tests between each change, creating bd tasks for tracking refactoring work
---

# Refactoring Safely

## Overview

Refactoring changes code structure without changing behavior. The danger is accidentally changing behavior while restructuring.

**Core principle:** Tests must stay green throughout refactoring. If tests break, you changed behavior (that's rewriting, not refactoring).

**Violating this rule means you're not refactoring - you're making risky changes without a safety net.**

## When to Use

Use this skill when:
- Improving code structure without changing functionality
- Extracting duplicated code
- Renaming for clarity
- Reorganizing file/module structure
- Simplifying complex code
- Improving performance (while preserving behavior)

**Do NOT use for:**
- Changing functionality (use feature development instead)
- Fixing bugs (use fixing-bugs instead)
- Adding new features while restructuring (do separately)

## When to Refactor vs. Rewrite

### Refactor When:
- Tests exist and pass
- Changes are incremental
- Business logic stays same
- Can transform in small, safe steps
- Each step independently valuable

### Rewrite When:
- No tests exist (write tests first, then refactor)
- Fundamental architecture change needed
- Easier to rebuild than modify
- Requirements changed significantly
- After 3+ failed refactoring attempts

**Rule:** If you need to change tests (not just add tests), you're rewriting, not refactoring.

## The Safe Refactoring Process

### Step 1: Verify Tests Pass

**BEFORE any refactoring:**

```bash
# Run full test suite via test-runner agent
Dispatch test-runner agent: "Run: cargo test"

# Verify: ALL tests pass
# If any fail: Fix them first, THEN refactor
```

**Why:** Failing tests mean you don't know if refactoring breaks things.

**Red flag:** "I'll fix failing tests as part of refactoring" = Wrong. Fix first, refactor second.

### Step 2: Create bd Task for Refactoring

**Track the refactoring work:**

```bash
# Create refactoring task
bd create "Refactor: Extract user validation logic" \
  --type task \
  --priority P2

# Document what and why
bd edit bd-456 --design "
## Refactoring Goal
Extract user validation logic from UserService into separate Validator class.

## Why
- Validation logic duplicated across 3 services
- Makes testing individual validations difficult
- Violates single responsibility principle

## Approach
1. Create UserValidator class
2. Extract email validation
3. Extract name validation
4. Extract age validation
5. Update UserService to use validator
6. Remove duplicated code from other services

## Success Criteria
- All existing tests still pass
- No behavior changes
- Validator class has 100% test coverage
"

bd status bd-456 --status in-progress
```

### Step 3: Make ONE Small Change

**The smallest transformation that compiles:**

**Examples of small refactorings:**
- Extract one method
- Rename one variable
- Move one function to different file
- Inline one constant
- Extract one interface

**NOT small:**
- Extracting multiple methods at once
- Renaming + moving + restructuring
- "While I'm here" improvements

**Example - Extract Method:**

```rust
// Before
fn create_user(name: &str, email: &str) -> Result<User> {
    // Validation (to be extracted)
    if email.is_empty() {
        return Err(Error::InvalidEmail);
    }
    if !email.contains('@') {
        return Err(Error::InvalidEmail);
    }

    // Creation logic
    let user = User { name, email };
    Ok(user)
}

// After - ONE small change
fn create_user(name: &str, email: &str) -> Result<User> {
    validate_email(email)?;  // EXTRACTED

    let user = User { name, email };
    Ok(user)
}

fn validate_email(email: &str) -> Result<()> {
    if email.is_empty() {
        return Err(Error::InvalidEmail);
    }
    if !email.contains('@') {
        return Err(Error::InvalidEmail);
    }
    Ok(())
}
```

**ONE change:** Extract email validation to separate function. Nothing else.

### Step 4: Run Tests Immediately

**After EVERY small change:**

```bash
# Run via test-runner agent
Dispatch test-runner agent: "Run: cargo test"

# Verify: ALL tests still pass
# Exit code: 0
```

**If tests fail:**
1. STOP
2. Undo the change (git restore)
3. Understand why it broke
4. Make smaller change
5. Try again

**Never proceed with failing tests.**

### Step 5: Commit the Small Change

**Commit each safe transformation:**

```bash
git add src/user_service.rs
git commit -m "refactor(bd-456): extract email validation to function

No behavior change. All tests pass.

Part of bd-456"
```

**Why commit so often:**
- Easy to undo if next step breaks
- Clear history of transformations
- Can review each step independently
- Proves tests passed at each point

### Step 6: Repeat Until Complete

**Repeat steps 3-5 for each small transformation:**

```
1. Extract validate_email() ✓ (committed)
2. Extract validate_name() ✓ (committed)
3. Extract validate_age() ✓ (committed)
4. Create UserValidator struct ✓ (committed)
5. Move validations into UserValidator ✓ (committed)
6. Update UserService to use validator ✓ (committed)
7. Remove validation from OrderService ✓ (committed)
8. Remove validation from AccountService ✓ (committed)
```

Each step: change → test → commit

### Step 7: Final Verification

**After all transformations complete:**

```bash
# Run full test suite one more time
Dispatch test-runner agent: "Run: cargo test"

# Run linter
Dispatch test-runner agent: "Run: cargo clippy"

# Verify no warnings introduced
```

**Review the changes:**
```bash
# See all refactoring commits
git log --oneline | grep "bd-456"

# Review full diff
git diff main...HEAD
```

**Checklist:**
- [ ] All tests pass
- [ ] No new warnings
- [ ] No behavior changes
- [ ] Code is cleaner/simpler
- [ ] Each commit is small and safe

### Step 8: Close bd Task

```bash
bd edit bd-456 --design "
... (previous content)

## Completed Refactoring
- Created UserValidator class with email, name, age validation
- Removed duplicated validation from UserService, OrderService, AccountService
- All tests pass (verified)
- No behavior changes

Commits: 8 small transformations, each tested
"

bd status bd-456 --status closed
```

## Common Refactoring Patterns

### Extract Method

**When:** Duplicated code or long function

```rust
// Before: Long function
fn process(data: Vec<i32>) -> i32 {
    let mut sum = 0;
    for x in data {
        sum += x * x;
    }
    sum
}

// After: Extracted method
fn process(data: Vec<i32>) -> i32 {
    data.iter().map(|x| square(x)).sum()
}

fn square(x: &i32) -> i32 {
    x * x
}
```

**Steps:**
1. Extract square() function
2. Run tests
3. Commit
4. Replace loop with iterator
5. Run tests
6. Commit

### Rename Variable/Function

**When:** Name is unclear or misleading

```rust
// Before
fn calc(d: Vec<i32>) -> f64 {
    let s: i32 = d.iter().sum();
    s as f64 / d.len() as f64
}

// After - Step by step
// Step 1: Rename function
fn calculate_average(d: Vec<i32>) -> f64 { ... }  // Test, commit

// Step 2: Rename parameter
fn calculate_average(data: Vec<i32>) -> f64 { ... }  // Test, commit

// Step 3: Rename variable
fn calculate_average(data: Vec<i32>) -> f64 {
    let sum: i32 = data.iter().sum();  // Test, commit
    sum as f64 / data.len() as f64
}
```

### Extract Class/Struct

**When:** Class has multiple responsibilities

```rust
// Before: God object
struct UserService {
    db: Database,
    email_validator: Regex,
    name_validator: Regex,
}

// After: Single responsibility
struct UserService {
    db: Database,
    validator: UserValidator,  // EXTRACTED
}

struct UserValidator {
    email_pattern: Regex,
    name_pattern: Regex,
}
```

**Steps:**
1. Create empty UserValidator struct
2. Test, commit
3. Move email_validator field
4. Test, commit
5. Move name_validator field
6. Test, commit
7. Update UserService to use UserValidator
8. Test, commit

### Inline Unnecessary Abstraction

**When:** Abstraction adds no value

```rust
// Before: Pointless wrapper
fn get_user_email(user: &User) -> &str {
    &user.email
}

fn process() {
    let email = get_user_email(&user);  // Just use user.email!
}

// After: Inline
fn process() {
    let email = &user.email;
}
```

**Steps:**
1. Replace one call site with direct access
2. Test, commit
3. Replace next call site
4. Test, commit
5. Remove wrapper function
6. Test, commit

## Refactoring Anti-Patterns - STOP

**Never do these:**

### Changing Behavior While Refactoring

❌ **Wrong:**
```rust
// "Refactoring" that changes behavior
fn validate_email(email: &str) -> Result<()> {
    if email.is_empty() {
        return Err(Error::InvalidEmail);
    }
    // NEW: Added extra validation
    if !email.contains('.') {  // BEHAVIOR CHANGE
        return Err(Error::InvalidEmail);
    }
    Ok(())
}
```

✓ **Right:** Refactor first (extract), THEN add new validation as separate change.

### Breaking Tests During Refactoring

❌ **Wrong:**
```
Test fails → "I'll fix tests as part of refactoring" → More changes → More failures
```

✓ **Right:** Test fails → STOP, undo, make smaller change

### Big Bang Refactoring

❌ **Wrong:**
```
Change 10 files, extract 5 classes, rename everything, THEN test
```

✓ **Right:** Change one thing, test, commit. Repeat.

### Refactoring Without Tests

❌ **Wrong:**
```
"No tests, but I'll be careful"
```

✓ **Right:** Write tests first, THEN refactor

### "While I'm Here" Improvements

❌ **Wrong:**
```
// Extracting validation AND fixing bug AND renaming AND...
```

✓ **Right:** One refactoring at a time. Improvements come AFTER refactoring complete.

## When Refactoring Goes Wrong

### If Tests Fail After Refactoring

**STOP immediately:**

1. **Undo the change:**
   ```bash
   git restore src/file.rs
   ```

2. **Understand why:**
   - Did I change behavior accidentally?
   - Was my transformation incorrect?
   - Are tests flaky?

3. **Make smaller change:**
   - Break into smaller steps
   - Add intermediate state
   - Verify assumptions

4. **Try again with smaller step**

### If Refactoring Seems Impossible

**After 3 failed attempts:**

1. **Question the approach:**
   - Is refactoring the right solution?
   - Should I rewrite instead?
   - Do I need tests first?

2. **Consider alternatives:**
   - Write tests first
   - Refactor smaller piece
   - Extract interface before implementing

3. **Discuss with human partner:**
   - Maybe architecture needs bigger change
   - Maybe not worth refactoring
   - Maybe rewrite is better

## Integration with Other Skills

**This skill requires:**
- **test-driven-development** - For writing tests before refactoring (if none exist)
- **verification-before-completion** - For final verification
- **test-runner agent** - For running tests without context pollution

**This skill uses:**
- bd for tracking refactoring work
- Git for committing each small step
- test-runner agent for verification

## Red Flags - STOP

If you catch yourself thinking:
- "I'll test after refactoring" → Wrong. Test after EACH change.
- "This is just refactoring" (while changing behavior) → Wrong. That's rewriting.
- "Tests will fail temporarily" → Wrong. Tests must stay green.
- "I'll commit when done" → Wrong. Commit each small change.
- "While I'm here..." → Wrong. One refactoring at a time.
- "No tests, but it's simple" → Wrong. Write tests first.

**ALL of these mean: STOP. Return to the process.**

## Common Rationalizations

| Excuse | Reality |
|--------|---------|
| "Small refactoring, don't need tests" | All refactorings need tests to verify no behavior change. |
| "I'll test at the end" | Tests prove each step safe. End-only testing misses where it broke. |
| "Tests are slow, I'll run once" | Slow tests reveal bad design. Fix tests, then refactor. |
| "Just fixing bugs while refactoring" | Bug fixes are behavior changes. Do separately. |
| "Easier to do all at once" | Easier to break. Small steps safer. |
| "I know it works" | Your confidence ≠ proof. Tests prove it. |

## Example: Complete Refactoring Session

**Goal:** Extract validation logic from UserService

**Time: 60 minutes**

### Minutes 0-5: Verify Tests Pass
```bash
Dispatch test-runner: "Run: cargo test"
Result: ✓ 234 tests pass
```

### Minutes 5-10: Create bd Task
```bash
bd create "Refactor: Extract user validation" --type task
bd edit bd-456 --design "Extract validation to UserValidator class..."
bd status bd-456 --status in-progress
```

### Minutes 10-15: Step 1 - Extract email validation function
```rust
// Extract validate_email()
```
```bash
Dispatch test-runner: "Run: cargo test"
Result: ✓ 234 tests pass
git commit -m "refactor(bd-456): extract email validation"
```

### Minutes 15-20: Step 2 - Extract name validation function
```rust
// Extract validate_name()
```
```bash
Dispatch test-runner: "Run: cargo test"
Result: ✓ 234 tests pass
git commit -m "refactor(bd-456): extract name validation"
```

### Minutes 20-25: Step 3 - Create UserValidator struct
```rust
struct UserValidator { /* empty */ }
impl UserValidator { /* empty */ }
```
```bash
Dispatch test-runner: "Run: cargo test"
Result: ✓ 234 tests pass
git commit -m "refactor(bd-456): create UserValidator struct"
```

### Minutes 25-35: Steps 4-6 - Move validations to UserValidator
Each step: move one method, test, commit

### Minutes 35-45: Step 7 - Update UserService to use validator
```rust
// Use UserValidator instead of inline validation
```
```bash
Dispatch test-runner: "Run: cargo test"
Result: ✓ 234 tests pass
git commit -m "refactor(bd-456): use UserValidator in UserService"
```

### Minutes 45-55: Step 8 - Remove duplication from other services
Each service: one change, test, commit

### Minutes 55-60: Final verification and close
```bash
Dispatch test-runner: "Run: cargo test"
Result: ✓ 234 tests pass

Dispatch test-runner: "Run: cargo clippy"
Result: ✓ No warnings

bd status bd-456 --status closed
```

**Result:** Refactoring complete, 8 safe commits, all tests green throughout.

## Remember

- **Tests MUST stay green** throughout refactoring
- **Commit after EACH small change**
- **One transformation at a time**
- **Behavior changes ≠ refactoring**
- **3+ failures = question approach**
- **Track work in bd**

Refactoring is safe when done in small, tested steps. Rushing creates bugs.
