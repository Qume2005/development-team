# Patch: Add IMMEDIATE ACTION ON LOAD section to sp-architect/SKILL.md

## Context
The sp-architect skill was missing an immediate-action-on-load section that instructs the agent to invoke superpowers skills (brainstorming, writing-plans) right away upon being dispatched, rather than deferring until they are needed.

## Key Decisions
- Inserted the new section after "Check Availability" and before "Enhanced Workflows" so availability is confirmed first, then skills are loaded proactively.
- Kept all existing content intact below the new section.

## Output
File modified: `skills/sp-architect/SKILL.md`

Added section `## ⚡ IMMEDIATE ACTION ON LOAD` with three steps:
1. Invoke `superpowers:brainstorming` — for exploring architectural approaches, trade-offs, and module decomposition.
2. Invoke `superpowers:writing-plans` — for structuring the architecture document with proper sections and decisions.
3. Proceed with the brainstorming process, then use writing-plans to produce the final architecture document.

## Constraints & Open Questions
- None. The change is additive; no existing behavior was removed or altered.

## References
- `/Users/liqianmo/.claude/skills/development-team/skills/sp-architect/SKILL.md`
