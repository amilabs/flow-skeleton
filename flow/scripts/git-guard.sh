#!/bin/bash
# flow git-guard — PreToolUse(Bash) hook.
# Blocks: force-push targeting main/master; git commit --no-verify.
# Fail-open: any tooling problem allows the command through (exit 0).

command -v jq >/dev/null 2>&1 || exit 0
input=$(cat) || exit 0
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null) || exit 0
[ -n "$cmd" ] || exit 0

# Analyze each pipeline/list segment separately so words from neighboring
# commands (e.g. "... && git log main") cannot leak into the push check.
blocked=""
while IFS= read -r seg; do
  printf '%s' "$seg" | grep -qE 'git[^|;&]*push[^|;&]*(--force(-with-lease)?([= ]|$)|[[:space:]]-f([[:space:]]|$))' || continue
  if printf '%s' "$seg" | grep -qE '[[:space:]](main|master)([[:space:]]|:|$)'; then
    blocked="yes"; break
  fi
  # Second non-flag token after "push" is the refspec (first is the remote).
  refspec=$(printf '%s' "$seg" | awk '{
    push=0; n=0
    for (i=1; i<=NF; i++) {
      if ($i=="push") { push=1; continue }
      if (!push) continue
      if ($i ~ /^-/) continue
      n++
      if (n==2) { print $i; exit }
    }
  }')
  if [ -z "$refspec" ]; then
    branch=$(git -C "${CLAUDE_PROJECT_DIR:-.}" symbolic-ref --short HEAD 2>/dev/null)
    case "$branch" in main|master) blocked="yes"; break;; esac
  fi
done <<EOF
$(printf '%s' "$cmd" | tr '|;&' '\n')
EOF

if [ -n "$blocked" ]; then
  echo "flow git-guard: force-push to main/master is blocked. Push a branch and open a PR, or have the owner run the command manually." >&2
  exit 2
fi

if printf '%s' "$cmd" | grep -qE 'git[^|;&]*commit[^|;&]*--no-verify'; then
  echo "flow git-guard: 'git commit --no-verify' is blocked. Fix the failing hook instead of bypassing it." >&2
  exit 2
fi

exit 0
