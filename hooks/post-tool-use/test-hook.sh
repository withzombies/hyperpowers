#!/bin/bash
set -e

echo "=== Testing PostToolUse Hook (Edit Tracker) ==="
echo ""

# Clean up log before testing
> hooks/context/edit-log.txt

# Test 1: Edit tool event
echo "Test 1: Edit tool event"
result=$(echo '{"tool":{"name":"Edit","input":{"file_path":"/Users/ryan/src/hyper/test.txt"}}}' | bash hooks/post-tool-use/01-track-edits.sh)
if echo "$result" | jq -e '.decision == "continue"' > /dev/null; then
    echo "✓ Returns continue decision"
else
    echo "✗ FAIL: Wrong decision"
fi

if grep -q "test.txt" hooks/context/edit-log.txt; then
    echo "✓ Logged edit to test.txt"
else
    echo "✗ FAIL: Did not log edit"
fi
echo ""

# Test 2: Write tool event
echo "Test 2: Write tool event"
result=$(echo '{"tool":{"name":"Write","input":{"file_path":"/Users/ryan/src/hyper/newfile.txt"}}}' | bash hooks/post-tool-use/01-track-edits.sh)
if echo "$result" | jq -e '.decision == "continue"' > /dev/null; then
    echo "✓ Returns continue decision"
else
    echo "✗ FAIL: Wrong decision"
fi

if grep -q "newfile.txt" hooks/context/edit-log.txt; then
    echo "✓ Logged write to newfile.txt"
else
    echo "✗ FAIL: Did not log write"
fi
echo ""

# Test 3: Malformed JSON
echo "Test 3: Malformed JSON"
result=$(echo 'invalid json' | bash hooks/post-tool-use/01-track-edits.sh)
if echo "$result" | jq -e '.decision == "continue"' > /dev/null; then
    echo "✓ Gracefully handles malformed JSON"
else
    echo "✗ FAIL: Did not handle malformed JSON"
fi
echo ""

# Test 4: Empty input
echo "Test 4: Empty input"
result=$(echo '' | bash hooks/post-tool-use/01-track-edits.sh)
if echo "$result" | jq -e '.decision == "continue"' > /dev/null; then
    echo "✓ Gracefully handles empty input"
else
    echo "✗ FAIL: Did not handle empty input"
fi
echo ""

# Test 5: Check log format
echo "Test 5: Check log format"
cat hooks/context/edit-log.txt
line_count=$(wc -l < hooks/context/edit-log.txt | tr -d ' ')
if [ "$line_count" -eq 2 ]; then
    echo "✓ Correct number of log entries (2)"
else
    echo "✗ FAIL: Expected 2 log entries, got $line_count"
fi

if grep -q "| hyper |" hooks/context/edit-log.txt; then
    echo "✓ Repo name detected correctly"
else
    echo "✗ FAIL: Repo name not detected"
fi
echo ""

# Test 6: Context query utilities
echo "Test 6: Context query utilities"
source hooks/utils/context-query.sh

recent=$(get_recent_edits)
if [ -n "$recent" ]; then
    echo "✓ get_recent_edits works"
else
    echo "✗ FAIL: get_recent_edits returned empty"
fi

session_files=$(get_session_files)
if echo "$session_files" | grep -q "test.txt"; then
    echo "✓ get_session_files works"
else
    echo "✗ FAIL: get_session_files did not find test.txt"
fi

if was_file_edited "/Users/ryan/src/hyper/test.txt"; then
    echo "✓ was_file_edited works"
else
    echo "✗ FAIL: was_file_edited did not detect edit"
fi

stats=$(get_repo_stats)
if echo "$stats" | grep -q "hyper"; then
    echo "✓ get_repo_stats works"
else
    echo "✗ FAIL: get_repo_stats did not find hyper repo"
fi
echo ""

# Clean up
> hooks/context/edit-log.txt

echo "=== All Tests Complete ==="
