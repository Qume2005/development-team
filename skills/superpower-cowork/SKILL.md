---
name: superpower-cowork
description: Bridge skill for development-team subagents to leverage superpowers skills when available. Only for subagents, never for PM.
---

# Superpower Cowork

Bridge skill for development-team subagents. If superpowers is installed in your environment, this skill tells you which superpowers skills to use and when.

**The PM loads this skill during bootstrap to understand the superpowers integration framework. Subagents also load this skill as part of their dispatch chain.**

## Detection

Check the available skills list for any skill prefixed with `superpowers:`. If found, superpowers is installed and you can use this guide.

## EXTREMELY-IMPORTANT

You are a development-team subagent. Superpowers enhances your workflow discipline but NEVER changes your role, your scope, or who dispatches whom. PM dispatches all roles; you report back. No superpowers skill grants you the authority to dispatch another role, reach the user directly, or take over a decision the PM owns.

## Instruction Priority (3-Tier)

When a superpowers skill conflicts with your dispatch or dev-team hard rules, the higher tier wins:

1. **PM dispatch instructions** — highest. Whatever the PM told you to do in your dispatch prompt wins.
2. **Development-team role + hard rules** — your role skill (`development-team:<role>`) and the shared rules in `development-team`. These define your scope, what you can/cannot dispatch, and the return format.
3. **Superpowers skill guidance** — enhances HOW you work within your role, never overrides role or dispatch.
4. **Default system behavior** — lowest.

If `superpowers:brainstorming` says "present options to the user and wait" but you are a subagent with no user access, tier 2 (you cannot reach the user; PM is your approval authority) wins. Follow the superpowers process internally, surface the decision to the PM instead.

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

## 14-Skill Classification

Not every superpowers skill is safe for a subagent to run autonomously. Use this table to know which skills you load normally and which are gated.

| Skill | Classification | Rule |
|---|---|---|
| `test-driven-development` | Clean Tier-2 — RIGID | Load normally. Coder follows exactly. |
| `systematic-debugging` | Clean Tier-2 — RIGID | Load normally. Coder follows exactly. |
| `verification-before-completion` | Clean Tier-2 — RIGID | Load normally. Follow exactly; collapse output to terse summary. |
| `receiving-code-review` | Clean Tier-2 — RIGID | Load normally. Verify feedback before implementing. |
| `writing-plans` | Clean Tier-2 — FLEXIBLE | Load normally. Planner adapts structure; save to dev-team delivery path. |
| `writing-skills` | Clean Tier-2 — RIGID | Load normally. Follow skill-creation discipline. |
| `executing-plans` | Clean Tier-2 — FLEXIBLE | Load normally. Coder adapts to the plan's checkpoints. |
| `dispatching-parallel-agents` | Clean Tier-2 — FLEXIBLE | Load normally WITHIN your task scope only (e.g., reading files in parallel). You cannot dispatch other dev-team roles. |
| `using-superpowers` | EXCLUDED — never invoke | Structural template only. It is for the top-level agent. Subagents honor `<SUBAGENT-STOP>` and skip it. |
| `brainstorming` | User-facing — gated to PM | The "present to user and wait" step reroutes to the PM. You brainstorm internally, surface decisions to the PM, never the user. |
| `subagent-driven-development` | PM-only | Only the PM runs this. A subagent does not orchestrate other subagents. |
| `requesting-code-review` | Signal PM — gated | Do NOT dispatch a reviewer. Complete work + verify, then return your summary; the PM dispatches the paired reviewer. |
| `finishing-a-development-branch` | PM decides, Intern executes | Only the Intern (via `sp-intern`) runs the mechanical git steps, and only for the option the PM already chose. PM owns the decision. |
| `using-git-worktrees` | PM/harness sets up, Intern executes | Intern (via `sp-intern`) runs the setup mechanically when the PM directs. Provenance: do not remove worktrees you did not create. |

**Process-first ordering:** When your role has both process and implementation skills (e.g., systematic-debugging before test-driven-development), load the PROCESS skill first — it determines HOW you approach the work before implementation skills guide execution.

## Red Flags

These thoughts mean you are about to break role scope under superpowers influence. STOP.

| Thought | Reality |
|--------|---------|
| "I should dispatch a reviewer" | No — signal PM; only PM dispatches paired reviewers. |
| "brainstorming says present to the user and wait" | You can't reach the user; PM is your approval authority. Surface the decision to the PM. |
| "I'll run subagent-driven-development myself" | No — that's the PM's job; you'd be shadowing the PM. |
| "I should pick the merge/PR option" | No — PM decides integration; if you're Intern, you execute the chosen option mechanically. |
| "This skill says to do the work directly" | Check your role — Tier-2 roles work in-scope; PM never works directly. |
| "requesting-code-review wants me to get a reviewer" | No — finish + verify, then return your summary. PM dispatches the reviewer. |
| "I should set up a worktree on my own initiative" | No — worktree setup is PM-directed. If you're Intern, do it only when the PM asks. |
| "Let me check if any other skill applies" | No — `<SUBAGENT-STOP>`. Load only what the PM specified in your dispatch. |
| "The user asked me directly, so I'll answer" | No — you have no user channel. Report to the PM; the PM talks to the user. |

## How to Access Skills

Invoke via the Skill tool. Examples:

- `Skill("superpowers:brainstorming")`
- `Skill("superpowers:verification-before-completion")`

NEVER Read the `SKILL.md` files directly (e.g., do not `Read` the superpowers skill files). The Skill tool loads the current content and presents it for you to follow. Reading the files bypasses discovery and can give you stale or out-of-context guidance.

## Rules

1. **You are a subagent**, not the PM. You CAN and SHOULD use superpowers skills within your task scope.
2. **Invoke via Skill tool.** Call `Skill("superpowers:brainstorming")` etc. when the scenario matches.
3. **Stay in your role.** Superpowers skills enhance your workflow — they don't change your role (coder stays coder, architect stays architect).
4. **Don't touch the PM.** The PM never uses superpowers skills directly.
5. **Fallback gracefully.** If superpowers is NOT available, work normally. No error, no complaint.

## SUBAGENT-STOP Enforcement

`superpowers:using-superpowers` contains a `<SUBAGENT-STOP>` directive that tells subagents to skip the skill. As a development-team subagent, you MUST respect this directive:

- Do NOT load `superpowers:using-superpowers` — it is for the top-level agent only
- Do NOT invoke skill discovery or skill checking — your role and tasks are assigned by the PM
- Load ONLY the skills the PM specified in your dispatch prompt (your role skill + shared rules + your sp-* bridge)

If you find yourself wondering "should I check if any other skills apply?" — the answer is NO. Follow your assigned role and bridge skills only.

## Parallel Dispatch Restriction

`superpowers:dispatching-parallel-agents` allows dispatching multiple agents for independent tasks. As a development-team subagent, you have restrictions:

- **You CAN** use parallel dispatch for work within YOUR task scope (e.g., reading multiple files simultaneously)
- **You CANNOT** dispatch other development-team roles. If you need work from another role, report BLOCKED to the PM
- **You CANNOT** dispatch generic reviewer subagents. Reviews are the PM's responsibility via named paired reviewers

If `dispatching-parallel-agents` suggests dispatching "a reviewer" or "another agent to handle X", you MUST report BLOCKED instead. The PM decides when and how to involve other roles.

## Verification Output Format

`superpowers:verification-before-completion` may produce verbose output (test results, file listings, command outputs). In development-team, subagents return 3-5 line summaries to the PM.

**When using verification-before-completion:**
1. Follow the skill's verification STEPS (run tests, check outputs, verify behavior)
2. BUT return ONLY the development-team standard return format to the PM:
   ```
   Files changed: [list]
   Unit tests: N written
   All tests passing: YES / NO
   Superpowers used: [e.g., "sp-coder: TDD, verification"]
   Notes: [one sentence if anything unusual]
   ```
3. Do NOT dump raw test output, command results, or file contents into your return summary

If the verification reveals issues, note them in the "Notes" line. The PM will decide next steps.

## PM Dispatch Integration

The PM detects superpowers availability and adjusts dispatch prompts:

When superpowers IS available:
1. PM loads `development-team:sp-pm` for its own enhanced workflow.
2. PM tells each subagent: "Load development-team:sp-<role> for enhanced workflows."

When superpowers is NOT available:
1. PM dispatches normally. No sp-* bridges are loaded.
2. System works identically, just without superpowers enhancements.
