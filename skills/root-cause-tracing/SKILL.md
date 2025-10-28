---
name: root-cause-tracing
description: Use when errors occur deep in execution and you need to trace back to find the original trigger - systematically traces bugs backward through call stack, adding instrumentation when needed, to identify source of invalid data or incorrect behavior
---

# Root Cause Tracing

## Overview

Bugs often manifest deep in the call stack (database error, file operation failure, validation error in utility function). Your instinct is to fix where the error appears, but that's treating a symptom.

**Core principle:** Trace backward through the call chain until you find the original trigger, then fix at the source.

**Never fix just where the error appears.** Always find the source.

## When to Use

Use this technique when:
- Error happens deep in execution (not at entry point)
- Stack trace shows long call chain
- Unclear where invalid data originated
- Need to find which test/code triggers the problem
- Error message points to utility/library code

**Example symptoms:**
- "Database rejects empty string" ← Where did empty string come from?
- "File not found: ''" ← Why is path empty?
- "Invalid argument to function" ← Who passed invalid argument?
- "Null pointer dereference" ← What should have been initialized?

## The Tracing Process

### 1. Observe the Symptom

**Read the error completely:**
```
Error: Invalid email format: ""
  at validateEmail (validator.ts:42)
  at UserService.create (user-service.ts:18)
  at ApiHandler.createUser (api-handler.ts:67)
  at HttpServer.handleRequest (server.ts:123)
  at TestCase.test_create_user (user.test.ts:10)
```

**Symptom:** Email validation fails on empty string
**Location:** Deep in validator utility

### 2. Find Immediate Cause

**What code directly causes this?**

```typescript
// validator.ts:42
function validateEmail(email: string): boolean {
  if (!email) throw new Error(`Invalid email format: "${email}"`);
  return EMAIL_REGEX.test(email);
}
```

**DON'T fix here.** This is the symptom, not the source.

### 3. Trace Backward: What Called This?

**Use stack trace or debugger:**

```typescript
// user-service.ts:18
create(request: UserRequest): User {
  validateEmail(request.email); // Called with request.email = ""
  // ...
}
```

**Question:** Why is `request.email` empty?
**Keep tracing:** What called UserService.create?

### 4. Keep Tracing Up the Stack

```typescript
// api-handler.ts:67
async createUser(req: Request): Promise<Response> {
  const userRequest = {
    name: req.body.name,
    email: req.body.email || "", // ← FOUND IT!
  };
  return this.userService.create(userRequest);
}
```

**Root cause found:** API handler provides default empty string when email missing.

**This is where to fix:** Validate/reject at API boundary, don't pass invalid data downstream.

### 5. Identify the Pattern

**Why empty string used as default?**
- Misguided "safety": Thought empty string better than undefined
- Should reject invalid request at API boundary
- Downstream code assumes data already validated

**Proper fix:**
```typescript
// api-handler.ts
async createUser(req: Request): Promise<Response> {
  if (!req.body.email) {
    return Response.badRequest("Email is required");
  }
  const userRequest = {
    name: req.body.name,
    email: req.body.email, // No default, already validated
  };
  return this.userService.create(userRequest);
}
```

## Using Debugger for Tracing

**When stack trace isn't clear enough:**

**IMPORTANT:** Claude cannot run interactive debuggers. Instead, Claude should guide the user through debugger usage or add instrumentation.

### Option 1: Guide User Through Debugger

**Claude provides commands for user to run:**

```
"Let's use lldb to trace backward through the call stack.

Please run these commands:
  lldb target/debug/myapp
  (lldb) breakpoint set --file validator.rs --line 42
  (lldb) run

When breakpoint hits:
  (lldb) frame variable email     # Check the value here
  (lldb) bt                       # See full call stack
  (lldb) up                       # Move to caller
  (lldb) frame variable request   # Check values in caller
  (lldb) up                       # Move up again
  (lldb) frame variable           # Check where empty string created

Please share:
  1. Value of 'email' at validator.rs:42
  2. Value of 'request.email' in user_service.rs
  3. Value of 'req.body.email' in api_handler.rs
  4. Where does empty string appear first?"
```

**User shares debugger output:**
```
(lldb) frame variable email
(string) email = ""

(lldb) up
frame #1: user_service.rs:18 create
(lldb) frame variable request.email
(string) request.email = ""

(lldb) up
frame #2: api_handler.rs:67 createUser
(lldb) frame variable req.body.email
(option) req.body.email = nil
(lldb) frame variable userRequest.email
(string) userRequest.email = ""  ← Created here!
```

**Root cause identified:** API handler converts nil to empty string at line 67.

### Option 2: Add Instrumentation (Claude CAN do this)

## Adding Instrumentation When Needed

**When debugger not available or issue is intermittent:**

### Add Diagnostic Logging

```rust
// Add at error location
fn validate_email(email: &str) -> Result<()> {
    eprintln!("DEBUG validate_email called:");
    eprintln!("  email: {:?}", email);
    eprintln!("  stack trace: {}", std::backtrace::Backtrace::capture());

    if email.is_empty() {
        return Err(Error::InvalidEmail);
    }
    // ...
}
```

**Critical:** Use `eprintln!()` or `console.error()` in tests, not logger (may be suppressed).

### Run and Capture

```bash
# Run tests, capture stderr
cargo test 2>&1 | grep "DEBUG validate_email" -A 10
```

**Analyze output:**
- Look for test file names in stack traces
- Find the line number triggering the call
- Identify the pattern (same test? same parameter?)

## Real Example: Tracing Through Multiple Layers

**Problem:** `.git` directory created in source code directory during tests

**Symptom:**
```
Error: Cannot initialize git repo
Location: src/workspace/git.rs:45
```

**Trace chain:**

```
1. git init runs with cwd=""
   ↓ Why is cwd empty?

2. WorkspaceManager.init(projectDir="")
   ↓ Why is projectDir empty?

3. Session.create(projectDir="")
   ↓ Why was projectDir passed as empty?

4. Test: Project.create(context.tempDir)
   ↓ Why is context.tempDir empty?

5. context.tempDir = ""  ← FOUND IT
   Test file declares: const context = setupTest();
   setupTest() returns { tempDir: "" } initially
   tempDir assigned in beforeEach()
   But test accessed it at top level!
```

**Root cause:** Test accessed `context.tempDir` before `beforeEach` ran.

**Symptom fix (wrong):** Validate cwd in git module
**Source fix (right):** Make tempDir a getter that throws if accessed before init

```typescript
function setupTest() {
  let _tempDir: string | undefined;

  return {
    beforeEach() {
      _tempDir = makeTempDir();
    },
    get tempDir(): string {
      if (!_tempDir) {
        throw new Error("tempDir accessed before beforeEach!");
      }
      return _tempDir;
    }
  };
}
```

**Also add defense-in-depth:**
- Layer 1: Getter throws if accessed early
- Layer 2: Project.create validates directory not empty
- Layer 3: WorkspaceManager validates directory exists
- Layer 4: NODE_ENV guard prevents git init outside test dirs

## Finding Which Test Pollutes

**When something appears during tests but you don't know which test:**

### Binary Search Approach

```bash
# Run half the tests
npm test tests/first-half/*.test.ts
# Does pollution appear? Yes → in first half
# No → in second half

# Subdivide and repeat
npm test tests/first-quarter/*.test.ts

# Continue until you find the specific test file
npm test tests/auth/*.test.ts
npm test tests/auth/login.test.ts  ← Found it!
```

### Or Use Test Isolation

```bash
# Run tests one at a time
for test in tests/**/*.test.ts; do
  echo "Testing: $test"
  npm test "$test"
  if [ -d .git ]; then
    echo "FOUND POLLUTER: $test"
    break
  fi
done
```

## Key Principles

### Never Fix Symptoms

❌ **Wrong:** Add validation deep in stack
```rust
fn git_init(directory: &str) {
    if directory.is_empty() {
        panic!("Directory cannot be empty"); // Band-aid
    }
    Command::new("git").arg("init").current_dir(directory).run()
}
```

✓ **Right:** Fix at source where empty string created
```rust
fn create_project(directory: &str) {
    if directory.is_empty() {
        return Err("Directory required");
    }
    // Now git_init will never receive empty string
    git_init(directory)
}
```

### Trace Until You Find the Source

**Don't stop at first suspicious code.** Keep tracing backward until you find:
- Where invalid data was created
- Where incorrect assumption was made
- Where validation should have happened but didn't

### Then Add Defense in Depth

After fixing source, add validation at each layer:
```rust
// Layer 1: API - Reject invalid input (SOURCE FIX)
if directory.is_empty() { return Err(...); }

// Layer 2: Service - Validate assumptions
assert!(!directory.is_empty());

// Layer 3: Utility - Defensive check
if directory.is_empty() { panic!("invariant violated"); }
```

**But:** Fix at source first. Defense is backup, not primary fix.

## Integration with debugging-with-tools

Use root-cause-tracing when:
- debugging-with-tools Phase 2: "Trace Backward Through Call Stack"
- Error is deep in execution
- Stack trace shows multiple layers
- Need to find original trigger

**Pattern:**
1. Start with debugging-with-tools
2. In Phase 2, use root-cause-tracing for deep stack analysis
3. Return to debugging-with-tools with root cause identified

## Quick Reference

| Step | Action | Tool | Who Uses It |
|------|--------|------|-------------|
| 1. Symptom | Read error, find location | Error message | Claude |
| 2. Immediate cause | What code threw error? | Stack trace | Claude |
| 3. Trace up | What called this? | Stack trace | Claude |
| 4. Keep tracing | What called that? | Debugger OR instrumentation | User (Claude guides) OR Claude (adds logging) |
| 5. Find source | Where did bad value originate? | Debugger OR instrumentation | User (Claude guides) OR Claude (adds logging) |
| 6. Fix source | Address root cause | Code change | Claude |
| 7. Add defense | Validate at each layer | Multiple checks | Claude |

**Note:** Claude guides user through debugger OR adds instrumentation Claude can run.

## Remember

- **Symptoms appear deep**, sources are shallow
- **Fix at source**, not at symptom
- **Use debugger** to navigate call stack
- **Trace backward** until you find the original trigger
- **Then add defense** at each layer as backup
- **Never fix just where error appears**

Tracing takes 10 extra minutes. Fixing symptoms wastes days.
