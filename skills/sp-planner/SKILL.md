---
name: sp-planner
description: Superpowers bridge for Task Planner — uses brainstorming and writing-plans for better task decomposition
---

# Planner Superpowers Bridge

This skill enhances the Task Planner with superpowers. **Requires superpowers plugin.** If superpowers is NOT available, stop here and work normally.

## Check Availability

Look at the available skills list. If you see skills like `superpowers:brainstorming` or `superpowers:writing-plans`, superpowers is installed. If not, skip this skill entirely.

## ⚡ IMMEDIATE ACTION ON LOAD

If you just loaded this skill as part of your dispatch prompt, invoke these superpowers skills RIGHT NOW via the Skill tool — do not wait until you need them:

**Step 1:** Invoke `superpowers:brainstorming` via Skill tool. You will use brainstorming to explore task requirements and design approaches before writing any plan.

**Step 2:** Invoke `superpowers:writing-plans` via Skill tool. You will use this to structure your plan output with proper decomposition.

**Step 3:** You are now prepared. Follow the brainstorming skill's process first, then use writing-plans to produce the final plan document.

## Enhanced Workflows

### Before Decomposing a Complex Task
Invoke `superpowers:brainstorming` to explore:
- What the user actually wants vs what they said
- Edge cases and hidden requirements  
- Dependencies and risks
- Alternative decomposition strategies

### Before Writing a Plan
Invoke `superpowers:writing-plans` for structured plan creation:
- Clear subtask boundaries
- Explicit dependencies
- Effort and risk estimates
- Verification criteria

### When Creating or Editing Skill Files or Plan-Like Documents
Invoke `superpowers:writing-skills` — follow structured skill creation/editing patterns for plan documents that serve as reusable templates.

## Delivery Path Override

When using `superpowers:writing-plans` for plan creation, you MUST override the default save path:

**Superpowers default path:** `docs/superpowers/plans/YYYY-MM-DD-<name>.md`
**Development-team required path:** `.claude/development-team/planner/<summary>-<year>-<month-name>-<day><time>.md`

Follow `superpowers:writing-plans` for the PLAN CONTENT (structure, decomposition, etc.) but ALWAYS save to the development-team delivery directory path. The plan must be findable by the PM and downstream subagents.

**Why:** The PM tracks delivery docs by path. If a plan is saved outside `.claude/development-team/`, the PM cannot find it, the handoff chain breaks, and downstream subagents (API Designer, Code Developer) cannot locate their input.

**Example path:** `.claude/development-team/planner/resnet-fashionmnist-experiment-2026-june-13-11pm.md`

### Fallback
If superpowers invocation fails or is unavailable, decompose and plan using your standard role instructions. No errors, no complaints.
