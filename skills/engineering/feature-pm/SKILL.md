---
name: feature-pm
description: Product manager lens on a new feature request. Evaluates fit against the current architecture, checks for issue overlap, identifies risks, and breaks the feature into atomic GitHub issues. Use before any implementation begins on a non-trivial feature.
---

# Feature PM

Think through a feature like a PM who reads code. Evaluate before building. Decompose before filing.

## Phase 1 — Understand

State four things before continuing:

1. **User story** — "As <user>, I want <capability> so that <outcome>."
2. **Problem** — what is broken or missing today?
3. **Success metric** — how would you know it's working in production?
4. **Scope signal** — small extension / new subsystem / architecturally novel?

If the request is too vague to evaluate, ask one clarifying question.

## Phase 2 — Check for overlap

```bash
gh issue list --search "<keywords>" --state open
gh issue list --search "<keywords>" --state closed
```

Run 2–3 searches with different phrasings.

- **Duplicate** → link to existing, don't file new.
- **Related** → reference in the new issue.
- **Supersedes** → flag explicitly.

## Phase 3 — Architectural fit

Read the relevant code first. Then answer:

**Backend**
- Data model — exists or new migration needed?
- Handler domain — extend or new?
- Authorization — which role gates each operation?
- Performance — expensive queries, large payloads, background jobs?
- Shared infra — auth, webhooks, audit log, notifications?

**Frontend**
- UI pattern — does an analogous page/component exist? Reuse list/CRUD/autosave hooks?
- Types — extend existing or new?
- Navigation / settings / command palette — affected?

**Cross-cutting**
- Migration — additive or destructive?
- Webhooks / public API — affected?
- i18n — list every new user-visible string; propose key names from the existing namespace.

**Access control**
- For each action × role: who can, who can't? List the error code for each denial.

**Error design**
- Every failure path: trigger, error code (`ERR_<DOMAIN>_<CAUSE>`), HTTP status, i18n key.

**Accessibility**
- New interactive elements → keyboard nav, screen-reader labels, focus management.
- New visual states → contrast and non-color indicators.

### Verdict

State one:

- **Clean fit** — extends existing patterns; low risk.
- **Moderate fit** — new domain following established conventions; medium risk.
- **Architectural friction** — conflicts with existing design or has unknown complexity; **stop and present analysis before filing anything.**
- **Out of scope** — recommend against. Don't file without explicit approval.

## Phase 4 — Decompose into parent + sub-issues

A feature → **one parent issue** describing the overall change + **multiple sub-issues** for each independently-completable piece. Never one giant ticket. Never orphan sub-issues without a parent.

Rules:
- Each sub-issue completable in one focused session.
- Each sub-issue independently testable.
- Parent body lists every sub-issue as a `- [ ] #N` checkbox.
- Every sub-issue body has `Parent: #<parent>`.
- Cross-sub dependencies explicit (`Depends on #N`).
- Backend and frontend separated unless truly inseparable.

Standard sub-issue breakdown for a full-stack feature:

| Sub-issue | Scope | Labels |
|---|---|---|
| Data model + migration | Backend | `backend` |
| API endpoint(s) | Backend | `backend` |
| API types + client method | Frontend | `admin` |
| UI component / page | Frontend | `admin`, `ux` |
| Tests (if not in scope above) | Frontend | `admin` |
| Public-template integration (if applicable) | Template | — |

Skip rows that don't apply.

## Phase 5 — Phase label

| Phase | When |
|---|---|
| `phase:1` | Foundational — gap that makes the product feel incomplete |
| `phase:2` | Progressive — usability lift on solid base |
| `phase:3` | Differentiation — sets the product apart |
| `phase:4` | Speculative — depends on unbuilt infra |

Don't label everything `phase:1` — it dilutes priority.

## Phase 6 — File parent + sub-issues with `gh`

**File the parent first** so its number can be referenced from each sub-issue.

```bash
PARENT=$(gh issue create \
  --title "<feature name>" \
  --label "<type>,<area>,<phase>,epic" \
  --body "$(cat <<'EOF'
## Summary
<user benefit + the architectural fit verdict>

## Sub-issues
- [ ] #TBD — <sub 1 title>
- [ ] #TBD — <sub 2 title>
- [ ] #TBD — <sub 3 title>

## Acceptance Criteria (overall)
- [ ] All sub-issues closed
- [ ] End-to-end test covers the user journey
- [ ] No regressions in related features

## Out of Scope
<what this feature does NOT include>

## Access Control
| Action | Role A | Role B | … |

## Error Cases
| Trigger | Code | HTTP | i18n key |

## Test Strategy (overall)
| Category | Scenario | Outcome |
|---|---|---|
| Tracer bullet | <one E2E that proves the feature works> | <observable outcome> |
| Happy path | <user action> | <result> |
| Permission | <denied role attempts action> | <code, status> |
| Validation | <field at boundary> | <code, status> |
| Edge case | <state/timing/data edge> | <graceful handling> |
EOF
)" --json number --jq .number)
```

**Then file each sub-issue**, referencing the parent and naming its tracer-bullet test:

```bash
SUB=$(gh issue create \
  --title "<sub-issue, action-oriented>" \
  --label "<type>,<area>,<phase>" \
  --body "$(cat <<EOF
Parent: #${PARENT}

## Summary
<what this sub delivers>

## Current State
<gap today>

## Proposed Solution
<high-level; reference existing patterns>

## Acceptance Criteria
- [ ] Specific, testable
- [ ] Tracer-bullet test passes
- [ ] No regressions in related features

## Dependencies
- Depends on #N — <why>

## Out of Scope
<scope fence>

## Test Strategy
| Category | Scenario | Outcome |
|---|---|---|
| Tracer bullet | <one test that proves the sub's path works end-to-end> | <observable> |
| Happy path |  |  |
| Permission |  |  |
| Validation |  |  |
| Edge case |  |  |

Implementation must follow Pocock-style TDD (vertical slices, one test → minimal impl).
EOF
)" --json number --jq .number)
```

**After each sub is filed, edit the parent** to replace the `#TBD` placeholder with the real number:

```bash
gh issue edit ${PARENT} --body "$(gh issue view ${PARENT} --json body --jq .body | sed "s|#TBD — <sub 1 title>|#${SUB} — <sub 1 title>|")"
```

(Or just rewrite the parent body once all subs are filed — whichever is cleaner.)

## Phase 7 — Report

```
## Feature PM Review: <name>

### User Story
<...>

### Architectural Fit
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

Before filing, every issue (parent and sub) must satisfy:

- [ ] Title says what should exist (not "improve X", not implementation detail)
- [ ] Summary states user benefit
- [ ] Acceptance criteria testable by someone who didn't write the code
- [ ] "Out of Scope" present
- [ ] Phase label genuine, not aspirational
- [ ] All applicable area labels
- [ ] Parent has `Sub-issues` checklist; each sub has `Parent: #N`
- [ ] Cross-sub dependencies referenced with `#N`
- [ ] Access control matrix present (parent for the feature, subs for sub-actions)
- [ ] Error cases table present
- [ ] Test Strategy table present, with a named **tracer-bullet** test
- [ ] i18n keys for all new strings
- [ ] Accessibility noted if new UI

After all subs are filed, sanity-check the parent body — every `#TBD` replaced, every sub linked back.
