---
name: using-git-worktrees
description: Canonical worktree-isolation methodology — detect existing isolation first, prefer native worktree/session tools, fall back to git worktree. Invoked before risky, large, refactor, or parallel file-modifying work to guarantee an isolated workspace.
---

# Using Git Worktrees — Isolated Workspace Methodology

> **Invokable as** `development-team:using-git-worktrees` via the Skill tool. Triggered by the PM's Pre-Flight isolation check before any task that modifies files — especially risky, large, refactor, or parallel work. Production subagents self-invoke when their dispatch begins touching files and no isolation has been confirmed.

## Why This Exists

File-modifying work that runs in the main checkout mixes in-progress changes with the user's working tree. A subagent's bad output then pollutes tracked files, breaks the restore point, and makes rollback impossible. Isolation — a separate linked workspace on its own branch — quarantines in-progress work so the main branch stays clean and every change is recoverable by discarding or merging the isolated branch.

This skill is the **canonical "how"** for getting an isolated workspace. It exists as a standalone methodology so the Pre-Flight check (and any subagent) can invoke one discipline rather than re-deriving the isolation decision each time. The PM's Pre-Flight references this skill; this skill does not reference the PM — it is the leaf of that dependency.

The core principle is **detect before create, prefer native before git, never fight the harness.** The three worst failure modes this prevents: (1) creating a nested worktree inside one that already exists, (2) using `git worktree add` when the harness already provides isolation (creating phantom state the harness cannot see or manage), and (3) leaving orphaned worktrees that accumulate on disk after the work is done.

## When to Isolate

Isolation is not free — it costs a directory, a branch, and setup time. Isolate when the work is **worth quarantining**; skip it when the cost exceeds the risk.

### Isolate when ANY signal is present

- **Risky work** — touching auth, payments, secrets, migrations, schema, deployment configs, or anything with no clean rollback in the main tree
- **Large work** — multi-file, multi-module, or multi-dispatch sequences where partial failure must not corrupt the main branch
- **Refactors** — structural changes (monolith to services, API paradigm shift, framework migration) where intermediate states are broken
- **Parallel work** — two or more subagents (or the user) writing simultaneously; isolation per work-stream prevents cross-contamination
- **Exploratory / disposable work** — spike, prototype, "let me try an approach" where the whole point is that it may be thrown away

### Do NOT bother isolating

- **Read-only work** — investigation, scoping, reviewing, summarizing. No files change, no isolation needed.
- **Single-file, low-risk edits** — a one-line config tweak, a typo fix, a doc edit. The blast radius is smaller than the worktree setup overhead.
- **The harness already isolated you** — see Step 0. If detection shows you are already in an isolated workspace, creating another is the #1 failure mode.
- **Tasks modifying files outside the project tree** — system configs, global packages. Git worktree isolation does not apply there; route through the PM's outside-project warning instead.

### Anti-Pattern: "This Is Too Small To Isolate"

Once the PM (or subagent) has decided the task is risky/large/parallel enough to invoke this skill, the isolation discipline runs in full. Do not rationalize skipping it mid-flow because the task *seems* small after all. The decision to skip is made **before invocation**, at triage — same model as brainstorming. After invocation, the steps below apply.

## The HARD GATE

**No file modification begins until isolation state is confirmed.** This gate is about confirming where work will land, not about dispatch ownership. The gate lifts the moment Step 0 reports an isolation state and, if the state is "normal repo," Step 1 has created the worktree (or the user has explicitly declined). Work that starts modifying files before this confirmation is the root cause of every "my main branch got polluted" incident.

## Core Process

Run these steps in order. Each is a discipline, not a suggestion.

### Step 0: Detect Existing Isolation

**Before creating anything, determine whether you are already isolated.** Creating a worktree inside an existing worktree is the single most common isolation failure.

```bash
GIT_DIR=$(cd "$(git rev-parse --git-dir)" 2>/dev/null && pwd -P)
GIT_COMMON=$(cd "$(git rev-parse --git-common-dir)" 2>/dev/null && pwd -P)
BRANCH=$(git branch --show-current)
```

**Submodule guard.** `GIT_DIR != GIT_COMMON` is also true inside a git submodule. Before concluding "already in a worktree," rule out the submodule case:

```bash
# If this returns a path, you are in a submodule, not a worktree — treat as normal repo
git rev-parse --show-superproject-working-tree 2>/dev/null
```

**Interpret the result:**

| Detection result | Isolation state | Next action |
|------------------|-----------------|-------------|
| `GIT_DIR != GIT_COMMON` (and not a submodule) | Linked worktree — **already isolated** | Skip to Step 2 (Project Setup). Do NOT create another worktree. |
| Harness-managed sandbox detected (the environment advertises a session/sandbox isolation mechanism) | Already isolated | Skip to Step 2. Never fight the harness. |
| `GIT_DIR == GIT_COMMON`, or in a submodule, or not a git repo | Normal repo — **not isolated** | Proceed to Step 1. |

**Report the state** so the dispatch chain knows provenance (this matters at cleanup time):
- On a branch: *"Already isolated at `<path>` on branch `<name>`."*
- Detached HEAD: *"Already isolated at `<path>` (detached HEAD, externally managed). Branch creation needed at finish time."*

**If no git repo exists at all:** worktree isolation does not apply. Route to the PM's "No Git Repo" warning — the user should decide whether to `git init` before proceeding.

### Step 1: Create Isolated Workspace (only if Step 0 says "normal repo")

You have two mechanisms. Try them **in this order**. Skipping 1a and jumping to 1b is the #2 failure mode.

#### 1a. Native worktree / session tools (preferred)

Check whether the harness already provides a way to create an isolated workspace — a tool named `EnterWorktree`, `WorktreeCreate`, a `/worktree` command, a `--worktree` flag, or a session/sandbox creation mechanism. If it does, **use it** and skip to Step 2.

Native tools handle directory placement, branch creation, and cleanup automatically. Using `git worktree add` underneath them creates phantom git state the harness cannot see or manage — which breaks the harness's own cleanup logic and leaves orphaned directories.

**Only proceed to 1b if no native mechanism is available.**

#### 1b. Git worktree fallback

Use this **only** when Step 1a does not apply. Create the worktree manually via git.

**Consent first.** Before creating, if the user has not already declared a worktree preference in their instructions, ask:

> *"Would you like me to set up an isolated worktree? It protects your current branch from changes."*

Honor any declared preference without asking. If the user declines, work in place and skip to Step 2 — isolation is opt-in for normal-repo work, not forced.

**Directory selection** (priority order — explicit preference beats observed state):

1. A declared worktree directory from the user's instructions → use it, do not ask.
2. An existing project-local worktree dir → reuse it. Check `.worktrees` (preferred, hidden) then `worktrees`. If both exist, `.worktrees` wins.
3. If nothing else guides you, default to `.worktrees/` at the project root.

**Safety verification (project-local dirs only).** Before creating, confirm the directory is gitignored so worktree contents never get tracked:

```bash
git check-ignore -q .worktrees 2>/dev/null || git check-ignore -q worktrees 2>/dev/null
```

If **not** ignored: add it to `.gitignore` and commit that change first, then proceed. Committing worktree contents into the repo is a pollution failure this step exists to prevent.

**Create the worktree:**

```bash
project=$(basename "$(git rev-parse --show-toplevel)")
path=".worktrees/$BRANCH_NAME"
git worktree add "$path" -b "$BRANCH_NAME"
cd "$path"
```

**Sandbox fallback.** If `git worktree add` fails with a permission error (the sandbox denied it), tell the user the sandbox blocked worktree creation and that work will proceed in the current directory instead. Then run setup and baseline tests in place. Do not silently retry — a denied worktree is a signal the harness has its own isolation story.

### Step 2: Project Setup

In the isolated workspace, auto-detect and run the project's dependency setup so the workspace is buildable:

```bash
if [ -f package.json ]; then npm install; fi
if [ -f Cargo.toml ]; then cargo build; fi
if [ -f requirements.txt ]; then pip install -r requirements.txt; fi
if [ -f pyproject.toml ]; then poetry install; fi
if [ -f go.mod ]; then go mod download; fi
```

Skip dependency install if no recognized manifest exists.

### Step 3: Verify Clean Baseline

Run the project's test suite to confirm the workspace starts from a known-good state. **This is mandatory** — without a green baseline, you cannot later tell whether a failing test is your change or a pre-existing breakage.

```bash
npm test | cargo test | pytest | go test ./...   # whichever applies
```

- **Tests pass:** Report ready, with the test count.
- **Tests fail:** Report the failures and ask whether to proceed or investigate the pre-existing break first. Do not start feature work on a red baseline without explicit acknowledgment.

### Report

```
Isolated workspace ready at <full-path>
Isolation mechanism: <native-tool | git worktree | in-place (declined/sandbox)>
Baseline: <N> tests, 0 failures
Ready to begin work on <task>
```

## Cleanup

Worktrees accumulate. Orphaned ones clutter disk, confuse `git worktree list`, and can hold stale branches that block operations on the main repo. Cleanup is part of the methodology, not an afterthought.

### Provenance rule (HARD)

**dev-team only removes worktrees it created** — those under `.worktrees/`. Never remove:
- Harness-managed sandboxes or sessions (the harness owns their lifecycle).
- Worktrees the user created themselves.
- Linked worktrees that Step 0 detected as pre-existing isolation.

Before removing, verify provenance with `git worktree list` — confirm the path is under `.worktrees/` and was created by this workflow.

### When cleanup fires

Cleanup runs at **branch-finishing** (merge or discard), not before. It is invoked by the PM's Post-Task branch-finishing flow:

| Finish choice | Cleanup action |
|--------------|----------------|
| Merge (A) | After merge, remove the dev-team-created worktree dir. |
| Discard (D) | After confirming with the user (destructive), discard changes and remove the worktree. |
| Push + PR (B), Keep as-is (C) | Leave the worktree in place — the branch is still alive. |

### How to clean up

```bash
# From the main repo (not from inside the worktree):
git worktree remove .worktrees/<branch-name>
git branch -d <branch-name>   # only after merge; use -D only on explicit discard
```

If `git worktree remove` complains about untracked or modified files, that means the work was not actually finished — investigate before forcing. `git worktree remove --force` is reserved for the explicit-discard path after user confirmation.

## Quick Reference

| Situation | Action |
|-----------|--------|
| Step 0 detects linked worktree | Skip creation, proceed to setup |
| Step 0 detects harness sandbox | Skip creation, proceed to setup |
| In a submodule | Treat as normal repo (run the submodule guard) |
| Native worktree tool available (1a) | Use it, skip 1b |
| No native tool | Git worktree fallback (1b) |
| `.worktrees/` exists | Reuse it (verify ignored) |
| `worktrees/` exists | Reuse it (verify ignored) |
| Both exist | Use `.worktrees/` |
| Neither exists, no guidance | Default `.worktrees/` |
| Project-local dir not gitignored | Add to `.gitignore`, commit, then create |
| `git worktree add` permission-denied | Sandbox fallback, work in place |
| Baseline tests fail | Report failures, ask before proceeding |
| No package manifest | Skip dependency install |
| Cleanup: merge or discard of dev-team worktree | Remove via `git worktree remove` |
| Cleanup: harness/user worktree | Do NOT remove |

## Common Mistakes

### Fighting the harness

- **Problem:** Using `git worktree add` when the platform already provides isolation, or removing a harness-managed sandbox.
- **Fix:** Step 0 detects existing isolation; Step 1a defers to native tools. The provenance rule blocks removing anything dev-team did not create.

### Skipping detection

- **Problem:** Creating a nested worktree inside an existing one, producing a confusing pile of linked worktrees.
- **Fix:** Always run Step 0 before creating anything. Detection is cheap; nested worktrees are expensive.

### Jumping straight to git

- **Problem:** Reaching for `git worktree add` when a native `EnterWorktree`-style tool exists, creating phantom state.
- **Fix:** Step 1a is the first creation mechanism. Only fall through to 1b when 1a genuinely does not apply.

### Skipping ignore verification

- **Problem:** Worktree contents get tracked, polluting `git status` and risking an accidental commit of an entire working tree.
- **Fix:** Always run `git check-ignore` before creating a project-local worktree. If not ignored, fix `.gitignore` first.

### Assuming directory location

- **Problem:** Inconsistency with project conventions — worktrees scattered across multiple paths.
- **Fix:** Follow the priority order: declared preference > existing dir > default `.worktrees/`.

### Proceeding with failing tests

- **Problem:** Cannot distinguish new bugs from pre-existing breakage later in the work.
- **Fix:** Step 3 is mandatory. Report failures and get explicit permission to proceed on a red baseline.

### Orphaning worktrees

- **Problem:** Work finishes, the branch merges, the worktree stays on disk forever.
- **Fix:** Cleanup runs at branch-finishing for merge/discard choices. Provenance-verified removal only.

## Red Flags — Stop

- Creating a worktree when Step 0 detects existing isolation
- Using `git worktree add` when a native worktree tool is available
- Skipping Step 1a and jumping to Step 1b's git commands
- Creating a project-local worktree without verifying it is gitignored
- Skipping the baseline test verification
- Proceeding with failing baseline tests without asking
- Removing a harness-managed sandbox or a user-created worktree
- Removing any worktree without verifying provenance via `git worktree list`
- Forcing worktree removal (`--force`) outside the explicit-discard path
