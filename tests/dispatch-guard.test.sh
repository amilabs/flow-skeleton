#!/bin/zsh
# dispatch-guard regression tests (mirrors git-guard.test.sh style).
set -u
DIR="$(cd "$(dirname "$0")/.." && pwd)"
GUARD="$DIR/flow/scripts/dispatch-guard.py"
SID="tguard-$$"
STATE="$(python3 -c 'import tempfile; print(tempfile.gettempdir())')/flow-dispatch-guard-$SID.json"
rm -f "$STATE"
pass=0; fail=0

check() { # $1 desc, $2 expected rc, $3 mode, $4 stdin json
    printf '%s' "$4" | python3 "$GUARD" "$3" >/dev/null 2>&1
    rc=$?
    if [[ "$rc" == "$2" ]]; then
        pass=$((pass+1))
    else
        fail=$((fail+1)); echo "FAIL: $1 (rc=$rc, want $2)"
    fi
}

DISPATCH="{\"session_id\":\"$SID\",\"tool_name\":\"Task\",\"tool_input\":{}}"
SKILL="{\"session_id\":\"$SID\",\"tool_name\":\"Skill\",\"tool_input\":{\"skill\":\"superpowers:dispatching-parallel-agents\"}}"
OTHER_SKILL="{\"session_id\":\"$SID\",\"tool_name\":\"Skill\",\"tool_input\":{\"skill\":\"superpowers:brainstorming\"}}"

check "first dispatch allowed" 0 pre "$DISPATCH"
check "second dispatch blocked once" 2 pre "$DISPATCH"
check "third dispatch allowed (already warned)" 0 pre "$DISPATCH"

rm -f "$STATE"
check "fresh session: first dispatch allowed" 0 pre "$DISPATCH"
check "recording an unrelated skill passes" 0 post "$OTHER_SKILL"
check "second dispatch still blocked (wrong skill)" 2 pre "$DISPATCH"

rm -f "$STATE"
check "record the discipline skill" 0 post "$SKILL"
check "first dispatch allowed" 0 pre "$DISPATCH"
check "second dispatch allowed (disciplined)" 0 pre "$DISPATCH"
check "tenth-style dispatch allowed (disciplined)" 0 pre "$DISPATCH"

check "garbage stdin fails open" 0 pre "not-json"
check "empty stdin fails open" 0 pre ""
check "post with garbage fails open" 0 post "not-json"

rm -f "$STATE"
echo "dispatch-guard: pass=$pass fail=$fail"
[[ "$fail" == "0" ]]
