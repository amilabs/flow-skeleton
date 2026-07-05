---
name: spec
description: Design a change before any implementation - interview, impact analysis, OpenSpec change folder with risk profile and behavior inventory. Ends at the owner approval gate. Invoke only when the owner explicitly asks to design or spec a change (in any wording); never start it on your own initiative.
argument-hint: "[task description]"
---

# Design a change

Task: $ARGUMENTS

You are in the design phase. Do not write implementation code. The
deliverable is an OpenSpec change folder ready for owner approval.

Relationship to superpowers: this skill IS the brainstorming/design phase
for flow-managed changes — do not additionally invoke the superpowers
brainstorming or writing-plans skills; the change folder (proposal, design,
tasks) replaces their design doc and plan. Superpowers execution
disciplines (TDD, debugging, verification, finishing a branch) apply
later, from /flow:implement and /flow:accept.

## Architecture bar (never lower this)

Decompose the change into units with one clear purpose each and
well-defined interfaces: a consumer must be able to use a unit without
reading its internals, and internals must be changeable without breaking
consumers. Follow existing codebase patterns; when existing boundaries
hinder the change, include targeted improvements in the design — never
unrelated refactoring. Design depth scales with risk, not with mood: the
heavier the change, the fuller design.md must be.

## Setup

- This phase belongs on the strongest model: if the session is not on
  Fable, suggest `/model fable` (advisory — continue either way; the picker
  key `s` switches this session only). Effort is the owner's choice too —
  suggest a higher level for architecturally heavy changes. Plan mode is
  recommended.
- Read `openspec/project.md` if it exists (project context and constraints).

## Steps

1. **Scope check first.** If the request spans multiple independent
   subsystems, decompose it into several changes and spec only the first —
   each change must be implementable and acceptable on its own.
2. **Interview.** Clarify with AskUserQuestion whatever the request leaves
   open: scope, out-of-scope, constraints, success criteria. Skip what the
   request already answers; prefer a few sharp questions over many obvious
   ones.
3. **Explore alternatives.** When the change has architectural freedom,
   sketch 2-3 approaches with trade-offs and lead with your recommendation
   before settling. Skip only when there is genuinely one reasonable way.
4. **Locate affected areas.** For large codebases use an Explore subagent
   so this session's context stays clean.
5. **Baseline specs (brownfield).** For each affected capability, read its
   spec under `openspec/specs/`. If none exists, first write a baseline
   spec of CURRENT behavior — document only the area being touched, never
   the whole legacy project upfront.
6. **Impact analysis.** If the change modifies existing code with
   dependents outside the change scope, run /flow:blast-radius and put the
   impact note in the change's design.md.
7. **Risk profile.** Select profile(s) from the flow risk-profiles table
   and record them in proposal.md. If the change qualifies as trivial,
   stop: tell the owner the fast path applies and no change folder is
   needed.
8. **Behavior inventory (ui-surface).** List observable behavior that must
   survive: routes/pages, navigation entries, table columns, form fields,
   states (empty/error/loading/success). Keep it in the change folder.
9. **Write the change folder** `openspec/changes/<kebab-case-id>/`:
   - `proposal.md` — why, what, risk profile(s), the chosen approach and
     rejected alternatives (one line each), explicit out-of-scope list
   - spec deltas for affected capabilities
   - `design.md` — REQUIRED when the change crosses module boundaries,
     introduces new components or interfaces, or carries the api-contract,
     data-storage, or auth-security profile: component boundaries, exact
     interfaces/signatures, data flow, error handling. The blast-radius
     impact note lives here. Omit only for changes with no architectural
     freedom.
   - `tasks.md` — ordered checkbox tasks, each sized for one test cycle
     and naming the files it touches; for multi-task changes each task
     states what it consumes from earlier tasks and produces for later
     ones (names and signatures); mark decisions only the owner can make
     with `[USER GATE]`
10. **Self-review, then validate.** Re-read the change folder with fresh
    eyes: placeholders, internal contradictions, requirements readable two
    ways, scope creep — fix inline. Then, with the openspec CLI:
    `openspec validate <id>`; without it, check structurally: files above
    present, every task actionable, profile recorded, inventory present
    when required.
11. **Stop for approval.** Summarize the change and ask the owner to
    approve it. Do not start implementation. After approval the owner runs
    /flow:implement — ideally in a fresh session on Opus.
