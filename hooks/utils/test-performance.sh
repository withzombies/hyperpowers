#!/usr/bin/env bash
set -e

cd "$(dirname "$0")/.."
source utils/skill-matcher.sh

echo "=== Performance Tests ==="
echo ""

# Test 1: match_keywords performance (<50ms)
echo "Test 1: match_keywords performance"
prompt="I want to write a test for the login function"
keywords="test,testing,TDD,spec,unit test"

start=$(date +%s%N)
for i in {1..10}; do
  match_keywords "$prompt" "$keywords" >/dev/null
done
end=$(date +%s%N)

duration_ns=$((end - start))
duration_ms=$((duration_ns / 1000000 / 10))

echo "  Duration: ${duration_ms}ms (target: <50ms)"
if [ $duration_ms -lt 50 ]; then
  echo "  ✓ PASS"
else
  echo "  ✗ FAIL"
  exit 1
fi

echo ""

# Test 2: find_matching_skills performance (<1000ms acceptable for 113 patterns)
echo "Test 2: find_matching_skills performance"
prompt="I want to implement a new feature with TDD"
rules_path="skill-rules.json"

start=$(date +%s%N)
result=$(find_matching_skills "$prompt" "$rules_path" 3)
end=$(date +%s%N)

duration_ns=$((end - start))
duration_ms=$((duration_ns / 1000000))

echo "  Duration: ${duration_ms}ms (target: <1000ms for 19 skills, 113 patterns)"
echo "  Matches found: $(echo "$result" | jq 'length')"
if [ $duration_ms -lt 1000 ]; then
  echo "  ✓ PASS"
else
  echo "  ✗ FAIL - Performance degradation detected"
  exit 1
fi

# Note: 113 regex patterns × 19 skills with bash regex matching
# Typical user prompts are 10-50 words, matching completes in <600ms
# This is acceptable for a user-prompt-submit hook (runs once per prompt)

echo ""
echo "=== All Performance Tests Passed ==="
