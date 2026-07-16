---
name: init
description: Bootstrap a project for the flow workflow (new project) or migrate an existing one (--existing). Sets up CLAUDE.md, OpenSpec structure, LSP suggestion, run recipe, optional project hooks. Invoke only when the owner explicitly asks to bootstrap or migrate a project (in any wording); never start it on your own initiative.
argument-hint: "[--existing]"
---

# Project bootstrap

Mode: `--existing` in "$ARGUMENTS" means migration of a live project;
otherwise fresh setup. Everything here is opt-in and non-destructive:
propose, show the diff, apply only on confirmation.

## Both modes

1. **Detect the stack**: package.json (Node/TS — note the framework),
   pyproject.toml or requirements.txt (Python), composer.json (PHP). Mixed
   stacks get all applicable adapters.
2. **LSP plugin**: suggest the matching code-intelligence plugin and check
   its binary is installed — typescript-lsp (typescript-language-server),
   pyright-lsp (pyright-langserver), php-lsp (intelephense). Skip silently
   when the stack has no official LSP plugin.
3. **Run recipe**: if no `.claude/skills/run-*` skill exists, offer
   /run-skill-generator so /verify and /flow:accept can drive the real app.
4. **superpowers check**: verify the superpowers plugin is installed; if
   the plugin dependency did not auto-install it, print:
   `/plugin install superpowers@claude-plugins-official`
5. **Security layer (opt-in, by exposure)**: for projects with an auth
   surface, payment handling, or public/production deployment, offer the
   continuous `security-guidance` plugin
   (`/plugin install security-guidance@claude-plugins-official`). Skip the
   offer for local-only tools — the gate-level /security-review, driven by
   risk profiles at /flow:accept, is enough there.
6. **Project hooks (opt-in)**: offer a PostToolUse hook running the stack's
   affected lint/typecheck after edits and, for autonomous runs, an
   optional Stop-hook test gate. Write to the project's
   `.claude/settings.json` only on explicit confirmation.
7. **Team snippet (opt-in)**: for shared repos, offer the self-describing
   settings from [templates/team-settings.json](templates/team-settings.json).

## New project additionally

8. **git**: `git init -b main` when not a repo; add a sensible .gitignore
   for the detected stack.
9. **OpenSpec skeleton**: `openspec init` when the CLI exists; otherwise
   create by hand: `openspec/project.md` (project context, constraints,
   conventions), `openspec/specs/`, `openspec/changes/`. Plain files are
   the contract; the CLI is an accelerator.
10. **CLAUDE.md**: generate from
   [templates/CLAUDE.md.template](templates/CLAUDE.md.template), filling
   Commands from the detected stack. Keep it at or under 60 lines:
   commands, architecture facts, invariants, environment quirks, and the
   bounded `Current state` block from the template (latest-release copy +
   open branches/tasks as links + pointers). CLAUDE.md loads into every
   session: per-release history and long reference go to CHANGELOG,
   archives, or docs/, not here. Process rules do NOT go here either —
   they live in the flow plugin.
11. **CHANGELOG.md**: scaffold an empty changelog (`# Changelog` plus a
   one-line format note) so release history has a designated home from
   day one — /flow:accept records each release there.

## --existing additionally

8. **CLAUDE.md migration**: identify generic process rules (TDD cycles,
   review/gate rules, commit etiquette) and collapse them to the Workflow
   section of the template. Keep project facts untouched: Commands,
   Architecture, Invariants, environment quirks. Current-state notes are
   kept but bounded to the template's status-block shape (latest-release
   copy + open branches/tasks as links + pointers); offer to move any
   accumulated release history to CHANGELOG.md (create it if absent) —
   CLAUDE.md loads into every session and must stay lean. Show the full
   diff before applying.
9. **OpenSpec**: if `openspec/` is absent, offer the skeleton from step 9
   above. Never restructure existing openspec/ or docs/ content.
