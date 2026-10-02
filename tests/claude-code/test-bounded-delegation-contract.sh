#!/usr/bin/env bash
# Static contract test for the bounded phase/pair delegation workflow.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

SDD="$REPO_ROOT/skills/subagent-driven-development/SKILL.md"
IMPLEMENTER="$REPO_ROOT/skills/subagent-driven-development/implementer-prompt.md"
REVIEWER="$REPO_ROOT/skills/subagent-driven-development/milestone-reviewer-prompt.md"
RE_REVIEWER="$REPO_ROOT/skills/subagent-driven-development/re-review-prompt.md"
EXECUTING="$REPO_ROOT/skills/executing-plans/SKILL.md"
REQUESTING="$REPO_ROOT/skills/requesting-code-review/SKILL.md"
CODE_REVIEWER="$REPO_ROOT/skills/requesting-code-review/code-reviewer.md"
WRITING="$REPO_ROOT/skills/writing-plans/SKILL.md"
README="$REPO_ROOT/README.md"
CODEX="$REPO_ROOT/skills/using-superpowers/references/codex-tools.md"
GEMINI="$REPO_ROOT/skills/using-superpowers/references/gemini-tools.md"
PI="$REPO_ROOT/skills/using-superpowers/references/pi-tools.md"
ANTIGRAVITY="$REPO_ROOT/skills/using-superpowers/references/antigravity-tools.md"
HERMES="$REPO_ROOT/skills/using-superpowers/references/hermes-tools.md"

assert_has() {
    local file="$1"
    local pattern="$2"
    local label="$3"

    if grep -Eiq "$pattern" "$file"; then
        printf '  [PASS] %s\n' "$label"
    else
        printf '  [FAIL] %s\n' "$label"
        printf '         missing /%s/ in %s\n' "$pattern" "${file#"$REPO_ROOT/"}"
        return 1
    fi
}

assert_lacks() {
    local file="$1"
    local pattern="$2"
    local label="$3"

    if grep -Eiq "$pattern" "$file"; then
        printf '  [FAIL] %s\n' "$label"
        grep -Ein "$pattern" "$file" | sed 's/^/         /'
        return 1
    else
        printf '  [PASS] %s\n' "$label"
    fi
}

echo "=== Bounded delegation contract ==="

assert_has "$SDD" 'at most (2-3|two or three).*milestones' \
    "phase size is capped"
assert_has "$SDD" 'one persistent implementer' \
    "one persistent implementer is reused"
assert_has "$SDD" 'one persistent.*reviewer' \
    "one persistent reviewer is reused"
assert_has "$SDD" 'at most one delegated agent.*active' \
    "delegated work is sequential"
assert_has "$SDD" 'same implementer' \
    "findings return to the same implementer"
assert_has "$SDD" 'at most six total review passes' \
    "review passes are capped at six"
assert_has "$SDD" 'Pass 1.*initial review|initial review.*Pass 1' \
    "pass 1 is the initial review"
assert_has "$SDD" 'later pass.*same implementer' \
    "later passes reuse the same implementer"
assert_has "$SDD" 'then the same reviewer' \
    "later passes reuse the same reviewer"
assert_has "$SDD" 'full fixed.*BASE_SHA\.\.HEAD_SHA|full.*fixed.*BASE_SHA\.\.HEAD_SHA' \
    "later reviews cover the full fixed range"
assert_has "$SDD" 'stable ID' \
    "blocking findings have stable IDs"
for finding_status in 'resolved' 'downgraded' 'unchanged' 'reopened' 'new'; do
    assert_has "$SDD" "$finding_status" \
        "blocking findings support $finding_status status"
done
assert_has "$SDD" 'Critical = 2 points' \
    "aggregate blocking severity weights Critical findings"
assert_has "$SDD" 'Important = 1 point' \
    "aggregate blocking severity weights Important findings"
assert_has "$SDD" 'Pass 3.*CONVERGING|CONVERGING.*Pass 3' \
    "pass 3 classifies convergence"
assert_has "$SDD" 'at least one.*(resolved|downgraded).*preceding pass' \
    "convergence requires blocking progress"
assert_has "$SDD" 'no blocking finding.*reopened' \
    "convergence rejects reopened blocking findings"
assert_has "$SDD" 'no new Critical finding' \
    "convergence rejects new Critical findings"
assert_has "$SDD" 'aggregate.*severity.*decreas' \
    "convergence requires aggregate severity decrease"
assert_has "$SDD" 'NOT_CONVERGING.*stop.*escalate|stop.*escalate.*NOT_CONVERGING' \
    "non-convergence stops and escalates"
assert_has "$SDD" 'Passes 4-6|Pass 4.*Pass 6' \
    "convergence unlocks passes 4 through 6"
assert_has "$SDD" 'first non-converging pass.*stop|stop.*first non-converging pass' \
    "later non-convergence stops immediately"
assert_has "$SDD" 'After Pass 6.*remaining Critical or Important.*stop.*escalate|Pass 6.*stop.*escalate.*Critical or Important' \
    "blocking findings after pass 6 escalate"
assert_has "$SDD" 'no automatic Pass 7|never.*Pass 7' \
    "there is no automatic pass 7"
assert_has "$SDD" 'no replacement reviewer|never.*replacement reviewer' \
    "there is no replacement reviewer"
assert_has "$SDD" 'Minor findings.*never drive.*repair.*re-review|Minor findings.*do not trigger another pass' \
    "minor findings do not drive another pass"
assert_has "$SDD" 'stop after.*approved phase' \
    "execution stops at the phase boundary"
assert_has "$SDD" 'retire.*implementer.*reviewer|implementer.*reviewer.*retire' \
    "phase completion retires both child identities"
assert_has "$SDD" 'later phase.*newly disclosed.*newly approved.*newly created.*pair' \
    "each later phase requires a newly approved pair"
assert_has "$SDD" 'model.*provider.*reasoning effort.*context tier' \
    "approval disclosure includes exact runtime choices"
assert_has "$SDD" 'gpt-5\.6-sol' \
    "default GPT-5.6 Sol child model is explicit"
assert_has "$SDD" 'runtime.*exception.*exact approved phase' \
    "runtime exceptions are scoped to one exact phase"
assert_has "$SDD" 'later phase.*return.*default model configuration' \
    "later phases return to the default model configuration"
assert_has "$SDD" 'later phase proposal.*prominently identif.*exact exception.*explicitly approves.*again' \
    "later exceptions require prominent renewed approval"
assert_has "$SDD" 'do not silently inherit or carry forward.*prior phase' \
    "prior runtime exceptions cannot carry forward silently"

assert_lacks "$SDD" 'fresh (implementer )?subagent per task|broad (final|whole-branch) review|dispatch.*most capable available model' \
    "unbounded topology language is removed"

for prompt in "$IMPLEMENTER" "$REVIEWER" "$RE_REVIEWER"; do
    for term in 'task' 'create_session' 'run_factory' 'background agents' 'nested delegation'; do
        assert_has "$prompt" "$term" \
            "$(basename "$prompt") prohibits $term"
    done
done

assert_has "$REVIEWER" 'exact.*BASE\.\.HEAD|fixed.*BASE\.\.HEAD' \
    "reviewer receives a fixed review range"
assert_has "$REVIEWER" 'read-only' \
    "reviewer remains read-only"
assert_has "$REVIEWER" 'return the complete review in (this|your) response' \
    "reviewer returns its complete review without writing artifacts"
assert_lacks "$REVIEWER" 'REVIEW_REPORT_PATH|write.*review.*file|put.*analysis.*file' \
    "reviewer prompt has no ambiguous writable report path"
assert_lacks "$SDD" 'review artifacts in files|review report path' \
    "controller does not route reviewer output through checkout files"
assert_has "$SDD" 'create both.*idle|already-created idle' \
    "children are created idle"
assert_has "$SDD" 'wait until the implementer is idle' \
    "implementer reaches idle before reviewer initialization"
assert_has "$SDD" 'sending the reviewer prompt together with review pass 1' \
    "reviewer initialization waits for the implementer"
assert_has "$IMPLEMENTER" 'already-created idle child' \
    "implementer prompt is not an auto-start kickoff"
assert_has "$REVIEWER" 'already-created idle child' \
    "reviewer prompt is not an auto-start kickoff"
assert_has "$SDD" 'every child activation.*counts|every activation.*counts' \
    "every child activation consumes the budget"
assert_has "$SDD" 'BLOCKED.*counts|blocked.*consumes' \
    "blocked turns consume the activation budget"
assert_has "$SDD" 'base allowance.*8 × M \+ 1|8 × M \+ 1.*base allowance' \
    "phase activation budget has a finite base formula"
assert_has "$SDD" 'conditional reserve.*6 × M|6 × M.*conditional reserve' \
    "phase activation budget has a finite conditional reserve"
assert_has "$SDD" 'When Pass 3 is CONVERGING, a conditional reserve' \
    "conditional reserve unlocks only after pass 3 converges"
assert_has "$SDD" 'absolute.*14 × M \+ 1|14 × M \+ 1.*absolute' \
    "phase activation budget has an absolute maximum"
assert_has "$SDD" 'up to two blocker-resolution' \
    "blocker allowance is finite"
assert_has "$SDD" 'stop.*reapproval.*exceed|before exceeding.*reapproval' \
    "budget exhaustion requires reapproval"
assert_has "$EXECUTING" 'approval.*phase|approved phase' \
    "inline routing preserves the phase approval gate"
assert_has "$REQUESTING" 'additional review.*approval|approval.*additional review' \
    "extra review requires new approval"
assert_lacks "$CODE_REVIEWER" 'git worktree add|worktree add' \
    "generic reviewer cannot create a temporary worktree"
assert_has "$CODE_REVIEWER" 'stop.*controller|controller.*stop' \
    "generic reviewer stops when read-only inspection is insufficient"
for runtime_field in 'EXACT_MODEL_AND_PROVIDER' 'REASONING_EFFORT' 'CONTEXT_TIER'; do
    assert_has "$CODE_REVIEWER" "$runtime_field" \
        "generic reviewer template requires $runtime_field"
    assert_has "$REQUESTING" "$runtime_field" \
        "generic review dispatch requires $runtime_field"
done
assert_has "$REQUESTING" 'harness-native|native.*harness' \
    "generic review dispatch applies approved settings through the harness"
assert_has "$REQUESTING" 'cannot explicitly apply.*stop|stop.*cannot explicitly apply' \
    "unsupported runtime settings require revised approval"
assert_has "$WRITING" '2-3 closely related.*milestones|two or three closely related.*milestones' \
    "plans define bounded phases"
assert_has "$README" 'persistent implementer' \
    "user documentation describes the persistent implementer"
assert_has "$README" 'persistent.*reviewer' \
    "user documentation describes the persistent reviewer"
assert_lacks "$CODEX" 'close each implementer.*after its task' \
    "Codex keeps the phase pair reusable"
assert_has "$GEMINI" 'at most one active delegated agent' \
    "Gemini preserves sequential bounded dispatch"
assert_has "$PI" 'do not emulate persistence with fresh children' \
    "Pi refuses fresh-child emulation"
assert_has "$ANTIGRAVITY" 'execute the phase inline' \
    "Antigravity falls back inline without resumable children"
assert_has "$HERMES" 'fresh children' \
    "Hermes falls back inline without resumable children"
assert_has "$REPO_ROOT/tests/claude-code/test-subagent-driven-development-integration.sh" \
    'claude-sonnet-4-5-20250929.*Anthropic|Anthropic.*claude-sonnet-4-5-20250929' \
    "integration fixture names an exact approved model and provider"
assert_has "$REPO_ROOT/tests/claude-code/test-subagent-driven-development-integration.sh" \
    'medium reasoning, default context' \
    "integration fixture names approved effort and context"
assert_has "$REPO_ROOT/tests/claude-code/test-subagent-driven-development-integration.sh" \
    'maximum 17 child activations' \
    "integration fixture states the finite phase budget"
assert_lacks "$REPO_ROOT/tests/claude-code/README.md" \
    'persistent implementer and reviewer are reused|Delegated work is sequential|Reviewer stays read-only|Findings return to the same implementer|stops at the approved phase boundary' \
    "test documentation does not overclaim unasserted runtime properties"

echo "=== Bounded delegation contract passed ==="
