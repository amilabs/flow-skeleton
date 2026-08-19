---
name: closed-area-gate
description: Instructions for the DEDICATED closed-area gate session that some risk profiles demand at /flow:accept. Load ONLY inside that dedicated, compatible, owner-armed session — never during ordinary flow work, and never inside the accept session itself, which consumes the gate's verdict by reference.
disable-model-invocation: true
---

# The closed-area gate session

The risk-profiles table's "closed-area review" column names when this gate is
mandatory. The gate NEVER runs inside the working or accept session: dense
material from this area destabilizes general-purpose working sessions (owner
rule; one in-session attempt killed a session on 2026-08-18). Everything below
concerns only the dedicated session the owner sets up for it.

## Session preconditions

- A dedicated session on a compatible model (the owner's standing choice:
  Opus), started for this gate alone.
- The owner has armed the tooling for it explicitly; nothing here is armed by
  default in working sessions. The machine-wide default STAYS off: the
  user-scope `enabledPlugins` entry for the specialized official plugin
  remains `false` in `~/.claude/settings.json`. The dedicated session arms it
  only through a temporary CLI override —
  `claude --settings '{"enabledPlugins":{"claude-security@claude-plugins-official":true}}'`
  — never by editing the global file, so nothing needs reverting when the
  session ends.
- The session starts with the project's standing boundary preamble (see the
  project's closed-area memory records) before any repository content is read.

## What the gate runs

- The built-in `/security-review` command over the candidate's pending
  changes, scoped by the change's risk profile (an `auth-boundary` profile
  reviews the affected auth/session/permission/payment flows; a
  `data-storage` profile with the "if auth-adjacent" cell reviews the
  storage/tenancy boundary; a `build-deploy` profile's cell means the
  dependency audit for new dependencies).
- Project-specific review skills for this area, when the project registers
  them, load HERE and only here.

## The verdict, and how accept consumes it

The gate's output is a verdict record: the exact git SHA reviewed, the
profile(s) covered, the verdict (pass, or blocking findings by reference),
and the date. The accept session records that reference — never the gate's
content — and BLOCKS acceptance when the verdict's SHA does not equal the
candidate under acceptance: a stale verdict is no verdict.

## The continuous layer (init step 7)

The opt-in continuous-guidance plugin that /flow:init offers for exposed
projects is `security-guidance`
(`/plugin install security-guidance@claude-plugins-official`). Install and
arm it only per the owner's explicit decision, and never leave it enabled in
ordinary working sessions of projects that follow the dedicated-session rule.
