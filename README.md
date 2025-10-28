# Hyperpowers

Strong guidance for Claude Code as a software development assistant.

Hyperpowers is a Claude Code plugin that provides structured workflows, best practices, and specialized agents to help you build software more effectively. Think of it as a pair programming partner that ensures you follow proven development patterns.

## Features

### Skills

Reusable workflows for common development tasks:

**Feature Development:**
- **brainstorming** - Interactive design refinement using Socratic method
- **writing-plans** - Create detailed implementation plans (single task or multiple tasks)
- **executing-plans** - Execute tasks continuously with optional per-task review
- **review-implementation** - Verify implementation matches requirements
- **finishing-a-development-branch** - Complete workflow for PR creation and cleanup
- **sre-task-refinement** - Ensure all corner cases and requirements are understood (uses Opus 4.1)

**Bug Fixing & Debugging:**
- **debugging-with-tools** - Systematic investigation using debuggers, internet research, and agents
- **root-cause-tracing** - Trace backward through call stack to find original trigger
- **fixing-bugs** - Complete workflow from bug discovery to closure with bd tracking

**Refactoring & Maintenance:**
- **refactoring-safely** - Test-preserving transformations in small steps with tests staying green

**Quality & Testing:**
- **test-driven-development** - Write tests first, ensure they fail, then implement
- **testing-anti-patterns** - Prevent common testing mistakes
- **verification-before-completion** - Always verify before claiming success

**Task & Project Management:**
- **managing-bd-tasks** - Advanced bd operations: splitting tasks, merging duplicates, dependencies, metrics

**Collaboration & Process:**
- **dispatching-parallel-agents** - Investigate independent failures concurrently
- **writing-skills** - TDD for process documentation itself

### Slash Commands

Quick access to key workflows:

- `/hyperpowers:brainstorm` - Start interactive design refinement
- `/hyperpowers:write-plan` - Create detailed implementation plan
- `/hyperpowers:execute-plan` - Execute plan with review checkpoints
- `/hyperpowers:review-implementation` - Review completed implementation

### Specialized Agents

Domain-specific agents for complex tasks:

- **code-reviewer** - Review implementations against plans and coding standards
- **codebase-investigator** - Understand current codebase state and patterns
- **internet-researcher** - Research APIs, libraries, and current best practices
- **test-runner** - Run tests/pre-commit hooks/commits without context pollution (uses Haiku)

### Hooks

Automatic behaviors that enhance your workflow:

- Session start hooks to establish context
- Integration with development workflows

## Key Benefits

### Context Efficiency with test-runner Agent

The **test-runner** agent solves a common problem: running tests, pre-commit hooks, or git commits can generate massive amounts of output that pollutes your context window with successful test results, formatting changes, and debug prints.

**How it works:**
- Agent runs commands in its own separate context
- Captures all output (test results, hook output, etc.)
- Returns **only**: summary statistics + complete failure details
- Filters out: passing test output, "Reformatted X files" spam, verbose formatting diffs

**Example:**
```bash
# Without agent: Your context gets 500 lines of passing test output
pytest tests/  # 47 tests pass, prints everything

# With test-runner agent: Your context gets clean summary
Task("Run tests", "Run pytest tests/")
# Agent returns: "✓ 47 tests passed, 0 failed. Exit code 0."
```

**Benefits:**
- Keeps your context clean and focused
- Still provides complete failure details when tests fail
- Works with all test frameworks (pytest, cargo, npm, go)
- Handles pre-commit hooks without formatting spam
- Provides verification evidence for verification-before-completion skill

## Installation

Install directly from the Claude Code plugin marketplace:

```bash
claude-code plugins install withzombies-hyper/hyperpowers
```

That's it! The plugin will be automatically loaded in your next Claude Code session.

## Usage

### Getting Started

The `using-hyper` skill automatically loads at the start of each conversation and establishes core workflows. It ensures you:

1. Check for relevant skills before starting any task
2. Follow mandatory workflows (brainstorming before coding, TDD, verification)
3. Use TodoWrite for tracking checklist items
4. Announce which skills you're using

### Example Workflow

```
User: I need to add user authentication to my app

Claude: I'm using the brainstorming skill to refine your authentication requirements.

[Socratic questioning to understand requirements]

Claude: Now I'm using the writing-plans skill to create a detailed implementation plan.

[Creates detailed plan with specific tasks in bd]

Claude: I'm using the executing-plans skill to implement the tasks.

[Works through ready tasks continuously, using bd ready to find next task]

Claude: I'm using the test-runner agent to verify all tests pass.

[Agent runs tests, reports: "✓ 47 tests passed, 0 failed"]

Claude: I'm using the review-implementation skill to verify everything works.

[Reviews implementation against requirements]

Claude: I'm using the finishing-a-development-branch skill to wrap up.

[Creates PR, cleans up]
```

## Philosophy

Hyperpowers embodies several core principles:

- **Incremental progress over big bangs** - Small changes that compile and pass tests
- **Learning from existing code** - Study patterns before implementing
- **Explicit workflows over implicit assumptions** - Make the process visible
- **Verification before completion** - Evidence over assertions
- **Test-driven when possible** - Red, green, refactor

## Contributing

Contributions are welcome! This plugin is inspired by [obra/superpowers](https://github.com/obra/superpowers).

### Adding New Skills

1. Create a new directory in `skills/`
2. Add a `skill.md` file with the workflow
3. Follow the TDD approach in `writing-skills` skill
4. Test with subagents before deployment

## License

MIT

## Author

Ryan Stortz (ryan@withzombies.com)

## Acknowledgments

Inspired by [obra/superpowers](https://github.com/obra/superpowers) - a strong foundation for structured development workflows