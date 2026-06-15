---
name: verification-before-completion
description: Run verification commands and confirm their actual output before claiming anything is done, fixed, or passing. Evidence before assertions, always. Invoked by every producer before a completion claim and enforced as a hard PASS/FAIL gate by the paired Reviewer.
---

# Verification Before Completion

## Overview

Claiming work is complete without running the verification command in the current turn is dishonesty, not efficiency. Evidence before claims, always.

**Violating the letter of this rule is violating the spirit of this rule.** Paraphrases, synonyms, and implications of success are all claims — the rule applies to all of them.

In dev-team this is not a self-discipline. It is a gate. A paired Reviewer will demand fresh evidence for every completion claim and will FAIL the review if it is missing, stale, or contradicted.

## The Iron Law

```
NO COMPLETION CLAIMS WITHOUT FRESH VERIFICATION EVIDENCE
```

If you have not run the verification command in the current turn and read its full output, you cannot make the claim. Period.

## When To Apply

**ALWAYS before** any of these appears in a delivery doc or return summary:

- "All tests passing: YES"
- "Build succeeds"
- "Bug fixed"
- "Requirements met"
- "Done" / "Complete" / "Passing"
- Any expression of satisfaction or positive statement about work state
- Committing, creating a PR, marking a task complete
- Moving to the next task

The rule covers exact phrases, paraphrases ("good to go", "ships clean"), and any implication of success. Different words do not exempt you.

## The Gate Function

Run this before stating any status or expressing satisfaction:

```
1. IDENTIFY — What command proves this claim?
2. RUN     — Execute the FULL command fresh, in the current turn.
3. READ    — Full output. Check the exit code. Count the failures.
4. VERIFY  — Does the output actually confirm the claim?
               NO  → state the actual status WITH the evidence.
               YES → state the claim WITH the evidence.
5. ONLY THEN make the claim.
```

Skipping any step is not verification.

## What Counts as Valid Evidence

**Valid evidence** = the actual command run this turn, plus its actual output (exit code, pass/fail counts, error text). The evidence must be recorded in the delivery doc or return summary alongside the claim it supports.

| Evidence | Why it counts |
|----------|---------------|
| Test command output showing 0 failures, run this turn | Directly proves "tests pass" |
| Build command exit 0, run this turn | Directly proves "build succeeds" |
| Original symptom test now passing, run this turn | Directly proves "bug fixed" |
| Line-by-line checklist mapping each requirement to verified behavior | Directly proves "requirements met" |

**Not evidence** (these are assertions):

- "Should pass now" / "Looks correct" / "I'm confident"
- A previous run from an earlier turn or session
- A summary, a memory, or a recollection of an output
- A linter pass presented as proof of build success (linter ≠ compiler)
- A Code Developer's "success" report presented as proof the work is done — Reviewers verify this independently
- Partial verification extrapolated to a full claim

## Common Failures

| Claim | Requires | Not Sufficient |
|-------|----------|----------------|
| Tests pass | Test command output: 0 failures, this turn | Previous run, "should pass" |
| Linter clean | Linter output: 0 errors, this turn | Partial check, extrapolation |
| Build succeeds | Build command: exit 0, this turn | Linter passing, logs look good |
| Bug fixed | Test of the original symptom: passes, this turn | Code changed, assumed fixed |
| Regression test works | Red-Green cycle verified (write → pass → revert fix → must fail → restore → pass) | Test passes once |
| Subagent completed | VCS diff showing the actual changes, read this turn | Subagent reports "success" |
| Requirements met | Line-by-line checklist verification | Tests passing (tests ≠ requirements) |

## Forbidden Wording

Do not use any of these (or a synonym) without accompanying fresh evidence:

- "should", "probably", "seems to"
- "Great!", "Perfect!", "Done!", "All good!"
- "I'm confident this works"
- Any wording implying success without having run verification this turn

## Rationalization Prevention

| Excuse | Reality |
|--------|---------|
| "Should work now" | RUN the verification. |
| "I'm confident" | Confidence is not evidence. |
| "Just this once" | No exceptions. |
| "Linter passed" | Linter is not the compiler. |
| "The subagent said success" | Verify independently — check the diff, run the tests. |
| "I'm tired / the work is over" | Exhaustion is not an excuse. |
| "A partial check is enough" | Partial proves nothing. |
| "I used different words" | Spirit over letter — paraphrases are still claims. |
| "The Reviewer will catch it anyway" | True, and the Reviewer will FAIL you. Save the round-trip. |

## The Reviewer Gate (How This Is Enforced)

dev-team enforces this skill as a hard PASS/FAIL gate, not honor-system compliance. What the paired Reviewer will demand:

1. **Presence** — does the delivery doc contain fresh verification evidence (actual command + actual output + exit code or failure count) for every completion claim? Missing evidence = automatic FAIL.
2. **Freshness** — was the command run in the current turn/session? Stale evidence from a prior turn, a prior session, or "before the last edit" = automatic FAIL.
3. **Consistency** — does the evidence match the claim? "All pass" while the recorded output lists failures, or "0 failures" while the output shows a non-zero count = automatic FAIL.
4. **Scope match** — does the evidence actually prove the specific claim? A linter run presented as proof the build compiles = automatic FAIL. Tests passing presented as proof requirements are met = automatic FAIL.

For bug-fix tasks specifically, the Reviewer also checks that a regression test exists and that root-cause evidence is present (the `systematic-debugging` contract).

**Implication for producers:** a Code Developer who writes "All tests passing: YES" in the delivery doc or return summary without the accompanying test-command output is wasting a review round. Attach the evidence up front.

## Key Patterns

**Tests:**
```
OK   [run test command] [see: 34/34 pass, exit 0] → "All 34 tests pass (exit 0)."
FAIL "Should pass now." / "Looks correct."
```

**Regression tests (TDD Red-Green):**
```
OK   write test → run (pass) → revert fix → run (MUST fail) → restore fix → run (pass).
     Record both runs as evidence.
FAIL "I've written a regression test." (without the red-green verification)
```

**Build:**
```
OK   [run build] [see: exit 0] → "Build passes (exit 0)."
FAIL "Linter passed." (linter does not check compilation)
```

**Requirements:**
```
OK   re-read the plan → build a checklist → verify each item against fresh evidence → report gaps or completion.
FAIL "Tests pass, so the phase is complete." (tests ≠ requirements)
```

**Subagent delegation:**
```
OK   subagent reports success → read the VCS diff → run the verification commands yourself → report the actual state.
FAIL trusting the subagent's report as proof.
```

## Quick Reference

Run the command. Read the full output. Confirm it supports the claim. Then — and only then — make the claim, with the evidence attached.

Claims without fresh evidence are treated as false. The paired Reviewer enforces this as a PASS/FAIL blocker, and the Project Manager treats satisfaction as a precondition to delivery.

## References

- Shared rules and review protocol: `skills/development-team/SKILL.md`
- PM deliver gate and red flags: `skills/pm/SKILL.md`
- Coder TDD + completion-claim discipline: `agents/coder.md`
- Reviewer verification-evidence gate: `agents/code-reviewer.md`
