---
name: systematic-debugging
description: Use when encountering any bug, test failure, or unexpected behavior — before proposing any fix. Enforces root-cause investigation (reproduce → isolate → root cause → minimal fix → verify), never symptom patching. Backed by a Code Reviewer PASS/FAIL gate.
---

# Systematic Debugging

## Overview

Random fixes waste time and create new bugs. Symptom patches mask underlying issues and return later. dev-team treats debugging as a discipline, not a guess-and-check loop, and — critically — **backs that discipline with an externally-enforced review gate** rather than relying on self-discipline.

**Core principle:** ALWAYS find the root cause before attempting any fix. A fix without root-cause evidence is not a fix; it is a guess.

**Violating the letter of this process is violating the spirit of debugging.**

## The Iron Law

```
NO FIXES WITHOUT ROOT-CAUSE INVESTIGATION FIRST
```

Phase 1 (Root Cause) must complete before any fix is proposed, written, or dispatched. There are no exceptions for "simple" bugs, emergencies, or "obvious" causes.

## When to Use

Use for ANY technical issue, on ANY bug-fix / test-failure / unexpected-behavior task:

- Test failures
- Production bugs
- Unexpected behavior
- Performance problems
- Build failures
- Integration issues
- Flaky / non-deterministic failures

**Who invokes this skill:**
- **Project Manager** — references it in every bug-fix dispatch (the PM's bug-fix workflow names this skill as the discipline the Code Developer must follow).
- **Code Developer** — self-invokes when reproduction or root-cause work is needed; this skill IS the coder's bug-fix loop.
- **DevOps Engineer / Data Engineer** — when their task is a bug fix, they follow the same discipline.
- **Code Reviewer** — enforces the contract below as a PASS/FAIL gate (does not invoke the loop; checks its evidence).

**Use ESPECIALLY when:**
- Under time pressure (emergencies make guessing tempting — systematic is faster than thrashing)
- "Just one quick fix" seems obvious
- You have already tried multiple fixes
- The previous fix did not work
- You don't fully understand the issue

**Do NOT skip when:**
- The issue seems simple (simple bugs have root causes too; the process is fast for simple bugs)
- You are in a hurry (rushing guarantees rework)
- A manager/user wants it fixed NOW (systematic resolves it faster than a guess loop)

## The Four Phases

Complete each phase before proceeding to the next. The output of Phases 1-3 is evidence that the Code Reviewer will demand (see the Reviewer Gate below).

### Phase 1 — Root Cause Investigation

BEFORE attempting ANY fix:

1. **Read errors completely.** Do not skim past errors or warnings — they often contain the exact solution. Read stack traces to the end. Note line numbers, file paths, error codes.
2. **Reproduce consistently.** Can you trigger it reliably? What are the exact steps? Does it happen every time? If it is not reproducible, gather more data — do not guess. A bug you cannot reproduce is a bug you cannot verify fixed.
3. **Check recent changes.** What changed that could cause this? Review recent commits and diffs (via the allowed tools). New dependencies, config changes, environmental differences.
4. **Gather evidence in multi-component systems.** When the system has multiple components (API → service → database, CI → build → signing), add diagnostic instrumentation at EACH component boundary before proposing fixes: log what enters and exits each component; verify environment/config propagation; check state at each layer. Run once to gather evidence showing WHERE it breaks, then investigate that specific component.
5. **Trace data flow backward.** When the error is deep in a call stack, trace the bad value to its origin: where does it originate? What called this with the bad value? Keep tracing up until you find the source. Fix at the source, not at the symptom.

**Exit criterion for Phase 1:** a written root-cause statement — "The root cause is X, because evidence Y." If you cannot state this, you have not finished Phase 1.

### Phase 2 — Pattern Analysis

Find the pattern before fixing:

1. **Find working examples.** Locate similar working code in the same codebase. What works that resembles what is broken?
2. **Compare against references completely.** If implementing a known pattern, read the reference implementation in FULL — every line. Do not skim. Partial understanding guarantees bugs.
3. **Enumerate every difference.** What differs between working and broken? List each one, however small. Do not assume "that can't matter."
4. **Understand dependencies.** What other components does this need? What settings, config, environment? What assumptions does it make?

### Phase 3 — Hypothesis and Testing

Scientific method, one variable at a time:

1. **Form a single, specific hypothesis.** State it explicitly: "I think X is the root cause because Y." Write it down. Be specific, not vague.
2. **Test minimally.** Make the SMALLEST possible change that tests the hypothesis. One variable at a time. Do not fix multiple things at once.
3. **Verify before continuing.** Did it work? Yes → Phase 4. No → form a NEW hypothesis. Do NOT stack fixes on top of a failed one.

### Phase 4 — Implementation

Fix the root cause, not the symptom:

1. **Write the failing test FIRST.** Before any fix, write the simplest possible automated test that reproduces the issue and fails. This test becomes the regression test. (No test framework? Write a one-off reproduction script — but a real test is preferred.)
2. **Implement a single, targeted fix.** Address the root cause identified in Phase 1. ONE change. No "while I'm here" improvements. No bundled refactoring.
3. **Verify the fix.** The new test now passes. No other tests break. The original symptom is resolved.
4. **If the fix does not work:** STOP. Count how many fixes have been tried. If fewer than 3, return to Phase 1 and re-analyze with the new information. If 3 or more fixes have failed, see Escalation below — do not attempt fix #4.

### Escalation — 3+ Failed Fixes Means Wrong Architecture

If three or more fixes fail, this is NOT a failed hypothesis. It is a wrong architecture.

Signals:
- Each fix reveals new shared state / coupling / a problem in a different place.
- Fixes require "massive refactoring" to implement.
- Each fix creates new symptoms elsewhere.

When this happens, STOP fixing. Report BLOCKED to the Project Manager:

```
BLOCKED: Need Architecture Designer to reassess [component / pattern]
Reason: 3+ targeted fixes have failed following systematic-debugging. This indicates an architectural problem, not a localized bug.
Impact: The bug cannot be resolved by further fixes at the current level.
Alternative: none — architectural reassessment is required.
```

The PM may then dispatch the Architecture Designer (whose output routes through the Architecture Reviewer). This is dev-team's structured replacement for "discuss with your human partner" — the escalation has a defined destination and a review gate.

## The Code Reviewer Gate (PASS/FAIL)

This is the surpass move. Where a self-discipline debugging methodology relies on the debugger's own rigor, dev-team **enforces the discipline with an independent reviewer**. The Code Reviewer treats the systematic-debugging contract as a hard PASS/FAIL blocker — the same weight as the TDD-compliance gate and the verification-evidence gate.

A bug-fix review FAILS automatically if ANY of these are missing:

1. **Root-cause statement.** The delivery doc must contain an explicit root-cause statement with evidence (the Phase 1 exit criterion). "Fixed the bug" without a stated root cause is an automatic FAIL.
2. **Regression test written from the failing case.** A test that fails BEFORE the fix and passes AFTER must exist in the delivery. A fix with no regression test is an automatic FAIL — the bug is not proven fixed and not guarded against recurrence.
3. **Singular, targeted fix.** The fix must address the stated root cause, not the symptom, and must not bundle unrelated changes ("while I'm here" refactors). A symptom patch or a bundled change is an automatic FAIL.

**What the Code Reviewer demands, concretely:**
- The root-cause statement (one or two sentences, with the evidence that supports it).
- The regression test path, plus confirmation it failed pre-fix and passes post-fix (fresh verification output — see `development-team:verification-before-completion`).
- The diff, narrow enough to be a single targeted fix.

If the Code Developer attempts to ship a bug fix without these three, the review FAILS and the work returns for revision. The discipline is externally enforced — it cannot be rationalized away under time pressure, because a second party checks it.

## Common Rationalizations

| Excuse | Reality |
|--------|---------|
| "The issue is simple, I don't need the process." | Simple issues have root causes too. The process is fast for simple bugs. |
| "Emergency — no time for the process." | Systematic debugging is FASTER than guess-and-check thrashing. |
| "Let me try this one fix first, then investigate." | The first fix sets the pattern. Do it right from the start. |
| "I'll write the test after confirming the fix works." | Untested fixes do not stick. The test is what proves the fix — and the Code Reviewer will fail you without it. |
| "Multiple fixes at once saves time." | You cannot isolate what worked, and you will introduce new bugs. |
| "The reference is too long; I'll adapt the pattern." | Partial understanding guarantees bugs. Read it completely. |
| "I can see the problem — let me fix it." | Seeing a symptom is not understanding the root cause. |
| "One more fix attempt" (after 2+ failures) | 3+ failures = architectural problem. Escalate, do not fix again. |

## Red Flags — STOP and Return to Phase 1

If you catch yourself thinking any of these, stop and restart at Phase 1:

- "Quick fix for now, investigate later."
- "Just try changing X and see if it works."
- "Add multiple changes and run the tests."
- "Skip the test, I'll verify manually."
- "It's probably X, let me fix that."
- "I don't fully understand this, but it might work."
- "Here are the main problems:" (listing fixes without investigation).
- Proposing solutions before tracing data flow.
- "One more fix attempt" when you have already tried two or more.
- Each fix reveals a new problem in a different place.

## Quick Reference

| Phase | Key Activities | Exit Criterion |
|-------|---------------|----------------|
| **1. Root Cause** | Read errors, reproduce, check changes, gather evidence, trace data flow | A stated root cause with supporting evidence |
| **2. Pattern** | Find working examples, compare completely, enumerate differences | The relevant differences identified |
| **3. Hypothesis** | Form one specific theory, test minimally, one variable at a time | Hypothesis confirmed or replaced |
| **4. Implementation** | Write failing regression test, apply single targeted fix, verify | Test passes, no regressions, symptom resolved |

**Reviewer gate (always on for bug-fix tasks):** root-cause statement + regression test + targeted fix → PASS. Any missing → FAIL.

## Related Skills

- **`development-team:verification-before-completion`** — the fix is not "done" until fresh command output confirms the regression test passes and no other tests break. The Code Reviewer checks both gates.
- **`development-team:brainstorming`** — when the 3+-fix escalation fires and the Architecture Designer is engaged, the redesign of the offending component may route through brainstorming before architecture work begins.
