#!/bin/bash
# Unit tests for flow/scripts/git-guard.sh
# Run: bash tests/git-guard.test.sh
set -u
GUARD="$(cd "$(dirname "$0")/.." && pwd)/flow/scripts/git-guard.sh"
pass=0; fail=0

# Deterministic environments for the current-branch fallback:
NONGIT_DIR=$(mktemp -d)                       # not a repo → no branch
MAIN_REPO=$(mktemp -d); git -C "$MAIN_REPO" init -q -b main
FEAT_REPO=$(mktemp -d); git -C "$FEAT_REPO" init -q -b feature/x
trap 'rm -rf "$NONGIT_DIR" "$MAIN_REPO" "$FEAT_REPO"' EXIT

check() { # description, expected_exit, project_dir, bash_command_string
  desc="$1"; expected="$2"; dir="$3"; cmd="$4"
  printf '{"tool_name":"Bash","tool_input":{"command":"%s"}}' "$cmd" \
    | CLAUDE_PROJECT_DIR="$dir" bash "$GUARD" >/dev/null 2>&1
  actual=$?
  if [ "$actual" -eq "$expected" ]; then
    pass=$((pass+1))
  else
    fail=$((fail+1)); echo "FAIL: $desc (expected exit $expected, got $actual)"
  fi
}

check "force push to main blocked"            2 "$NONGIT_DIR" "git push --force origin main"
check "force-with-lease to master blocked"    2 "$NONGIT_DIR" "git push --force-with-lease origin master"
check "short -f push to main blocked"         2 "$NONGIT_DIR" "git push -f origin main"
check "force push to feature ref allowed even from main checkout" 0 "$MAIN_REPO" "git push --force origin feature/x"
check "bare force push while on main blocked" 2 "$MAIN_REPO"   "git push -f origin"
check "bare force push on feature branch allowed" 0 "$FEAT_REPO" "git push -f origin"
check "plain push to main allowed"            0 "$NONGIT_DIR" "git push origin main"
check "no-verify commit blocked"              2 "$NONGIT_DIR" "git commit --no-verify -m msg"
check "plain commit allowed"                  0 "$NONGIT_DIR" "git commit -m msg"
check "unrelated command allowed"             0 "$NONGIT_DIR" "ls -la"
check "empty command tolerated"               0 "$NONGIT_DIR" ""
check "compound: force push to feature + git log main allowed" 0 "$MAIN_REPO" "git push --force-with-lease origin feature/x && git log --oneline -2 main"
check "compound: force push to main after other command blocked" 2 "$NONGIT_DIR" "git log --oneline && git push -f origin main"
check "compound: bare force push on main + later main-word blocked" 2 "$MAIN_REPO" "git push -f origin && git log -2 main"

echo "pass=$pass fail=$fail"
[ "$fail" -eq 0 ]
