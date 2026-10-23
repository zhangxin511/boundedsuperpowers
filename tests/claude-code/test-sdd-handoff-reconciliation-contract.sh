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

SDD="$REPO_ROOT/skills/subagent-driven-development/SKILL.md"
IMPLEMENTER="$REPO_ROOT/skills/subagent-driven-development/implementer-prompt.md"
REVIEWER="$REPO_ROOT/skills/subagent-driven-development/milestone-reviewer-prompt.md"
failures=0

assert_has() {
    local file="$1"
    local pattern="$2"
    local label="$3"

    if tr '\n' ' ' < "$file" | grep -Eiq "$pattern"; then
        printf '  [PASS] %s\n' "$label"
    else
        printf '  [FAIL] %s\n' "$label"
        printf '         missing /%s/ in %s\n' "$pattern" "${file#"$REPO_ROOT/"}"
        failures=$((failures + 1))
    fi
}

echo "=== SDD handoff and admitted-message reconciliation contract ==="

assert_has "$SDD" \
    'refresh.*authoritative.*(live )?status.*before.*(working|waiting)' \
    "parent refreshes authoritative status before working/waiting claims"
assert_has "$SDD" \
    'refresh.*authoritative.*(live )?status.*before.*(milestone|phase).*complet' \
    "parent refreshes authoritative status before completion claims"
assert_has "$SDD" \
    'idle.*(expected )?handoff.*missing' \
    "idle-without-handoff triggers reconciliation"
assert_has "$SDD" \
    '(missing handoff.*(latest )?(child|session).*state|(latest )?(child|session).*state.*missing handoff)' \
    "missing-handoff recovery inspects latest session state"
assert_has "$SDD" \
    '(missing handoff.*(latest )?commit|(latest )?commit.*missing handoff)' \
    "missing-handoff recovery inspects the latest commit"
assert_has "$SDD" \
    '(missing handoff.*(latest )?report|(latest )?report.*missing handoff)' \
    "missing-handoff recovery inspects the latest report"
assert_has "$SDD" \
    'exactly one.*recovery handoff|recovery handoff.*exactly once' \
    "parent requests exactly one recovery handoff"
assert_has "$SDD" \
    '(recovery.*fail|handoff.*still missing).*(stop|delivery failure)' \
    "failed recovery stops with an explicit delivery failure"
assert_has "$SDD" \
    '(never|do not).*(wait indefinitely|keep waiting)' \
    "parent never waits indefinitely for a missing handoff"
assert_has "$SDD" \
    'messages? admitted.*(current )?turn.*process.*compatible' \
    "parent processes compatible messages admitted into the turn"
assert_has "$SDD" \
    'DISCARDED_AS_STALE.*reason.*(newer assignment|newer commit|closed phase)' \
    "parent explicitly discards superseded admitted messages with a reason"
assert_has "$SDD" \
    '(cannot.*(inspect|see|read).*(host-private|private|transport).*(not-yet-delivered|undelivered).*queue|(host-private|private|transport).*(not-yet-delivered|undelivered).*queue.*cannot.*(inspect|see|read))' \
    "skill does not claim visibility into an undelivered private queue"

for prompt in "$IMPLEMENTER" "$REVIEWER"; do
    assert_has "$prompt" \
        'before.*(terminal|BLOCKED|MILESTONE_READY_FOR_REVIEW|complete review).*process.*message.*admitted.*turn' \
        "$(basename "$prompt") processes admitted messages before terminal output"
    assert_has "$prompt" \
        'DISCARDED_AS_STALE.*reason.*(newer assignment|newer commit|closed phase)' \
        "$(basename "$prompt") explicitly discards stale admitted messages"
done

if [ "$failures" -gt 0 ]; then
    printf '=== Contract failed: %d missing rule(s) ===\n' "$failures"
    exit 1
fi

echo "=== SDD handoff and admitted-message reconciliation contract passed ==="
