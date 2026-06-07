[中文版本 / Chinese Version](README-CN.md)

# DevelopmentTeam

> A Claude Code skill that turns your AI agent into an IT team project manager — dispatching 17 specialized roles to collaborate on software engineering tasks, while safeguarding your precious context window.

---

## Overview

If you have used Claude Code for complex tasks, you have likely run into this problem: as a conversation grows longer, the agent's context window gradually fills up with code snippets, diffs, and logs. Its judgment and memory deteriorate along the way. Halfway through a task, it may have already forgotten the original requirements. **Context is a scarce and non-renewable resource** — once consumed, it cannot be recovered.

**DevelopmentTeam** was built to solve exactly this problem. The core idea is simple: the AI agent plays the role of an IT team project manager, and **the project manager never does the work themselves** — they only understand requirements, design workflows, dispatch specialized subagents, and make decisions based on the brief verdicts (1-2 sentence summaries) those subagents return. All context flows through structured documents on disk; the project manager never reads the actual deliverables.

This is not a codebase or a framework. It is a carefully crafted set of Markdown rule files (19 in total). Install them into `~/.claude/skills/`, and every Claude Code conversation automatically enters "project manager mode." Whether you are building a brand-new full-stack project or fixing a small bug, DevelopmentTeam automatically matches the right workflow template and delivers high-quality results through TDD, code reviews, and quality gates.

---

## Core Principles

| Principle | Description |
|-----------|-------------|
| **Context is scarce** | The agent's context window is limited and non-recoverable — treat it like a budget |
| **The project manager never does the work** | The Project Manager never reads code, writes docs, or runs commands — all real work is delegated to subagents |
| **Disk is the communication channel** | Subagents exchange context through structured deliverable documents under `.claude/development-team/`, not through conversation |
| **Absorb only verdicts** | The Project Manager receives only file paths + 1-2 sentence conclusions for decision-making, never full deliverables |

---

## Features

- **17 specialized roles** — 10 production roles + 7 review roles, each with clear responsibilities and authority
- **7 workflow templates (+ custom)** — From Greenfield new projects to Quick Fixes, automatically matched by task complexity
- **TDD first** — Test Designer writes tests before Code Developer implements, ensuring quality from the start
- **Review gates** — Every production deliverable must pass its paired reviewer, up to 3 rounds; failures escalate to the user
- **Parallel execution** — Task Planner identifies independent subtasks and dispatches them in parallel; downstream dependencies start only after review passes
- **Failure handling** — Covers 8+ failure modes including subagent crashes, incomplete output, review loops, permission errors, and Git conflicts
- **Session recovery** — Deliverables persist on disk; if a session is interrupted, the Summarizer reads the state and resumes from the breakpoint
- **Pre-flight safety checks** — Evaluates Git status and project directory risks before execution; provides three safety options when modifying files outside the project
- **Mandatory task tracking** — Uses `TaskCreate` to maintain a visible progress list; users see real-time status of every step in the panel
- **Mandatory dispatch announcements** — Every subagent dispatch outputs a natural-language announcement: who, what, and why
- **Permission matrix** — Read/write/review permissions for each role over deliverable documents are precisely defined to prevent unauthorized access
- **Document recommendation matrix** — Each production role is explicitly told which upstream deliverables to read, ensuring correct context flow
- **Pure Markdown** — Zero dependencies, zero build steps, zero configuration — 19 `.md` files are the entire product

---

## Role Reference

### Production Roles

| Role | File | Responsibility |
|------|------|----------------|
| Project Manager | `SKILL.md` | Understands requirements, designs workflows, dispatches subagents, makes decisions — but never does the work |
| Architecture Designer | `architect.md` | Designs system architecture, module decomposition, technology selection |
| Product Designer | `product-designer.md` | Designs product specifications, user stories, feature prioritization |
| Task Planner | `planner.md` | Breaks tasks into small units and writes execution plans |
| API Designer | `api-designer.md` | Designs APIs, interfaces, and contracts |
| Test Designer | `test-designer.md` | Designs integration and system tests (TDD: tests first) |
| Code Developer | `coder.md` | Writes code + unit tests, runs all tests, ensures they pass |
| Document Writer | `doc-writer.md` | Writes documentation, articles, and specifications |
| Intern | `intern.md` | Miscellaneous tasks — cleanup, archival, file operations, simple chores |
| Summarizer | `summarizer.md` | Heavy context consumer — reads papers, projects, and codebases to distill answers |

### Review Roles

| Role | File | Reviews |
|------|------|---------|
| Architecture Reviewer | `architect-reviewer.md` | Architecture design — modularity, scalability, feasibility |
| Product Reviewer | `product-reviewer.md` | Product design — user value, completeness, prioritization |
| Task Reviewer | `task-reviewer.md` | Execution plans — feasibility, scope, decomposition quality |
| API Reviewer | `api-reviewer.md` | API design — correctness, consistency, usability |
| Test Design Reviewer | `test-design-reviewer.md` | Test design — completeness, correctness, edge cases |
| Code Reviewer | `code-reviewer.md` | Code + tests — bugs, coverage, maintainability, TDD compliance |
| Document Reviewer | `doc-reviewer.md` | Documentation — clarity, accuracy, completeness |

---

## Workflow Templates

| Template | Use Case | Typical Flow |
|----------|----------|--------------|
| **Greenfield System Development** | New projects from scratch (2+ modules) | (Optional) Product design → Architecture design → Planning → Integration TDD (per unit) → System testing → Delivery |
| **Architectural Refactoring** | Architecture-level refactoring (e.g., monolith to microservices) | Architecture design → Planning → Integration TDD → System testing → Delivery |
| **Full System Development** | Large features, new modules | Planning → Integration TDD → System testing → Delivery |
| **Standard Development** | Medium features, refactoring, new endpoints | Planning → API design → Coding + unit tests → Delivery |
| **Quick Fix** | Small bugs, typos, config changes | Coding → Code review → Delivery |
| **Investigation Only** | Research, analysis, questions | Summarizer investigates → Delivers conclusions |
| **Documentation Only** | READMEs, guides, articles | Document Writer → Document review → Delivery |

In every template, production deliverables go through their paired reviewer before the workflow advances. The Project Manager selects the appropriate template based on the task and can also customize the flow.

---

## Installation & Usage

### Prerequisites

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI installed
- Claude Code skill directory at `~/.claude/skills/`

### Installation Steps

```bash
# 1. Clone the repository into the Claude Code skills directory
git clone https://github.com/your-username/the-company.git ~/.claude/skills/the-company

# 2. Verify installation — confirm these files exist
ls ~/.claude/skills/the-company/SKILL.md
ls ~/.claude/skills/the-company/system.md
```

Once installed, DevelopmentTeam skill is automatically activated in every Claude Code conversation. The Project Manager takes over, analyzes your request, and proposes a workflow.

### Usage Examples

After launching Claude Code, just describe what you need:

```
> Build me a user authentication system with JWT and OAuth2 support

# The Project Manager will automatically:
# 1. Dispatch the Summarizer to assess the project scope
# 2. Propose a Full System Development workflow
# 3. Wait for your confirmation before executing
```

For simple tasks:

```
> Fix a typo on the login page

# The Project Manager selects the Quick Fix flow:
# Code Developer → Code Reviewer → Delivery
```

### Deliverable Directory

All intermediate artifacts and final deliverables are stored in the project's `.claude/development-team/` directory, organized by date hierarchy:

```
.claude/development-team/<year>/<month>/<week-ordinal>-week/<agentname>/<summary>-<hour><ampm>-<day><ordinal>.md
```

Example for June 7, 2026 (1st week of June):

```
.claude/development-team/2026/06/1st-week/
  ├── planner/
  │   └── auth-refactor-12pm-7th.md      # Execution plan
  ├── api-designer/
  │   └── auth-endpoints-01pm-7th.md     # API design document
  ├── test-designer/
  │   └── auth-tests-02pm-7th.md         # Test design document
  ├── coder/
  │   └── auth-module-03pm-7th.md        # Code implementation record
  ├── code-reviewer/
  │   └── review-code-round1-03pm-7th.md  # Review feedback
  └── summarizer/
      └── oauth-research-10am-7th.md     # Research summary
```

---

## Project Structure

```
the-company/
├── SKILL.md                     # Entry point / Project Manager rules (Skill manifest)
├── system.md                    # Shared system overview (read by all roles)
├── .gitignore                   # Ignores .claude/, .idea/, .vscode/
│
├── 📦 Production Roles (10):
│   ├── architect.md             # Architecture Designer
│   ├── product-designer.md      # Product Designer
│   ├── planner.md               # Task Planner
│   ├── api-designer.md          # API Designer
│   ├── test-designer.md         # Test Designer
│   ├── coder.md                 # Code Developer
│   ├── doc-writer.md            # Document Writer
│   ├── intern.md                # Intern (miscellaneous)
│   └── summarizer.md            # Summarizer (heavy context consumer)
│
├── 🔍 Review Roles (7):
│   ├── architect-reviewer.md    # Reviews architecture design
│   ├── product-reviewer.md      # Reviews product design
│   ├── task-reviewer.md         # Reviews execution plans
│   ├── api-reviewer.md          # Reviews API design
│   ├── test-design-reviewer.md  # Reviews test design
│   ├── code-reviewer.md         # Reviews code + tests
│   └── doc-reviewer.md          # Reviews documentation
│
└── .claude/development-team/         # Runtime deliverable directory
    └── 2026/06/1st-week/             # Organized by year/month/week
        └── <agentname>/              # Each role has its own subdirectory
    └── deprecated/                   # Archived old deliverable documents
```

**Total: 2 core system files + 17 role definition files = 19 Markdown files.**

---

## License

This project is licensed under the [MIT License](LICENSE).

---

## Contributing

This is a personal project, currently maintained by a solo developer. If you have suggestions or find bugs, feel free to open an issue on [GitHub Issues](https://github.com/your-username/DevelopmentTeam/issues).

## Acknowledgments

DevelopmentTeam was inspired by a straightforward observation: **an AI agent's context window is its most precious resource**, yet most interaction patterns squander it unconsciously. Thanks to the Anthropic Claude Code team for providing the skill system and subagent mechanism that make this "project manager mode" possible.
