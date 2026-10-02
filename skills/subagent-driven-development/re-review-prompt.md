# Persistent Reviewer Re-Review Prompt

Send this as a new turn to the existing reviewer child. Never create a new
reviewer for a fix round.

```text
Re-review milestone [MILESTONE_NAME] as pass [2_TO_6].

Acceptance criteria:
[ACCEPTANCE_CRITERIA]

Prior Critical/Important findings with stable IDs:
[FINDINGS]

Preceding-pass aggregate Critical/Important severity:
[PREVIOUS_AGGREGATE]

Prior convergence classifications:
[CONVERGENCE_HISTORY]

Implementer report:
[REPORT_PATH]

Exact fixed review range:
[BASE_SHA]..[HEAD_SHA]

Review the full exact BASE..HEAD milestone range against the acceptance
criteria. Verdict every prior finding and check whether the fixes introduced
new Critical or Important breakage anywhere in this milestone range.

Passes 4-6 are valid only when Pass 3 and every intervening pass is CONVERGING.
If the supplied history does not prove that gate, do not perform the review;
report the invalid activation to the controller.

Remain read-only. Do not edit files or create commits.

Do not invoke `task`, `create_session`, `run_factory`, background agents, or
any other nested delegation. Do not create helper agents, reviewers, sessions,
factories, or swarms.

Return:

- each prior Critical/Important finding by stable ID with status `resolved`,
  `downgraded`, `unchanged`, or `reopened`, severity, and file:line evidence;
- each new Critical/Important finding with a new stable ID, status `new`,
  severity, and file:line evidence;
- Minor observations that do not extend the loop;
- milestone quality verdict;
- pass number and remaining Critical/Important count;
- preceding and current aggregate Critical/Important severity, using Critical
  = 2 points, Important = 1 point, and resolved or downgraded-to-Minor = 0;
- CONVERGING or NOT_CONVERGING for Passes 3-6, with the blocking IDs resolved
  or downgraded, reopened IDs, and new Critical IDs as evidence.

For Passes 3-6, report CONVERGING only when at least one blocking finding is
resolved or downgraded, none is reopened, no new Critical finding appears, and
aggregate severity decreases from the preceding pass. Otherwise report
NOT_CONVERGING and state that the controller must stop immediately.
Minor-only findings do not justify another pass.

This is review pass [2_TO_6] of at most six total. After Pass 6, any remaining
Critical or Important finding requires escalation. There is no automatic Pass 7.
Do not recommend a replacement reviewer.
```
