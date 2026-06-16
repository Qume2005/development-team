---
name: supervisory-polling
description: Use when you (the PM) are about to set a polling cron because the harness will NOT auto-resume you — e.g. the Stop hook just blocked you with pending todos, or you are deliberately waiting on external state / a user who may not return. Defines how to make the cron SUPERVISE (check → escalate) rather than silently re-arm. Invoked at the moment the cron is being created.
---

# Supervisory Polling — Make the Cron Supervise

> **Invokable as** `development-team:supervisory-polling` via the Skill tool. Triggered at the moment the PM is about to create a polling cron while blocked.

## Why This Exists

A cron that fires can do one of two things: **supervise** (check whether the blocker cleared, then proceed or escalate) or **silently re-arm** (assume the cron itself is "waiting," re-create itself, and idle). The second case reproduces the exact failure the cron was meant to close: the harness will not notify you, so you set a cron — and then the cron also does not notify you. The blocker clears and nobody finds out; or it never clears and nobody escalates. A cron that merely exists supervises nothing.

This skill closes the gap between "a cron exists" and "the cron supervises." It is the methodology layer that sits on top of the mechanical Stop hook: **the hook forces a cron to exist; this skill guarantees that cron checks and escalates.**

> **The Iron Law of this skill:** a polling cron's prompt must encode a check-and-escalate checklist. A cron whose prompt is bare "Continue." or "check again" violates this skill and is rejected.

## When to Invoke

Invoke this skill at the moment you are about to call `CronCreate` for any of these signals:

| Signal | What it means |
|--------|---------------|
| The Stop hook just blocked you and told you to create a polling cron | You have pending todos and nothing will auto-resume you. |
| You are waiting on external state the harness will not notify you about | e.g. a Codex/long-running build, a CI run, a deploy, a webhook. |
| You are waiting on a person who may not return promptly | e.g. an unresponsive user, a human approval gate. |
| none of the above | Do NOT set a polling cron. A cron is not a general-purpose timer. |

DEFAULT: If you are unsure whether this skill applies, it applies — the cost of invoking when unnecessary is one extra read; the cost of skipping when necessary is silent re-arm.

> **Composition with the hook.** The Stop hook is *mechanical*: it makes "a cron must exist" impossible to bypass. This skill is *methodology*: it makes "the cron supervises" the behavior at fire time. They compose — the hook forces the moment; this skill defines what to do at it. Neither alone is sufficient.

## The Cron Is a Timer, Not a Supervisor

The cron fires and hands control back to you. **You** are the supervisor. The cron does not "wait for you" — it is an alarm clock. When the alarm goes off, you must do the supervisory work: concretely check the blocker, and if it has not cleared, actively notify someone. Re-arming the cron without doing that work is the failure mode this skill exists to prevent.

## Interval Choice (match the wait target; respect the 5-minute cache window)

The interval is not a free parameter — it is a cache-budget and busy-loop decision. The prompt cache window is ~300s (5 minutes). Polling faster than that window burns the cache re-reading unchanged state.

| Wait target | Interval | Why |
|-------------|----------|-----|
| Fast-changing external state you can afford to poll tight | ≥270s (just under the cache window) | Polls at the edge of the cache window; any faster and you re-read cached-unchanged state for no signal. |
| Fast-changing state, but you don't want to live at the edge | ≥1200s (20 min) | Commits to a coarser cadence; lets the cache fully expire between fires. Use this unless you have a reason to be tight. |
| A person (user, approver, human gate) | 1200s–1800s (20–30 min) | A long heartbeat. People are not pinged usefully every minute; a 20–30 min poll is a polite "still here?" cadence. |

**Explicitly rejected:**

| Rejected interval | Rationalization it closes | Why rejected |
|-------------------|---------------------------|--------------|
| 60s / 90s / 120s | "60s is fine, it's just polling" | Burns the prompt cache every fire; spends the whole budget re-reading unchanged state. Never poll faster than the cache window unless the state genuinely changes that fast AND you've committed to the ≥270s edge. |
| "Whatever feels responsive" | "I'll pick a number" | Interval must be tied to the wait target, not a vibe. State the target, pick the row. |

Decision ladder (run in order):

1. Waiting on a person? → 1200s–1800s.
2. Waiting on fast-changing state you must poll tight? → ≥270s (and only if you have justified why coarser won't do).
3. Waiting on anything else (a build, a deploy, a webhook)? → ≥1200s.
DEFAULT: 1200s. If unsure, coarse is safer than tight — a too-tight loop wastes cache and looks busy without supervising.

## The On-Fire Checklist (must be encoded in the cron prompt)

The cron prompt is the **only** instruction that travels with the cron. The re-invoked agent at fire time has no other context for what to do. Therefore the prompt must carry the full checklist, not a one-word verb. Encode these four steps in the prompt text:

1. **CHECK concretely whether the blocker cleared.** Name the check: read the build status, query the deploy state, test whether the file exists, look at the CI result. "Check" is a concrete action, not "see if it's done."
2. **If cleared → proceed with the pending todos.** Resume the blocked work immediately; do not re-arm.
3. **If NOT cleared → ESCALATE / actively notify.** Do not silently re-arm. Push a notification to the user — e.g. invoke `cc-alarm-larkcli` to send a Feishu message that the wait is ongoing — or, if escalation is not configured, report the continued block to the user in-thread. Silence is not a valid branch.
4. **Only re-arm with a stated reason, and lengthen the interval.** If you re-arm, state why the blocker is still expected to clear and bump the interval one step coarser to avoid a busy-loop.

### Example cron prompt (the on-fire checklist, made concrete)

For a build-wait, interval 1200s:

```
You were re-invoked by a polling cron because the PM was blocked on a build.
Supervisory on-fire checklist — perform in order:

1. CHECK concretely: read the build status (run: <the actual check command>).
   "Check" means run this command and read its output, not "see if it's done."
2. If the build SUCCEEDED → proceed with the pending todos immediately. Do not re-arm.
3. If the build is STILL RUNNING or FAILED → ESCALATE: invoke cc-alarm-larkcli to
   push a Feishu message "Build <id> still blocked at <time>, pending todos waiting."
   Then re-arm this cron at 1800s (coarsen the interval) with a one-line stated reason.
4. Re-arm only with a stated reason, never reflexively.

Do NOT silently re-arm. Do NOT assume the user will notice on their own.
```

For a person-wait, interval 1500s:

```
You were re-invoked by a polling cron because the PM is waiting on a human
(<who>, <what they need to decide/do>).
Supervisory on-fire checklist:

1. CHECK concretely: has the user responded in-thread or taken the action? (look)
2. If YES → proceed with the pending todos.
3. If NO → ESCALATE: invoke cc-alarm-larkcli to nudge via Feishu
   ("Still waiting on <X>; blocking <todos>"). Then re-arm at 1800s.
4. Re-arm only with a stated reason.

Silence is not a branch. Nudging a person every poll is the polite long-heartbeat
cadence this wait calls for.
```

> **Why correct (rationale line):** the checklist travels with the cron because the re-invoked agent has no other context at fire time; encoding check-and-escalate in the prompt is the only way to guarantee supervision survives across invocations.

## Anti-Pattern: Silent Re-Arm

**Anti-pattern — Silent Re-Arm:** a cron whose prompt is bare `"Continue."`, `"check again"`, `"resume"`, or any one-word verb with no check-and-escalate structure. This reproduces the silent-waiting failure under a new name: the cron exists (satisfying the Stop hook), fires on schedule, and the re-invoked agent re-arms without ever checking or escalating — indistinguishable from no supervision at all.

**Target:** a cron whose prompt encodes the full on-fire checklist (CHECK concretely → if cleared proceed → if not escalate → re-arm only with stated reason and a coarsened interval).

Even if framed as any of these, **still no**:

| Rationalization | Rejection |
|-----------------|-----------|
| "The cron is doing the waiting for me." | No — the cron is a timer; you are the supervisor. Re-arm-without-check is the named anti-pattern. |
| "I'll just re-arm and check next time." | No — "next time" re-defers forever. Each firing must CHECK now; re-arm requires a stated reason and a coarsened interval. |
| "The user will see it finish on their own." | No — the whole point of the cron is that the harness will NOT notify. If-not-cleared MUST escalate (e.g. Feishu push); silence is not a branch. |
| "'Continue.' is enough — I'll know what to do." | No — the re-invoked agent has only the prompt. No checklist in the prompt → no supervision at fire time. |
| "60s is fine, it's just polling." | No — see the interval table. Never poll faster than the cache window (≥270s edge, else ≥1200s). |

## Pre-Action Self-Check

Before calling `CronCreate`, answer all of these (a "no" on any → revise before creating):

- Is this genuinely a moment the harness will NOT auto-resume me? (If it will notify you, you do not need a cron.)
- Does the interval match the wait target per the table, and is it ≥270s (or ≥1200s if not tight-polling)?
- Does the prompt encode the full on-fire checklist: CHECK concretely → if cleared proceed → if not ESCALATE → re-arm only with stated reason + coarsened interval?
- Is there an escalation mechanism named in the prompt (e.g. `cc-alarm-larkcli` Feishu push), so silence is never a branch?
- Is the prompt free of bare "Continue." / "check again" verbs?

## Quick Reference

| Concern | Rule |
|---------|------|
| What the cron is | A timer. You are the supervisor. |
| Interval (person) | 1200s–1800s (long heartbeat). |
| Interval (tight state) | ≥270s, or commit to ≥1200s. Never <270s. |
| Prompt must contain | The four-step on-fire checklist. |
| If cleared | Proceed. Do not re-arm. |
| If not cleared | ESCALATE (e.g. Feishu via `cc-alarm-larkcli`). Never silent. |
| Re-arm | Only with a stated reason; coarsen the interval. |
| Anti-pattern | Silent Re-Arm — bare "Continue." prompt. |

## Composition Reminder

- **Hook (mechanical):** forces "a polling cron must exist" when the PM is blocked with pending todos.
- **This skill (methodology):** guarantees "the cron supervises" — checks concretely and escalates rather than silently re-arming.

The Stop hook's block message references this skill by name (`development-team:supervisory-polling`). When you see that block, invoke this skill before creating the cron.

## References

- `skills/writing-skills/SKILL.md` — the TDD-for-docs discipline this skill was authored under (baseline-failure artifact first).
- `skills/development-team/SKILL.md` — methodology-skills registration table (this skill is registered there).
- Companion Stop hook — forces the cron to exist; out of this skill's scope to modify.
