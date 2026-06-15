---
name: writing-skills
description: Use when creating a new dev-team skill, editing any SKILL.md or agent rule, or extending dev-team's methodology. Enforces authoring skills/rules as TDD-for-docs — a baseline-failure artifact first, then the minimal doc that closes that failure, then loophole-closing re-test.
---

# Writing Skills — TDD-for-Docs

> **Invokable as** `development-team:writing-skills` via the Skill tool. Triggered by the PM before dispatching any "add/improve a dev-team skill or agent rule" task, and self-invoked by the authoring role (typically Document Writer) at the moment of authoring.

## Why This Exists

dev-team extends itself: new skills are authored, agents are added, rules in `SKILL.md` or a sibling skill are edited. Without discipline, this turns into documentation bloat — rules that sound good but change nothing. A skill that does not prevent a specific, observed failure mode is prose, not methodology. It will be ignored, drift, and eventually rot.

This skill forces self-extension to earn its place the same way code earns its place under TDD: **by first demonstrating the failure it prevents.** A new or edited rule ships only after the failure mode it targets has been observed, documented, and shown to close under the new rule.

The terminal state is a skill or rule that has *proven* it changes behavior — not one that *asserts* it does.

## The Iron Law

```
NO SKILL OR RULE WITHOUT A FAILING TEST FIRST
```

Applies to **NEW** skills **AND** to **edits** of existing ones. If you cannot show the failure mode the new or edited rule prevents, you cannot ship it.

**Violating the letter of this process is violating the spirit of this process.** "It's just a small addition", "it's only documentation", and "this is obviously an improvement" are all rationalizations — they are the documentation equivalent of "I'll write the test after." No exceptions for simple additions, section expansions, or "clarifying" rewrites.

## What Counts as a Skill / Rule (Scope of This Discipline)

This discipline applies to anything that tells dev-team agents how to behave:

- A new `skills/<name>/SKILL.md` (a methodology skill like this one).
- An edit to any existing `SKILL.md` — shared rules, methodology skills, the PM skill.
- A new or edited `agents/<role>.md` (role definition, including its rules and gates).
- Any rule inside those files: a dispatch rule, a review gate, a return-format row, a BLOCKED protocol, a path-format spec.

It does **not** apply to delivery docs (those are work products, not rules), nor to one-off prose produced for a single task. The test is: *does this file, once written, govern how agents behave on future tasks?* If yes, this discipline applies.

## The Cycle (RED → GREEN → REFACTOR)

Authoring a skill or rule follows the same shape as writing code under TDD. Each phase has a concrete artifact and an exit criterion.

### RED — Document the Baseline Failure

**Before writing the rule**, capture the failure mode it prevents. This is the baseline-failure artifact. Run the scenario (or recall a concrete observed instance) without the rule in place, and record:

1. **The bad outcome.** What concretely went wrong — a missed gate, a skipped step, a misrouted dispatch, a wrong return format, an undefined loop. Be specific: name the role, the step, the consequence.
2. **The rationalization that allowed it.** Verbatim, the wording the agent used to justify the bad behavior — "this is simple enough to skip", "I'll verify after", "the reviewer will catch it anyway", "the rule says X but the spirit is Y". Rationalizations are load-bearing: the rule must close *these specific* escape hatches, not generic ones.
3. **Why it recurred / would recur.** What structural gap let the failure happen — no gate, an ambiguous trigger, an honor-system clause with no external check, an undefined escalation path.

The artifact is a short delivery doc under the author's role directory (Document Writer → `.claude/development-team/doc-writer/`), following the standard delivery path format. It is the "test that fails" — without it, the rule has nothing to prove it changes behavior.

**Exit criterion for RED:** a written baseline-failure artifact exists, containing a concrete bad outcome, the verbatim rationalization, and the structural cause. If you cannot produce this, you have not earned the right to write the rule.

### GREEN — Write the Minimal Doc That Closes the Failure

Author the skill or rule to close **exactly** the failure modes documented in RED — no more, no less.

- Address the specific rationalizations from RED. Each rationalization in the artifact maps to an explicit counter in the rule (a rationalization table, a "no exceptions" clause, a red-flags list).
- Do not add content for hypothetical failures you have not observed. Speculative scope is bloat — it dilutes the rule and creates unmaintained surface area.
- If the rule's shape is genuinely open (multiple viable structures, real design trade-offs), run `development-team:brainstorming` on it first. The approved design feeds GREEN, exactly as it feeds a code workflow.
- Cross-reference existing skills rather than duplicating. A new rule that restates `verification-before-completion` or `systematic-debugging` is noise; one that links to them and adds only its novel discipline is signal.

**Exit criterion for GREEN:** the doc exists, is scoped to the RED failures, and each documented rationalization has a named counter in the text.

### REFACTOR — Re-Test and Close Loopholes

Re-run the scenario from RED against the new rule. Does the rule actually prevent the failure?

- Look for **spirit-vs-letter gaps**: wording an agent can technically satisfy while still doing the wrong thing ("I ran *a* command" vs. "I ran *the* command that proves the claim").
- Look for **rationalization gaps**: an escape hatch the rule leaves open that the RED artifact didn't cover but re-testing surfaces.
- Look for **ambiguous triggers**: conditions vague enough that the rule fails to fire when it should, or fires when it shouldn't.
- Close each one explicitly — a clause, a table row, a red-flags entry. Then re-test.

Verify compliance with `development-team:verification-before-completion`: the proof that the rule changes behavior is **fresh evidence** (a re-run of the RED scenario showing the failure no longer occurs under the new rule), not an assertion that it does. Record the re-test output in the delivery doc alongside the rule.

**Exit criterion for REFACTOR:** fresh re-test evidence shows the RED failure closes under the new rule, and every loophole surfaced during re-test has an explicit counter.

## What a Valid Baseline-Failure Artifact IS

This is methodology — the definition of the artifact. (The *requirement* that a reviewer block on its absence is a rule; see the section on enforcement below.)

A valid baseline-failure artifact contains, at minimum:

| Element | What it captures | Example |
|---------|------------------|---------|
| **Concrete bad outcome** | The observed misbehavior, with the role and step named | "The Code Developer marked the bug 'fixed' without a regression test; the Code Reviewer had no red-green evidence to check." |
| **Verbatim rationalization** | The wording that justified the bad behavior, quoted not paraphrased | "'I'll write the test after confirming the fix works.'" |
| **Structural cause** | The gap that let the failure recur | "No gate required a failing-test-before-fix; the rule was honor-system." |
| **Re-test target** | The specific behavior the new rule must change | "Under the new rule, a bug fix with no failing-first regression test must be rejected at review." |

A weak artifact — one that describes a failure in vague terms ("sometimes agents skip steps") with no verbatim rationalization and no structural cause — is not a valid baseline. It does not constrain GREEN to anything specific, so GREEN will over- or under-shoot. The artifact's job is to make the rule *falsifiable*: the rule passes only if the re-test against this exact failure shows it closed.

## Keeping Skills Self-Contained and Discoverable

Two discipline rules that apply to the GREEN artifact itself:

### Self-Contained

A skill must be readable without prior context. A reader landing on the `SKILL.md` cold should understand what the skill is, when to apply it, and what the cycle produces — without needing another file open. Concretely:

- State the Iron Law and the cycle in the skill body, not by reference alone.
- Cross-reference sibling skills (`brainstorming`, `systematic-debugging`, `verification-before-completion`) by name and role, but do not make the skill's own logic depend on the reader having loaded them.
- Zero references to external lineages, upstream repositories, or "the source methodology this was adapted from." The skill stands on its own. Any *conscious-framing* note for maintainers belongs in a clearly marked section, not woven into the instructions agents follow.

### Discoverable

A skill that cannot be found cannot be invoked. Two levers:

- **Frontmatter `description`** — describes *when to use* (triggering conditions, symptoms), not *what the skill does* (its process summary). A description that summarizes the workflow causes agents to follow the summary and skip the body. Start with "Use when..." and name the concrete triggers.
- **Keyword coverage** — use the terms an agent will actually encounter when the skill applies: "new skill", "edit a rule", "agent rule", "baseline failure", "documentation bloat", "skill that changes nothing".

## Where the Enforcement Lives (Rule, Not Methodology)

This skill *defines* the baseline-failure artifact and the RED→GREEN→REFACTOR cycle. It does **not** mandate that the Document Reviewer block on a missing artifact. That is a rule — "the Document Reviewer FAILs a new/edited skill that ships without a baseline-failure artifact" — and rules about reviewer behavior live in the reviewer's agent definition, not in a methodology skill.

The clean separation:

| Lives in `writing-skills` (methodology — "how") | Lives in `agents/doc-reviewer.md` (rule — "what the reviewer must do") |
|--------------------------------------------------|----------------------------------------------------------------------|
| Definition of a valid baseline-failure artifact | The PASS/FAIL gate: "no baseline-failure artifact → automatic FAIL" |
| The RED→GREEN→REFACTOR cycle | The check that the GREEN doc closes the RED failure |
| What counts as fresh re-test evidence | The demand for re-test evidence at review |

This keeps the methodology reusable (any author can follow the cycle) and the enforcement localized (the reviewer's gate is where its weight comes from). If the gate needs to change — tighten, loosen, add a check — that edit happens in the agent rule, and (per this skill's own Iron Law) that edit itself requires a baseline-failure artifact first.

## Common Rationalizations

| Excuse | Reality |
|--------|---------|
| "It's just a small addition to an existing rule." | Small additions change behavior too. Show the failure it prevents. |
| "This is obviously an improvement." | "Obvious" is an assertion. The Iron Law wants evidence. |
| "It's only documentation; it can't hurt." | Unearned documentation rots, dilutes signal, and teaches agents that rules are aspirational. It can hurt. |
| "I'll capture the baseline failure after I draft the rule." | That is tests-after. The rule will be shaped by what you imagine the failure is, not what it is. RED first. |
| "The rule is clear, so testing it is overkill." | Clear to the author is not clear to the agent it governs. The re-test is what proves clarity. |
| "I can't find a failure mode, but the rule is still worth having." | If you cannot show the failure it prevents, you cannot ship it. This is the Iron Law working as intended — the rule probably does not earn its place. |
| "The re-test passed in my head." | That is an assertion. Run the scenario, record fresh evidence per `verification-before-completion`. |

## Red Flags — STOP and Return to RED

If you catch yourself doing any of these, stop and restart at RED:

- Drafting the rule before the baseline-failure artifact exists.
- Describing the failure in vague terms ("agents sometimes skip this") with no verbatim rationalization.
- Adding sections for failures you have not observed.
- Duplicating a rule that already exists in a sibling skill instead of cross-referencing it.
- Treating the re-test as a formality — "the rule obviously fixes it."
- Marking the rule done without fresh re-test evidence recorded in the delivery doc.
- Baking a reviewer-enforcement clause into the skill body (that is a rule; it belongs in the agent definition).

## Quick Reference

| Phase | Artifact | Exit Criterion |
|-------|----------|----------------|
| **RED** | Baseline-failure doc (concrete outcome + verbatim rationalization + structural cause) | A written artifact exists that the new rule can be tested against |
| **GREEN** | The minimal skill/rule, scoped to the RED failures, each rationalization countered | The doc exists, is scoped, and maps to the RED failures |
| **REFACTOR** | Re-test evidence + loophole counters | Fresh evidence shows the RED failure closes; every surfaced loophole has an explicit counter |

**Self-contained & discoverable:** body stands alone; frontmatter describes *when*, not *what*; zero external-lineage references.

**Enforcement is a rule, not methodology:** the gate that *requires* a baseline-failure artifact lives in `agents/doc-reviewer.md`, not here.

## Related Skills

- **`development-team:brainstorming`** — invoked in GREEN when a rule's shape is genuinely open (multiple viable structures). The approved design feeds the rule authoring, the same way it feeds a code workflow.
- **`development-team:verification-before-completion`** — the REFACTOR re-test is a completion claim like any other: it requires fresh command/scenario output, not an assertion. The discipline is the same one.
- **`development-team:systematic-debugging`** — structural cousin. Both enforce "evidence before action" (root cause before fix; baseline failure before rule) and both are backed by an independent reviewer gate rather than self-discipline.
