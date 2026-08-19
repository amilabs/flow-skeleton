#!/bin/sh
# flow SessionStart hook: inject the session contract into context
# (stdout of a SessionStart hook is added to the model's context).
# Mirrors how superpowers guarantees its meta-rule is seen every session.
# Fail-open: never block session start.

IP="$HOME/.claude/plugins/installed_plugins.json"
if [ -r "$IP" ] && ! grep -q '"superpowers@' "$IP" 2>/dev/null; then
    echo "WARNING: the superpowers plugin looks missing on this machine — flow depends on it. Install: /plugin install superpowers@claude-plugins-official"
fi

cat <<'EOF'
flow session contract (the flow plugin is active in this session):
- Non-trivial work: /flow:spec -> owner approval -> /flow:implement (fresh session) -> /flow:accept -> owner accepts. Trivial changes (one-sentence diff, no dependents) skip the lifecycle.
- Mandatory superpowers wiring: fan-out to 2+ agents or any multi-session batch -> invoke dispatching-parallel-agents BEFORE the first dispatch, one git worktree per writing agent; bug or unexpected behavior -> systematic-debugging before any fix; before claiming a task done -> verification-before-completion (fresh evidence, then tick); processing review findings -> receiving-code-review.
- Domain skills: the task touches a specific technology or domain (a database, framework, performance, UX/design, or another specialized domain) -> check the skill list for a matching domain skill and invoke it before working in that area; if a core project technology has no skill in this session, say so to the owner instead of silently proceeding.
- Static analyzers are part of the definition of done (commands live in CLAUDE.md).
- Never commit or push without an explicit owner instruction. WIP stays local within a version. Nothing non-English is pushed without recorded permission.
EOF
exit 0
