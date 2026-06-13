---
name: sp-pm
description: Superpowers bridge for Project Manager — uses subagent-driven-development for structured parallel dispatch
---

# PM Superpowers Bridge

This skill is the ONLY superpowers bridge the PM loads. **Requires superpowers plugin.** If superpowers is NOT available, stop here and work normally.

## Check Availability

Look at the available skills list. If you see `superpowers:subagent-driven-development`, superpowers is installed. If not, skip this skill entirely.

## Enhanced Workflows

### When Executing an Implementation Plan with Independent Tasks
**You MUST invoke `superpowers:subagent-driven-development` via the Skill tool before dispatching any parallel group.** This is not optional — it structures parallel subagent dispatch to ensure proper isolation, progress tracking, and error handling.

Failure to invoke this skill when dispatching parallel work is a protocol violation equivalent to skipping Scope Validation.

This is the ONLY superpowers skill the PM uses. All other superpowers skills (brainstorming, TDD, debugging, etc.) are for subagents via their own sp-* bridge skills.

## Dispatching Subagents with Superpowers

**MANDATORY:** When dispatching subagents and superpowers is available, you MUST include this in EVERY dispatch prompt (no exceptions):

```
Load your role skill (development-team:<role>) for role instructions.
Load development-team for shared rules.
If superpowers skills are available, load development-team:sp-<role> for enhanced workflows.
```

If you dispatch a subagent without including the sp-<role> instruction when superpowers is available, you are violating PM protocol.

## Fallback

If superpowers is NOT available, dispatch subagents normally without the sp-* bridge instruction. No impact on system functionality.
