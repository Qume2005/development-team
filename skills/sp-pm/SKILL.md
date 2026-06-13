---
name: sp-pm
description: Superpowers bridge for Project Manager — uses subagent-driven-development for structured parallel dispatch
---

# PM Superpowers Bridge

This skill is the ONLY superpowers bridge the PM loads. **Requires superpowers plugin.** If superpowers is NOT available, stop here and work normally.

## ⚡ IMMEDIATE ACTION ON LOAD

If you just loaded this skill as part of the development-team bootstrap, you MUST do these things RIGHT NOW — not later, not "when needed," but NOW:

**Step 1: Announce activation**
Output this exact announcement to the user:
> "⚡ Superpowers bridge active. Subagent-driven-development will be used for parallel dispatch. All production subagents will load their sp-* bridges."

**Step 2: Prepare for parallel dispatch**
Remember these rules for the rest of this session:
- When dispatching ANY parallel group → Invoke `superpowers:subagent-driven-development` via Skill tool FIRST, then dispatch
- When dispatching ANY production subagent → Include "Load development-team:sp-<role> for enhanced workflows" in the dispatch prompt
- When receiving ANY subagent return → Check for "Superpowers used" field

**Step 3: You are now prepared.** Continue with normal PM workflow (scope, propose, dispatch). The superpowers integration will activate automatically when you dispatch your first parallel group or production subagent.

## What Changed vs. Without Superpowers

| Scenario | Without Bridge | With Bridge |
|----------|---------------|-------------|
| Parallel dispatch | Dispatch agents directly | Invoke `subagent-driven-development` first, then dispatch |
| Subagent dispatch | "Load development-team:<role>" | Add "Load development-team:sp-<role> for enhanced workflows" |
| Return summary check | Files changed + tests passing | Also check "Superpowers used" field |
| TDD enforcement | Code Reviewer checks | Code Reviewer checks + TDD Gate blocks |

## Fallback

If superpowers is NOT available, dispatch subagents normally without the sp-* bridge instruction. No impact on system functionality.
