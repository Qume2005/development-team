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
Invoke `superpowers:subagent-driven-development` — helps structure parallel subagent dispatch when executing plans that have independent, non-overlapping tasks.

This is the ONLY superpowers skill the PM uses. All other superpowers skills (brainstorming, TDD, debugging, etc.) are for subagents via their own sp-* bridge skills.

## Dispatching Subagents with Superpowers

When dispatching subagents, if superpowers is available, include this in your dispatch prompt:

```
Load your role skill (development-team:<role>) for role instructions.
Load development-team for shared rules.
If superpowers skills are available, load development-team:sp-<role> for enhanced workflows.
```

## Fallback

If superpowers is NOT available, dispatch subagents normally without the sp-* bridge instruction. No impact on system functionality.
