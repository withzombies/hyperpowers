# Hyper Plugin Recommendations

This document outlines recommended improvements and missing workflows for the hyper plugin.

**Last Updated:** 2024-10-27

---

## Executive Summary

The hyper plugin provides excellent coverage for **greenfield feature development** but lacks critical workflows for **bug fixing, debugging, refactoring, and production incidents**.

**Current State:**
- ✅ Complete workflow: idea → design → implementation → PR
- ✅ Strong quality culture (TDD, verification, SRE review)
- ✅ Clean bd integration (single source of truth)
- ❌ Zero bug/debugging coverage
- ❌ Zero refactoring workflows
- ❌ Zero incident response

**Priority:** Add debugging and bug-fixing skills immediately. Most software work is maintenance, not greenfield development.

---

## Tier 1: Critical (Implement Immediately)

### 1. debugging-systematically

**Why:** No systematic approach to finding root causes.

**Skill should cover:**
- Reproducing the issue reliably
- Isolating the problem (binary search through code)
- Root cause analysis techniques
- When to add logging vs. debugging
- Documentation of findings

**Example workflow:**
1. Reproduce bug consistently
2. Add minimal reproduction test case
3. Binary search to isolate component
4. Identify root cause with evidence
5. Document findings before fixing

### 2. fixing-bugs

**Why:** No workflow for bug fixes with regression tests.

**Skill should cover:**
- Creating bd issue for bug
- Writing regression test (RED phase)
- Implementing fix (GREEN phase)
- Verifying fix doesn't break other things
- Updating bd status and closing issue

**Example workflow:**
1. Create bd bug issue with reproduction steps
2. Write failing test demonstrating bug
3. Implement minimal fix
4. Run full test suite (not just new test)
5. Commit with reference to bd issue
6. Close bd issue

### 3. responding-to-code-review

**Why:** We have code-reviewer agent for GIVING reviews but no skill for RECEIVING them.

**Skill should cover:**
- Systematic review of all feedback
- Categorizing comments (must-fix, should-fix, discussion)
- Making requested changes
- Responding to questions/disagreements
- Re-requesting review
- Updating bd tasks based on feedback

**Example workflow:**
1. Read all review comments
2. Create checklist from feedback
3. Address each comment systematically
4. Reply to comments as changes are made
5. Re-request review when complete
6. Update bd task if scope changed

### 4. refactoring-safely

**Why:** No guidance for refactoring without breaking things.

**Skill should cover:**
- When to refactor vs. rewrite
- Test-preserving transformations
- Breaking large refactorings into safe steps
- Running tests between each step
- Creating bd tasks for refactoring work
- Refactoring anti-patterns (changing behavior, breaking tests)

**Example workflow:**
1. Ensure tests pass before starting
2. Make one small refactoring change
3. Run tests - must stay green
4. Commit
5. Repeat until refactoring complete

---

## Tier 2: High Priority (Implement Soon)

### 5. handling-incidents

**Why:** Production emergencies need different workflow than feature development.

**Skill should cover:**
- Immediate mitigation (stop the bleeding)
- Creating hotfix branch
- Minimal fix approach
- Testing under time pressure
- Rollback procedures
- Post-incident bd issue creation
- Post-mortem analysis

**Phases:**
1. **Mitigate:** Stop the problem immediately
2. **Fix:** Minimal change to restore service
3. **Deploy:** Hotfix deployment process
4. **Follow-up:** Create bd issues for proper fix
5. **Post-mortem:** Learn and improve

### 6. resolving-merge-conflicts

**Why:** Conflicts are common, need systematic resolution.

**Skill should cover:**
- Understanding conflict origins
- Choosing resolution strategy (ours, theirs, manual)
- Resolving conflicts safely
- Testing after resolution
- When to ask for help
- Preventing future conflicts

**Anti-patterns:**
- Blindly accepting one side
- Not testing after resolution
- Not understanding what changed

### 7. managing-bd-tasks

**Why:** Need guidance for advanced bd operations beyond basic create/close.

**Skill should cover:**
- Splitting tasks mid-flight when too large
- Merging duplicate tasks
- Changing dependencies after work starts
- Archiving completed epics
- Querying bd for metrics
- Managing cross-epic dependencies

**Commands:**
```bash
# Split task
bd create "Subtask 1" --type task
bd dep add bd-new bd-original --type parent-child

# Merge tasks
# (workflow for consolidating duplicates)

# Archive epic
bd status bd-1 --status archived
```

### 8. writing-documentation

**Why:** No documentation standards or workflow.

**Skill should cover:**
- When to document (API, architecture, setup)
- README structure
- API documentation standards
- Architecture Decision Records (ADRs)
- Code comments vs. documentation
- Documentation as bd task

**Templates:**
- README template
- ADR template
- API documentation template

### 9. investigating-performance

**Why:** Performance issues need systematic investigation.

**Skill should cover:**
- Establishing baseline performance
- Profiling techniques
- Identifying bottlenecks
- Benchmark creation
- Measuring improvements
- Performance regression testing

**Example workflow:**
1. Create performance test (baseline)
2. Profile to find hotspots
3. Optimize one hotspot
4. Measure improvement
5. Repeat

---

## Tier 3: Medium Priority (Nice to Have)

### 10. security-review

**Why:** Security should be part of design/review process.

**Skill should cover:**
- Common vulnerabilities (OWASP Top 10)
- Input validation
- Authentication/authorization
- Secrets management
- Dependency vulnerabilities
- Security in bd success criteria

### 11. setting-up-quality-gates

**Why:** Pre-commit hooks and CI mentioned but not explained.

**Skill should cover:**
- Pre-commit hook installation
- Hook configuration
- Debugging hook failures
- Adding custom hooks
- CI/CD integration
- When gates fail during development

### 12. analyzing-test-coverage

**Why:** No guidance on measuring or improving coverage.

**Skill should cover:**
- Running coverage tools
- Understanding coverage reports
- Coverage targets/thresholds
- Adding missing coverage
- Coverage trends over time
- Coverage in bd success criteria

### 13. updating-dependencies

**Why:** Dependency updates are risky without process.

**Skill should cover:**
- Checking for updates
- Reading changelogs
- Testing with updated deps
- Handling breaking changes
- Security updates (high priority)
- Dependency conflict resolution

---

## Tier 4: Future Enhancements

### 14. team-handoff

**Why:** Collaboration requires handoff workflows.

**Skill should cover:**
- Handing work to another developer
- Picking up incomplete work
- Understanding bd task history
- Communication protocols
- Knowledge transfer

### 15. pair-programming

**Why:** Real-time collaboration needs different workflow.

**Skill should cover:**
- Driver/navigator roles
- Switching roles
- Collaborative decision making
- Using Claude in pair programming
- Screen sharing workflows

### 16. conducting-retrospectives

**Why:** Learning from completed work improves process.

**Skill should cover:**
- Reviewing completed epics
- What went well/poorly
- Updating process based on learnings
- Capturing lessons learned
- bd retrospective queries

### 17. extracting-patterns

**Why:** Recognizing patterns improves architecture.

**Skill should cover:**
- Recognizing repeated code
- Extracting to reusable components
- Documenting architectural decisions
- Building pattern library
- When to extract vs. leave duplicated

### 18. bd-template-system

**Why:** Successful task structures should be reusable.

**Templates needed:**
- API endpoint implementation
- Database schema change
- Bug fix
- Refactoring task
- Documentation update
- Performance optimization

**Implementation:**
```bash
# Future bd feature?
bd create --template bug-fix "Fix login issue"
```

---

## Skill Quality Improvements

### Language-Specific Examples

**Current:** Some skills have Rust/Swift/TypeScript examples, others don't.

**Recommendation:** Standardize on showing examples in:
- Rust (for systems programming)
- Swift (for iOS/macOS)
- TypeScript (for web/Node.js)

**Skills needing updates:**
- test-driven-development (currently TypeScript-only)
- verification-before-completion (currently generic)

### Redundancy Reduction

**Completed:**
- ✅ Created `skills/common-patterns/bd-commands.md`
- ✅ Created `skills/common-patterns/common-anti-patterns.md`
- ✅ Created `skills/common-patterns/common-rationalizations.md`
- ✅ Updated skills to reference common patterns

**Benefits:**
- Single source of truth for bd commands
- Easier to update anti-patterns
- Consistent rationalizations across skills

### Infrastructure & Customization Skills

**Completed:**
- ✅ Created **building-hooks** skill with progressive disclosure
  - Main skill: 397 lines
  - Resources: hook-examples.md, hook-patterns.md, testing-hooks.md
  - Covers all hook lifecycle events, progressive enhancement, security
- ✅ Created **skills-auto-activation** skill with progressive disclosure
  - Main skill: 484 lines
  - Resources: hook-implementation.md, skill-rules-examples.md, troubleshooting.md
  - Covers the known problem of skills not activating reliably
  - Documents official solutions and custom hook-based workarounds

**Benefits:**
- Addresses common pain point: skills not activating automatically
- Provides reusable patterns for custom workflow automation
- Follows Anthropic's <500 line recommendation with progressive disclosure

### Missing Cross-References

Some skills should reference each other more explicitly:

- **executing-plans** → reference **test-driven-development**
- **writing-plans** → reference **test-driven-development**
- **review-implementation** → reference **verification-before-completion**

---

## bd Integration Enhancements

### Missing Operations

Current bd coverage is basic. Need skills for:

1. **Task relationships beyond blocking:**
   - Related tasks (not blocking but connected)
   - Duplicate detection
   - Task grouping

2. **Metrics and reporting:**
   - Velocity calculation
   - Burndown charts
   - Cycle time analysis
   - Bottleneck identification

3. **Bulk operations:**
   - Updating multiple tasks
   - Batch status changes
   - Epic cloning

4. **Search and filtering:**
   - Complex queries
   - Custom views
   - Saved filters

### bd Best Practices

Need documentation for:
- Task naming conventions
- Priority assignment guidelines
- When to create epic vs. feature vs. task
- Granularity guidelines (4-8 hour tasks)
- Success criteria templates

---

## Agent Enhancements

### Missing Agents

Consider adding:

1. **performance-profiler** - Automated profiling and bottleneck identification
2. **security-scanner** - Automated security vulnerability scanning
3. **test-generator** - Generate test cases from code
4. **dependency-auditor** - Check for outdated/vulnerable dependencies

### Agent Improvements

**codebase-investigator:**
- Add caching for repeated searches
- Improve multi-file relationship tracking

**code-reviewer:**
- Add automated metrics (complexity, coverage)
- Compare against project style guides

**internet-researcher:**
- Add version compatibility checking
- Track API deprecations

---

## Command Improvements

Current commands are thin wrappers to skills. Consider adding:

### Workflow Commands

```bash
# Quick start commands
/start-feature "Feature name"  # Runs brainstorming → sre-task-refinement
/fix-bug "Bug description"     # Runs debugging → fixing-bugs
/hotfix "Critical issue"       # Runs handling-incidents

# Status commands
/bd-status                     # Show current bd state
/my-tasks                      # Show my in-progress tasks
/next-task                     # Show next ready task
```

---

## Testing Recommendations

### Skill Testing

Current: No automated testing of skills

**Recommendation:** Add skill validation:
```bash
# Validate skill frontmatter
validate-skills.sh

# Check for broken references
check-skill-links.sh

# Ensure common patterns are used
check-redundancy.sh
```

### Integration Testing

Test complete workflows end-to-end:
1. Create test project
2. Run brainstorming → executing-plans → finishing
3. Verify bd issues created/closed correctly
4. Verify PR created with bd references

---

## Documentation Improvements

### Missing Documentation

1. **Plugin architecture** - How skills/agents/commands interact
2. **Skill authoring guide** - Beyond writing-skills, actual examples
3. **Troubleshooting guide** - Common issues and solutions
4. **FAQ** - Frequently asked questions

### Documentation Structure

Recommended structure:
```
docs/
  architecture.md      # How hyper works
  getting-started.md   # Quick start guide
  workflows/
    feature-dev.md     # Complete feature workflow
    bug-fixing.md      # Bug fix workflow
    refactoring.md     # Refactoring workflow
  reference/
    skills.md          # Skill reference
    agents.md          # Agent reference
    bd-commands.md     # bd command reference
  troubleshooting.md   # Common issues
  faq.md              # FAQ
```

---

## Prioritized Implementation Plan

### Week 1 (Critical)

1. ✅ Fix hooks/session-start.sh path bug
2. ✅ Create common-patterns files
3. ✅ Update skills to reference common patterns
4. Create **debugging-systematically** skill
5. Create **fixing-bugs** skill

### Week 2 (High Value)

6. Create **responding-to-code-review** skill
7. Create **refactoring-safely** skill
8. Create **managing-bd-tasks** skill

### Week 3 (Production Ready)

9. Create **handling-incidents** skill
10. Create **resolving-merge-conflicts** skill
11. Create **writing-documentation** skill

### Month 2+ (Quality & Collaboration)

12. Tier 3 skills (security, coverage, dependencies)
13. Tier 4 skills (team collaboration, retrospectives)
14. Agent enhancements
15. Template system
16. Documentation improvements

---

## Success Metrics

Track adoption and effectiveness:

**Usage metrics:**
- Skills invoked per week
- Most-used skills
- Least-used skills (candidates for improvement/removal)

**Quality metrics:**
- PRs created via hyper workflow
- Bug fix cycle time
- Refactoring safety (broken tests after refactor)
- Code review iteration count

**Developer experience:**
- Time from idea to PR
- Developer satisfaction surveys
- Skill clarity feedback

---

## Contributing

To propose new skills or improvements:

1. Check if skill fits tier system
2. Write skill proposal following writing-skills
3. Test with subagents (TDD for documentation)
4. Submit for review
5. Iterate based on feedback

**Skill proposal template:**
```markdown
## Skill: [name]

**Tier:** [1-4]

**Problem:** [What gap does this fill?]

**Workflow:** [High-level steps]

**Success criteria:** [How do we know it works?]

**Dependencies:** [What skills/agents needed?]
```

---

## Conclusion

The hyper plugin has **excellent foundations for greenfield development** but needs **critical maintenance workflows** to be production-complete.

**Immediate priorities:**
1. Debugging/bug-fixing (developers spend 50%+ time here)
2. Code review response (required for team collaboration)
3. Refactoring (essential for codebase health)

**With these additions, hyper becomes a complete development workflow system.**

---

**Questions or feedback?** Open an issue or update this document.
