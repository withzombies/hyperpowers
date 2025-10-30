#!/bin/bash
set -e

echo "=== Testing Stop Hook Reminders ==="
echo ""

# Test 1: No edits = no reminder
echo "Test 1: No edits"
> hooks/context/edit-log.txt
output=$(echo '{"text": "All done!"}' | bash hooks/stop/10-gentle-reminders.sh 2>&1 || true)
if [ -z "$output" ] || ! echo "$output" | grep -q "━━━"; then
    echo "✓ No reminder (correct)"
else
    echo "✗ Unexpected reminder"
    echo "$output"
fi
echo ""

# Test 2: Source file edited without test = TDD reminder
echo "Test 2: TDD reminder"
echo "$(date +"%Y-%m-%d %H:%M:%S") | hyper | Edit | src/main.ts" > hooks/context/edit-log.txt
output=$(echo '{"text": "Feature implemented"}' | bash hooks/stop/10-gentle-reminders.sh 2>&1 || true)
if echo "$output" | grep -q "TDD"; then
    echo "✓ TDD reminder shown"
else
    echo "✗ TDD reminder missing"
    echo "$output"
fi
echo ""

# Test 3: Completion claim = verification reminder (with edits)
echo "Test 3: Verification reminder"
echo "$(date +"%Y-%m-%d %H:%M:%S") | hyper | Edit | src/main.ts" > hooks/context/edit-log.txt
output=$(echo '{"text": "All done and tests pass!"}' | bash hooks/stop/10-gentle-reminders.sh 2>&1 || true)
if echo "$output" | grep -q "Run tests"; then
    echo "✓ Verify reminder shown"
else
    echo "✗ Verify reminder missing"
    echo "$output"
fi
echo ""

# Test 4: Many files = commit reminder
echo "Test 4: Commit reminder"
> hooks/context/edit-log.txt
for i in {1..5}; do
    echo "$(date +"%Y-%m-%d %H:%M:%S") | hyper | Edit | src/file$i.ts" >> hooks/context/edit-log.txt
done
output=$(echo '{"text": "Refactoring complete"}' | bash hooks/stop/10-gentle-reminders.sh 2>&1 || true)
if echo "$output" | grep -q "commit"; then
    echo "✓ Commit reminder shown"
else
    echo "✗ Commit reminder missing"
    echo "$output"
fi
echo ""

# Test 5: Test with test file edited = no TDD reminder
echo "Test 5: Test file edited = no TDD reminder"
> hooks/context/edit-log.txt
echo "$(date +"%Y-%m-%d %H:%M:%S") | hyper | Edit | src/main.ts" > hooks/context/edit-log.txt
echo "$(date +"%Y-%m-%d %H:%M:%S") | hyper | Edit | src/main.test.ts" >> hooks/context/edit-log.txt
output=$(echo '{"text": "Feature implemented"}' | bash hooks/stop/10-gentle-reminders.sh 2>&1 || true)
if echo "$output" | grep -q "TDD"; then
    echo "✗ TDD reminder shown (should not)"
    echo "$output"
else
    echo "✓ No TDD reminder (correct - test file edited)"
fi
echo ""

# Clean up
> hooks/context/edit-log.txt

echo "=== All Tests Complete ==="
