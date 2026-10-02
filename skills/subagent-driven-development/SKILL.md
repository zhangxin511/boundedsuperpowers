---
name: subagent-driven-development
description: Use when executing an approved phase of two or three closely related milestones with delegated implementation and independent review
---

# Subagent-Driven Development

Execute one approved phase with a persistent implementer/reviewer pair. The
phase contains at most 2-3 closely related, independently testable and
committable milestones.

**Core principle:** One approved phase, one persistent implementer, one
persistent independent reviewer, sequential dispatches, then stop.

## Non-Negotiable Topology

- Reuse one persistent implementer child session for every milestone and fix
  round in the phase.
- Reuse one persistent independent read-only reviewer child session for every
  review pass in the phase.
- At most one delegated agent may be active at a time. Never run the pair in
  parallel.
- The implementer is the only child allowed to edit code.
- Critical and Important findings return to the same implementer. Never create
  a fixer child.
- The same reviewer performs at most six total review passes per milestone.
  Pass 1 is the initial review. Every later pass uses the same implementer to
  fix findings, then the same reviewer to re-review the full fixed
  `BASE_SHA..HEAD_SHA` range.
- Passes 2 and 3 happen only while Critical or Important findings remain.
  Passes 4-6 unlock only when Pass 3 is CONVERGING, and each later pass must
  remain CONVERGING.
- The first NOT_CONVERGING classification stops the loop and escalates to your
  human partner. After Pass 6, any remaining Critical or Important finding stops and escalates.
  There is no automatic Pass 7 and no replacement reviewer.
- Children must not invoke `task`, `create_session`, `run_factory`, background
  agents, or any other nested delegation.
- Do not automatically invoke Rubber Duck, adversarial review, review swarms,
  extra reviewers, or a final whole-branch reviewer. Additional review requires
  a new disclosed approval.
- At phase completion, retire the implementer and reviewer child identities.
  Never resume or reuse either identity in a later phase.
- A later phase requires a newly disclosed, newly approved, and newly created implementer/reviewer pair.
- Stop after the approved phase. Do not continue to another phase, push, create
  a pull request, merge, or deploy.

## Phase Approval Gate

Before creating either child, disclose one proposal containing:

| Field | Required detail |
| --- | --- |
| Phase | Name and at most 2-3 milestones |
| Implementer | Agent type, exact model/provider, reasoning effort, context tier |
| Reviewer | Agent type, exact model/provider, reasoning effort, context tier |
| Scope | Files/components each milestone may change |
| Validation | Focused commands and milestone acceptance criteria |
| Bounds | Two idle child creations, sequential activations, a base allowance of `8 × milestones + 1` child activations through Pass 3, a conditional reserve of at most `6 × milestones` after Pass 3 is CONVERGING, an absolute maximum of `14 × milestones + 1`, and at most six review passes per milestone |
| Stop boundary | Stop after this phase; no next phase, push, PR, merge, or deploy |

Wait for exact approval of that proposal. Approval covers only the disclosed
phase and runtime choices. A general "implement it" or approval of the overall
plan is not approval to create children.

### Model Selection

Always specify both child models explicitly. Never rely on inheritance,
automatic routing, or "most capable available model."

Default proposal:

- Same provider/model family as the parent
- Medium reasoning
- Default context

When the parent is GPT-5.6 Sol, propose explicit `gpt-5.6-sol` for both
children. Max reasoning, long context, a provider change, or a different model
requires exact prior approval. If an approved child becomes unavailable, stop
and request approval for the replacement instead of silently rerouting.

Every model, provider, reasoning-effort, or context-tier runtime exception is scoped to the exact approved phase.
A later phase must return to the default model configuration.
A later phase proposal may include an exception only when it prominently identifies the exact exception and the user explicitly approves it again.
Do not silently inherit or carry forward any runtime configuration from a prior phase.

## Setup

1. Verify or create an isolated worktree with
   `superpowers:using-git-worktrees`.
2. Read the plan and its referenced spec once.
3. Select at most 2-3 closely related milestones for one phase. Split larger or
   loosely related groups into later phases.
4. Confirm each milestone is independently testable and committable.
5. Create a todo per milestone and record the phase approval.
6. Create both child sessions idle, with no kickoff prompt or auto-start:
   one implementer and one reviewer. Idle creation does not activate a child.
7. Record both child session IDs. Reuse these exact sessions for the whole
   phase.
8. Initialize one role at a time on first use. Send the implementer prompt
   together with Milestone 1, then wait until the implementer is idle before
   sending the reviewer prompt together with review pass 1. Never initialize
   both roles concurrently.

For a phase with `M` milestones, the base allowance is `8 × M + 1` child
activations through Pass 3:

- per milestone: one implementation activation, up to two blocker-resolution
  activations, up to two fix activations, and up to three review activations;
- per phase: one optional implementer phase-complete summary activation.

When Pass 3 is CONVERGING, a conditional reserve of at most `6 × M`
activations unlocks for Passes 4-6. This reserve covers at most one fix and one
review activation for each additional pass per milestone. It does not unlock
for a milestone classified NOT_CONVERGING. The absolute disclosed maximum is `14 × M + 1`;
unused reserve from one milestone does not authorize work outside
the approved phase or beyond Pass 6.

Every child activation or resume counts against this total, including first-use
initialization, milestone work, a turn that returns BLOCKED, blocker resolution,
fixes, reviews, re-reviews, no-op turns, and the optional phase summary. The
first implementer activation combines initialization with Milestone 1; the
first reviewer activation combines initialization with review pass 1. If a
platform requires separate initialization, those activations still count and
reduce the remaining budget.

Stop and seek reapproval before exceeding the disclosed activation budget.
Repeated blockers do not create an unlimited exception: after two
blocker-resolution activations for a milestone, stop unless a revised finite
budget is approved.

Use the platform's session-native messaging and resume mechanisms. If the
platform cannot preserve two reusable child sessions, do not emulate the
topology with fresh children; use `superpowers:executing-plans` in the current
session or request a revised approval.

## Milestone Loop

### 1. Dispatch the persistent implementer

Record the fixed review base before implementation:

```bash
BASE_SHA=$(git rev-parse HEAD)
```

Activate the same implementer with:

- milestone requirements and acceptance criteria;
- exact allowed scope;
- interfaces and decisions it needs;
- focused validation commands;
- the milestone report path;
- the explicit no-nested-delegation contract.

For Milestone 1, generate its focused input with
[`scripts/milestone-brief`](scripts/milestone-brief), then include
[implementer-prompt.md](implementer-prompt.md) in this first message to the
already-created idle child. Later milestones resume the initialized child
without repeating the role prompt.

The implementer uses TDD where required, validates, self-reviews, commits, and
reports only when blocked or milestone-ready-for-review. Verbose implementation
evidence belongs in the implementer's report file, not the chat response.

If blocked, resolve the blocker without creating another child. A material
scope, model, provider, reasoning, context, or milestone change requires new
approval.

### 2. Dispatch the persistent reviewer

Wait until the implementer is idle. Record:

```bash
HEAD_SHA=$(git rev-parse HEAD)
```

Activate the same reviewer with the milestone acceptance criteria, implementer
report, and exact fixed `BASE_SHA..HEAD_SHA` range. For the first review, include
[milestone-reviewer-prompt.md](milestone-reviewer-prompt.md) in this first
message to the already-created idle child. The reviewer remains read-only and
does not broaden the range, edit files, create commits, dispatch children, or
write review artifacts into the checkout or worktree.

The reviewer returns:

- spec-compliance verdict;
- strengths;
- Critical, Important, and Minor findings with file:line evidence;
- stable IDs for every Critical and Important finding, with status `resolved`,
  `downgraded`, `unchanged`, `reopened`, or `new` relative to the preceding
  pass;
- milestone quality verdict.

Minor findings never drive another repair or re-review pass unless the
acceptance criteria explicitly make one blocking. Summarize and defer all
other Minor findings.

### 3. Fix and re-review

If Critical or Important findings remain:

1. Resume the same implementer with the findings verbatim.
2. Let it fix, run focused validation, self-review, and commit.
3. Wait until it is idle.
4. Resume the same reviewer with the original `BASE_SHA`, the new `HEAD_SHA`,
   prior findings, and the exact fixed `BASE_SHA..HEAD_SHA` range.

The reviewer re-evaluates the full fixed `BASE_SHA..HEAD_SHA` milestone range
against the acceptance criteria so fixes cannot hide regressions elsewhere in
the milestone. It preserves each blocking finding's stable ID across passes;
a finding first observed on a later pass receives a new stable ID and status
`new`.

For Pass 3 and every allowed later pass, compare the current pass with the
immediately preceding pass. Compute aggregate blocking severity from all
currently active Critical and Important findings: Critical = 2 points,
Important = 1 point, and resolved or downgraded-to-Minor findings = 0 points.
A downgrade from Critical to Important therefore reduces the aggregate by one.
Classify the pass CONVERGING only when all of these are true:

1. At least one blocking finding is `resolved` or `downgraded` from the preceding pass.
2. No blocking finding is `reopened`.
3. No new Critical finding appears.
4. Aggregate Critical/Important severity decreases relative to the preceding
   pass.

Otherwise classify the pass NOT_CONVERGING, stop immediately, and escalate to
the human partner.

Review pass limits:

| Pass | When allowed | Result |
| --- | --- | --- |
| 1 | Always | Initial milestone review |
| 2 | Unresolved Critical/Important findings after pass 1 | Same reviewer |
| 3 | Unresolved Critical/Important findings after pass 2 | Same reviewer classifies CONVERGING or NOT_CONVERGING |
| 4-6 | Findings remain and every preceding pass from Pass 3 onward is CONVERGING | Same pair; apply the same convergence rule after each pass |
| After 6 | Critical/Important findings remain | Stop and escalate; no automatic Pass 7 or replacement reviewer |

Never fix findings in the controller session and never create a separate
fixer. The same implementer owns the milestone until it passes or escalates.
For Passes 4-6, the first non-converging pass stops immediately and escalates.

### 4. Complete the milestone

A milestone is complete only when:

- its acceptance criteria are satisfied;
- focused validation is green;
- no Critical or Important findings remain;
- its changes are committed.

Mark it complete and begin the next approved milestone with the same pair.
Do not replace a child merely to obtain fresh context or a different verdict.

## Phase Completion

After the last approved milestone:

1. Confirm every milestone commit and validation result.
2. Summarize deferred Minor findings and any decisions.
3. Retire both phase-scoped child identities.
4. Report the phase as complete.
5. Stop.

Do not automatically run a final whole-branch review. Do not invoke
`superpowers:finishing-a-development-branch` unless the human partner
separately asks to integrate or otherwise finish the branch.

## Reporting Contract

Children report only at these boundaries:

- **BLOCKED** — decision or missing context prevents progress;
- **MILESTONE_READY_FOR_REVIEW** — committed implementation and validation are
  ready for the reviewer;
- **PHASE_COMPLETE** — only when explicitly asked to summarize the completed
  approved phase.

Keep implementer responses concise and put verbose implementation logs in its
report file. The reviewer returns its complete review in its response and does
not write review artifacts into the repository or worktree.

## Red Flags

- Creating a fresh child for the next milestone
- Running implementer and reviewer concurrently
- Auto-starting either child during creation
- Initializing the reviewer before the implementer is idle
- Letting the reviewer edit or commit
- Creating a fixer for review findings
- Starting review pass 2 or 3 without unresolved Critical/Important findings
- Starting review pass 4 before Pass 3 is CONVERGING
- Continuing after a non-converging pass
- Starting review pass 7 or replacing the reviewer
- Selecting a model through inheritance, automatic routing, or "most capable"
- Adding an undisclosed reviewer or review swarm
- Continuing into the next phase after completion
- Treating BLOCKED or initialization turns as free activations
- Exceeding the disclosed activation budget without reapproval

Any of these means stop and restore the approved bounded topology.

## Common Rationalizations

| Excuse | Reality |
| --- | --- |
| "Fresh agents avoid context pollution." | The approved phase deliberately preserves context in one implementer and one reviewer. |
| "Parallel work is faster." | Shared phase state and review ordering require at most one active delegated agent. |
| "A specialist fixer will converge faster." | A third editor breaks ownership and the approved topology; return findings to the same implementer. |
| "One more review pass cannot hurt." | Passes 4-6 require measured convergence and the conditional reserve. Pass 7 is never automatic. |
| "A blocked turn did no work, so it should not count." | Every activation consumes budget and can retain resources or trigger more work. |
| "The parent model is inherited automatically." | Automatic routing is not disclosed approval. Specify the exact model. |
| "A final reviewer is extra assurance." | It is an extra agent and dispatch outside the approved topology. Obtain new approval first. |
| "The plan has more tasks, so keep going." | Approval covers one phase only. Stop at its boundary. |
