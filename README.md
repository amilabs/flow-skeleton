# flow-skeleton

A Claude Code plugin marketplace with one plugin: **flow** — a universal
development workflow. Design on the strongest model, implement economically,
verify by risk, survive brownfield rewrites.

## Install (once per machine)

Inside any Claude Code session:

```
/plugin marketplace add amilabs/flow-skeleton
/plugin install flow@flow-skeleton
```

Choose **User scope** — flow becomes available in every project on the
machine. Then enable updates: `/plugin` → Marketplaces → flow-skeleton →
**Enable auto-update**. The superpowers plugin is declared as a dependency
and installs alongside.

Manual update (note: `update` requires the fully-qualified name, unlike
`install`):

```bash
claude plugin marketplace update flow-skeleton
claude plugin update flow@flow-skeleton
```

## Commands

| Command | Purpose |
|---|---|
| `/flow:init` | bootstrap a project (`--existing` migrates a live one) |
| `/flow:spec` | design a change → OpenSpec change folder → owner approval |
| `/flow:implement` | execute the approved change with TDD (fresh session) |
| `/flow:accept` | acceptance gate: checks, live verify, reviews, summary |
| `/flow:blast-radius` | impact analysis before touching existing code |

Trivial changes (one-sentence diff, no dependents) skip the lifecycle
entirely — that is a rule, not an exception.

## Team repositories

Commit this to the project's `.claude/settings.json` and teammates get an
install prompt on first trusted open — their instruction is one sentence:
"clone, open in Claude Code, accept the prompts."

```json
{
  "extraKnownMarketplaces": {
    "flow-skeleton": {
      "source": { "source": "github", "repo": "amilabs/flow-skeleton" }
    }
  },
  "enabledPlugins": { "flow@flow-skeleton": true }
}
```

## Design

The full design document:
[docs/superpowers/specs/2026-07-05-flow-plugin-design.md](docs/superpowers/specs/2026-07-05-flow-plugin-design.md).

## License

Apache-2.0
