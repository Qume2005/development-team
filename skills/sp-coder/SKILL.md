---
name: sp-coder
description: Superpowers bridge for Code Developer — uses TDD, debugging, verification, plan execution, and git worktrees
---

# Coder Superpowers Bridge

This skill enhances the Code Developer with superpowers. **Requires superpowers plugin.** If superpowers is NOT available, stop here and work normally.

## Check Availability

Look at the available skills list. If you see skills like `superpowers:test-driven-development`, superpowers is installed. If not, skip this skill entirely.

## ⚡ IMMEDIATE ACTION ON LOAD

If you just loaded this skill as part of your dispatch prompt, invoke this superpowers skill RIGHT NOW via the Skill tool — do not wait until you start coding:

**Step 1:** Invoke `superpowers:test-driven-development` via Skill tool. TDD is your core discipline — you write tests BEFORE implementation. Loading it now ensures the TDD framework is active from the start.

**Step 2:** You are now prepared. Follow the TDD skill's process: write failing test → minimal implementation → pass → refactor → repeat.

**Note:** Other superpowers skills (systematic-debugging, verification-before-completion, executing-plans, using-git-worktrees) are situational — invoke them only when those situations arise, not at setup time.

## Enhanced Workflows

### Before Writing Implementation Code
Invoke `superpowers:test-driven-development` — write tests first, then implement to pass them.

### When Executing a Written Plan
Invoke `superpowers:executing-plans` — follow the structured execution pattern with review checkpoints.

### When You Hit a Bug or Test Failure
Invoke `superpowers:systematic-debugging` — diagnose before fixing, never guess.

### Before Claiming Work Is Complete
Invoke `superpowers:verification-before-completion` — run tests, verify output, evidence before assertions.

### Before Starting Feature Work Needing Isolation
Invoke `superpowers:using-git-worktrees` — create an isolated workspace.

### When You Receive Code Review Feedback
Invoke `superpowers:receiving-code-review` — don't blindly implement suggestions, verify them first.

### Before Claiming Implementation Is Ready for Merge
Invoke `superpowers:requesting-code-review` — verify work meets requirements before requesting review.

### When Implementation Is Complete, Tests Pass, Ready to Integrate
Invoke `superpowers:finishing-a-development-branch` — guides merge, PR, or cleanup decisions.

### When Creating or Editing Skill Files
Invoke `superpowers:writing-skills` — follow structured skill creation/editing patterns.

### Fallback
If superpowers invocation fails or is unavailable, code and test using your standard role instructions.

## Review Routing — PM's Responsibility

`superpowers:requesting-code-review` suggests dispatching a code reviewer when your work is complete. In development-team, **review dispatch is the PM's job, not yours.**

**What you do:**
1. Complete your implementation + unit tests
2. Run verification per `superpowers:verification-before-completion`
3. Return your standard summary to the PM (Files changed + tests + passing + Superpowers used)
4. The PM will dispatch Code Reviewer if needed

**What you do NOT do:**
- Do NOT dispatch a Code Reviewer yourself
- Do NOT invoke `superpowers:requesting-code-review` to create a review
- Do NOT dispatch any generic reviewer subagent

If `requesting-code-review` suggests you "dispatch a reviewer" or "get feedback," remember: in development-team, you report completion to the PM, and the PM handles the review. This ensures:
- TDD Compliance Gate is checked (Code Reviewer's responsibility)
- Review feedback is saved to the correct delivery directory
- PM tracks the review status and manages the dependency chain

## Verification Output — Return Format Only

When using `superpowers:verification-before-completion`:
1. Follow ALL verification steps (run tests, check outputs, verify behavior)
2. Fix any issues found during verification
3. Return ONLY the standard development-team return format:
   ```
   Files changed: [list]
   Unit tests: N written
   All tests passing: YES / NO
   Superpowers used: [e.g., "sp-coder: TDD, verification"]
   Notes: [one sentence if anything unusual]
   ```

Do NOT include raw test output, command results, or verification details in your return summary. The PM absorbs verdicts (3-5 lines), not full reports.
