---
name: branch-finishing
description: Structured integration of completed, verified work — verify tests, detect the git environment, present merge/PR/keep/discard options, execute the user's choice, and clean up. The canonical "how" when implementation is done and it's time to integrate.
---

# Branch Finishing — Integration of Completed Work

> **Invokable as** `development-team:branch-finishing` via the Skill tool. Triggered by the PM (or a Code Developer at completion) once implementation is complete and all deliverables have passed review. This skill encodes the **process** of finishing; the **policy** (commit-message conventions, AI-attribution, ask-before-commit) lives in `skills/pm/SKILL.md` and the relevant agent definitions.

## Why This Exists

Implementation being "done" is not the same as the work being **integrated**. The moment between "tests pass, review passed" and "the work is actually merged or shipped" is where work is most easily lost, mis-merged, or left to rot on a feature branch. A bare `git commit` step assumes there is nothing to decide — but there is always something to decide: merge locally, open a PR, keep the branch, or throw the work away. And there is always an environment to account for: a normal repo, a linked worktree, a detached HEAD, or no git at all.

This skill replaces the ad-hoc "commit and we're done" step with a structured finish: **verify the work is actually done → detect the environment → present structured options → execute the chosen option → clean up.** It is the canonical methodology an agent follows when the implementation phase is over and the integration phase begins.

The terminal state is **"branch finished"** — the work is merged, pushed, kept, or discarded according to an explicit user choice, with provenance-safe cleanup. It is not another skill invocation, not a plan, not more code. It is the back door to dev-team's execution pipeline, symmetric to brainstorming's front door.

## Scope Boundary — Process, Not Policy

This skill encodes the **process** of finishing. It does **not** encode the **policy** that governs commits and merges:

- **Commit-message conventions** (neutral messages, no AI attribution, ask-user-before-commit) are RULES. They live in `skills/pm/SKILL.md` and the agent definitions, not here.
- **Co-authoring policy** (AI `Co-Authored-By` default-off) is a RULES decision owned by `pm.md`.
- **Worktree-creation policy** (where to create worktrees, what to gitignore) is a RULES decision owned by `pm.md`'s pre-flight.

This skill's job is the integration flow. Where a commit or push happens inside the flow, the skill says **"follow the project's commit conventions"** and defers the specifics to the policy layer. Do not duplicate hard commit-message rules here — that bloats the methodology and creates a second source of truth that drifts from `pm.md`.

## When to Invoke

**Invoke when ALL of these are true:**

- Implementation is complete (the Code Developer has returned and the Code Reviewer has PASSED)
- The verification gate (`development-team:verification-before-completion`) has been satisfied with fresh evidence
- The next step is to integrate the work into the larger context (merge, PR, or explicit decision to keep/discard)

**Do NOT invoke for:**

- Mid-task commits on a long-lived branch (that is a checkpoint, not a finish — the work isn't integrated)
- Work that is still under review (review PASS is a precondition)
- Work where the verification gate has not passed (the verify step below re-checks, but the gate must already be green)
- Tasks that produced no code/file changes (a pure-analysis or read-only task has nothing to integrate)

### Anti-Pattern: "Just Commit It"

The most common shortcut is skipping the structured options and jumping straight to `git commit` (or `git push`) on the agent's own initiative. This exports the integration decision from the user to the agent. The user may want to keep the branch for further iteration, may want a PR rather than a local merge, or may want to discard an experiment. Defaulting to "commit and move on" silently makes that choice for them. **Once this skill is invoked, the options menu runs — there is no "just commit it" shortcut.**

## The HARD GATE

**No integration action (merge, push, delete, discard) executes until the user explicitly chooses an option.** The agent presents the options menu and waits. The gate lifts on an explicit user choice — not on silence, not on "they didn't object," not on "they seemed eager to be done." This mirrors brainstorming's no-implementation-before-approval gate, applied to the integration side.

The one exception: if the user pre-declared their choice earlier in the workflow (e.g., "when this is done, just merge it"), the pre-declaration counts as the explicit choice, and the agent may execute without re-asking. If there is any doubt about whether the pre-declaration still holds, re-ask.

## Core Process

Run these steps in order. Each is a discipline, not a suggestion. The PM delegates every git operation to an Intern; a Code Developer self-invoking this skill executes the commands directly within its own scope.

### 1. Verify (HARD GATE)

Before presenting any options, confirm the work is actually done. Apply `development-team:verification-before-completion`: run the project's full test command fresh, read the complete output, and confirm zero failures with **fresh evidence** — a test result from ten minutes ago, or a claim of "tests pass" without command output, is stale and forbidden.

**If tests fail:** the finish does not proceed. The work returns to the author (Code Developer) with the failure evidence. Report:

> *"Cannot finish — N test(s) failing. Returning the work for fixes before integration. Failures: [summary]."*

**If tests pass:** continue to Step 2. Do not present options on the basis of a claim or a stale result.

> **PM-tier note:** The verification is delegated to an Intern, which runs the test command, reads the full output, and reports the pass/fail verdict with the evidence. The PM absorbs only the verdict.

### 2. Detect the Environment

Determine the git state before presenting options — the menu and the cleanup both depend on it. Report:

- **Is this a git repository at all?** (`git rev-parse --is-inside-work-tree`)
- **What is the current branch?** (`git branch --show-current`)
- **Is this a normal repo, a linked worktree, or a detached HEAD?** Compare `git rev-parse --git-dir` against `git rev-parse --git-common-dir` — equal means a normal repo; unequal means a linked worktree; `HEAD` detached (no branch name) means a detached-HEAD worktree.
- **What is the base/default branch?** Try `main`, then `master`, then ask the user.
- **Is there an upstream remote?** (`git remote` non-empty)
- **Are there uncommitted changes?** (`git status --porcelain`)

| State | Menu shown | Cleanup applies |
|-------|-----------|-----------------|
| Normal repo, named branch | Standard 4 options | No worktree to clean up |
| Linked worktree, named branch | Standard 4 options | Provenance-based (Step 5) |
| Detached HEAD (externally managed) | Reduced 3 options (no local merge) | Never (host owns the workspace) |
| No git repo | Skip to "No Git Repo" below | N/A |

> **PM-tier note:** Delegated to an Intern, which runs the detection commands and reports the six fields above. The PM absorbs the result.

### 3. Determine the Base Branch

Identify the branch the work should merge into or PR against. Try `git merge-base HEAD main` (then `master`). If ambiguous or multi-branch, **ask the user** — do not guess. A misidentified base branch merges or PRs against the wrong line of development, which is expensive to undo.

### 4. Present Options to the User

**Normal repo or named-branch worktree — present exactly these 4 options:**

> *"All tasks completed, reviewed, and verified. How would you like to finish this branch?*
> - *(A) Merge into `[base_branch]` locally and delete the feature branch*
> - *(B) Push and open a pull request*
> - *(C) Keep the branch as-is (commit only, no merge)*
> - *(D) Discard the branch (throw the work away)"*

**Detached HEAD — present exactly these 3 options (local merge is impossible on a detached HEAD):**

> *"All tasks completed, reviewed, and verified. You're on a detached HEAD (externally managed workspace). How would you like to finish?*
> - *(A) Push as a new branch and open a pull request*
> - *(B) Keep the work as-is (I'll handle it later)*
> - *(C) Discard this work"*

**Do not add explanation or rationale to the options.** Keep them concise. The user picks one; the agent does not editorialize. Wait for an explicit choice — the HARD GATE applies.

### 5. Execute the Chosen Option

Git operations are always delegated (PM → Intern) or executed directly (Code Developer self-invoking). **Commit-message and co-authoring policy is deferred to `skills/pm/SKILL.md`** — follow the project's conventions; this skill does not duplicate them.

| Choice | Execution |
|--------|-----------|
| **A — Merge locally** (normal/worktree) | Commit uncommitted changes (if any) → checkout base → pull (if remote) → merge the feature branch → **re-run tests on the merged result** → only after tests pass, clean up the worktree (Step 6) → delete the feature branch. |
| **A — Push + PR** (detached HEAD) | Commit (if uncommitted) → create a named branch from HEAD → push with `-u` → surface the PR URL / hand off to the user's PR tool. Do NOT clean up the workspace (user needs it for PR iteration). |
| **B — Push + PR** (normal/worktree) | Commit (if uncommitted) → push with `-u` → surface the PR URL / hand off to the user's PR tool. Do NOT clean up the worktree (user needs it for PR iteration). |
| **C — Keep as-is** | Commit (if uncommitted). Leave the branch/workspace in place. Report the branch name and worktree path so the user can find it later. |
| **D — Discard** (destructive) | **Confirm first** (see below) → discard changes → if in a dev-team-created worktree, remove it (Step 6) → force-delete the branch. |

**Merge ordering is load-bearing:** merge first, verify tests on the merged result, *then* clean up the worktree, *then* delete the branch. Deleting the branch before removing the worktree fails (the worktree still references it); cleaning up before verifying the merge succeeds destroys the rollback path.

**Discard confirmation (required for option D):** destructive actions require explicit typed confirmation. Present exactly what will be lost — the branch name, the commit list, and the worktree path — and require the user to type `discard` (or an equivalent explicit confirmation). Silence or "yes" is not enough; the typed token makes the destructiveness unambiguous.

### 6. Clean Up

Cleanup runs **only for merge (A) and discard (D)** in a worktree environment. Push/PR (B) and keep-as-is (C) always preserve the workspace — the user needs it for iteration.

**Provenance rule (HARD):** dev-team removes only the worktrees *it created* (under `.worktrees/` or equivalent gitignored dir). It **never** removes:
- Harness-managed sandboxes (the host owns these)
- User-created worktrees
- Worktrees whose path is not under a dev-team-managed directory

Before removing, verify provenance: `git worktree list` confirms which worktrees exist and their paths. If the path is not clearly dev-team-created, **leave it in place** and report that the workspace is externally managed.

When removing a dev-team-created worktree:
1. `cd` to the main repo root first (running `git worktree remove` from inside the worktree being removed fails silently).
2. `git worktree remove <path>`.
3. `git worktree prune` (self-healing — clears any stale registrations).

### No Git Repo

If the pre-flight check (run earlier, in `pm.md`) revealed no git repo and the user declined to initialize one, **ask again at finish time:**

> *"Task is done. You still have no git repository, which means this work is not under version control and cannot be recovered if lost. I recommend initializing one now with an initial commit. Shall I do that? (Y/N)"*

If yes → Intern runs `git init && git add -A && git commit -m "Initial commit"` (following the project's commit conventions). If no → deliver the work as-is and note the un-versioned state.

## Conscious Framing

This skill is **parity with the source methodology, natively owned** at the process level. The surpass over a bare commit step comes from two places:

1. **The options menu makes integration an explicit user decision**, not an agent default. The source skill's structured 4-option (or 3-option for detached HEAD) menu is preserved verbatim in shape — it is a well-tested forcing function against silent integration choices.
2. **The provenance rule and the verify-before-options gate** are enforced as HARD gates, not suggestions. The source methodology states them as "always/never" lists; dev-team elevates them to gates that block the flow until satisfied.

Where the source methodology bundles commit-message and co-authoring policy into the finish flow, dev-team deliberately **separates process from policy**: this skill owns the integration flow; `pm.md` owns the commit-message rules. This prevents the two from drifting and keeps each layer single-purpose.

## Quick Reference

| Step | Action | Output |
|------|--------|--------|
| 1 | Verify tests pass (fresh evidence) | Pass/fail verdict — fail returns work to author |
| 2 | Detect environment (repo/worktree/detached, branch, base, remote, uncommitted) | Six-field environment report |
| 3 | Determine base branch | Confirmed base branch (ask if ambiguous) |
| 4 | Present options menu (4 for normal/worktree, 3 for detached HEAD) | User's explicit choice |
| 5 | Execute chosen option (merge / push+PR / keep / discard) | Integrated (or kept/discarded) work |
| 6 | Clean up (merge & discard only, provenance-checked) | Removed dev-team worktree, pruned registrations |

| Option | Merge | Push | Keep Workspace | Delete Branch |
|--------|-------|------|----------------|---------------|
| A — Merge locally | yes | — | no (cleanup) | yes |
| B — Push + PR | — | yes | yes | — |
| C — Keep as-is | — | — | yes | — |
| D — Discard | — | — | no (cleanup) | yes (force) |

## Common Mistakes

- **Skipping the verify step.** "The Code Reviewer already passed, so tests must be fine." No. Review-pass is about code quality; the verify step re-runs the suite fresh to catch environment drift, partial commits, or a review that passed on a stale build. A finish on stale evidence is forbidden.
- **Presenting options before detecting the environment.** Showing the 4-option menu in a detached-HEAD workspace offers a local-merge option that is impossible to execute. Detect first, then present the menu that fits.
- **Adding explanation to the options.** "Option A merges locally, which means..." — no. The options are self-explanatory; editorializing biases the user's choice. Present them terse and wait.
- **Defaulting to commit-and-move-on.** Jumping straight to `git commit` without presenting the menu exports the integration decision from the user to the agent. Once invoked, the menu runs.
- **Cleaning up the workspace for push/PR or keep-as-is.** The user needs the workspace alive to iterate on PR feedback or to resume the branch later. Cleanup runs only for merge and discard.
- **Deleting the branch before removing the worktree.** `git branch -d` fails because the worktree still references the branch. Merge → remove worktree → delete branch, in that order.
- **Running `git worktree remove` from inside the worktree.** The command fails silently when the CWD is inside the worktree being removed. Always `cd` to the main repo root first.
- **Removing a harness-managed or user-created worktree.** The provenance check exists precisely to prevent this. If the path is not under a dev-team-managed directory, leave it.
- **Accepting silence or "yes" as discard confirmation.** Destructive actions require the typed token (`discard`) — it makes the irreversibility unambiguous. "Yes" is too easy to say by reflex.
- **Baking commit-message rules into this skill.** Neutral-message, no-AI-attribution, ask-before-commit are POLICY, owned by `pm.md`. This skill says "follow the project's conventions" and defers. Duplicating them here creates a second source of truth that drifts.

## Red Flags — Stop

- Presenting options before verifying tests pass with fresh evidence
- Presenting the 4-option menu in a detached-HEAD environment (offer the 3-option menu instead)
- Executing any integration action before the user explicitly chooses an option
- Merging without re-running tests on the merged result
- Deleting the branch before removing the worktree that references it
- Removing a worktree whose path is not dev-team-managed (harness or user-owned)
- Running `git worktree remove` from inside the worktree being removed
- Discarding work without the typed `discard` confirmation
- Committing with a message that violates the project's conventions (this is a policy violation — the conventions live in `pm.md`, not here, but the skill must defer to them)
- Finishing work whose verification gate has not passed — Step 1 re-checks, but the gate must already be green from the execution phase
