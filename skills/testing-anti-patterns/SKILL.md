---
name: testing-anti-patterns
description: Use when writing or changing tests, adding mocks, or tempted to add test-only methods to production code - prevents testing mock behavior, production pollution with test-only methods, and mocking without understanding dependencies
---

# Testing Anti-Patterns

## Overview

Tests must verify real behavior, not mock behavior. Mocks are a means to isolate, not the thing being tested.

**Core principle:** Test what the code does, not what the mocks do.

**Following strict TDD prevents these anti-patterns.**

## The Iron Laws

```
1. NEVER test mock behavior
2. NEVER add test-only methods to production classes
3. NEVER mock without understanding dependencies
```

## Anti-Pattern 1: Testing Mock Behavior

**The violation (Rust):**
```rust
// ❌ BAD: Testing that the mock exists
#[test]
fn test_processes_request() {
    let mock_service = MockApiService::new();
    let handler = RequestHandler::new(Box::new(mock_service));

    // Testing that mock exists, not actual behavior
    assert!(handler.service().is_mock());
}
```

**The violation (Swift):**
```swift
// ❌ BAD: Testing that the mock exists
func testProcessesRequest() {
    let mockService = MockAPIService()
    let handler = RequestHandler(service: mockService)

    // Testing that mock exists, not actual behavior
    XCTAssertTrue(handler.service is MockAPIService)
}
```

**Why this is wrong:**
- You're verifying the mock works, not that the code works
- Test passes when mock is present, fails when it's not
- Tells you nothing about real behavior

**your human partner's correction:** "Are we testing the behavior of a mock?"

**The fix (Rust):**
```rust
// ✅ GOOD: Test real behavior
#[test]
fn test_processes_request() {
    let service = TestApiService::new();  // Real implementation or full fake
    let handler = RequestHandler::new(Box::new(service));

    let result = handler.process_request("data");
    assert_eq!(result.status, StatusCode::OK);
}

// OR if service must be mocked for isolation:
// Don't assert on the mock type - test handler's behavior with service present
```

**The fix (Swift):**
```swift
// ✅ GOOD: Test real behavior
func testProcessesRequest() {
    let service = TestAPIService()  // Real implementation or full fake
    let handler = RequestHandler(service: service)

    let result = handler.processRequest("data")
    XCTAssertEqual(result.status, .ok)
}

// OR if service must be mocked for isolation:
// Don't assert on the mock type - test handler's behavior with service present
```

### Gate Function

```
BEFORE asserting on any mock element:
  Ask: "Am I testing real component behavior or just mock existence?"

  IF testing mock existence:
    STOP - Delete the assertion or unmock the component

  Test real behavior instead
```

## Anti-Pattern 2: Test-Only Methods in Production

**The violation (Rust):**
```rust
// ❌ BAD: reset() only used in tests
pub struct Connection {
    pool: Arc<ConnectionPool>,
}

impl Connection {
    // Looks like production API!
    pub fn reset(&mut self) {
        self.pool.clear_all();
        // ... cleanup
    }
}

// In tests
#[cfg(test)]
mod tests {
    #[test]
    fn test_something() {
        let mut conn = Connection::new();
        // ... test code ...
        conn.reset();  // Test-only method
    }
}
```

**The violation (Swift):**
```swift
// ❌ BAD: reset() only used in tests
public class DataStore {
    func reset() {  // Looks like production API!
        cache.removeAll()
        // ... cleanup
    }
}

// In tests
override func tearDown() {
    dataStore.reset()  // Test-only method
    super.tearDown()
}
```

**Why this is wrong:**
- Production code polluted with test-only methods
- Dangerous if accidentally called in production
- Violates YAGNI and separation of concerns
- Confuses object lifecycle with entity lifecycle

**The fix (Rust):**
```rust
// ✅ GOOD: Test utilities handle test cleanup
// Connection has no reset() - it's stateless in production

// In tests/test_utils.rs
pub fn cleanup_connection(conn: &Connection) {
    if let Some(pool) = conn.get_pool() {
        pool.clear_test_data();
    }
}

// In tests
#[test]
fn test_something() {
    let conn = Connection::new();
    // ... test code ...
    cleanup_connection(&conn);
}
```

**The fix (Swift):**
```swift
// ✅ GOOD: Test utilities handle test cleanup
// DataStore has no reset() - it's stateless in production

// In TestHelpers/DataStoreHelpers.swift
func cleanupDataStore(_ store: DataStore) {
    store.cache.removeAll()
    // Access internals properly for testing
}

// In tests
override func tearDown() {
    cleanupDataStore(dataStore)
    super.tearDown()
}
```

### Gate Function

```
BEFORE adding any method to production class:
  Ask: "Is this only used by tests?"

  IF yes:
    STOP - Don't add it
    Put it in test utilities instead

  Ask: "Does this class own this resource's lifecycle?"

  IF no:
    STOP - Wrong class for this method
```

## Anti-Pattern 3: Mocking Without Understanding

**The violation (Rust):**
```rust
// ❌ BAD: Mock breaks test logic
#[test]
fn test_detects_duplicate_server() {
    // Mock prevents config write that test depends on!
    let mut config_manager = MockConfigManager::new();
    config_manager.expect_add_server()
        .returning(|_| Ok(()));  // No actual config write!

    config_manager.add_server(&config).unwrap();
    config_manager.add_server(&config).unwrap();  // Should fail - but won't!
}
```

**The violation (Swift):**
```swift
// ❌ BAD: Mock breaks test logic
func testDetectsDuplicateServer() {
    // Mock prevents config write that test depends on!
    let mockConfig = MockConfigManager()
    mockConfig.addServerHandler = { _ in () }  // No actual config write!

    try! mockConfig.addServer(config)
    try! mockConfig.addServer(config)  // Should throw - but won't!
}
```

**Why this is wrong:**
- Mocked method had side effect test depended on (writing config)
- Over-mocking to "be safe" breaks actual behavior
- Test passes for wrong reason or fails mysteriously

**The fix (Rust):**
```rust
// ✅ GOOD: Mock at correct level
#[test]
fn test_detects_duplicate_server() {
    // Mock the slow part, preserve behavior test needs
    let server_manager = MockServerManager::new();  // Just mock slow server startup
    let config_manager = ConfigManager::new_with_manager(server_manager);

    config_manager.add_server(&config).unwrap();  // Config written
    let result = config_manager.add_server(&config);  // Duplicate detected ✓
    assert!(result.is_err());
}
```

**The fix (Swift):**
```swift
// ✅ GOOD: Mock at correct level
func testDetectsDuplicateServer() {
    // Mock the slow part, preserve behavior test needs
    let mockServerManager = MockServerManager()  // Just mock slow server startup
    let configManager = ConfigManager(serverManager: mockServerManager)

    try configManager.addServer(config)  // Config written
    XCTAssertThrowsError(try configManager.addServer(config))  // Duplicate detected ✓
}
```

### Gate Function

```
BEFORE mocking any method:
  STOP - Don't mock yet

  1. Ask: "What side effects does the real method have?"
  2. Ask: "Does this test depend on any of those side effects?"
  3. Ask: "Do I fully understand what this test needs?"

  IF depends on side effects:
    Mock at lower level (the actual slow/external operation)
    OR use test doubles that preserve necessary behavior
    NOT the high-level method the test depends on

  IF unsure what test depends on:
    Run test with real implementation FIRST
    Observe what actually needs to happen
    THEN add minimal mocking at the right level

  Red flags:
    - "I'll mock this to be safe"
    - "This might be slow, better mock it"
    - Mocking without understanding the dependency chain
```

## Anti-Pattern 4: Incomplete Mocks

**The violation (Rust):**
```rust
// ❌ BAD: Partial mock - only fields you think you need
struct MockResponse {
    status: String,
    data: UserData,
    // Missing: metadata that downstream code uses
}

impl ApiResponse for MockResponse {
    fn status(&self) -> &str { &self.status }
    fn data(&self) -> &UserData { &self.data }
    fn metadata(&self) -> &Metadata {
        panic!("metadata not implemented!")  // Breaks at runtime!
    }
}
```

**The violation (Swift):**
```swift
// ❌ BAD: Partial mock - only fields you think you need
class MockResponse: APIResponse {
    let status: String
    let data: UserData
    // Missing: metadata that downstream code uses

    var metadata: Metadata {
        fatalError("metadata not implemented!")  // Breaks at runtime!
    }
}
```

**Why this is wrong:**
- **Partial mocks hide structural assumptions** - You only mocked fields you know about
- **Downstream code may depend on fields you didn't include** - Silent failures
- **Tests pass but integration fails** - Mock incomplete, real API complete
- **False confidence** - Test proves nothing about real behavior

**The Iron Rule:** Mock the COMPLETE data structure as it exists in reality, not just fields your immediate test uses.

**The fix (Rust):**
```rust
// ✅ GOOD: Mirror real API completeness
struct MockResponse {
    status: String,
    data: UserData,
    metadata: Metadata,  // All fields real API returns
}

impl ApiResponse for MockResponse {
    fn status(&self) -> &str { &self.status }
    fn data(&self) -> &UserData { &self.data }
    fn metadata(&self) -> &Metadata { &self.metadata }
}

// In test
let mock = MockResponse {
    status: "success".to_string(),
    data: UserData { user_id: "123", name: "Alice" },
    metadata: Metadata { request_id: "req-789", timestamp: 1234567890 },
};
```

**The fix (Swift):**
```swift
// ✅ GOOD: Mirror real API completeness
class MockResponse: APIResponse {
    let status: String
    let data: UserData
    let metadata: Metadata  // All fields real API returns

    init(status: String, data: UserData, metadata: Metadata) {
        self.status = status
        self.data = data
        self.metadata = metadata
    }
}

// In test
let mock = MockResponse(
    status: "success",
    data: UserData(userId: "123", name: "Alice"),
    metadata: Metadata(requestId: "req-789", timestamp: 1234567890)
)
```

### Gate Function

```
BEFORE creating mock responses:
  Check: "What fields does the real API response contain?"

  Actions:
    1. Examine actual API response from docs/examples
    2. Include ALL fields system might consume downstream
    3. Verify mock matches real response schema completely

  Critical:
    If you're creating a mock, you must understand the ENTIRE structure
    Partial mocks fail silently when code depends on omitted fields

  If uncertain: Include all documented fields
```

## Anti-Pattern 5: Integration Tests as Afterthought

**The violation:**
```
✅ Implementation complete
❌ No tests written
"Ready for testing"
```

**Why this is wrong:**
- Testing is part of implementation, not optional follow-up
- TDD would have caught this
- Can't claim complete without tests

**The fix:**
```
TDD cycle:
1. Write failing test
2. Implement to pass
3. Refactor
4. THEN claim complete
```

## When Mocks Become Too Complex

**Warning signs:**
- Mock setup longer than test logic
- Mocking everything to make test pass
- Mocks missing methods real components have
- Test breaks when mock changes

**your human partner's question:** "Do we need to be using a mock here?"

**Consider:** Integration tests with real components often simpler than complex mocks

## TDD Prevents These Anti-Patterns

**Why TDD helps:**
1. **Write test first** → Forces you to think about what you're actually testing
2. **Watch it fail** → Confirms test tests real behavior, not mocks
3. **Minimal implementation** → No test-only methods creep in
4. **Real dependencies** → You see what the test actually needs before mocking

**If you're testing mock behavior, you violated TDD** - you added mocks without watching test fail against real code first.

## Quick Reference

| Anti-Pattern | Fix |
|--------------|-----|
| Assert on mock elements | Test real component or unmock it |
| Test-only methods in production | Move to test utilities |
| Mock without understanding | Understand dependencies first, mock minimally |
| Incomplete mocks | Mirror real API completely |
| Tests as afterthought | TDD - tests first |
| Over-complex mocks | Consider integration tests |

## Red Flags

- Assertion checks for `*-mock` test IDs
- Methods only called in test files
- Mock setup is >50% of test
- Test fails when you remove mock
- Can't explain why mock is needed
- Mocking "just to be safe"

## The Bottom Line

**Mocks are tools to isolate, not things to test.**

If TDD reveals you're testing mock behavior, you've gone wrong.

Fix: Test real behavior or question why you're mocking at all.
