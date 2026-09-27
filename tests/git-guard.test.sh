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
# A feature-branch dir holding a nested checkout on main, and a twin whose
# nested checkout sits on a feature branch, for relative -C paths (resolved
# against the hook's cwd, or the project dir when the input has no cwd):
HUB_DIR=$(mktemp -d); git -C "$HUB_DIR" init -q -b feature/hub
git -C "$HUB_DIR" init -q -b main code
HUB2_DIR=$(mktemp -d); git -C "$HUB2_DIR" init -q -b feature/hub2
git -C "$HUB2_DIR" init -q -b feature/y code
trap 'rm -rf "$NONGIT_DIR" "$MAIN_REPO" "$FEAT_REPO" "$HUB_DIR" "$HUB2_DIR"' EXIT

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
check "echo of a force-push string allowed"    0 "$NONGIT_DIR" "echo git push --force origin main"
check "commit message mentioning force-push allowed" 0 "$NONGIT_DIR" "git commit -m 'never git push --force origin main'"
check "changelog-style quoted message with && allowed" 0 "$NONGIT_DIR" "git commit -m 'fix: git push -f origin main && git log main case'"
check "sudo-wrapped force push to main blocked" 2 "$NONGIT_DIR" "sudo git push --force origin main"
check "full-path git force push to main blocked" 2 "$NONGIT_DIR" "/usr/bin/git push -f origin main"
check "plus-refspec force push to main blocked" 2 "$NONGIT_DIR" "git push origin +main"
check "full-ref force push to main blocked"    2 "$NONGIT_DIR" "git push -f origin refs/heads/main"
check "refspec dst full-ref main blocked"      2 "$NONGIT_DIR" "git push -f origin HEAD:refs/heads/main"
check "branch named feature/main allowed"      0 "$NONGIT_DIR" "git push -f origin feature/main"

# git -C <path>: the bare force push is judged by the checkout at <path>.
check "-C on a main checkout, bare force push blocked" 2 "$FEAT_REPO" "git -C $MAIN_REPO push --force origin"
check "-C on a feature checkout from main project allowed" 0 "$MAIN_REPO" "git -C $FEAT_REPO push --force origin"
check "-C relative to project dir, main checkout blocked" 2 "$HUB_DIR" "git -C code push -f origin"
check "-C=<path> form on a main checkout blocked" 2 "$FEAT_REPO" "git -C=$MAIN_REPO push -f origin"
check "-C with explicit feature refspec allowed" 0 "$FEAT_REPO" "git -C $MAIN_REPO push -f origin feature/x"
check "-C with explicit main refspec blocked" 2 "$FEAT_REPO" "git -C $FEAT_REPO push -f origin main"

# The input's cwd is where the command runs (it follows cd and worktrees;
# CLAUDE_PROJECT_DIR stays at the project root): the bare force push and a
# relative -C are judged from there, and the project dir only stands in
# when the input carries no cwd (the cases above).
check_cwd() { # description, expected_exit, project_dir, cwd, bash_command_string
  desc="$1"; expected="$2"; dir="$3"; cwd="$4"; cmd="$5"
  printf '{"tool_name":"Bash","cwd":"%s","tool_input":{"command":"%s"}}' "$cwd" "$cmd" \
    | CLAUDE_PROJECT_DIR="$dir" bash "$GUARD" >/dev/null 2>&1
  actual=$?
  if [ "$actual" -eq "$expected" ]; then
    pass=$((pass+1))
  else
    fail=$((fail+1)); echo "FAIL: $desc (expected exit $expected, got $actual)"
  fi
}
check_cwd "cwd on a main checkout, bare force push blocked (project dir on feature)" 2 "$FEAT_REPO" "$MAIN_REPO" "git push -f origin"
check_cwd "cwd on a feature checkout, bare force push allowed (project dir on main)" 0 "$MAIN_REPO" "$FEAT_REPO" "git push -f origin"
check_cwd "-C relative to cwd, main checkout blocked (no such path under the project dir)" 2 "$FEAT_REPO" "$HUB_DIR" "git -C code push -f origin"
check_cwd "-C=<path> relative to cwd, main checkout blocked" 2 "$FEAT_REPO" "$HUB_DIR" "git -C=code push -f origin"
check_cwd "-C relative to cwd, feature checkout allowed although the project dir's same path is on main" 0 "$HUB_DIR" "$HUB2_DIR" "git -C code push -f origin"
check_cwd "empty cwd falls back to the project dir" 2 "$MAIN_REPO" "" "git push -f origin"

# FLOW_PROTECTED_BRANCHES replaces the default main,master set.
check_env() { # description, expected_exit, protected_list, bash_command_string
  desc="$1"; expected="$2"; list="$3"; cmd="$4"
  printf '{"tool_name":"Bash","tool_input":{"command":"%s"}}' "$cmd" \
    | FLOW_PROTECTED_BRANCHES="$list" CLAUDE_PROJECT_DIR="$NONGIT_DIR" bash "$GUARD" >/dev/null 2>&1
  actual=$?
  if [ "$actual" -eq "$expected" ]; then
    pass=$((pass+1))
  else
    fail=$((fail+1)); echo "FAIL: $desc (expected exit $expected, got $actual)"
  fi
}
check_env "env: force push to develop blocked"      2 "develop"      "git push --force origin develop"
check_env "env: force push to main allowed when not listed" 0 "develop" "git push --force origin main"
check_env "env: list with spaces blocks each name"  2 "main, develop" "git push -f origin develop"
check_env "env: empty value keeps main protected"   2 ""             "git push -f origin main"
check_env "env: develop unprotected by default"     0 ""             "git push -f origin develop"

echo "pass=$pass fail=$fail"
[ "$fail" -eq 0 ]
