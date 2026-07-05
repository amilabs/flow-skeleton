---
name: blast-radius
description: Impact analysis before modifying existing code. Use before changing shared modules, widely imported utilities, or any existing code whose dependents may not be covered by tests - especially in legacy or brownfield projects. Maps dependents, then pins uncovered ones with characterization tests.
argument-hint: "[file, symbol, or module to change]"
---

# Blast radius

Target: $ARGUMENTS (if empty, use the code the current task is about to modify).

## 1. Map dependents

- With a code-intelligence (LSP) plugin active: use find-references and the
  call hierarchy on the symbols being changed.
- Without LSP: grep for imports/usages of the module and its exported
  names; trace one level of re-exports.

List every dependent: file, symbol used, and how it would break if the
behavior shifts.

## 2. Classify coverage

For each dependent, determine whether an existing test exercises it through
the code being changed. Run the relevant slice of the suite to confirm —
do not guess from file names.

## 3. Pin uncovered dependents

For each dependent without coverage, write a characterization test BEFORE
modifying anything: capture current observable behavior (input → current
output), even if that behavior looks wrong. If it looks wrong, flag it in
the impact note — do not silently fix it; changing it is a scope decision
for the owner.

## 4. Write the impact note

Produce a short note: dependents found, coverage classification, tests
added, residual risks. Put it in the active change's design.md (create the
file if the change lacks one), or report it inline for fast-path work.

Do not start the actual modification until the characterization tests pass
against the unmodified code.
