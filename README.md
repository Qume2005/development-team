# development-team

> A Claude Code plugin that turns the main agent into an IT Project Manager — it scopes, proposes a workflow, dispatches 19 specialized native subagents, and gates every deliverable behind a paired reviewer.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Claude Code Plugin](https://img.shields.io/badge/Claude%20Code-Plugin-orange)](https://docs.anthropic.com/en/docs/claude-code)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](https://github.com/Qume2005/development-team/pulls)

**English** | [简体中文](README-CN.md)

---

## Detailed Contents

- [What it is](#what-it-is)
- [📦 Installation](#-installation)
- [🚀 Usage](#-usage)
- [✨ Features](#-features)
- [🧠 How it works](#-how-it-works)
- [👥 Roles (20)](#-roles-20)
- [🛠️ Skills (9)](#️-skills-9)
- [⚙️ Hooks](#-hooks)
- [❓ FAQ & Troubleshooting](#-faq--troubleshooting)
- [📐 Project structure](#-project-structure)
- [🤝 Contributing](#-contributing)
- [License](#license)

---

## What it is

`development-team` is a Claude Code plugin (v1.0.0, MIT, by [Qume2005](https://github.com/Qume2005)) that puts the main agent into an **IT Project Manager operating mode**. The PM never does the work itself — it scopes tasks, proposes a workflow, dispatches specialized native subagents, and decides based on reviewer verdicts. **Every production deliverable is gated by a paired reviewer (PASS/FAIL, max 3 rounds).**

Why you'd want this:

- **Structured workflow** — a request flows through a real pipeline: product design → architecture → planning → API design → test design → code → review → deliver. The PM picks the right slice of that pipeline for the size of the task.
- **Mandatory review** — no code, plan, API, or doc ships until its paired reviewer returns PASS. Bug fixes require a root-cause statement plus a failing-first regression test; completion claims require fresh command-output evidence.
- **Context protection** — the PM structurally cannot `Read` / `Write` / `Bash`. It sees only short subagent summaries, so the scarce context window is reserved for decision-making, not file content.
- **Zero dependencies, zero build step** — the entire plugin is pure Markdown (skills + agent definitions) plus bash hooks. No `npm install`, no compile, no runtime. Clone it and it runs.

---

## 📦 Installation

### Method 1 — `git clone` (recommended)

```bash
git clone https://github.com/Qume2005/development-team.git ~/.claude/skills/development-team
chmod +x ~/.claude/skills/development-team/hooks/*
```

Two commands, no build step, no config.

### Method 2 — community marketplace (not yet live)

```bash
/plugin install development-team@claude-community
```

> **Note:** the marketplace listing is not live yet. Until it is, use Method 1.

### Activation

There is **no slash command** and nothing to run after install. Start a Claude Code session in any project and the `SessionStart` hook injects the bootstrap context automatically. The agent will load the PM skill and enter project-manager operating mode — just state a goal.

### Uninstall

```bash
rm -rf ~/.claude/skills/development-team
```

Optionally clean the registry: edit `~/.claude/plugins/installed_plugins.json` and remove the `"development-team@local"` block (keep the JSON valid — no trailing commas). `settings.json` needs no change. Restart Claude Code (or `/clear`) so the next session does not auto-activate the team.

---

## 🚀 Usage

After install, your only job is to **state a goal in one sentence** and let go. The PM sizes the workflow to the task, dispatches the right roles, and gates every deliverable.

### A large task → full pipeline

```
> Build a user authentication system with JWT and OAuth2.

# The PM will:
#  1. (optionally) dispatch Intern/Explore to scope the codebase
#  2. propose a Full System Development workflow
#     (Product → Architecture → Plan → API → Test Design → Code → Review → deliver)
#  3. wait for your approval, then run it — producers in parallel where independent,
#     each deliverable gated by its paired reviewer (max 3 rounds)
```

### A small task → Quick Fix

```
> Fix the typo on the login page.

# The PM picks a Quick Fix workflow:
#  Code Developer → Code Reviewer → deliver
# (bug fixes still require a root-cause statement + failing-first regression test)
```

In both cases, every deliverable must pass its paired reviewer and carry fresh verification evidence. Intermediate and final artifacts land under the project's `.claude/development-team/<role>/` directory, organized flatly per role.

---

## Relationship to Claude Code's plan mode

Claude Code ships with a built-in **plan mode** (research, then propose a plan, then ask the user to approve before executing). This plugin **supplements and enhances** plan mode — it does not fight it. `EnterPlanMode` / `ExitPlanMode` remain the approval channel, and `AskUserQuestion` is still how the PM clarifies an ambiguous request before proposing.

What changes is **who authors the plan and who searches the codebase**:

- The plan is authored by the **Task Planner** role (`development-team:planner`) and gated by the **Task Reviewer** — the PM never writes the plan file itself, and a plan is not presented for approval until its review PASSes.
- Fan-out codebase search goes through **`development-team:explore`**, not the built-in `Explore` agent.
- Every production deliverable still flows through its paired reviewer (PASS/FAIL).

Where the built-in plan-mode workflow and this one disagree, **this workflow takes precedence.** Plan mode is the presentation and approval surface; the dev-team dispatch chain owns planning, search, and review.

---

## ✨ Features

| Feature | What it gives you |
|---------|-------------------|
| **20 specialized roles** | 13 producers (PM, Intern, Code Developer, Task Planner, Architecture Designer, Product Designer, API Designer, Test Designer, Document Writer, DevOps Engineer, Data Engineer, Migrator, Explore) + 7 reviewers. Each role is a native Claude Code plugin agent with its own craft and tool list. |
| **Mandatory paired review** | Every deliverable flows to its paired reviewer. PASS/FAIL, max 3 rounds. A FAIL returns the work for revision; only a PASS lets the PM treat the artifact as deliverable. |
| **TDD discipline** | The Test Designer designs integration and system tests **before** code is written; the Code Developer writes unit tests first (red → green) and implements against the pre-designed tests. |
| **Verification gate** | No "done / passing / fixed" claim without fresh command output from the current turn. Stale runs, "should pass", and assertions-without-evidence are reviewer FAILs by default. |
| **Event-driven, non-blocking dispatch** | Independent subtasks are dispatched in parallel. The PM is an event-driven scheduler: each completion and each review PASS is an event that unlocks the next dependent batch. |
| **Hook-enforced PM tool restriction** | The PM's tool limit is enforced **structurally** by a hook, not by good behavior — the PM literally cannot invoke `Read`, `Write`, `Edit`, `Bash`, `Glob`, `Grep`, `WebSearch`, `LSP`, or `NotebookEdit`. Subagents are unaffected. |
| **Anti-idle supervisory polling** | A `Stop` hook prevents the PM from going silently idle on pending work: if nothing will auto-resume the session (no background task, no valid supervisory cron), the stop is blocked and the PM must set up explainable polling. |
| **Zero dependencies** | Pure Markdown + bash hooks. No build step, no install step beyond `chmod +x`. Runs anywhere bash runs. |

---

## 🧠 How it works

### The PM loop

```
1. Scope        — PM (optionally) dispatches Intern/Explore to read the request and report a 3–5 line summary
2. Propose      — PM designs a workflow sized to the task and presents it for user approval
3. Dispatch     — PM dispatches producers (non-blocking, event-driven); independent work runs in parallel
4. Review gate  — each producer's deliverable goes to its paired reviewer (PASS/FAIL, max 3 rounds)
5. Deliver      — once every gate is PASS and fresh verification evidence is attached, PM delivers to the user
```

### Two-tier information access

The system deliberately splits information access across two tiers:

| Tier | Role | Can read |
|------|------|----------|
| **Tier 1** | Project Manager | **Only** user conversation + subagent return summaries (3–5 lines). The PM never reads files. When it needs to understand something, it dispatches an Intern to read and report back. |
| **Tier 2** | Everyone else (Intern, all producers, all reviewers) | Anything they need — source code, configs, delivery docs, papers. Their constraint is **task scope** (≈1 module / 2–3 files), not access. |

This is what "context protection" means in practice: the PM's context window is reserved for decisions, while the workers read freely within a focused scope.

### Producer → reviewer pipeline

Context flows between roles as **Markdown delivery docs on disk**, written under `.claude/development-team/<role>/`. Each phase's output doc is the next phase's input. The PM never reads these docs — it only tracks their paths and absorbs the reviewer's verdict.

```
                        ┌─────────────────────────────────────────────┐
                        │              Project Manager                 │
                        │  scope → propose → dispatch → decide         │
                        │  (reads only summaries, never files)         │
                        └─────────────┬───────────────────┬────────────┘
                                      │ dispatches        │ dispatches
                                      ▼                   ▼
   ┌──────────────┐   ┌──────────────┐   ┌──────────────┐   ┌──────────────┐
   │   Intern /   │   │    Product   │   │ Architecture │   │ Task Planner │
   │   Explore    │   │   Designer   │   │   Designer   │   │              │
   │ (read/map)   │   │      │       │   │      │       │   │      │       │
   └──────────────┘   │      ▼       │   │      ▼       │   │      ▼       │
                 ┌────┴──────────────┴┐  ┌┴──────────────┴┐  ┌┴──────────────┐
                 │  Product Reviewer  │  │ Arch. Reviewer  │  │ Task Reviewer │
                 │      (PASS?)       │  │    (PASS?)      │  │    (PASS?)    │
                 └─────────┬──────────┘  └────────┬────────┘  └───────┬───────┘
                           │                      │                   │
                           └──────────┬───────────┴───────────────────┘
                                      ▼
                          ┌───────────────────────┐    ┌───────────────────────┐
                          │     API Designer      │───▶│     API Reviewer       │
                          └───────────┬───────────┘    └───────────┬───────────┘
                                      ▼ (TDD: tests first)
                          ┌───────────────────────┐    ┌───────────────────────┐
                          │     Test Designer     │───▶│ Test Design Reviewer   │
                          └───────────┬───────────┘    └───────────┬───────────┘
                                      ▼                            │ PASS
                          ┌───────────────────────┐    ┌───────────────────────┐
                          │     Code Developer    │───▶│     Code Reviewer       │
                          └───────────┬───────────┘    └───────────┬───────────┘
                                      ▼                            │ PASS
                                      ▼                            ▼
                          ┌──────────────────────────────────────────────────┐
                          │      Verification gate (fresh evidence)           │
                          └──────────────────────────┬───────────────────────┘
                                                     ▼
                                          ┌────────────────────┐
                                          │   Deliver to user   │
                                          └────────────────────┘
```

> The PM is never the pipe. Documents on disk carry context between roles. The PM only tracks paths and absorbs verdicts.

---

## 👥 Roles (20)

There are **20 roles**: 19 are native Claude Code plugin agent files in `agents/`, plus the **Project Manager**, which is the `skills/pm` skill (not an agent file). Each role is dispatched via `subagent_type: development-team:<role>`.

### Producers (13)

| Role | Produces | Tools |
|------|----------|-------|
| **Project Manager** (`skills/pm`, not an agent file) | Scopes, proposes workflow, dispatches, decides — never produces a deliverable itself | *(structurally restricted — see [Hooks](#-hooks))* |
| **Intern** | Housekeeping + the PM's reader: cleanup, archive, file ops, targeted reading & summarizing | `Read, Write, Edit, Bash` |
| **Code Developer** (`coder`) | Application code + unit tests for one module; runs all tests; verifies passing | `Read, Write, Edit, Bash, LSP, WebSearch` |
| **Task Planner** (`planner`) | Execution plans: decomposes work into single-module subtasks with explicit dependency edges | `Read, Write, WebSearch` |
| **Architecture Designer** (`architect`) | System architecture: module decomposition, tech choices, dependency-graph layering, system-test scope | `Read, Write, WebSearch` |
| **Product Designer** (`product-designer`) | Product specs: user personas, user stories, feature prioritization, success criteria | `Read, Write, WebSearch` |
| **API Designer** (`api-designer`) | APIs, interfaces, and contracts (contract-first, top-down) | `Read, Write, WebSearch` |
| **Test Designer** (`test-designer`) | Integration & system tests, designed before code (TDD) | `Read, Write, Edit, Bash` |
| **Document Writer** (`doc-writer`) | Documents, articles, specs, guides, READMEs | `Read, Write, Edit, WebSearch` |
| **DevOps Engineer** (`devops-engineer`) | Infra-as-code, CI/CD pipelines, build configs, containers, deploy scripts, observability wiring | `Read, Write, Edit, Bash, WebSearch` |
| **Data Engineer** (`data-engineer`) | DB schema changes, migrations, backfills, seeds; schema-evolution discipline (expand→contract, reversible) | `Read, Write, Edit, Bash, LSP` |
| **Migrator** (`migrator`) | Repo-wide mechanical changes (codemods, bulk renames, deprecation sweeps); exempt from the 1-module rule | `Read, Write, Edit, Bash, LSP` |
| **Explore** (`explore`) | Broad fan-out codebase search & mapping — "where does X live", touchpoint enumeration. Read-only to code; writes a map doc; no reviewer | `Read, Bash, Write` |

### Reviewers (7)

Each reviewer is a PASS/FAIL gate for the artifact type in its column. A single FAIL stops the review and returns the work for revision.

| Reviewer | What it gates |
|----------|---------------|
| **Product Reviewer** (`product-reviewer`) | Product designs — user value, completeness, prioritization |
| **Architecture Reviewer** (`architect-reviewer`) | Architecture designs — modularity, scalability, feasibility |
| **Task Reviewer** (`task-reviewer`) | Execution plans — feasibility, scope, decomposition quality |
| **API Reviewer** (`api-reviewer`) | APIs — correctness, consistency, usability |
| **Test Design Reviewer** (`test-design-reviewer`) | Test designs — completeness, correctness, edge cases |
| **Code Reviewer** (`code-reviewer`) | Code + unit tests (also DevOps/Data/Migrator output) — bugs, coverage, maintainability, TDD compliance, root-cause & verification-evidence gates |
| **Document Reviewer** (`doc-reviewer`) | Documents — clarity, accuracy, completeness; also enforces the `writing-skills` baseline-failure gate for skill/rule edits |

> **About the PM:** the PM is the only coordination role. It writes no code, reads no files, and runs no commands — that is both a fact and its accurate scope. The team's value comes from the 12 other producers each owning their craft and the 7 reviewers gating each gate.

---

## 🛠️ Skills (9)

Skills are reusable **methodology** — the canonical "how" at the moment a discipline applies. The PM (and, where relevant, subagents) invoke them contextually. They are *not* loaded at bootstrap and they *do not* replace the role map.

| Skill | When it fires | One-line purpose |
|-------|---------------|------------------|
| **`development-team`** | Auto-triggers at the start of every session (via the SessionStart hook) | The shared system rules — delivery directory, review protocol, role map, permissions matrix. The mandatory bootstrap skill. |
| **`pm`** | Loaded by the agent at session start (after `development-team`) | PM-specific rules: the core operating loop, non-blocking dispatch, verification gate, commit policy. |
| **`brainstorming`** | PM invokes before proposing a workflow on ambiguous/creative tasks | Turn an open-ended request into a short, user-approved design *before* any production work. |
| **`systematic-debugging`** | PM references it in every bug-fix dispatch; Code Developer self-invokes during reproduction | Force root-cause investigation (reproduce → isolate → root cause → minimal fix → verify) before any fix. |
| **`verification-before-completion`** | Every producer before a completion claim; Code Reviewer as a hard PASS/FAIL gate | Require fresh verification evidence (run command → read output → confirm) before any "done/passing/fixed" claim. |
| **`branch-finishing`** | PM invokes when a task is complete and the branch must close out | Bring a feature branch to a mergeable state (tests green, rebased, PR-ready) before handoff or merge. |
| **`using-git-worktrees`** | PM invokes before parallel/risky/large file-modifying work | Isolate parallel work streams in separate git worktrees so concurrent branches don't clobber each other. |
| **`supervisory-polling`** | PM invokes at the moment it is about to set a polling cron while blocked | Make a polling cron *supervise* (check → escalate) rather than silently re-arm. |
| **`writing-skills`** | PM invokes before dispatching any "add/improve a skill or agent rule" task | Author skills/rules as TDD-for-docs — baseline-failure artifact first, then the minimal doc that closes it. |

---

## ⚙️ Hooks

The plugin's discipline is enforced **structurally** by bash hooks, not by good behavior. Hooks are registered in [`hooks/hooks.json`](hooks/hooks.json). All hook scripts run through [`hooks/run-hook.cmd`](hooks/run-hook.cmd), a cross-platform polyglot launcher (bash on Unix; it locates Git-for-Windows bash on Windows). The registered events:

| Event (matcher) | Script | What it does |
|-----------------|--------|--------------|
| **`SessionStart`** (`startup\|clear\|compact`) | `session-start` | Clears all per-session markers, then injects the bootstrap context. This is **how the team activates** — there is no slash command. At session start the PM skill is not yet loaded, so all work tools are blocked until the agent loads `development-team:pm` and `development-team` via the Skill tool. |
| **`PreToolUse`** (`Skill`) | `pre-skill-use` | When `development-team:pm` is loaded, creates the `PM_LOADED` and `PM_RESTRICTED` markers. Always allows the Skill call. |
| **`PreToolUse`** (`Agent`) | `pre-agent-use` | Increments the active-subagent counter (one marker file per dispatch). Always allows the Agent call. |
| **`PreToolUse`** (`Read\|Bash\|Write\|Edit\|Glob\|Grep\|WebSearch\|LSP\|NotebookEdit`) | `pre-tool-use` | **The structural PM tool restriction.** Identifies the caller: any subagent (foreground or background, by non-null `agent_id`/`agent_type`) is allowed unconditionally; the root/PM agent is blocked if `PM_RESTRICTED` is set, or if `PM_LOADED` is absent (bootstrap state). The check parses JSON with a `grep`/`sed` fallback when `jq` is absent, so it works on minimal images. |
| **`PostToolUse`** (`Agent`) | `post-agent-use` | **No-op router.** The counter decrement used to live here, but for *background* subagents the Agent tool returns immediately while the subagent keeps running, so decrementing here drained the counter mid-run. The decrement now lives on `SubagentStop`. This script is retained only so the matcher stays valid. |
| **`SubagentStop`** (all) | `subagent-stop` | Decrements the active-subagent counter when a subagent *actually* finishes — correct for both foreground and background dispatches (the active counter stays > 0 for the entire run of a background subagent). |
| **`Stop`** (all) | `stop` | **Anti-idle / explainable polling.** If the PM has pending todos and nothing will auto-resume the session (no in-flight background task, no valid supervisory cron with a non-trivial prompt and a bounded next-fire gap), the stop is **blocked** and the PM is told to create an explainable polling cron. Has an anti-loop backstop (`stop_hook_active`) and a path-traversal guard on `session_id`. |

> **Not registered (do not confuse with live hooks):**
> - There is no `commands/` directory — there are **no slash commands**. Activation is purely the SessionStart hook plus the mandatory auto-trigger `development-team` skill.
> - `hooks/test-stop.sh` is a **dry-run test driver** for the Stop hook (19 cases). It is not registered in `hooks.json`.

### jq is optional

Every hook that reads JSON prefers `jq` when present but falls back to `grep`/`sed`, so the plugin works on minimal Linux images and fresh macOS installs where `jq` is not available.

---

## ❓ FAQ & Troubleshooting

### "All my tools are blocked!"

That is **expected at session start**. The SessionStart hook injects bootstrap context, but the PM skill is not loaded yet, so `pre-tool-use` blocks `Read`/`Bash`/`Write`/etc. with a message telling the agent to load the PM skill first via the Skill tool:

```
development-team active but PM skills not loaded.
Invoke via Skill tool FIRST:
  1) development-team:pm
  2) development-team
Then retry.
```

Once the agent loads `development-team:pm`, the `pre-skill-use` hook sets the `PM_LOADED` and `PM_RESTRICTED` markers. From then on the PM is intentionally restricted (it dispatches subagents instead), and subagents are unrestricted.

### "Where did `.claude/development-team/` come from?"

That directory holds **internal delivery docs** — the Markdown handoffs the roles write to each other (plans, designs, review feedback, maps). It is created on first use and is **gitignored** (see [`.gitignore`](.gitignore): `.claude/`). It is safe to delete; it is not part of the plugin and not part of your source tree.

### Windows / cross-platform

The hooks are bash scripts. On Windows they run via [`hooks/run-hook.cmd`](hooks/run-hook.cmd), which locates Git-for-Windows bash (or `bash` on `PATH`) and delegates to it. If no bash is found, the launcher exits silently — the plugin still loads, it just skips the SessionStart context injection (the PM restriction hook still runs where bash is available). macOS and Linux work natively.

### Is `jq` required?

No. Every hook that reads JSON prefers `jq` when present and falls back to `grep`/`sed`. The plugin runs on minimal images without `jq`.

### How do I add a role or skill?

Authoring or editing a skill or agent rule follows the **`writing-skills`** methodology (TDD-for-docs): produce a baseline-failure artifact first, then the minimal doc that closes that failure, then a loophole-closing re-test. Invoke `development-team:writing-skills` for the full method. The Document Reviewer enforces the baseline-failure requirement as a PASS/FAIL gate.

---

## 📐 Project structure

```
development-team/
├── .claude-plugin/
│   └── plugin.json                  # Plugin manifest (name, version, author, license, keywords)
├── agents/                          # 19 native Claude Code plugin agents (flat .md files)
│   ├── intern.md
│   ├── coder.md
│   ├── planner.md
│   ├── architect.md
│   ├── product-designer.md
│   ├── api-designer.md
│   ├── test-designer.md
│   ├── doc-writer.md
│   ├── devops-engineer.md
│   ├── data-engineer.md
│   ├── migrator.md
│   ├── explore.md
│   ├── task-reviewer.md
│   ├── api-reviewer.md
│   ├── architect-reviewer.md
│   ├── product-reviewer.md
│   ├── test-design-reviewer.md
│   ├── code-reviewer.md
│   └── doc-reviewer.md
├── skills/                          # 9 skills (each a directory with SKILL.md)
│   ├── development-team/            #   shared system rules + bootstrap (auto-trigger)
│   │   ├── SKILL.md
│   │   └── bootstrap.md
│   ├── pm/                          #   PM-specific rules (the 20th role)
│   ├── brainstorming/
│   ├── systematic-debugging/
│   ├── verification-before-completion/
│   ├── branch-finishing/
│   ├── using-git-worktrees/
│   ├── supervisory-polling/
│   └── writing-skills/
├── hooks/
│   ├── hooks.json                   # Hook registration (SessionStart, PreToolUse, PostToolUse, SubagentStop, Stop)
│   ├── run-hook.cmd                 # Cross-platform launcher (bash polyglot)
│   ├── session-start                # SessionStart: clear markers + inject bootstrap
│   ├── pre-skill-use                # PreToolUse:Skill: set PM_LOADED / PM_RESTRICTED
│   ├── pre-agent-use                # PreToolUse:Agent: increment active-subagent counter
│   ├── pre-tool-use                 # PreToolUse:Read|Bash|...: enforce PM tool restriction
│   ├── post-agent-use               # PostToolUse:Agent: no-op router (decrement moved to SubagentStop)
│   ├── subagent-stop                # SubagentStop: decrement active-subagent counter
│   ├── stop                         # Stop: anti-idle / explainable polling enforcement
│   └── test-stop.sh                 # Dry-run test driver for the Stop hook (not registered)
├── .gitignore                       # Ignores .claude/ (delivery docs), skills-lock.json, editor dirs
├── LICENSE                          # MIT
├── README.md                        # This file (English, primary)
└── README-CN.md                     # Simplified Chinese mirror
```

**Counts:** 19 agent files (`agents/*.md`) + the PM skill (`skills/pm`) = **20 roles**. 9 skill directories under `skills/`. 7 registered hook scripts (plus `run-hook.cmd` launcher and `test-stop.sh` test driver). No `commands/` directory.

---

## 🤝 Contributing

This is a personal project, currently maintained by a single developer. Suggestions and bug reports are welcome via [GitHub Issues](https://github.com/Qume2005/development-team/issues); pull requests are welcome too.

> A `CONTRIBUTING.md` is a future follow-up and out of scope for this README. No banner/logo image assets exist in the repo today — one can be added later if provided (do not invent image paths).

---

## License

[MIT License](LICENSE) © 2025 Qume
