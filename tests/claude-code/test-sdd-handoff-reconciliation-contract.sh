#!/usr/bin/env bash
# Static RED contract for the SDD handoff/status reconciliation race.
#
# Pressure fixture:
# - A child's purpose=handoff message is accepted while the parent is in-flight.
# - The parent later observes the child idle, but the handoff is absent from its turn.
# - Stale event ordering pressures the parent to say the child is still working.
# - An older incompatible message is admitted before terminal completion.
#
# Required behavior:
# refresh authoritative status before claims; reconcile session state, commit,
# and report; request exactly one recovery handoff; process compatible admitted
# messages; mark stale admitted messages DISCARDED_AS_STALE with a reason; stop
# after failed recovery; never claim visibility into an undelivered private queue.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

SDD="${SDD_CONTRACT_FILE:-$REPO_ROOT/skills/subagent-driven-development/SKILL.md}"
IMPLEMENTER="${IMPLEMENTER_CONTRACT_FILE:-$REPO_ROOT/skills/subagent-driven-development/implementer-prompt.md}"
REVIEWER="${REVIEWER_CONTRACT_FILE:-$REPO_ROOT/skills/subagent-driven-development/milestone-reviewer-prompt.md}"
failures=0

assert_section_has_all() {
    local file="$1"
    local heading="$2"
    local label="$3"
    shift 3
    local section
    local pattern
    local missing=()

    section="$(
        awk -v heading="$heading" '
            $0 == heading { in_section = 1; next }
            in_section && /^#{1,6}[[:space:]]/ { exit }
            in_section { print }
        ' "$file"
    )"

    if [ -z "$section" ]; then
        printf '  [FAIL] %s\n' "$label"
        printf '         missing section %s in %s\n' \
            "$heading" "${file#"$REPO_ROOT/"}"
        failures=$((failures + 1))
        return
    fi

    for pattern in "$@"; do
        if ! grep -Eiq "$pattern" <<<"$section"; then
            missing+=("$pattern")
        fi
    done

    if [ "${#missing[@]}" -eq 0 ]; then
        printf '  [PASS] %s\n' "$label"
    else
        printf '  [FAIL] %s\n' "$label"
        printf '         section %s in %s is missing:\n' \
            "$heading" "${file#"$REPO_ROOT/"}"
        printf '           /%s/\n' "${missing[@]}"
        failures=$((failures + 1))
    fi
}

echo "=== SDD handoff and admitted-message reconciliation contract ==="

assert_section_has_all "$SDD" "## Live Status and Missing Handoff Reconciliation" \
    "parent refreshes status and performs one bounded handoff recovery" \
    'refresh' 'authoritative' '(live )?status' 'before' 'working' 'waiting' \
    'milestone' 'phase' 'complet' 'idle' 'handoff' 'missing' \
    '(latest )?(child|session).*state' '(latest )?commit' '(latest )?report' \
    'exactly one' 'recovery handoff' 'delivery failure' 'stop' \
    '(never|do not)' 'wait indefinitely' \
    'recovery activation.*(terminal|idle)' 'authoritative.*(status|inspection)' \
    '(condition|status) mechanism' 'reconcile.*exactly once' \
    'admitted messages' '(second|another) recovery'

assert_section_has_all "$SDD" "## Phase Approval Gate" \
    "phase proposal discloses layered primary, paired-recovery, and absolute caps" \
    'base.*8 × milestones \+ 1' 'conditional.*6 × milestones' \
    'primary.*14 × milestones \+ 1' \
    'recover.*14 × milestones \+ 1' '28 × milestones \+ 2' \
    'at most six review passes'

assert_section_has_all "$SDD" "## Setup" \
    "setup pairs one recovery with each authorized primary activation" \
    'base.*8 × M \+ 1.*primary' \
    'Pass 3.*CONVERGING.*conditional.*6 × M|conditional.*6 × M.*Pass 3.*CONVERGING' \
    'maximum.*primary.*14 × M \+ 1|14 × M \+ 1.*maximum.*primary' \
    'each.*authorized primary activation.*at most one recovery' \
    'base.*8 × M \+ 1.*recover' \
    'conditional.*6 × M.*recover.*unlock' \
    'maximum.*recover.*14 × M \+ 1|14 × M \+ 1.*maximum.*recover' \
    '28 × M \+ 2' \
    'cannot.*Passes 4.?6' 'cannot.*ordinary work' \
    'cannot.*another primary activation' 'cannot.*replacement child' \
    'cannot.*expand scope' 'cannot.*second recovery' \
    'every recovery.*counts' 'stop.*reapproval'

assert_section_has_all "$SDD" "## Admitted Message Reconciliation" \
    "parent processes current admitted messages and discards stale ones" \
    'process' 'compatible' 'message' 'admitted' 'current turn' \
    'DISCARDED_AS_STALE' 'reason' 'newer assignment' 'newer commit' \
    'closed phase'

assert_section_has_all "$SDD" "## Private Queue Boundary" \
    "skill disclaims visibility into an undelivered private queue" \
    'cannot' '(inspect|see|read)' '(host-private|private|transport)' \
    '(not-yet-delivered|undelivered)' 'queue'

for prompt in "$IMPLEMENTER" "$REVIEWER"; do
    assert_section_has_all "$prompt" "## Admitted Message Reconciliation" \
        "$(basename "$prompt") reconciles admitted messages before terminal output" \
        'before' '(terminal|BLOCKED|MILESTONE_READY_FOR_REVIEW|complete review)' \
        'process' 'compatible' 'message' 'admitted' 'current turn' \
        'DISCARDED_AS_STALE' 'reason' 'newer assignment' 'newer commit' \
        'closed phase'
done

if [ "$failures" -gt 0 ]; then
    printf '=== Contract failed: %d missing rule(s) ===\n' "$failures"
    exit 1
fi

echo "=== SDD handoff and admitted-message reconciliation contract passed ==="
