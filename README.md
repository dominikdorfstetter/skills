# Dominik's Skills

My personal Claude Code skills, organized in the same fashion as Matt Pocock's [`mattpocock/skills`](https://github.com/mattpocock/skills) — small, composable, language- and framework-agnostic where possible.

Designed to mix with `mattpocock/skills`: the two repos coexist in `~/.claude/skills` after running each repo's installer. See the upstream repo for `grill-me`, `tdd`, `caveman`, `diagnose`, `to-prd`, and friends.

## Quickstart

```bash
./scripts/link-skills.sh
```

Symlinks every skill in `engineering/`, `productivity/`, and `misc/` into `~/.claude/skills/`. Skills in `personal/` and `deprecated/` are not promoted.

To pick up Pocock's skills too, install them from his repo (https://github.com/mattpocock/skills):

```bash
# clone alongside this repo
git clone https://github.com/mattpocock/skills.git ../pocock-skills
cd ../pocock-skills && ./scripts/link-skills.sh
```

## Conventions

Issue-producing skills (`bug-report`, `feature-pm`, `architect-review`, `security-audit`, `resolve-issue`) follow a consistent contract:

1. **All issue I/O goes through `gh`** — `gh issue view`, `gh issue list --search`, `gh issue create`, `gh issue edit`, `gh issue comment`. Never assume a different tracker.
2. **Non-trivial work is a parent epic + sub-issues.** Parent body lists `- [ ] #N` checkboxes; each sub has `Parent: #N`. Parent and sub link both ways.
3. **Every issue ships a Test Strategy table** with a named tracer-bullet test, plus rows for happy path, permissions, validation, and at least one edge case.
4. **Implementation is always TDD** — Pocock-style red-green-refactor in vertical slices. One test → minimal impl → repeat. Never write all tests first. See [`mattpocock/skills` `tdd`](https://github.com/mattpocock/skills/blob/main/skills/engineering/tdd/SKILL.md).
5. **Skills stay language- and framework-agnostic.** Even scaffolders describe artifacts/layers (schema, repo, handler, routing) — never specific frameworks.

## Reference

### Engineering

Project-, language-, and framework-agnostic skills used daily.

- **[add-backend-endpoint](./skills/engineering/add-backend-endpoint/SKILL.md)** — Add a new backend HTTP endpoint following the project's existing conventions. Walks the layers (schema → repo → handler → routing → spec → client wiring), TDD-first.
- **[add-list-page](./skills/engineering/add-list-page/SKILL.md)** — Scaffold a new CRUD list page in any frontend codebase. Covers data fetch, mutations, RBAC, loading/empty/error, i18n, accessibility, UX polish.
- **[architect-review](./skills/engineering/architect-review/SKILL.md)** — Architectural evaluation. Finds tech debt, missing patterns, coverage gaps; files parent + sub-issues via `gh`.
- **[bug-report](./skills/engineering/bug-report/SKILL.md)** — Turn a vague bug into a complete `gh` issue with reproduction steps, root-cause analysis, and a regression test strategy.
- **[coding-principles](./skills/engineering/coding-principles/SKILL.md)** — Reference doc encoding the owner's coding philosophy. Loaded by other skills as a shared source of truth.
- **[feature-pm](./skills/engineering/feature-pm/SKILL.md)** — PM lens on a feature request. Evaluates fit, checks overlap, decomposes into a parent epic + sub-issues with baked-in tests.
- **[resolve-issue](./skills/engineering/resolve-issue/SKILL.md)** — End-to-end issue resolver. Reads via `gh`, gates on requirements, implements with TDD (Pocock vertical slices), verifies, commits.
- **[run-checks](./skills/engineering/run-checks/SKILL.md)** — Run the project's quality gates (format, lint, typecheck, tests, frontend health). Detects toolchain automatically.
- **[security-audit](./skills/engineering/security-audit/SKILL.md)** — White-hat audit against the OWASP Top 10. Maps the surface, proves vulns with PoCs, files parent + sub-issues with regression tests.
- **[write-component-tests](./skills/engineering/write-component-tests/SKILL.md)** — Write tests for UI components, pages, and hooks across any UI codebase. Covers semantic queries, user-journey naming, validation boundaries, RBAC, accessibility.

### Productivity

General workflow tools, not code-specific. None yet.

### Misc

Tools kept around but rarely used. None yet.

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

The structure, conventions, and several skill ideas are adapted from Matt Pocock's [`mattpocock/skills`](https://github.com/mattpocock/skills). The TDD discipline (red-green-refactor, vertical slices, no horizontal slicing) is his — see his [`tdd` skill](https://github.com/mattpocock/skills/blob/main/skills/engineering/tdd/SKILL.md).
