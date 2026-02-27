#!/bin/bash
set -e

echo "=== Testing Skill Activator Hook ==="
echo ""

test_prompt() {
    local prompt="$1"
    local expected_skills="$2"

    echo "Test: $prompt"
    result=$(echo "{\"text\": \"$prompt\"}" | node hooks/user-prompt-submit/10-skill-activator.js)

    if echo "$result" | jq -e 'has("decision") | not' > /dev/null; then
        echo "✓ Returns valid response without decision field"
    else
        echo "✗ FAIL: Should not have decision field"
        return 1
    fi

    if echo "$result" | jq -e '.additionalContext' > /dev/null 2>&1; then
        activated=$(echo "$result" | jq -r '.additionalContext' | grep -o '\*\*[^*]\+\*\*' | sed 's/\*\*//g' | tr '\n' ' ' || true)
        echo "  Activated: $activated"

        if [ -n "$expected_skills" ]; then
            for skill in $expected_skills; do
                if echo "$activated" | grep -q "$skill"; then
                    echo "  ✓ Expected skill activated: $skill"
                else
                    echo "  ✗ Missing expected skill: $skill"
                fi
            done
        fi
    else
        echo "  No skills activated"
    fi

    echo ""
}

# Test 1: TDD prompt should activate test-driven-development
test_prompt "I want to write a test for the login function" "test-driven-development"

# Test 2: Debugging prompt should activate debugging-with-tools
test_prompt "Help me debug this error in my code" "debugging-with-tools"

# Test 3: Planning prompt should activate brainstorming
test_prompt "I want to design a new authentication system" "brainstorming"

# Test 4: Refactoring prompt should activate refactoring-safely
test_prompt "Let's refactor this code to be cleaner" "refactoring-safely"

# Test 5: Empty prompt should return response with no context and no decision field
test_prompt "" ""

# Test 6: Agent-style invocation of sre-task-refinement should be corrected
echo "Test: Correct sre-task-refinement agent-style invocation"
result=$(echo "{\"text\": \"hyperpowers:sre-task-refinement(SRE refinement on task bd-13)\"}" | node hooks/user-prompt-submit/10-skill-activator.js)
if echo "$result" | jq -r '.additionalContext // ""' | grep -q "Use \`/hyperpowers:sre-task-refinement\`"; then
    echo "✓ Includes corrective guidance for skill invocation"
else
    echo "✗ FAIL: Missing corrective guidance for sre-task-refinement"
    exit 1
fi
if echo "$result" | jq -r '.additionalContext // ""' | grep -q "sre-task-refinement"; then
    echo "✓ Activates sre-task-refinement"
else
    echo "✗ FAIL: sre-task-refinement not activated"
    exit 1
fi
echo ""

echo "=== All Tests Complete ==="
