#!/usr/bin/env bash
set -e

check_dependencies() {
  local missing=()
  command -v jq >/dev/null 2>&1 || missing+=("jq")
  command -v grep >/dev/null 2>&1 || missing+=("grep")

  if [ ${#missing[@]} -gt 0 ]; then
    echo "ERROR: Missing required dependencies: ${missing[*]}" >&2
    echo "Please install missing tools and try again." >&2
    return 1
  fi
  return 0
}

check_dependencies || exit 1

# Load and validate skill-rules.json
load_skill_rules() {
  local rules_path="$1"

  if [ -z "$rules_path" ]; then
    echo "ERROR: No rules path provided" >&2
    return 1
  fi

  if [ ! -f "$rules_path" ]; then
    echo "ERROR: Rules file not found: $rules_path" >&2
    return 1
  fi

  if ! jq . "$rules_path" 2>/dev/null; then
    echo "ERROR: Invalid JSON in $rules_path" >&2
    return 1
  fi

  return 0
}

# Match keywords (case-insensitive substring matching)
match_keywords() {
  local text="$1"
  local keywords="$2"

  if [ -z "$text" ] || [ -z "$keywords" ]; then
    return 1
  fi

  local lower_text=$(echo "$text" | tr '[:upper:]' '[:lower:]')

  IFS=',' read -ra KEYWORD_ARRAY <<< "$keywords"
  for keyword in "${KEYWORD_ARRAY[@]}"; do
    local lower_keyword=$(echo "$keyword" | tr '[:upper:]' '[:lower:]' | xargs)
    if [[ "$lower_text" == *"$lower_keyword"* ]]; then
      return 0
    fi
  done

  return 1
}

# Match regex patterns (case-insensitive)
match_patterns() {
  local text="$1"
  local patterns="$2"

  if [ -z "$text" ] || [ -z "$patterns" ]; then
    return 1
  fi

  # Use bash regex matching for performance (no external process spawning)
  local lower_text=$(echo "$text" | tr '[:upper:]' '[:lower:]')

  IFS=',' read -ra PATTERN_ARRAY <<< "$patterns"
  for pattern in "${PATTERN_ARRAY[@]}"; do
    pattern=$(echo "$pattern" | xargs | tr '[:upper:]' '[:lower:]')

    # Use bash's built-in regex matching (much faster than spawning grep)
    if [[ "$lower_text" =~ $pattern ]]; then
      return 0
    fi
  done

  return 1
}

# Find matching skills from prompt
# Returns JSON array of skill names, sorted by priority
find_matching_skills() {
  local prompt="$1"
  local rules_path="$2"
  local max_skills="${3:-3}"

  if [ -z "$prompt" ] || [ -z "$rules_path" ]; then
    echo "[]"
    return 0
  fi

  if ! load_skill_rules "$rules_path" >/dev/null; then
    echo "[]"
    return 1
  fi

  # Load all skill data in one jq call for performance
  local skill_data=$(jq -r '
    to_entries |
    map(select(.key != "_comment" and .key != "_schema")) |
    map({
      name: .key,
      priority: .value.priority,
      keywords: (.value.promptTriggers.keywords | join(",")),
      patterns: (.value.promptTriggers.intentPatterns | join(","))
    }) |
    .[] |
    "\(.name)|\(.priority)|\(.keywords)|\(.patterns)"
  ' "$rules_path")

  local matches=()

  while IFS='|' read -r skill priority keywords patterns; do
    # Check if keywords or patterns match
    if match_keywords "$prompt" "$keywords" || match_patterns "$prompt" "$patterns"; then
      matches+=("$priority:$skill")
    fi
  done <<< "$skill_data"

  # Sort by priority (critical > high > medium > low) and limit to max_skills
  if [ ${#matches[@]} -eq 0 ]; then
    echo "[]"
    return 0
  fi

  # Sort and format as JSON array
  printf '%s\n' "${matches[@]}" | \
    sed 's/^critical:/0:/; s/^high:/1:/; s/^medium:/2:/; s/^low:/3:/' | \
    sort -t: -k1,1n | \
    head -n "$max_skills" | \
    cut -d: -f2- | \
    jq -R . | \
    jq -s .
}
