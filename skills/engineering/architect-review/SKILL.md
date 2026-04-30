---
name: architect-review
description: Architectural evaluation of a codebase. Finds tech debt, missing patterns, coverage gaps, and design inconsistencies, then files structured GitHub issues. Use when user asks for an architecture review, codebase evaluation, or wants to know what to fix structurally.
---

# Architect Review

Systematic architecture review. Produces issues, not just observations.

## Scope flags

```
/architect-review              # full
/architect-review --backend
/architect-review --frontend
/architect-review --api        # API contract only
/architect-review --testing    # coverage and quality
/architect-review --security   # auth, guards, validation
```

Run all phases if no flag is given. Skip irrelevant phases for scoped runs.

## Phase 1 — Backend

For each handler/controller:
- Auth: every mutation has an explicit role/permission check; tenant filter present on every data query.
- Errors: no `unwrap`/`!` in handler or service code; consistent error response shape; correct HTTP status per error variant; no raw 500s for client errors.
- Layering: queries live in models/repos, not inline in handlers; handlers stay thin.
- Pagination: list endpoints have a `find_filtered` + `count_filtered` pair (or equivalent) and return a consistent paginated shape.
- API spec: every public endpoint registered in OpenAPI/spec doc.
- Migrations: additive only; foreign keys indexed; `ON DELETE` semantics intentional; case-insensitive columns where needed (slugs, emails).

Flag every violation as a candidate issue.

## Phase 2 — Frontend

For each page/route:
- Shared hooks used (list state, CRUD mutations, autosave) — not hand-rolled equivalents.
- RBAC guards on write actions, mirroring backend roles (UI hides; backend enforces).
- Loading / empty / error use shared components, not ad-hoc spinners or alerts.
- Hooks: stable callbacks (`useCallback` deps correct), no stale closures, refs typed for the framework version.

For types: every field in API types corresponds to a real backend DTO field; enum strings match backend serialization exactly; no leftover `any`.

For coverage: every page/hook/non-trivial shared component has a test file. List untested ones — each is an issue candidate.

For accessibility (WCAG 2.1 AA): semantic HTML over `<div onClick>`; `aria-label` on icon-only buttons; keyboard navigation works; focus managed across state changes; non-color status indicators; `prefers-reduced-motion` respected.

For i18n: no hardcoded user-visible strings in markup; locale files have identical key structure; spot-check translations for machine-translation drift.

## Phase 3 — API contract

- Every backend endpoint the frontend calls has a typed client method.
- Every typed client method's return matches the API types.
- Every client method is mocked in test setup.
- OpenAPI/spec registers all endpoints and DTOs.

Flag mismatches — these become silent runtime bugs.

## Phase 4 — Cross-cutting

| Concern | Check |
|---|---|
| Auth | Identity provider → backend chain consistent across endpoints |
| Caching | Query keys namespaced per tenant; no cross-tenant cache leaks |
| Pagination | Server-side; no large client-side filtering |
| i18n | All user-visible strings keyed |
| Migrations | Additive; destructive flagged |
| Rate limiting | Applied at the right layer to public + auth endpoints |
| Error codes | Every failure path has a stable code, mapped to a user message |

## Phase 5 — File parent + sub-issues with `gh`

For each finding, decide:

- **Skip** if already in an open issue (`gh issue list --search "<keywords>"`) or if it belongs in a PR comment.
- **File** if it's a pattern gap across multiple files, missing test on meaningful behavior, security/correctness concern, or design inconsistency that compounds over time.

When findings cluster into a theme (e.g. "handler-pattern violations across backend"), file a **parent epic** + one **sub-issue per file or per coherent fix** so the work can be parallelized and tracked.

**Parent epic**

```bash
gh issue create \
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
- [ ] No regressions in related features

## Test Strategy (overall)
| Category | Scenario | Outcome |
|---|---|---|
| Tracer bullet | One test that proves the new pattern works on the canonical example | Observable behavior |
| Regression | Existing functionality continues to pass | All green |
EOF
)"
```

**Sub-issue**

```bash
gh issue create \
  --title "<concise — what is missing or wrong>" \
  --label "<type>,<area>,<phase>" \
  --body "$(cat <<EOF
Parent: #<parent>

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
| Tracer bullet | <one test that fails today and passes after the change> | Observable |
| Regression | <existing behavior still works> | Green |

Implementation must follow Pocock-style TDD: failing test first, minimal fix, refactor green.

## Files Affected
- path — what changes
EOF
)"
```

After all subs are filed, edit the parent to replace `#TBD` placeholders with real numbers.

Labels: `bug` for incorrect behavior, `enhancement` for improvements, plus area labels (`backend`, `admin`, `a11y`, `security`, `i18n`, …) and a phase label if the project uses one (`phase:1` for foundational, `phase:2` for progressive).

## Phase 6 — Report

```
## Findings by layer
- Backend: N — <titles>
- Frontend: N — <titles>
- API contract: N
- Cross-cutting: N

## Highest priority
<top 3 with issue links>

## Clean
<layers/areas with no findings>
```

If a layer is clean, say so. Don't pad.
