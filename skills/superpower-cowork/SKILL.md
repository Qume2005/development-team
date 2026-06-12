---
name: superpower-cowork
description: Bridge skill for development-team subagents to leverage superpowers skills when available. Only for subagents, never for PM.
---

# Superpower Cowork

Bridge skill for development-team subagents. If superpowers is installed in your environment, this skill tells you which superpowers skills to use and when.

**The PM NEVER loads this skill. Only subagents do.**

## Detection

Check the available skills list for any skill prefixed with `superpowers:`. If found, superpowers is installed and you can use this guide.

## Skill Map

| Your Task Scenario | Superpowers Skill | When to Invoke |
|---|---|---|
| Creative work — designing features, new components, modifying behavior | `superpowers:brainstorming` | Before creating anything new |
| Multi-step task, have specs/requirements | `superpowers:writing-plans` | Before touching code |
| Creating or editing skills | `superpowers:writing-skills` | When working on skill files |
| Have a written plan to execute | `superpowers:executing-plans` | When implementing from an approved plan |
| Feature work needing isolation from workspace | `superpowers:using-git-worktrees` | Before starting isolated work |
| About to claim work is complete | `superpowers:verification-before-completion` | Before marking done, committing, or creating PRs |
| Encountered a bug or test failure | `superpowers:systematic-debugging` | Before proposing fixes |
| Implementing a feature or bugfix | `superpowers:test-driven-development` | Before writing implementation code |
| Code review feedback received | `superpowers:receiving-code-review` | Before implementing review suggestions |
| Need to dispatch 2+ independent tasks | `superpowers:dispatching-parallel-agents` | When facing parallelizable work |
| Before merging, verify work meets requirements | `superpowers:requesting-code-review` | Before requesting review of completed work |
| Implementation complete, tests pass, need to integrate | `superpowers:finishing-a-development-branch` | When deciding how to merge, PR, or cleanup |
| Executing a plan with independent tasks | `superpowers:subagent-driven-development` | When structuring parallel subagent dispatch (also available for PM) |

## Rules

1. **You are a subagent**, not the PM. You CAN and SHOULD use superpowers skills within your task scope.
2. **Invoke via Skill tool.** Call `Skill("superpowers:brainstorming")` etc. when the scenario matches.
3. **Stay in your role.** Superpowers skills enhance your workflow — they don't change your role (coder stays coder, architect stays architect).
4. **Don't touch the PM.** The PM never uses superpowers skills directly.
5. **Fallback gracefully.** If superpowers is NOT available, work normally. No error, no complaint.

## PM Dispatch Integration

The PM detects superpowers availability and adjusts dispatch prompts:

When superpowers IS available:
1. PM loads `development-team:sp-pm` for its own enhanced workflow.
2. PM tells each subagent: "Load development-team:sp-<role> for enhanced workflows."

When superpowers is NOT available:
1. PM dispatches normally. No sp-* bridges are loaded.
2. System works identically, just without superpowers enhancements.
