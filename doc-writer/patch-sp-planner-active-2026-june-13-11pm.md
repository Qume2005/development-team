# Patch: Add IMMEDIATE ACTION ON LOAD section to sp-planner SKILL.md

## Context
The sp-planner skill was missing an explicit load-time invocation instruction. When dispatched by the PM, the planner subagent had no clear directive to invoke superpowers skills immediately, leading to delayed or skipped superpowers usage. This patch adds a prominent section that triggers superpowers skill invocation right at load time.

## Key Decisions
- Placed the new section after "Check Availability" and before "Enhanced Workflows" so it activates only after superpowers availability is confirmed.
- Used a three-step structure: brainstorming first, then writing-plans, then proceed with work.
- Preserved all existing content (Enhanced Workflows, Delivery Path Override, Fallback) unchanged below the new section.

## Output
Added section `## IMMEDIATE ACTION ON LOAD` to `/Users/liqianmo/.claude/skills/development-team/skills/sp-planner/SKILL.md` (lines 14-22 in the updated file).

The section instructs the loaded skill to immediately invoke:
1. `superpowers:brainstorming` -- explore task requirements and design approaches before planning
2. `superpowers:writing-plans` -- structure plan output with proper decomposition
3. Then proceed: follow brainstorming process first, then writing-plans to produce the final document

No existing content was removed or modified. The "Enhanced Workflows", "Delivery Path Override", and "Fallback" sections remain intact as supplementary guidance.

## Constraints & Open Questions
- None. The change is additive only.
- The existing "Enhanced Workflows" section now serves as supplementary reference material, while the new "IMMEDIATE ACTION ON LOAD" section provides the active invocation path.

## References
- Modified file: `/Users/liqianmo/.claude/skills/development-team/skills/sp-planner/SKILL.md`
