---
name: spec
description: Design a change before any implementation - interview, impact analysis, OpenSpec change folder with risk profile and behavior inventory. Ends at the owner approval gate.
disable-model-invocation: true
argument-hint: "[task description]"
---

# Design a change

Task: $ARGUMENTS

You are in the design phase. Do not write implementation code. The
deliverable is an OpenSpec change folder ready for owner approval.

## Setup

- This phase belongs on the strongest model: if the session is not on
  Fable, suggest `/model fable` (advisory — continue either way). Plan mode
  is recommended.
- Read `openspec/project.md` if it exists (project context and constraints).

## Steps

1. **Interview.** Clarify with AskUserQuestion whatever the request leaves
   open: scope, out-of-scope, constraints, success criteria. Skip what the
   request already answers; prefer a few sharp questions over many obvious
   ones.
2. **Locate affected areas.** For large codebases use an Explore subagent
   so this session's context stays clean.
3. **Baseline specs (brownfield).** For each affected capability, read its
   spec under `openspec/specs/`. If none exists, first write a baseline
   spec of CURRENT behavior — document only the area being touched, never
   the whole legacy project upfront.
4. **Impact analysis.** If the change modifies existing code with
   dependents outside the change scope, run /flow:blast-radius and put the
   impact note in the change's design.md.
5. **Risk profile.** Select profile(s) from the flow risk-profiles table
   and record them in proposal.md. If the change qualifies as trivial,
   stop: tell the owner the fast path applies and no change folder is
   needed.
6. **Behavior inventory (ui-surface).** List observable behavior that must
   survive: routes/pages, navigation entries, table columns, form fields,
   states (empty/error/loading/success). Keep it in the change folder.
7. **Write the change folder** `openspec/changes/<kebab-case-id>/`:
   - `proposal.md` — why, what, risk profile(s), explicit out-of-scope list
   - spec deltas for affected capabilities
   - `design.md` — only when there are non-obvious tradeoffs (blast-radius
     impact note lives here)
   - `tasks.md` — ordered checkbox tasks, each sized for one test cycle;
     mark decisions only the owner can make with `[USER GATE]`
8. **Validate.** With the openspec CLI: `openspec validate <id>`. Without
   it, check structurally: files above present, every task actionable,
   profile recorded, inventory present when required.
9. **Stop for approval.** Summarize the change and ask the owner to approve
   it. Do not start implementation. After approval the owner runs
   /flow:implement — ideally in a fresh session on Opus.
