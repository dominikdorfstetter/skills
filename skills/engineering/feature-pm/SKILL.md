---
name: feature-pm
description: Product manager lens on a feature request. Evaluates fit, checks for issue overlap, identifies risks, and decomposes into a parent epic + sub-issues on GitHub via `gh`. Use before implementation begins on a non-trivial feature.
---

# Feature PM

Think through a feature like a PM who reads code. Evaluate before building. Decompose before filing.

## Phase 1 — Understand

State four things before continuing:

1. **User story** — "As <user>, I want <capability> so that <outcome>."
2. **Problem** — what's broken or missing today.
3. **Success metric** — how you'd know it's working in production.
4. **Scope signal** — small extension / new subsystem / architecturally novel.

If too vague to evaluate, ask one clarifying question.

## Phase 2 — Check overlap

```bash
gh issue list --search "<keywords>" --state open
gh issue list --search "<keywords>" --state closed
```

Run 2–3 phrasings. **Duplicate** → link, don't file. **Related** → reference. **Supersedes** → flag.

## Phase 3 — Architectural fit

Read the relevant code first, then answer:

- **Backend**: data model exists or new migration? Extend or new handler domain? Authorization role per operation? Performance hot spots? Shared infra touched (auth, webhooks, audit, notifications)?
- **Frontend**: analogous page/component to mirror? Reuse list/CRUD/autosave hooks? Types extend or new? Navigation / settings / palette affected?
- **Cross-cutting**: migration additive vs destructive? Public API / webhooks affected? List every new user-visible string with proposed i18n key.
- **Access control**: for each action × role: who can, who can't, with the error code for each denial.
- **Error design**: every failure path → trigger, code (`ERR_<DOMAIN>_<CAUSE>`), HTTP status, i18n key.
- **Accessibility**: new interactive elements → keyboard, screen-reader labels, focus management. New visual states → contrast, non-color indicators.

### Verdict

- **Clean fit** — extends existing patterns; low risk.
- **Moderate fit** — new domain following established conventions; medium risk.
- **Architectural friction** — conflicts or unknown complexity; **stop and present analysis before filing.**
- **Out of scope** — recommend against; don't file without explicit approval.

## Phase 4 — Decompose

A feature → **one parent epic** + **multiple sub-issues** for each independently-completable piece. Never one giant ticket. Never orphan subs.

Rules:
- Each sub completable in one focused session, independently testable.
- Parent body lists every sub as `- [ ] #N`. Every sub has `Parent: #<parent>`.
- Cross-sub dependencies explicit via `Depends on #N`.
- Backend and frontend separated unless truly inseparable.

Standard sub breakdown for a full-stack feature:

| Sub | Scope | Labels |
|---|---|---|
| Data model + migration | Backend | `backend` |
| API endpoint(s) | Backend | `backend` |
| API types + client method | Frontend | `admin` |
| UI component / page | Frontend | `admin`, `ux` |
| Tests (if not above) | Frontend | `admin` |

Skip rows that don't apply.

## Phase 5 — Phase label

| Phase | When |
|---|---|
| `phase:1` | Foundational — product feels incomplete without it |
| `phase:2` | Progressive — usability lift on solid base |
| `phase:3` | Differentiation — sets the product apart |
| `phase:4` | Speculative — depends on unbuilt infra |

Don't label everything `phase:1` — it dilutes priority.

## Phase 6 — File via `gh`

**Parent first** (so subs can reference it):

```bash
PARENT=$(gh issue create \
  --title "<feature name>" \
  --label "<type>,<area>,<phase>,epic" \
  --body "$(cat <<'EOF'
## Summary
<user benefit + architectural fit verdict>

## Sub-issues
- [ ] #TBD — <sub 1>
- [ ] #TBD — <sub 2>

## Acceptance Criteria (overall)
- [ ] All subs closed
- [ ] End-to-end test covers the user journey
- [ ] No regressions

## Out of Scope
<scope fence>

## Access Control
| Action | Role A | Role B |

## Error Cases
| Trigger | Code | HTTP | i18n key |

## Test Strategy (overall)
| Category | Scenario | Outcome |
|---|---|---|
| Tracer bullet | <E2E that proves the feature works> | <observable> |
| Happy path |  |  |
| Permission |  |  |
| Validation |  |  |
| Edge case |  |  |
EOF
)" --json number --jq .number)
```

**Then each sub:**

```bash
gh issue create \
  --title "<sub, action-oriented>" \
  --label "<type>,<area>,<phase>" \
  --body "$(cat <<EOF
Parent: #${PARENT}

## Summary
<what this sub delivers>

## Acceptance Criteria
- [ ] Specific, testable
- [ ] Tracer-bullet test passes

## Dependencies
- Depends on #N — <why>

## Test Strategy
| Category | Scenario | Outcome |
|---|---|---|
| Tracer bullet | <single E2E for this sub> | <observable> |
| Happy path |  |  |
| Permission |  |  |
| Validation |  |  |
| Edge case |  |  |

Implementation: Pocock-style TDD (see \`tdd\` skill).
EOF
)"
```

After all subs are filed, rewrite the parent body to replace `#TBD` with real numbers.

## Phase 7 — Report

```
## Feature PM Review: <name>

### User Story
<...>

### Fit
<verdict + 2-3 sentences>

### Existing Overlap
<none / list>

### Issues Created
- #N: <title> (labels)

### Implementation Order
1. #N — start here
2. #N — after #N

### Risks / Open Questions
<unresolved decisions>
```

## Quality bar

Every issue (parent and sub) before filing:

- [ ] Title says what should exist (not "improve X", not implementation detail)
- [ ] User benefit stated
- [ ] AC testable by someone who didn't write the code
- [ ] "Out of Scope" present
- [ ] Phase label genuine
- [ ] Parent has `Sub-issues` checklist; each sub has `Parent: #N`
- [ ] Test Strategy table with named tracer bullet
- [ ] Access control matrix on the parent (and subs that gate actions)
- [ ] Error cases table where failure is possible
- [ ] i18n keys for all new strings; a11y noted for new UI
