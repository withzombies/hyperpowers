#!/usr/bin/env python3
"""
PreToolUse hook to block direct edits to .git/hooks/pre-commit

Git hooks should be managed through proper tooling and version control,
not modified directly by Claude. Direct modifications bypass review and
can introduce issues.
"""

import json
import sys
import os

def main():
    # Read tool input from stdin
    try:
        input_data = json.load(sys.stdin)
    except json.JSONDecodeError:
        # If we can't parse JSON, allow the operation
        sys.exit(0)

    tool_name = input_data.get("tool_name", "")
    tool_input = input_data.get("tool_input", {})

    # Check for file_path in Edit/Write tools
    file_path = tool_input.get("file_path", "")

    if not file_path:
        sys.exit(0)

    # Normalize path for comparison
    normalized_path = os.path.normpath(file_path)

    # Check if path contains .git/hooks/pre-commit (handles various path formats)
    if ".git/hooks/pre-commit" in normalized_path or normalized_path.endswith("pre-commit"):
        # Additional check: is this actually in a .git/hooks directory?
        if "/.git/hooks/" in normalized_path or "\\.git\\hooks\\" in normalized_path:
            output = {
                "hookSpecificOutput": {
                    "hookEventName": "PreToolUse",
                    "permissionDecision": "deny",
                    "permissionDecisionReason": (
                        "🚫 DIRECT PRE-COMMIT HOOK MODIFICATION BLOCKED\n\n"
                        f"Attempted to modify: {file_path}\n\n"
                        "Git hooks should not be modified directly by Claude.\n\n"
                        "Why this is blocked:\n"
                        "- Pre-commit hooks enforce critical quality standards\n"
                        "- Direct modifications bypass code review\n"
                        "- Changes can break CI/CD pipelines\n"
                        "- Hook modifications should be version controlled\n\n"
                        "If you need to modify hooks:\n"
                        "1. Edit the source hook template in version control\n"
                        "2. Use proper tooling (husky, pre-commit framework, etc.)\n"
                        "3. Document changes and get them reviewed\n"
                        "4. Never bypass hooks with --no-verify\n\n"
                        "If the hook is causing issues:\n"
                        "- Fix the underlying problem the hook detected\n"
                        "- Ask the user for permission to modify hooks\n"
                        "- Document why the modification is necessary"
                    )
                }
            }
            print(json.dumps(output))
            sys.exit(0)

    # Allow all other edits
    sys.exit(0)

if __name__ == "__main__":
    main()
