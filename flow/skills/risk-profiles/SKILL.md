---
name: risk-profiles
description: Maps a change type to the verification it needs - tests, behavior inventory, security review, code-review effort. Consult when designing a change (/flow:spec), accepting one (/flow:accept), or whenever deciding how much testing or review a change requires.
user-invocable: false
---

# Risk profiles

Select one or more profiles for every change during /flow:spec and record
them in the change's proposal.md. Requirements of multiple profiles combine
(union). When in doubt between two profiles, take the stricter one.

| Profile | Applies to | Mandatory verification | Behavior inventory | /security-review | /code-review effort |
|---|---|---|---|---|---|
| trivial | typos, comments, log lines, local renames | affected tests | no | no | none (fast path: skip the flow lifecycle entirely) |
| pure-logic | algorithms, calculations, pure functions | TDD unit tests incl. edge cases | no | no | medium |
| ui-surface | routes, pages, components, forms, navigation | route/component tests; empty/error/loading states; /verify run | yes | no | medium |
| api-contract | endpoints, schemas, error formats, versioning | contract tests on both sides; backward-compat check | if UI affected | no | high |
| data-storage | persistence, schemas, migrations | migration up + idempotency; malformed old data; round-trip | no | if auth-adjacent | high |
| auth-security | auth, sessions, permissions, secrets, payments | negative tests: bypass attempts, injection-shaped inputs | affected flows | yes | high |
| external-integration | third-party APIs, webhooks, queues | mocked failure modes: timeout, non-2xx, malformed payload | no | if secrets handled | medium |
| build-deploy | build config, dependencies, env, CI | build passes; lockfile reviewed | no | dependency audit for new deps | medium |

**Brownfield modifier**: any profile additionally requires /flow:blast-radius
when the change modifies existing code that has dependents outside the
change scope. Blast-radius determines which dependents lack test coverage
and pins them with characterization tests before the modification.

**Fast path**: a change is trivial when its diff can be described in one
sentence and it touches no dependents. Trivial changes skip /flow:spec,
/flow:implement, and /flow:accept — edit directly, run affected tests, done.
