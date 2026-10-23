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
- The same reviewer performs at most three total review passes per milestone.
  Passes 2 and 3 happen only while Critical or Important findings remain.
- After pass 3, stop and escalate unresolved Critical or Important findings to
  your human partner.
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
| Bounds | Two idle child creations; sequential activations; `8 × milestones + 1` primary child activations; a handoff-recovery reserve of at most `8 × milestones + 1`; absolute maximum `16 × milestones + 2`; and three review passes per milestone |
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

For a phase with `M` milestones, disclose all three finite limits:

- normal work allowance: `8 × M + 1` primary child activations;
- handoff-recovery reserve: at most `8 × M + 1` recovery activations;
- absolute maximum: `16 × M + 2` total primary and recovery activations.

- per milestone: one implementation activation, up to two blocker-resolution
  activations, up to two fix activations, and up to three review activations;
- per phase: one optional implementer phase-complete summary activation.

Every child activation or resume counts against this total, including first-use
initialization, milestone work, a turn that returns BLOCKED, blocker resolution,
fixes, reviews, re-reviews, no-op turns, and the optional phase summary. The
first implementer activation combines initialization with Milestone 1; the
first reviewer activation combines initialization with review pass 1. If a
platform requires separate initialization, those activations still count and
reduce the remaining budget.

One recovery may pair with the same primary activation's missing handoff.
Pairing is allowed only after authoritative idle or terminal reconciliation.
The handoff-recovery reserve cannot fund new implementation or review work. It
cannot replace either child, cannot expand scope, cannot fund a second recovery
for the same primary activation, and cannot transfer to ordinary work.

Every recovery counts against both the handoff-recovery reserve and the
absolute maximum. If no recovery reserve remains, stop and seek reapproval
rather than violating the budget.

Stop and seek reapproval before exceeding the disclosed activation budget.
Repeated blockers do not create an unlimited exception: after two
blocker-resolution activations for a milestone, stop unless a revised finite
budget is approved.

Use the platform's session-native messaging and resume mechanisms. If the
platform cannot preserve two reusable child sessions, do not emulate the
topology with fresh children; use `superpowers:executing-plans` in the current
session or request a revised approval.

## Live Status and Missing Handoff Reconciliation

Before saying a child is working, still working, or that the controller is
waiting for idle, refresh authoritative live status with the platform's
session status or inspection tool. Refresh authoritative live status again
before declaring a milestone or phase complete. A report, commit, lifecycle
event, prior status read, or event ordering is not proof of current activity;
never infer live status from cached state.

If the child is idle and the expected handoff is missing:

1. Inspect the latest child or session state, latest commit or `HEAD`, and the
   expected latest report path.
2. Request exactly one recovery handoff from that same child session. This is
   a recovery activation and counts against the handoff-recovery reserve and
   absolute maximum; it does not authorize a replacement child or new work.
3. Use the existing bounded condition or status mechanism and authoritative
   status inspection until the exact recovery activation reaches terminal or
   idle. Do not rely on a lifecycle notification, cached state, or immediate
   absence in the current turn, and do not wait indefinitely.
4. Once terminal or idle, reconcile exactly once: admitted messages plus the
   latest session state, commit or `HEAD`, and report.
5. If the handoff is recovered, continue from the reconciled state. If it is
   still missing, report an explicit handoff delivery failure and stop.

Never wait indefinitely for a lifecycle notification or missing handoff.
Never issue a second recovery for the same primary activation.
Preserve the approved persistent pair, sequential activation, review-pass cap,
and phase boundary throughout recovery.

## Admitted Message Reconciliation

Before the controller completes the current turn or task, completes a
milestone, or completes the phase, process every cross-session message admitted
into the current turn.

- Process each message compatible with the current assignment, commit, and
  phase.
- If a message was superseded by a newer assignment, newer commit, or a
  `closed phase`, explicitly record `DISCARDED_AS_STALE` and the reason. Never
  silently ignore an admitted message.
- Do not invent work outside the approved phase, and do not let a stale message
  reopen completed work.

## Private Queue Boundary

This skill cannot inspect a host-private message that is not yet delivered into
the current turn. "Check queued messages" means reconcile messages admitted
into the current turn plus authoritative child or session state. Never claim
that an undelivered private transport queue was enumerated or is empty.

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

Before reporting that the implementer is working, still working, or that the
controller is waiting for idle, refresh authoritative live status. When the
implementer is idle but the expected handoff is absent, follow **Live Status
and Missing Handoff Reconciliation** instead of waiting for another lifecycle
event.

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
- milestone quality verdict.

Minor findings do not trigger another pass unless the acceptance criteria make
them blocking.

Before reporting that the reviewer is working, still working, or that the
controller is waiting for idle, refresh authoritative live status. When the
reviewer is idle but its complete review is absent, follow **Live Status and
Missing Handoff Reconciliation**. Process every admitted cross-session message
before acting on the review result.

### 3. Fix and re-review

If Critical or Important findings remain:

1. Resume the same implementer with the findings verbatim.
2. Let it fix, run focused validation, self-review, and commit.
3. Wait until it is idle.
4. Resume the same reviewer with the original `BASE_SHA`, the new `HEAD_SHA`,
   prior findings, and the exact fixed `BASE_SHA..HEAD_SHA` range.

The reviewer re-evaluates the full milestone range against the acceptance
criteria so fixes cannot hide regressions elsewhere in the milestone.

Review pass limits:

| Pass | When allowed | Result |
| --- | --- | --- |
| 1 | Always | Initial milestone review |
| 2 | Unresolved Critical/Important findings after pass 1 | Same reviewer |
| 3 | Unresolved Critical/Important findings after pass 2 | Same reviewer |
| After 3 | Findings still unresolved | Stop and escalate; no fourth pass or new reviewer |

Never fix findings in the controller session and never create a separate
fixer. The same implementer owns the milestone until it passes or escalates.

### 4. Complete the milestone

A milestone is complete only when:

- its acceptance criteria are satisfied;
- focused validation is green;
- no Critical or Important findings remain;
- its changes are committed.

Before marking it complete, refresh authoritative live status and process every
cross-session message admitted into the current turn. Apply compatible messages
and explicitly record stale ones as `DISCARDED_AS_STALE` with the reason.

Mark it complete and begin the next approved milestone with the same pair.
Do not replace a child merely to obtain fresh context or a different verdict.

## Phase Completion

After the last approved milestone:

1. Confirm every milestone commit and validation result.
2. Refresh authoritative live status for both children; do not infer it from
   commits, reports, lifecycle events, or prior reads.
3. Process every cross-session message admitted into the current turn. Apply
   compatible messages; record superseded messages as `DISCARDED_AS_STALE`
   with the reason.
4. Summarize deferred Minor findings and any decisions.
5. Retire both phase-scoped child identities.
6. Report the phase as complete.
7. Stop.

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
- Starting review pass 4
- Selecting a model through inheritance, automatic routing, or "most capable"
- Adding an undisclosed reviewer or review swarm
- Continuing into the next phase after completion
- Treating BLOCKED or initialization turns as free activations
- Exceeding the disclosed activation budget without reapproval
- Spending the handoff-recovery reserve on ordinary implementation or review
- Requesting a second recovery for the same primary activation
- Claiming a child is still working or waiting from a commit, report, lifecycle
  event, event ordering, or cached status instead of refreshing live status
- Waiting indefinitely for a lifecycle notification or missing handoff
- Silently ignoring a cross-session message admitted into the current turn
- Claiming to inspect or empty a host-private undelivered transport queue

Any of these means stop and restore the approved bounded topology.

## Common Rationalizations

| Excuse | Reality |
| --- | --- |
| "Fresh agents avoid context pollution." | The approved phase deliberately preserves context in one implementer and one reviewer. |
| "Parallel work is faster." | Shared phase state and review ordering require at most one active delegated agent. |
| "A specialist fixer will converge faster." | A third editor breaks ownership and the approved topology; return findings to the same implementer. |
| "One more review pass cannot hurt." | Three passes is the disclosed cap. Escalate after pass 3. |
| "A blocked turn did no work, so it should not count." | Every activation consumes budget and can retain resources or trigger more work. |
| "Recovery is just message delivery, so it does not count." | Every recovery consumes the dedicated reserve and absolute activation budget. |
| "Unused recovery reserve can fund another fix." | The reserve is non-transferable and exists only for one missing handoff from an otherwise-approved primary activation. |
| "The recovery message is not here yet, so delivery failed." | Refresh authoritative status until that exact recovery activation is terminal or idle, then reconcile once. |
| "Try recovery one more time." | A primary activation gets at most one recovery. Stop and report delivery failure after terminal reconciliation. |
| "The parent model is inherited automatically." | Automatic routing is not disclosed approval. Specify the exact model. |
| "A final reviewer is extra assurance." | It is an extra agent and dispatch outside the approved topology. Obtain new approval first. |
| "The plan has more tasks, so keep going." | Approval covers one phase only. Stop at its boundary. |
| "The latest event says it is working." | Event ordering and cached state are not authoritative. Refresh live session status before the claim. |
| "The handoff will arrive eventually." | Inspect state, commit, and report; request exactly one recovery handoff, then stop on delivery failure. |
| "That message is old, so I can ignore it." | Every admitted message is processed or explicitly marked `DISCARDED_AS_STALE` with a reason. |
| "I checked the queue and it was empty." | The skill cannot inspect an undelivered host-private queue; reconcile admitted messages and authoritative session state only. |
