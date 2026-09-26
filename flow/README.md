# flow

Universal development workflow plugin. Thin by design: 7 skills, 1
agent, 3 hook scripts (4 hook registrations) — growth requires removing
something first.

## Lifecycle

/flow:spec (design, strongest model) → owner approves →
/flow:implement (TDD, economical model, fresh session) →
/flow:accept (checks + live verify + plan compliance + risk-scaled review)
→ owner accepts → merge/PR, change archived.

## Components

- skills/spec — design phase, ends at the approval gate
- skills/implement — execution loop with scope discipline
- skills/accept — acceptance gates and owner summary
- skills/blast-radius — dependent mapping + characterization tests
- skills/init — project bootstrap and migration
- skills/risk-profiles — background knowledge: change type → verification
- skills/closed-area-gate — invoke-only instructions for the dedicated
  closed-area gate session
- agents/plan-reviewer — read-only diff-vs-change compliance review
- hooks + scripts/git-guard.{sh,py} — blocks force-push to protected
  branches (main/master, or the comma-separated FLOW_PROTECTED_BRANCHES
  environment variable) and --no-verify commits; shlex-based (quote-aware,
  per-segment), fail-open
- hooks + scripts/dispatch-guard.{sh,py} — pre (Task/Agent) and post
  (Skill) registrations: warns once per session when a second agent is
  dispatched without the dispatching-parallel-agents skill; fail-open
- hooks + scripts/session-context.sh — SessionStart: injects the session
  contract

## Layering

flow orchestrates and does not duplicate: process discipline comes from
superpowers, spec artifacts follow OpenSpec conventions (CLI optional —
plain files are the contract), review/verify/LSP come from Claude Code
built-ins and official plugins.
