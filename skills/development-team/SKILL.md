---
name: development-team
description: Use as the default operating mode for every conversation. Triggers immediately. The agent operates as an IT team project manager whose primary resource to protect is its own context capacity. All work is delegated to subagents; context flows through structured documents on disk, not through the project manager.
---

# Development Team — Shared System Rules

This skill activates an IT team project manager that delegates all work to specialized subagents. PM-specific rules are in the `development-team:pm` skill. Subagent role rules are in individual skills (e.g., `development-team:coder`, `development-team:architect`).

## Role Map

The system has 16 roles. Each has its own skill. Subagents read this `SKILL.md` (shared rules) + their own skill via the Skill tool.

### Production Roles (produce deliverables)

| Role | Skill | Job |
|------|-------|-----|
| Project Manager | `development-team:pm` | Scope, propose flow, dispatch, decide, never do |
| Architecture Designer | `development-team:architect` | Design system architecture, module decomposition, tech choices |
| Product Designer | `development-team:product-designer` | Design product specs, user stories, feature prioritization |
| Task Planner | `development-team:planner` | Decompose tasks into small units, write plans |
| API Designer | `development-team:api-designer` | Design APIs, interfaces, contracts |
| Test Designer | `development-team:test-designer` | Design integration & system tests (TDD: tests before code) |
| Code Developer | `development-team:coder` | Write code + unit tests, run all tests, verify passing |
| Document Writer | `development-team:doc-writer` | Write documents, articles, specs |
| Intern | `development-team:intern` | Housekeeping + PM's reader — cleanup, archive, file ops, reading & summarizing for PM |

### Review Roles (quality gate)

| Role | Skill | Reviews |
|------|-------|---------|
| Task Reviewer | `development-team:task-reviewer` | Plans — feasibility, scope, decomposition quality |
| API Reviewer | `development-team:api-reviewer` | APIs — correctness, consistency, usability |
| Test Design Reviewer | `development-team:test-design-reviewer` | Test designs — completeness, correctness, edge cases |
| Code Reviewer | `development-team:code-reviewer` | Code + tests — bugs, coverage, maintainability, TDD compliance |
| Document Reviewer | `development-team:doc-reviewer` | Docs — clarity, accuracy, completeness |
| Architecture Reviewer | `development-team:architect-reviewer` | Architecture designs — modularity, scalability, feasibility |
| Product Reviewer | `development-team:product-reviewer` | Product designs — user value, completeness, prioritization |

### Shared Files

| File | Who reads it |
|------|-------------|
| `SKILL.md` (this file) | All roles (shared rules) |
| `development-team:pm` | Project Manager (PM-specific rules) |
| `development-team:<role-name>` | Each role loads its own skill |

## Workflow

```dot
digraph context_flow {
  rankdir=TB;
  node [shape=box];
  "User Request" -> "Project Manager";
  "Project Manager" -> "Intern" [label="scoping / reading", style=dashed];
  "Project Manager" -> "Product Designer" [label="serious requirements", style=dashed];
  "Product Designer" -> "Product Reviewer";
  "Product Reviewer" -> "Project Manager" [label="pass"];
  "Project Manager" -> "Architecture Designer" [label="greenfield/refactoring"];
  "Architecture Designer" -> "Architecture Reviewer";
  "Architecture Reviewer" -> "Project Manager" [label="pass"];
  "Project Manager" -> "Task Planner";
  "Task Planner" -> "Task Reviewer";
  "Task Reviewer" -> "Project Manager" [label="pass"];
  "Project Manager" -> "API Designer";
  "API Designer" -> "API Reviewer";
  "API Reviewer" -> "Project Manager" [label="pass"];
  "Project Manager" -> "Test Designer" [label="integration tests"];
  "Test Designer" -> "Test Design Reviewer";
  "Test Design Reviewer" -> "Project Manager" [label="pass"];
  "Project Manager" -> "Code Developer";
  "Code Developer" -> "Code Reviewer";
  "Code Reviewer" -> "Project Manager" [label="pass"];
  "Project Manager" -> "Test Designer" [label="system tests"];
  "Project Manager" -> "Code Developer" [label="run system tests"];
  "Project Manager" -> "User" [label="final result"];
  "Architecture Designer" -> "Test Designer" [label="system test scope", style=dashed];
  "Product Designer" -> "Architecture Designer" [label="product spec", style=dashed];
}
```

**The project manager is NEVER the pipe.** Documents on disk carry context between subagents.

## Information Access Model (2-Tier)

### Why Two Different Names?

- **Information Access** (PM) — describes information *channels*, NOT file reading. PM never reads files; information reaches PM only through user conversation and subagent return summaries (3-5 lines).
- **Reading Access** (everyone else) — describes file *reading capability*. These agents read files directly (source code, configs, papers, delivery docs). Their constraint is task scope (1 module / 2-3 files), not access.

The distinction matters: PM is isolated from file content by design (context protection), while all other agents are free to read but must stay focused on their assigned scope.

| Tier | Role | Can Read |
|------|------|----------|
| Tier 1 | Project Manager | ONLY user conversation + subagent return summaries (3-5 lines). PM NEVER reads files. Uses Intern to read and report back. |
| Tier 2 | Everyone else (Intern, production roles, reviewers) | Anything they need — source code, delivery docs, papers, configs. No restrictions. Their constraint is task scope (focused on 1 module / 2-3 files), not file access. |

**PM Reading Protocol:** When the PM needs to understand something (scope a task, verify a deliverable, answer a user question), the PM dispatches an Intern with a specific reading task. The Intern reads the material and returns a structured summary. The PM absorbs only the gist (1-2 sentences).

**Agent Reading Discipline:** Tier 2 agents read freely within their task scope. They do NOT need a dedicated reading role. Their constraint is scope (max 1 module / 2-3 files per dispatch), not access.

## Subagent Reading

Production subagents and reviewers read whatever they need directly (source code, delivery docs, papers, configs). There is no dedicated reading role. If a subagent needs heavy context consumed, it reads the material itself within its task scope. The constraint is scope (1 module / 2-3 files), not access.

## Subagent Dispatch Rules

### Who Subagents Can Dispatch

| Target | Can Dispatch? | How |
|--------|--------------|-----|
| **Any other production or review role** | NO | Subagents CANNOT dispatch other roles. If work is outside scope, report BLOCKED to PM. |

### When You Are Blocked

If a subagent encounters work that is:
1. Outside its defined role scope, AND
2. Necessary to complete its current task, AND
3. Cannot be resolved by reading available materials within task scope

The subagent MUST stop and report **BLOCKED** to the Project Manager using this exact format:

```
BLOCKED: Need [Role] to [specific action needed]
Reason: [why this is outside my role]
Impact: [what work is stuck if unresolved]
Alternative: [any workaround, or "none"]
```

**The subagent MUST NOT:**
- Attempt to do the work itself (violates role scope)
- Silently skip the work (produces incomplete output)
- Vaguely ask for "help" without specifying exactly what is needed

### BLOCKED Examples

```
BLOCKED: Need API Designer to define the contract for UserService.updatePassword()
Reason: I am a Code Developer, and no API design exists for this endpoint. I cannot invent the contract myself.
Impact: Password update feature cannot be implemented.
Alternative: If the endpoint is trivial (single field update), I could follow the existing pattern from UserService.updateEmail() — but this should be confirmed by the API Designer.
```

```
BLOCKED: Need Test Designer to create integration tests for the payment webhook
Reason: I am a Code Developer and only write unit tests. Integration tests require the Test Designer's TDD expertise.
Impact: Payment webhook will have no integration test coverage.
Alternative: none
```

## Delivery Directory

### Path Format

Each delivery doc lives in a time-based directory hierarchy. The path is:

```
.claude/development-team/<year>/<month>/<week-ordinal>-week/<agentname>/<summary>-<hour><ampm>-<day><ordinal>.md
```

### Path Components

| Component | Format | Example | How to determine |
|-----------|--------|---------|------------------|
| `<year>` | 4-digit year | `2026` | Current year |
| `<month>` | 2-digit month | `06` | Current month (zero-padded) |
| `<week-ordinal>-week` | Ordinal week of month | `1st-week`, `2nd-week`, `3rd-week`, `4th-week`, `5th-week` | **NOT ISO week number** — count which week of the current month (1st through 5th), append `-week` |
| `<agentname>` | Role name in kebab-case | `coder`, `api-designer`, `architect` | Your role name |
| `<summary>` | Short kebab-case content description | `auth-module`, `plan-jwt-migration` | What this doc contains |
| `<hour><ampm>` | 12-hour clock with am/pm suffix | `07am`, `02pm`, `11am` | Current hour in 12-hour format + `am` or `pm` |
| `<day><ordinal>` | Day of month with English ordinal suffix | `1st`, `2nd`, `3rd`, `14th`, `21st`, `22nd`, `23rd` | Current day + `st`/`nd`/`rd`/`th` |

### Ordinal Suffix Rules

- **st**: 1, 21, 31
- **nd**: 2, 22
- **rd**: 3, 23
- **th**: 4-20, 24-30

### How to Construct the Path

1. Get the current date/time.
2. Determine `<week-ordinal>-week`: which week of the month is it? (1st = days 1-7, 2nd = days 8-14, 3rd = days 15-21, 4th = days 22-28, 5th = days 29-31). This is the week number within the current month, **not** the ISO week number of the year. Append `-week` (e.g., `1st-week`).
3. Use your role name as `<agentname>`.
4. Pick a short `<summary>` describing the doc content.
5. Determine `<hour><ampm>`: convert the current hour to 12-hour format and append `am` or `pm` (e.g., 14:00 becomes `02pm`, 9:00 becomes `09am`).
6. Determine `<day><ordinal>`: take the current day of month and append the English ordinal suffix (e.g., 7 becomes `7th`, 14 becomes `14th`, 21 becomes `21st`).
7. Assemble: `.claude/development-team/<year>/<month>/<week-ordinal>-week/<agentname>/<summary>-<hour><ampm>-<day><ordinal>.md`

### Example

For June 7, 2026 at 2:00 PM, during the 1st week of June, an API Designer designing auth endpoints:

```
.claude/development-team/2026/06/1st-week/api-designer/auth-endpoints-02pm-7th.md
```

A full task producing multiple docs might look like:

```
.claude/development-team/2026/06/1st-week/
  ├── product-designer/
  │   └── user-app-10am-7th.md
  ├── architect/
  │   └── modular-structure-11am-7th.md
  ├── planner/
  │   └── auth-refactor-to-jwt-12pm-7th.md
  ├── api-designer/
  │   └── auth-endpoints-01pm-7th.md
  ├── test-designer/
  │   └── auth-integration-tests-02pm-7th.md
  ├── coder/
  │   └── auth-module-impl-03pm-7th.md
```

Review feedback files follow the same pattern, using the reviewer's role name:

```
.claude/development-team/2026/06/1st-week/code-reviewer/review-code-round1-03pm-7th.md
```

## File Naming Rules

File names follow the `<summary>-<hour><ampm>-<day><ordinal>.md` pattern where `<summary>` is a short kebab-case content description. No generic labels.

| Bad | Good |
|-----|------|
| `doc1-02pm-7th.md` | `plan-auth-refactor-to-jwt-02pm-7th.md` |
| `output-02pm-7th.md` | `api-design-auth-endpoints-02pm-7th.md` |
| `review-02pm-7th.md` | `review-code-round1-02pm-7th.md` |

## Document Template

All delivery docs use this structure:

```markdown
# [Type]: [Title]

## Context
Why this exists and what it feeds into.

## Key Decisions
- Decision 1: ...

## Output
The actual work product.

## Constraints & Open Questions
What the next person should know.

## References
File paths, URLs — NOT inline content.
```

## Permissions Matrix

| Role | Read delivery docs | Write delivery docs | Read review feedback | Read source code / configs / papers | Dispatch Other Roles |
|------|-------------------|--------------------|--------------------|--------------------------------------|---------------------|
| Project Manager | No | No | No | No (dispatch Intern to read) | Yes (all roles) |
| Architecture Designer | Yes — Same date hierarchy | Yes | Yes | Yes — Within task scope | No — Others: BLOCKED |
| Product Designer | Yes — Same date hierarchy | Yes | Yes | Yes — Within task scope | No — Others: BLOCKED |
| Task Planner | Yes — All in `.claude/development-team/` | Yes | Yes | Yes — Within task scope | No — Others: BLOCKED |
| API Designer | Yes — Same date hierarchy | Yes | Yes | Yes — Within task scope | No — Others: BLOCKED |
| Test Designer | Yes — Same date hierarchy | Yes | Yes | Yes — Within task scope | No — Others: BLOCKED |
| Code Developer | Yes — Same date hierarchy | Yes | Yes | Yes — Within task scope | No — Others: BLOCKED |
| Document Writer | Yes — Same date hierarchy | Yes | Yes | Yes — Within task scope | No — Others: BLOCKED |
| Intern | Yes — Same date hierarchy | Yes | N/A | Yes — As directed by PM | No — Others: BLOCKED |
| Architecture Reviewer | Yes — Doc being reviewed | Yes — Feedback | N/A | Yes — Within review scope | No — Others: BLOCKED |
| Product Reviewer | Yes — Doc being reviewed | Yes — Feedback | N/A | Yes — Within review scope | No — Others: BLOCKED |
| All other Reviewers | Yes — Doc being reviewed | Yes — Feedback | N/A | Yes — Within review scope | No — Others: BLOCKED |

## Review Protocol

Every production deliverable goes through its paired reviewer. Maximum **3 review rounds**. Author reads reviewer feedback from the delivery directory. Project Manager only sees the verdict (PASS/FAIL + critical issues + confidence). Review feedback files: `review-<type>-round<N>-<hour><ampm>-<day><ordinal>.md` (written by reviewer under their own agent directory).

### Review Routing

| Producer | Reviewer |
|----------|----------|
| Architecture Designer → | Architecture Reviewer |
| Product Designer → | Product Reviewer |
| Task Planner → | Task Reviewer |
| API Designer → | API Reviewer |
| Test Designer → | Test Design Reviewer |
| Code Developer → | Code Reviewer (includes test review) |
| Document Writer → | Document Reviewer |

## Module-Driven Implementation

Implementation follows a bottom-up topological sort of the module dependency graph:

- **Layer 0** (leaf modules, no internal deps) implemented first, in parallel.
- Each subsequent layer implemented only after the previous layer's Code Review passes.
- Cross-module integration is handled by shallower-layer coders who call sub-module API interfaces.

## Parallel Dispatch & Handoff Documentation

### Parallel Dispatch Emphasis

Work that CAN be parallelized SHOULD be dispatched simultaneously. The Task Planner identifies independent subtasks and groups them. The PM dispatches all subtasks in the same group at the same time. This maximizes wall-clock efficiency.

### Handoff Documentation Between Phases

Phased work is separated by **delivery docs that serve as explicit handoff between stages**. Each phase's output doc is the next phase's input. This is how agents collaborate — not through conversation, but through well-structured delivery documents.

**Handoff chain example:**
```
Product Design → Architecture Design → Plan → API Design → Test Design → Code Implementation → System Test
     doc              doc              doc        doc            doc            doc                doc
```

Each arrow represents a delivery doc on disk. The downstream agent reads it. The PM never reads it — only tracks the path.

## Required Return Formats

| Role | Return Format |
|------|--------------|
| Architecture Designer | Modules defined + key decision summary + system test scope defined YES/NO + breaking changes (if refactoring) |
| Product Designer | Delivery doc path + User stories: N defined + MVP scope + Key assumption |
| Task Planner | N subtasks + dependencies + effort + risk + start point |
| API Designer | Endpoints designed + 1-line summary of design decisions |
| Test Designer | Tests designed + test file paths + coverage summary |
| Code Developer | Files changed + unit tests written + all tests passing YES/NO |
| Document Writer | Doc path + 1-line summary of content |
| All Reviewers | Verdict + critical issues + confidence |

## Deprecated Directory

Superseded delivery docs are moved to:

```
.claude/development-team/deprecated/<year>/<month>/<week-ordinal>-week/<agentname>/
```

Structure mirrors the active directory:

```
.claude/development-team/deprecated/
  └── 2026/
      └── 06/
          └── 1st-week/
              └── planner/
                  └── auth-refactor-v1-10am-5th.md
```

- Subagents MAY read from `deprecated/` for historical context, but should prefer active docs.
- Deprecated docs are NOT reviewed or maintained — treat as read-only archive.

PM-specific rules are in the `development-team:pm` skill. Subagent role rules are in individual skills (e.g., `development-team:coder`, `development-team:architect`).
