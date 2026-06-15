---
name: brainstorming
description: Collaborative intent, requirements, and design exploration BEFORE planning — for ambiguous or creative tasks. Turns an open-ended request into a short, user-approved design that feeds the PM's workflow proposal and the downstream review-gated dispatch chain.
---

# Brainstorming — Pre-Implementation Design Exploration

> **Invokable as** `development-team:brainstorming` via the Skill tool. Triggered by the PM (before proposing a workflow on ambiguous/creative tasks) or self-invoked by a Design role when a task is genuinely under-specified.

## Why This Exists

Some requests have open design space: "build me a habit tracker", a greenfield feature, a multi-option product decision, anything where the *right shape* of the solution is not yet known. Jumping from such a request straight to a workflow proposal — or worse, straight to code — buries unexamined assumptions that surface late and expensively. This skill forces a short, collaborative design pass *first*, so the workflow the PM proposes is built from an approved design rather than a guess.

The terminal state is **"design approved"** — not another skill invocation, not a plan, not code. The approved design becomes the input the PM uses to propose the workflow, and for serious work the PM may dispatch Product Designer / Architecture Designer on top of it. Brainstorming is the **front door** to dev-team's review-gated execution pipeline, not a standalone loop.

## When to Invoke

**Invoke when ANY of these signals are present:**

- "Build me a thing that does X" / "I want to create Y" — greenfield with open design space
- Multi-option product decision (the user is choosing between approaches)
- The request's *intent* is clear but its *shape* is not (what to build is under-specified)
- A Design role (Architect, Product Designer, API Designer) finds a task genuinely under-specified and cannot proceed without a design decision
- Feature work where success criteria are ambiguous

**Do NOT invoke for:**

- Well-specified bug fixes (route through `development-team:systematic-debugging`)
- Config tweaks, single-endpoint additions, mechanical refactors with a known target
- Tasks where the workflow shape is already obvious from the request

### Anti-Pattern: "This Is Too Simple To Need A Design"

Once brainstorming is triggered, do not rationalize skipping it because the task *seems* simple. **Once the gate is open, run the gate.** Simple-seeming creative tasks are exactly where unexamined assumptions cause the most wasted work — the request looks obvious, an approach gets built, and the user reveals three paragraphs of unstated requirements two days in. If the PM (or Design role) decided the request was ambiguous enough to invoke this skill, the design pass happens.

This is a **conscious scoping choice**: dev-team does not force *every* task through brainstorming — well-specified mechanical work skips it. But the decision to skip is made *before* invocation, at triage time, by the PM. After invocation, the discipline applies in full.

## The HARD GATE

**No implementation, no code, no production subagent dispatch until the design is approved.** This gate is about not jumping to production work. The PM still owns dispatch; this skill produces a design, not a dispatch. The gate lifts the moment the user explicitly approves the design.

## Core Process

Run these steps in order. Each is a discipline, not a suggestion.

### 1. Explore project context

Read recent files, existing patterns, adjacent modules — *within your reading scope* (1 module / 2-3 files). Understand what already exists so the design fits the codebase, not a blank page.

> **PM-tier note:** If the PM is driving this pass, heavy context exploration is delegated to Intern/subagents, not absorbed into the PM's context. The PM gets a distilled summary; the design conversation proceeds on that.

### 2. Scope the design surface

If the request spans multiple independent subsystems, **flag it and help decompose**. Brainstorm the first sub-project only — do not attempt to design an entire platform in one pass. A request like "build me a productivity suite" decomposes into sub-projects; brainstorm "the task manager" first, defer the rest.

### 3. Ask clarifying questions ONE AT A TIME

Sequential, not a wall of questions. Cover purpose, constraints, success criteria. **Prefer multiple choice** over open-ended prompts — multiple choice forces crisp decisions and is faster for the user to answer.

Bad: *"What are your requirements?"*
Good: *"Should this persist data locally, sync to a backend, or both? (A) local-only (B) backend-sync (C) both"*

### 4. Propose 2-3 approaches with trade-offs

Never propose a single approach. Offer 2-3, each with explicit trade-offs (complexity, time, flexibility, risk), and a **clear recommendation**. The recommendation is load-bearing — it's the design's default unless the user overrides it.

### 5. Present the design scaled to complexity

A quick-fix design is a paragraph. A greenfield design is a short structured note (sections, key decisions, what's explicitly out of scope). Match the artifact to the work. **Confirm with the user section by section** for non-trivial designs — do not dump the whole design and ask for blanket approval.

### 6. Self-review the design

Before asking for final approval, scan the design for:
- **Placeholders** — TODOs, hand-waves, "figure out later" items that are actually load-bearing
- **Contradictions** — section A implies X, section B implies not-X
- **Ambiguity** — terms used without definition, scope edges left fuzzy
- **Hidden scope** — features smuggled in as implementation details

Fix what you find. Do not present a design you haven't audited.

### 7. Get explicit user approval

Explicit. Not implied, not "the user didn't object." State the design summary and ask for approval directly. Only explicit approval lifts the HARD GATE.

### 8. Hand off

The approved design becomes the input the PM uses to propose the workflow. For serious work, the PM may dispatch **Product Designer** (to flesh out user stories) and/or **Architecture Designer** (to design system structure) *on top of* the approved design — these then route through their paired reviewers:

```
Approved design (this skill)
   → Product Designer → Product Reviewer       (if user-facing product)
   → Architecture Designer → Architecture Reviewer  (if greenfield/refactor)
   → Task Planner → Task Reviewer
   → API Designer → API Reviewer
   → Test Designer → Test Design Reviewer
   → Code Developer → Code Reviewer
   → System Test → Deliver
```

This is the surpass over a solo ideation loop: the design does not die in a generic plan document. It feeds dev-team's multi-agent dispatch chain with reviewer gates at every stage. Ideation is the front door, not the whole building.

## Conscious Divergences (for maintainers)

This skill is dev-team-native. Two methodology pieces common to standalone ideation skills are deliberately handled differently here:

1. **No visual-design companion artifact.** Some ideation methodologies offer a browser-based mockup/diagram tool during visual questions. dev-team does not include one. The PM-tier context-protection model makes ad-hoc browser tooling a poor fit, and visual design work is better routed to a dedicated Product Designer dispatch (with its own reviewer) than bolted onto an ideation pass. Do not attempt to port such a companion into this skill.

2. **"Too simple to need brainstorming" is a triage decision, not a per-step escape hatch.** See the Anti-Pattern section above: the PM decides *before invocation* whether a task needs this skill. Once invoked, the full process runs — there is no mid-process "this is simple, skip to approval" shortcut.

## Quick Reference

| Step | Action | Output |
|------|--------|--------|
| 1 | Explore context | Understanding of existing patterns |
| 2 | Scope the design surface | Decomposition decision (if needed) |
| 3 | Clarifying questions (one at a time, multiple choice) | Crisp requirements |
| 4 | 2-3 approaches + trade-offs + recommendation | Design options |
| 5 | Present design, confirm section by section | Draft design |
| 6 | Self-review (placeholders, contradictions, ambiguity, hidden scope) | Audited design |
| 7 | Get explicit approval | Approved design |
| 8 | Hand off to PM's workflow proposal (→ Product/Architect/Planner as needed) | Terminal state |

## Common Mistakes

- **Skipping the HARD GATE.** "The user seemed eager, so I started dispatching." No. The gate lifts on explicit approval, full stop.
- **Batching clarifying questions.** Dumping five questions at once overwhelms and produces shallow answers. One at a time, multiple choice.
- **Proposing a single approach.** One option is not a design — it's a fait accompli. Always 2-3 with trade-offs.
- **Presenting without self-review.** The self-review step catches the contradictions and placeholders that turn into rework. Skipping it exports your sloppiness to the user.
- **Treating approval as implicit.** Silence is not approval. Ask directly.
- **Designing the whole platform.** Multi-subsystem requests get decomposed; brainstorm the first sub-project, defer the rest.

## Red Flags — Stop

- Moving to workflow proposal or dispatch before explicit design approval
- Presenting a design you have not self-reviewed
- A "design" that is actually a single approach with no alternatives offered
- Scope quietly expanding during the design pass (new features appearing as "just part of it")
- Clarifying questions that are open-ended when multiple choice would do
- Attempting to produce code, plans, or dispatch during this skill — this produces a *design*, nothing else
