#!/usr/bin/env bash
# SessionStart hook for hyperpower plugin

set -euo pipefail

# Determine plugin root directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
PLUGIN_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Read using-hyper content
using_hyper_content=$(cat "${PLUGIN_ROOT}/skills/using-hyper/SKILL.md" 2>&1 || echo "Error reading using-hyper skill")

# Escape outputs for JSON
using_hyper_escaped=$(echo "$using_hyper_content" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g' | awk '{printf "%s\\n", $0}')

# Output context injection as JSON
cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": "<EXTREMELY_IMPORTANT>\nYou have hyperpowers.\n\n**The content below is from skills/using-hyper/SKILL.md - your introduction to using skills:**\n\n${using_hyper_escaped}\n</EXTREMELY_IMPORTANT>"
  }
}
EOF

exit 0
