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

---

# Authoring Standard — What Good Agent/Skill Content Looks Like

> **Sibling to the cycle above.** The RED→GREEN→REFACTOR cycle is the *process* that earns a rule its place. This section is the *content standard* — what the GREEN artifact must look like once it exists. The two compose: the cycle decides *whether* a rule ships; this standard decides *how it reads*. They never merge, and this standard never weakens the cycle's baseline-failure requirement.

This standard governs every agent definition (`agents/<role>.md`) and every skill (`skills/<name>/SKILL.md`) in this plugin. The application pass conforming all existing agents and reviewers to this standard is the consumer of this section. The Document Reviewer enforces it as part of the GREEN gate.

## The Three Non-Negotiables

These three recur at every depth of this standard. State them in the header, the body, the recap, and a pre-action self-check — do not state them once and move on.

1. **Judgment replaced by pattern-match.** Every routing decision a weaker model could fumble is a lookup table or a decision ladder with an explicit default — never a free-form instruction.
2. **Every hard rule names and rejects its own bypasses in advance.** A rule that does not enumerate the rationalizations an agent will invent to skip it is a rule that will be skipped.
3. **Reading the governing reference is unconditional.** Consult the relevant skill/agent rule *before* deciding you do not need it; self-assessed confidence is never a gate for skipping a reference.

## The Eight Techniques

Each technique is specified as: **what** it is, **why** it helps weaker models, **how** to author it, and a tiny original snippet. All snippets are illustrative patterns — instantiate, do not copy verbatim.

### 1. Trigger-to-Bucket Lookup Tables

- **What.** A table mapping a recognizable input signal to a predefined action bucket. Replaces "decide what to do" with "match a row."
- **Why weaker models benefit.** Judgment about *which* action fits is the most error-prone step for low-capability models; a lookup table reduces it to string/shape matching.
- **How to author.** Make the signal a concrete, syntactic cue (a keyword, a shape, a count), not a semantic judgment. Make the bucket a single named action. Include an explicit "none of the above" row pointing to the default branch.

```text
| If the task contains...          | Bucket               | Action                          |
|----------------------------------|----------------------|---------------------------------|
| "bug", "test failure", "broken"  | bug-fix              | Enter systematic-debugging      |
| new endpoint / new contract      | new-API              | BLOCKED until API design exists |
| single-file mechanical edit      | trivial-edit         | Proceed; skip architecture gate |
| none of the above                | unclassified         | Ask PM to classify — do NOT guess |
```

### 2. Pre-empt Named Rationalizations

- **What.** For each hard rule, list the justifications an agent is likely to invent to bypass it, and reject each explicitly ("even if framed as X, still no").
- **Why weaker models benefit.** Bypass justifications are highly stereotyped; naming them turns "is this a valid exception?" into "does this match a listed string?".
- **How to author.** Phrase the rejection as a closed form — *"Even if framed as [rationalization], still [the rule]."* One row per rationalization. No vague "don't make excuses."

```text
Hard rule: ONE module per dispatch.
- "It's just a one-line tweak in a neighbor"  → still no. Report OVERSCOPED.
- "The modules are tightly coupled, so it's really one change" → still no. Coupling is wiring; report OVERSCOPED.
- "Splitting would take longer than doing it" → still no. Scope discipline is not a time optimization.
```

### 3. Decision Ladders with Explicit Defaults

- **What.** Every routing decision is a short ordered ladder; each rung is a condition plus the action to take if it matches; the final rung is always the default action when nothing matches.
- **Why weaker models benefit.** A flat list of "consider A, B, C" leaves the model to weigh trade-offs. A ladder says: check rung 1, then 2, then 3, else default — deterministic traversal.
- **How to author.** Order rungs most-specific to most-general. End with `→ DEFAULT: <concrete action>`. The default must be an action, never "use judgment."

```text
Scope check (run in order):
1. Spans 2+ modules that are not your module's sub-modules? → OVERSCOPED, stop.
2. Single module, but needs an API contract that doesn't exist? → BLOCKED: API Designer.
3. Single module, contract exists? → Proceed.
DEFAULT: If unsure whether it's one module, treat as OVERSCOPED. Guessing "in" expands scope silently.
```

### 4. Rationale Line After Every Worked Example

- **What.** Each worked example ends with a one-sentence *why this is correct* line. The rationale is the transferable payload; the example is just the carrier.
- **Why weaker models benefit.** Without the rationale, a weaker model memorizes the example and fails to generalize. The rationale gives it the rule behind the example.
- **How to author.** One sentence. Start with "Why correct:". State the principle, not a restatement of the example.

```text
Example: The task says "rename UserService to UserAccountService across the repo."
Action: Route to Migrator, not Code Developer.
Why correct: Repo-wide mechanical renames are the Migrator's exempt-from-one-module job; a Code Developer would have to file OVERSCOPED.
```

### 5. Critical-Rule Repetition at Multiple Depths

- **What.** State the 2–3 non-negotiables in (a) the header summary, (b) a dedicated section, (c) a recap near the return format, and (d) a one-line pre-action self-check.
- **Why weaker models benefit.** A single statement deep in a long file gets dropped from context. Repetition at four depths maximizes the chance the rule is active when the decision point fires.
- **How to author.** Same rule, shorter each time. Header: one clause. Section: full statement + counters. Recap: bullet. Self-check: a question the agent answers before acting.

```text
Header:    "Bug fixes require root cause + regression test. No exceptions."
Section:   [full systematic-debugging gate with the three required artifacts]
Recap:     "- Root cause stated? - Regression test red→green? - Fix targeted?"
Self-check (before writing "fixed"): "Did I state the root cause with evidence, and does a test fail without my fix?"
```

### 6. Opinionated Role/Tool Descriptions

- **What.** The frontmatter `description` field carries when-to-use, when-NOT-to-use, and priority — not just a label or a process summary.
- **Why weaker models benefit.** The description is the first (and often only) text a dispatcher reads to route work. A label ("reviews code") leaves routing to guesswork; opinionated routing instructions collapse the decision.
- **How to author.** Include a when-NOT-to-use clause and, where two agents overlap, a priority/tiebreak. Do not summarize the agent's internal process in the description — that causes readers to follow the summary and skip the body.

```text
description: Dispatch to review code+tests for bugs, coverage, maintainability.
  Use for: any code produced by a Code Developer, DevOps Engineer, Data Engineer, or Migrator.
  Do NOT use for: API contracts (→ api-reviewer), plans (→ task-reviewer), architecture (→ architect-reviewer).
  Priority: this is the ONLY reviewer for code artifacts; do not split code review across reviewers.
```

### 7. "Consult the Reference Before Deciding You Don't Need It"

- **What.** Reading a governing skill or agent rule is unconditional — it is not gated on the agent's own confidence that it already knows the answer.
- **Why weaker models benefit.** A weaker model's confidence in "I already know this" is poorly calibrated; the only reliable gate is "did I actually read it this turn."
- **How to author.** Phrase as a closed trigger: *"When [signal], read [reference] in full this turn before acting — regardless of whether you think you already know it."*

```text
Before writing any "done / passing / fixed" claim:
read development-team:verification-before-completion IN FULL this turn —
even if you have used it before. Confidence that you remember it is not a substitute for reading it.
```

### 8. Named Anti-Patterns with Positive Targets

- **What.** Name the characteristic failure mode AND give the correct alternative in the same breath. A named anti-pattern is recognizable; a positive target tells the model what to do instead.
- **Why weaker models benefit.** "Don't be vague" is unactionable. "Avoid the Decorative-Bolding anti-pattern: bold only the load-bearing term, not every noun" is a concrete substitution.
- **How to author.** Name it (two-three words, capitalized). State the failure. State the target. Keep the pair inseparable.

```text
Anti-pattern — Shotgun Scope: listing every concern you *could* review, diluting the gate.
Target: name the 2-3 gates that are PASS/FAIL blockers; everything else is advisory and labeled as such.
```

## Supporting Craft

These are shorter rules that improve every technique above.

- **Conciseness, defined operationally.** Over-formatting counts as bloat. Decorative bolding (bolding a word that carries no decision weight), fragment bullets that restate the preceding sentence, and nested sub-sub-lists all dilute signal. Bold only the load-bearing term in a sentence. If a bullet and its parent sentence say the same thing, delete one.
- **Contrastive examples.** Wherever a rule has a correct form, show the incorrect form beside it. "Do this / not this" transfers better than "do this" alone.
- **Tables for mappings, prose for nuance.** A trigger→action map is a table. A rule with three qualifiers and an exception is prose. Do not force nuance into a table cell, and do not force a clean mapping into paragraphs.
- **One concern per section.** A section titled "Scope" should be about scope only. A section that mixes scope and verification and return format teaches the model that the boundaries are soft. Split.

## Producer Template

The section skeleton a production agent (coder / architect / planner / api-designer / devops / data-engineer / migrator) follows. The application pass instantiates this per role. Placeholders in `[brackets]`.

```markdown
---
name: [role]
description: [one-line label].
  Use for: [concrete trigger signals].
  Do NOT use for: [adjacent work that belongs to another role].
  Priority: [tiebreak if this role overlaps another].
tools: [tools]
model: inherit
skills:
  - development-team
---

# [Role] Rules

> Shared system rules preloaded via skills frontmatter — follow them.

## Header — The Non-Negotiables
[Technique 5a] One-line restatement of the 2-3 hard rules this role owns.

## Your Job
1. [step]
2. [step]

## [Discipline A — e.g. Bug-Fix / Verification / TDD]
[Technique 7] "When [signal], read [skill] IN FULL this turn — regardless of confidence."
[Technique 2] Hard rule, followed by named-rationalization rejections.

## [Discipline B]
[Technique 1] Trigger→bucket table for the routing decisions in this discipline.
[Technique 3] Decision ladder ending in DEFAULT.

## Scope Rule
[Technique 3] Ladder: multi-module → OVERSCOPED; missing contract → BLOCKED; else proceed.
DEFAULT: [concrete action, not "use judgment"].

## Examples
[Technique 4] Worked example + "Why correct:" line. Cover the 2-3 most likely misroutes.

## Anti-Patterns
[Technique 8] Named anti-pattern + positive target, for each characteristic failure of this role.

## Pre-Action Self-Check
[Technique 5d] One-line question per non-negotiable, answered before every completion claim.

## Delivery Doc / Return to PM
[Standard templates.]

## When You Need Help From Other Roles
BLOCKED format + common scenarios + "Do NOT report BLOCKED for" list.
```

## Reviewer Template

The section skeleton a review agent follows. Every reviewer (code, api, doc, architect, task, test-design, product) conforms to this shape.

```markdown
---
name: [role]-reviewer
description: [one-line label].
  Use for: [the specific artifact type this reviewer gates].
  Do NOT use for: [adjacent artifacts that belong to a different reviewer].
  Priority: [tiebreak — e.g. "the ONLY reviewer for X"].
tools: [tools]
model: inherit
skills:
  - development-team
---

# [Role] Reviewer Rules

## Identity
[Technique 6] What this reviewer gates, in one paragraph. State the artifact type and that the review is a PASS/FAIL gate, not advisory.

## Decision Ladder (run in order; stop at first match)
[Technique 3]
1. Artifact is not the type I review? → Re-route to correct reviewer; do NOT review.
2. A prerequisite gate applies (TDD / verification / systematic-debugging)? → Run it FIRST; FAIL stops the review.
3. Artifact passes all gates? → Run dimension review.
DEFAULT: if unsure whether a gate applies, treat it as applying. Skipping a gate on uncertainty is a FAIL.

## PASS/FAIL Gates
[Technique 1] A trigger→bucket table mapping each gate to its required evidence.
[Technique 2] For each gate, the named rationalizations agents use to bypass it, rejected in advance.
[Technique 5b] Each gate stated in full with its evidence requirements.

## Review Dimensions (advisory unless labeled a gate)
[One concern per section. Each dimension is either a labeled PASS/FAIL gate or explicitly advisory.]

## Named Anti-Patterns
[Technique 8] Per characteristic reviewer failure (e.g. "Shotgun Scope", "Rubber-Stamp").
Positive target for each.

## Examples
[Technique 4] One PASS example and one FAIL example, each with a "Why correct:" line.

## Feedback File Template
[Standard path + template. Feedback IS the handoff — specific enough to revise without questions.]

## Pre-Action Self-Check
[Technique 5d] Before writing verdict: "Did I run every gate in order? Did I cite fresh evidence for each FAIL?"

## Return to PM
Verdict / per-gate status / critical issues / confidence.
```

## Standard Recap

- **Three non-negotiables** (lookup-not-judgment, named-bypass-rejection, unconditional-reference-reading) appear in every conforming agent at four depths.
- **Eight techniques** are the toolkit; not every agent uses all eight, but every routing decision, every hard rule, and every example must trace to at least one.
- **Two templates** (Producer, Reviewer) are the skeletons the application pass instantiates. They are the contract between this standard and the conforming agents.

## Authoring-Standard Self-Check (for anyone editing this section)

Before this section itself is edited, confirm:
- Did I keep it a *sibling* to the cycle, not a merge? (Process decides whether; this decides how.)
- Did I avoid weakening the baseline-failure requirement? (This standard describes content quality; it does not replace RED→GREEN→REFACTOR.)
- Is every technique grounded in a real gap observable in a current agent file, not a hypothetical?

- **`development-team:brainstorming`** — invoked in GREEN when a rule's shape is genuinely open (multiple viable structures). The approved design feeds the rule authoring, the same way it feeds a code workflow.
- **`development-team:verification-before-completion`** — the REFACTOR re-test is a completion claim like any other: it requires fresh command/scenario output, not an assertion. The discipline is the same one.
- **`development-team:systematic-debugging`** — structural cousin. Both enforce "evidence before action" (root cause before fix; baseline failure before rule) and both are backed by an independent reviewer gate rather than self-discipline.
