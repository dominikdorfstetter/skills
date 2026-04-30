---
name: architect-review
description: Architectural evaluation of a codebase. Finds tech debt, missing patterns, coverage gaps, design inconsistencies; files parent + sub-issues via `gh`. Use when user asks for an architecture review, codebase evaluation, or wants to know what to fix structurally.
---

# Architect Review

Systematic architecture review. Produces issues, not just observations.

## Scope flags

```
/architect-review              # full
/architect-review --backend
/architect-review --frontend
/architect-review --api        # contract only
/architect-review --testing    # coverage and quality
/architect-review --security   # auth, guards, validation
```

No flag → all phases. Skip irrelevant phases for scoped runs.

## Phase 1 — Backend

For each handler/controller:

- **Auth** — every mutation has an explicit role check; tenant filter on every data query.
- **Errors** — no `unwrap`/panic in handler/service code; consistent error shape; correct HTTP status per variant; no raw 500s for client errors.
- **Layering** — queries in models/repos, not inline in handlers; handlers stay thin.
- **Pagination** — list endpoints have `find_filtered` + `count_filtered` (or equivalent); consistent paginated shape.
- **API spec** — every public endpoint registered.
- **Migrations** — additive only; FKs indexed; `ON DELETE` semantics intentional; case-insensitive columns where needed.

## Phase 2 — Frontend

For each page/route:

- **Shared hooks** used (list state, CRUD mutations, autosave) — not hand-rolled.
- **RBAC** guards on write actions (UI hides; backend enforces).
- **Loading / empty / error** use shared components, not ad-hoc spinners.
- **Hooks** — stable callbacks, no stale closures, framework-version-correct refs.

For types: every field in API types corresponds to a real backend DTO field; enum strings match backend serialization; no leftover `any`.

For coverage: every page/hook/non-trivial shared component has a test file. List untested ones.

For accessibility (WCAG 2.1 AA): semantic HTML over `<div onClick>`; `aria-label` on icon-only buttons; keyboard navigation; focus managed across state changes; non-color status indicators; `prefers-reduced-motion` respected.

For i18n: no hardcoded user-visible strings; locale files share key structure; spot-check translations for drift.

## Phase 3 — API contract

- Every backend endpoint the frontend calls has a typed client method.
- Every client method's return matches the API types.
- Every client method is mocked in test setup.
- OpenAPI/spec registers all endpoints and DTOs.

Mismatches become silent runtime bugs — flag them.

## Phase 4 — Cross-cutting

| Concern | Check |
|---|---|
| Auth | Identity provider → backend chain consistent |
| Caching | Query keys namespaced per tenant |
| Pagination | Server-side; no large client-side filtering |
| i18n | All user-visible strings keyed |
| Migrations | Additive; destructive flagged |
| Rate limiting | Right layer for public + auth endpoints |
| Error codes | Every failure path has a stable code mapped to a user message |

## Phase 5 — File via `gh`

For each finding:

- **Skip** if already filed (`gh issue list --search "<keywords>"`) or PR-comment-sized.
- **File** if it's a pattern gap, missing test on meaningful behavior, security/correctness concern, or design inconsistency that compounds.

Cluster findings into a theme → **parent epic + one sub per file or coherent fix**.

**Parent:**

```bash
PARENT=$(gh issue create \
  --title "<theme of findings>" \
  --label "<type>,<area>,<phase>,epic" \
  --body "$(cat <<'EOF'
## Summary
<why this theme matters architecturally>

## Sub-issues
- [ ] #TBD — <sub 1>
- [ ] #TBD — <sub 2>

## Acceptance Criteria (overall)
- [ ] Every sub closed
- [ ] No regressions

## Test Strategy (overall)
| Category | Scenario | Outcome |
|---|---|---|
| Tracer bullet | Test that proves the new pattern on the canonical example | Observable |
| Regression | Existing functionality passes | Green |
EOF
)" --json number --jq .number)
```

**Each sub:**

```bash
gh issue create \
  --title "<concise — what is missing or wrong>" \
  --label "<type>,<area>,<phase>" \
  --body "$(cat <<EOF
Parent: #${PARENT}

## Summary
<the specific gap>

## Current State
<file paths, function names, exact gap>

## Proposed Solution
<correct pattern; reference an existing good example>

## Acceptance Criteria
- [ ] Specific, testable
- [ ] All affected files migrated
- [ ] Tests cover the new pattern

## Test Strategy
| Category | Scenario | Outcome |
|---|---|---|
| Tracer bullet | <test that fails today, passes after change> | Observable |
| Regression | <existing behavior> | Green |

Fix per Pocock-style TDD: failing test first, minimal change, refactor green.

## Files Affected
- path — what changes
EOF
)"
```

After all subs are filed, rewrite the parent body replacing `#TBD` with real numbers.

Labels: `bug` for incorrect behavior, `enhancement` for improvements; plus area (`backend`, `admin`, `a11y`, `security`, `i18n`); phase if the project uses one.

## Phase 6 — Report

```
## Findings by layer
- Backend: N — <titles>
- Frontend: N
- API contract: N
- Cross-cutting: N

## Highest priority
<top 3 with issue links>

## Clean
<layers/areas with no findings>
```

If a layer is clean, say so. Don't pad.
