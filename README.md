# Dominik's Skills

My personal Claude Code skills, organized in a Pocock-style bucket layout. **One installer covers everything** — both my originals and the upstream Pocock skills, all aligned to my conventions (gh-only issues, parent + sub-issue decomposition, mandatory Test Strategy, Pocock-style TDD).

Adapted from Matt Pocock's [`mattpocock/skills`](https://github.com/mattpocock/skills) — the structure, several skills, and the TDD discipline are his.

## Quickstart

```bash
git clone https://github.com/dominikdorfstetter/skills.git
cd skills
./scripts/link-skills.sh
```

The installer discovers every bucket under `skills/` that contains at least one `SKILL.md` and asks Y/n per bucket. Defaults: `engineering`, `productivity`, `misc` are Y by default; `personal`, `deprecated`, and any new bucket (e.g. a future `managerial/`) are N by default.

Non-interactive options:

```bash
./scripts/link-skills.sh --yes                      # accept defaults (engineering, productivity, misc)
./scripts/link-skills.sh --all                      # everything, including personal
./scripts/link-skills.sh --buckets engineering,personal
./scripts/link-skills.sh --clean --yes              # wipe stale symlinks pointing into this repo first
./scripts/link-skills.sh --help
```

Add a new bucket: drop a `SKILL.md` under `skills/<bucket>/<skill-name>/` and rerun the installer — it'll show up in the prompt automatically.

## Conventions

Issue-producing skills (`bug-report`, `feature-pm`, `architect-review`, `security-audit`, `resolve-issue`, `to-issues`, `to-prd`, `triage`, `improve-codebase-architecture`) follow a consistent contract:

1. **All issue I/O goes through `gh`** — `gh issue view`, `gh issue list --search`, `gh issue create`, `gh issue edit`, `gh issue comment`. Never assume a different tracker.
2. **Non-trivial work is a parent epic + sub-issues.** Parent body lists `- [ ] #N` checkboxes; each sub has `Parent: #N`. Parent and sub link both ways. `to-issues` is the standard decomposer.
3. **Every issue ships a Test Strategy table** with a named tracer-bullet test, plus rows for happy path, permissions, validation, and at least one edge case.
4. **Implementation is always TDD** — Pocock-style red-green-refactor in vertical slices. One test → minimal impl → repeat. Never write all tests first. See the bundled [`tdd`](./skills/engineering/tdd/SKILL.md) skill.
5. **Skills stay language- and framework-agnostic.** Even scaffolders describe artifacts/layers (schema, repo, handler, routing) — never specific frameworks.

## Reference

### Engineering

- **[add-backend-endpoint](./skills/engineering/add-backend-endpoint/SKILL.md)** — Add a new backend HTTP endpoint following the project's existing conventions. Walks the layers (schema → repo → handler → routing → spec → client wiring), TDD-first.
- **[add-list-page](./skills/engineering/add-list-page/SKILL.md)** — Scaffold a new CRUD list page in any frontend codebase. Covers data fetch, mutations, RBAC, loading/empty/error, i18n, accessibility, UX polish.
- **[architect-review](./skills/engineering/architect-review/SKILL.md)** — Architectural evaluation. Finds tech debt, missing patterns, coverage gaps; files parent + sub-issues via `gh`.
- **[bug-report](./skills/engineering/bug-report/SKILL.md)** — Turn a vague bug into a complete `gh` issue with reproduction steps, root-cause analysis, and a regression test strategy.
- **[coding-principles](./skills/engineering/coding-principles/SKILL.md)** — Reference doc encoding the owner's coding philosophy. Loaded by other skills as a shared source of truth.
- **[diagnose](./skills/engineering/diagnose/SKILL.md)** — Disciplined diagnosis loop for hard bugs and performance regressions: reproduce → minimise → hypothesise → instrument → fix → regression-test.
- **[feature-pm](./skills/engineering/feature-pm/SKILL.md)** — PM lens on a feature request. Evaluates fit, checks overlap, decomposes into a parent epic + sub-issues with baked-in tests.
- **[grill-with-docs](./skills/engineering/grill-with-docs/SKILL.md)** — Grilling session that challenges your plan against the existing domain model, sharpens terminology, and updates `CONTEXT.md` and ADRs inline.
- **[improve-codebase-architecture](./skills/engineering/improve-codebase-architecture/SKILL.md)** — Find deepening opportunities in a codebase, informed by `CONTEXT.md` and ADRs. Files approved deepenings as `gh` epics.
- **[resolve-issue](./skills/engineering/resolve-issue/SKILL.md)** — End-to-end issue resolver. Reads via `gh`, gates on requirements, implements with TDD (Pocock vertical slices), verifies, commits.
- **[run-checks](./skills/engineering/run-checks/SKILL.md)** — Run the project's quality gates (format, lint, typecheck, tests, frontend health). Detects toolchain automatically.
- **[security-audit](./skills/engineering/security-audit/SKILL.md)** — White-hat audit against the OWASP Top 10. Maps the surface, proves vulns with PoCs, files parent + sub-issues with regression tests.
- **[tdd](./skills/engineering/tdd/SKILL.md)** — Test-driven development with a red-green-refactor loop. Vertical slices, never horizontal.
- **[to-issues](./skills/engineering/to-issues/SKILL.md)** — Break any plan, spec, or PRD into a parent epic + independently-grabbable sub-issues on GitHub via `gh`, using vertical-slice tracer bullets.
- **[to-prd](./skills/engineering/to-prd/SKILL.md)** — Synthesize the current conversation into a PRD and file it as a GitHub epic via `gh`. Hands off to `/to-issues` for decomposition.
- **[triage](./skills/engineering/triage/SKILL.md)** — Triage GitHub issues through a state machine of canonical roles via `gh`.
- **[write-component-tests](./skills/engineering/write-component-tests/SKILL.md)** — Write tests for UI components, pages, and hooks across any UI codebase. Covers semantic queries, user-journey naming, validation boundaries, RBAC, accessibility.
- **[zoom-out](./skills/engineering/zoom-out/SKILL.md)** — Tell the agent to zoom out and give broader context or a higher-level perspective on an unfamiliar section of code.

### Productivity

- **[caveman](./skills/productivity/caveman/SKILL.md)** — Ultra-compressed communication mode. Cuts token usage ~75% while keeping full technical accuracy.
- **[grill-me](./skills/productivity/grill-me/SKILL.md)** — Get relentlessly interviewed about a plan or design until every branch of the decision tree is resolved.
- **[write-a-skill](./skills/productivity/write-a-skill/SKILL.md)** — Create new skills with proper structure, progressive disclosure, and bundled resources. Includes the dominiks-skills repo conventions.

### Misc

- **[git-guardrails-claude-code](./skills/misc/git-guardrails-claude-code/SKILL.md)** — Set up Claude Code hooks to block dangerous git commands.
- **[migrate-to-shoehorn](./skills/misc/migrate-to-shoehorn/SKILL.md)** — Migrate test files from `as` type assertions to @total-typescript/shoehorn.
- **[scaffold-exercises](./skills/misc/scaffold-exercises/SKILL.md)** — Create exercise directory structures with sections, problems, solutions, and explainers.
- **[setup-pre-commit](./skills/misc/setup-pre-commit/SKILL.md)** — Set up Husky pre-commit hooks with lint-staged, Prettier, type checking, and tests.

## Layout

```
skills/
  engineering/    daily code work, project-/language-agnostic
  productivity/   daily non-code workflow tools
  misc/           kept around but rarely used
  personal/       tied to my own setup; not promoted
  deprecated/     no longer used
scripts/
  link-skills.sh  symlinks engineering/productivity/misc into ~/.claude/skills
.claude-plugin/
  plugin.json     promoted skills
CLAUDE.md         repo conventions
```

## Credit

Adapted from Matt Pocock's [`mattpocock/skills`](https://github.com/mattpocock/skills). Original skills (`tdd`, `diagnose`, `grill-with-docs`, `to-issues`, `to-prd`, `triage`, `improve-codebase-architecture`, `zoom-out`, `caveman`, `grill-me`, `write-a-skill`, and the four `misc/` skills) are his work, modified to fit my conventions (gh-only, parent + sub-issue, Test Strategy, mandatory TDD, language-agnostic). The TDD discipline (red-green-refactor, vertical slices, no horizontal slicing) is entirely his.
