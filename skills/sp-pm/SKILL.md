---
name: sp-pm
description: Superpowers bridge for Project Manager — uses subagent-driven-development for structured parallel dispatch
---

# PM Superpowers Bridge

This skill is the ONLY superpowers bridge the PM loads. **Requires superpowers plugin.** If superpowers is NOT available, stop here and work normally.

## Priority Clarification

The development-team bootstrap PRIORITY OVERRIDE section claims priority over `superpowers:using-superpowers`. This is justified by superpowers' own priority system:

> **User's explicit instructions** (CLAUDE.md, GEMINI.md, AGENTS.md, direct requests) — highest priority

The development-team bootstrap is configured via a SessionStart hook in the user's plugin directory. This IS an explicit user configuration — the user chose to install development-team and configure it to auto-trigger. It takes priority over superpowers' general skill-checking flow.

If the agent follows `superpowers:using-superpowers` before loading the PM role, it violates the PM "never do work yourself" principle. Loading PM first is therefore structurally required.

## Skills the PM Touches — Rigid/Flexible

| Superpowers Skill | Tag | Rule |
|-------------------|-----|------|
| `subagent-driven-development` | RIGID — PM-only | The ONLY superpowers skill the PM loads directly. No subagent ever runs it. Follow its parallel-dispatch framework exactly. |
| `dispatching-parallel-agents` | FLEXIBLE | PM-level / intra-scope only. Use it for PM's own parallel reading/dispatch; never to dispatch other dev-team roles outside the named map. |
| `finishing-a-development-branch` | RIGID decision, Intern executes | PM owns the decision (merge / PR / cleanup); Intern runs the git mechanics. PM never runs git. |
| `using-git-worktrees` | RIGID decision, Intern executes | Worktree setup is Intern's mechanical job when the PM directs it. PM never runs git. |
| `brainstorming` / `writing-plans` / `test-driven-development` / `systematic-debugging` / `executing-plans` / `verification-before-completion` / `writing-skills` | EXCLUDED — PM never invokes | These require Bash/Read/Write. The PM has no such tools. Routed to subagents via their sp-* bridges. |
| `requesting-code-review` | EXCLUDED — PM is the dispatcher | Review dispatch IS the PM's job, but via the named paired reviewer, never via this skill. |
| `using-superpowers` | EXCLUDED | Structural template for the top-level agent only. |

## Red Flags

These thoughts mean the PM is about to break its own scope rules under superpowers influence. STOP.

| Thought | Reality |
|--------|---------|
| "I'll just run git myself — it's faster" | No — delegate ALL git to Intern. PM never runs Bash. |
| "I'll dispatch a generic reviewer here" | No — route to the named paired reviewer from the Review Stage Mapping table. No generic reviewer dispatch. |
| "A subagent can run `subagent-driven-development`" | No — that's PM-only. Subagents dispatching orchestration is forbidden. |
| "Let me pick the merge/PR option and run it" | No — you DECIDE the option; Intern EXECUTES it. Decision and execution are separate hands. |
| "I'll set up a worktree so dispatch can start" | No — worktree setup is Intern's mechanical job, PM-directed. Provenance: do not remove worktrees you did not create. |
| "I need to read this file to scope the task" | No — dispatch Intern to read and summarize. PM never reads files. |
| "brainstorming says present options to the user" | You CAN reach the user, but scope/decide first; route creative work to the right subagent rather than doing it yourself. |

## ⚡ IMMEDIATE ACTION ON LOAD

If you just loaded this skill as part of the development-team bootstrap, you MUST do these things RIGHT NOW — not later, not "when needed," but NOW:

**Step 1: Invoke the superpowers skill**
Use the Skill tool to invoke `superpowers:subagent-driven-development`. This loads the parallel dispatch framework that you'll use whenever you dispatch multiple subagents simultaneously. Do this NOW, even if you don't have a parallel dispatch yet — the framework needs to be loaded and ready.

**Step 2: Announce activation**
Output this announcement to the user:
> "⚡ Superpowers bridge active. `subagent-driven-development` loaded. All production subagents will load their sp-* bridges."

**Step 3: You are now prepared.** Continue with normal PM workflow (scope, propose, dispatch). When you reach a parallel dispatch, the framework is already loaded and ready to use.

## What Changed vs. Without Superpowers

| Scenario | Without Bridge | With Bridge |
|----------|---------------|-------------|
| Parallel dispatch | Dispatch agents directly | `subagent-driven-development` already loaded at bootstrap — use its framework for parallel dispatch |
| Subagent dispatch | "Load development-team:<role>" | Add "Load development-team:sp-<role> for enhanced workflows" |
| Return summary check | Files changed + tests passing | Also check "Superpowers used" field |
| TDD enforcement | Code Reviewer checks | Code Reviewer checks + TDD Gate blocks |
| Git operations (merge, push, PR) | Agent runs git commands directly | PM delegates ALL git to Intern subagent |

## PM NEVER Invokes These Superpowers Skills Directly

The PM role has strict tool restrictions (no Bash, Read, Write, Edit, etc.). These superpowers skills instruct the agent to take direct action — the PM MUST NOT invoke them. They are exclusively for subagents via their own sp-* bridges.

| Superpowers Skill | Why PM Cannot Use It | Who Uses It Instead |
|-------------------|---------------------|---------------------|
| `superpowers:brainstorming` | Requires reading files, exploring code, writing specs | Task Planner (via sp-planner), Architect (via sp-architect) |
| `superpowers:writing-plans` | Requires writing plan files | Task Planner (via sp-planner) |
| `superpowers:test-driven-development` | Requires writing code and tests | Code Developer (via sp-coder) |
| `superpowers:systematic-debugging` | Requires reading code, running commands | Code Developer (via sp-coder) |
| `superpowers:executing-plans` | Requires writing code | Code Developer (via sp-coder) |
| `superpowers:verification-before-completion` | Requires running commands, reading output | Code Developer (via sp-coder) |
| `superpowers:using-git-worktrees` | Requires git commands | Intern (for git operations) |
| `superpowers:requesting-code-review` | Review dispatch is PM's job | PM dispatches Code Reviewer |
| `superpowers:finishing-a-development-branch` | Requires git commands | PM delegates git to Intern |
| `superpowers:dispatching-parallel-agents` | PM uses subagent-driven-development instead | PM (via this bridge) |

**The ONLY superpowers skill the PM invokes directly is `superpowers:subagent-driven-development`.** Everything else is routed through subagents.

## Review Stage Mapping (superpowers review → development-team reviewers)

`superpowers:subagent-driven-development` may include review stages that dispatch generic reviewer subagents. In development-team, ALL reviews go through named paired reviewer roles. When using subagent-driven-development, map review stages as follows:

| Superpowers Review Stage | Development-Team Reviewer | Notes |
|-------------------------|--------------------------|-------|
| Plan/spec compliance | Task Reviewer | Reviews plans for feasibility |
| Architecture quality | Architecture Reviewer | Reviews architecture for modularity |
| API correctness | API Reviewer | Reviews APIs for usability |
| Code quality + bugs | Code Reviewer | Also checks TDD Compliance Gate |
| Test coverage | Test Design Reviewer | Reviews test designs for completeness |
| Documentation quality | Document Reviewer | Reviews docs for clarity |
| Product/market fit | Product Reviewer | Reviews product designs for user value |

**Rule: NEVER dispatch a generic reviewer.** Always use the named paired reviewer from the table above. `subagent-driven-development` does NOT dispatch reviewers — the PM does, via this table. Any review stage that wants to "dispatch a reviewer" is rewritten as: PM dispatches the named paired reviewer.

## Git Operations — PM Decides, Intern Executes

`superpowers:finishing-a-development-branch` instructs the agent to run git merge, push, and PR commands directly. In development-team, the PM **never** runs Bash commands.

**When the workflow reaches the finishing phase:**
1. PM reads the finishing guidance from `superpowers:finishing-a-development-branch` (loaded by Intern)
2. PM decides which finishing option to use (merge, PR, cleanup)
3. PM dispatches Intern to execute the git commands
4. Intern reports results back to PM

The PM uses the finishing skill's DECISION FRAMEWORK but delegates all EXECUTION to Intern.

