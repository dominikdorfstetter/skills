# Engineering

Skills used daily for code work. Project-, language-, and framework-agnostic.

- **[add-backend-endpoint](./add-backend-endpoint/SKILL.md)** — Add a new backend HTTP endpoint following the project's existing conventions. Walks the layers (schema → repo → handler → routing → spec → client wiring), TDD-first.
- **[add-list-page](./add-list-page/SKILL.md)** — Scaffold a new CRUD list page in any frontend codebase. Covers data fetch, mutations, RBAC, loading/empty/error, i18n, accessibility, UX polish.
- **[architect-review](./architect-review/SKILL.md)** — Architectural evaluation. Finds tech debt, missing patterns, coverage gaps; files parent + sub-issues via `gh`.
- **[bug-report](./bug-report/SKILL.md)** — Turn a vague bug into a complete `gh` issue with reproduction steps, root-cause analysis, and a regression test strategy.
- **[coding-principles](./coding-principles/SKILL.md)** — Reference doc encoding the owner's coding philosophy. Loaded by other skills as a shared source of truth.
- **[diagnose](./diagnose/SKILL.md)** — Disciplined diagnosis loop for hard bugs and performance regressions: reproduce → minimise → hypothesise → instrument → fix → regression-test.
- **[feature-pm](./feature-pm/SKILL.md)** — PM lens on a feature request. Evaluates fit, checks overlap, decomposes into a parent epic + sub-issues with baked-in tests.
- **[grill-with-docs](./grill-with-docs/SKILL.md)** — Grilling session that challenges your plan against the existing domain model, sharpens terminology, and updates `CONTEXT.md` and ADRs inline.
- **[improve-codebase-architecture](./improve-codebase-architecture/SKILL.md)** — Find deepening opportunities in a codebase, informed by the domain language in `CONTEXT.md` and decisions in `docs/adr/`. Files approved deepenings as `gh` epics.
- **[resolve-issue](./resolve-issue/SKILL.md)** — End-to-end issue resolver. Reads via `gh`, gates on requirements, implements with TDD (Pocock vertical slices), verifies, commits.
- **[run-checks](./run-checks/SKILL.md)** — Run the project's quality gates (format, lint, typecheck, tests, frontend health). Detects toolchain automatically.
- **[security-audit](./security-audit/SKILL.md)** — White-hat audit against the OWASP Top 10. Maps the surface, proves vulns with PoCs, files parent + sub-issues with regression tests.
- **[tdd](./tdd/SKILL.md)** — Test-driven development with a red-green-refactor loop. Builds features or fixes bugs one vertical slice at a time. Adapted from Pocock.
- **[to-issues](./to-issues/SKILL.md)** — Break any plan, spec, or PRD into a parent epic + independently-grabbable sub-issues on GitHub via `gh`, using vertical-slice tracer bullets.
- **[to-prd](./to-prd/SKILL.md)** — Synthesize the current conversation into a PRD and file it as a GitHub epic via `gh`. Hands off to `/to-issues` for decomposition.
- **[triage](./triage/SKILL.md)** — Triage GitHub issues through a state machine of canonical roles via `gh`. Bug/enhancement × needs-triage/needs-info/ready-for-agent/ready-for-human/wontfix.
- **[write-component-tests](./write-component-tests/SKILL.md)** — Write tests for UI components, pages, and hooks across any UI codebase. Covers semantic queries, user-journey naming, validation boundaries, RBAC, accessibility.
- **[zoom-out](./zoom-out/SKILL.md)** — Tell the agent to zoom out and give broader context or a higher-level perspective on an unfamiliar section of code.
