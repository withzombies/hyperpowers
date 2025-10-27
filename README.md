# Hyperpowers

Strong guidance for Claude Code as a software development assistant.

Hyperpowers is a Claude Code plugin that provides structured workflows, best practices, and specialized agents to help you build software more effectively. Think of it as a pair programming partner that ensures you follow proven development patterns.

## Features

### Skills

Reusable workflows for common development tasks:

- **brainstorming** - Interactive design refinement using Socratic method
- **test-driven-development** - Write tests first, ensure they fail, then implement
- **writing-plans** - Create detailed implementation plans with bite-sized tasks
- **executing-plans** - Execute plans in batches with review checkpoints
- **review-implementation** - Verify implementation matches requirements
- **verification-before-completion** - Always verify before claiming success
- **finishing-a-development-branch** - Complete workflow for PR creation and cleanup
- **sre-task-refinement** - Ensure all corner cases and requirements are understood
- **testing-anti-patterns** - Prevent common testing mistakes
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

### Hooks

Automatic behaviors that enhance your workflow:

- Session start hooks to establish context
- Integration with development workflows

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

[Creates detailed plan with specific tasks]

Claude: I'm using the executing-plans skill to implement in batches.

[Implements with review checkpoints between batches]

Claude: I'm using the verification-before-completion skill to verify everything works.

[Runs tests, confirms all passing]

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