---
name: resolve-issue
description: End-to-end issue resolver. Reads a GitHub issue via `gh`, classifies the work, gates on requirements, implements TDD-first via Pocock vertical slices, verifies, commits. Use when given an issue number or URL to fix.
---

# Resolve Issue

`gh issue view` → analysis → TDD → verification → commit.

**Coding principles**: see `coding-principles` skill.
**TDD discipline**: see `tdd` skill — one test → minimal impl → repeat. Never horizontal.

## Phase 1 — Load

```bash
gh issue view <N> --comments
```

If the body has `Parent: #M`, also `gh issue view <M>` for context. Extract: title, body, labels, comments, parent, sibling subs, linked PRs. If no number was given, ask.

## Phase 2 — Classify

| Signal | Scope |
|---|---|
| `backend` label / handler/model/migration mentioned | `backend-only` |
| `frontend` label / page/component/hook | `frontend-only` |
| Both, or new API + new UI | `full-stack` |
| `bug` | TDD mandatory (test reproduces the bug) |
| `enhancement` / `feature` | TDD mandatory (test demonstrates new behavior) |
| `docs` / config-only | TDD not required |

**TDD is mandatory for any behavior change.** Pure docs / formatting / config-only is the only exemption. State the classification and reasoning out loud.

## Phase 3 — Requirement gate (HARD)

Don't proceed if any check fails.

**Freshness** — `git log --since=<issue date>` in affected dirs.
- Already implemented → `gh issue close <N> --reason "not planned" --comment "<why>"`, stop.
- Stale but salvageable → `gh issue edit` in-place, continue.
- Area has grown → flag and ask whether to extend scope.

**Completeness**

| Section | When | If missing |
|---|---|---|
| Acceptance Criteria | Always | Ask user for definition of done |
| Access Control | If feature has actions | Auto-generate from role model, confirm |
| Error Cases | If feature can fail | Auto-generate from handler/DTO, confirm |
| Test Strategy + tracer bullet | Always | Auto-generate, confirm — name the tracer-bullet test |
| i18n keys | If user-visible strings | Propose from existing namespace |
| Accessibility notes | If new UI | Add per component type |

Fill from codebase analysis (and confirm) or ask one specific question. Patch with `gh issue edit <N> --body "..."` once filled.

If the user says "skip the gate", note "issue incomplete, implemented per user request" in the commit and still flag what's missing.

## Phase 4 — Codebase analysis

Read only what's relevant.

- **Backend**: handler, model, DTO, tests, latest migration.
- **Frontend**: page/component, hooks, API client, types, tests.
- **Full-stack**: both, plus the contract boundary.

Produce: root cause (bugs) or gap analysis (features); file-by-file change list (create/modify/delete); risk areas; **the test list in vertical-slice order** (tracer bullet first, then incremental).

## Phase 5 — TDD plan

State before writing code:

1. **Tracer bullet** — one E2E that proves the whole path works.
2. **Incremental tests** — ordered list, each adding one behavior.

Each test describes behavior, uses the public interface, would survive a refactor. If the user scopes opinions ("skip path X"), respect and note in the commit.

## Phase 6 — Implementation (red → green → refactor)

Per test in order:

- **RED** — write at the right seam; run; confirm it fails for the **right reason** (not compile error, not mock setup).
- **GREEN** — minimal code to pass. No speculative abstractions, no "while I'm here" cleanup.
- **REFACTOR** — only while green. Extract duplication, deepen modules, apply SOLID where natural; re-run after each step.

Move to the next test only when the current cycle is fully green.

Route to scaffolders for boilerplate (`add-backend-endpoint`, `add-list-page`, `write-component-tests`) — keep the test-first cadence regardless.

## Phase 7 — Verification gate (HARD)

Three parts, all must pass. Show actual output — no summarizing.

- **A. Full test suite** — Run the project's check script regardless of scope.
- **B. Frontend health** (if UI files changed) — Run the project's check (e.g. React Doctor); score must meet threshold. Skip if backend-only.
- **C. Documentation** — For features and meaningful fixes: docs site (new endpoint / page / config / behavior change), README (major feature / dev workflow / prerequisites), changelog. State each: `PASSED` / `SKIPPED (reason)` / `UPDATED` / `NOT NEEDED (reason)`.

## Phase 8 — Self-review

```
□ Every AC addressed?
□ Edge cases from comments handled?
□ TDD followed — every behavior tested before its implementation?
□ Tests use public interfaces, not internals?
□ No new unwrap/panic in production code paths
□ Only what the issue asks for — no over-engineering
□ No files modified beyond Phase 4 scope
```

If gaps, fix and re-run Phase 7.

## Phase 9 — Commit & link

Always create a feature branch. Never commit directly to `main`.

```bash
git checkout -b fix/<short>   # bug
git checkout -b feat/<short>  # feature
```

If you already committed to `main`: `git checkout -b <branch>`, then `git branch -f main origin/main`, continue from the branch.

Stage specific files (never `git add -A`):

```bash
git commit -m "$(cat <<'EOF'
<type>(<scope>): <summary>

<what changed and why — connect to the issue>

Fixes #<N>
EOF
)"
```

Types: `fix`, `feat`, `refactor`, `test`, `docs`, `chore`. Never include AI attribution.

If this issue has a parent, update it:

```bash
gh issue comment <PARENT> --body "Closed sub #<N>: <summary>. Remaining: <list>."
```

Don't push or open a PR unless explicitly asked.

## Abort if

- Issue is ambiguous about "done".
- Change touches shared infrastructure (auth, schema, core services) in a way that affects many endpoints.
- Migration needed — confirm content first.
- Tests fail for unrelated reasons.
- No correct seam exists for the test — that itself is the finding (consult `/improve-codebase-architecture`).
