---
name: to-issues
description: Break a plan, spec, or PRD into a parent epic + independently-grabbable sub-issues on GitHub via `gh`, using vertical-slice tracer bullets. Each sub ships a Test Strategy with a tracer-bullet test. Use when the user wants to convert a plan into issues, create implementation tickets, or break work into trackable pieces.
---

# To Issues

Break a plan into a **parent epic + sub-issues** on GitHub via `gh`. Each sub is a vertical slice (tracer bullet) that cuts end-to-end through every layer.

**Conventions** (see top-level README): `gh` CLI only; parent body lists `- [ ] #N` checkboxes; each sub has `Parent: #N`; every sub ships a Test Strategy table with a named tracer-bullet test.

## Process

### 1. Gather context

Use what's already in the conversation. If the user passes an issue reference (number or URL), fetch with `gh issue view <N> --comments`. If the source is an existing GitHub issue, **that issue becomes the parent** — don't create a duplicate.

### 2. Explore the codebase (if not already)

Use the project's domain glossary so issue titles and descriptions match house language. Respect ADRs in the affected area.

### 3. Draft vertical slices

Each slice is a **tracer bullet**: a thin path through ALL integration layers (schema, API, UI, tests) that's demoable on its own. Prefer many thin slices over a few thick ones.

Mark each slice as `AFK` (can be implemented without human interaction) or `HITL` (requires a design call or review). Prefer AFK.

### 4. Quiz the user

Present a numbered list. For each slice show:

- **Title** — short, action-oriented
- **Type** — AFK / HITL
- **Blocked by** — which slices must complete first (placeholder `#TBD` until filed)
- **Tracer-bullet test** — the one end-to-end test that proves the slice works

Ask the user:

- Granularity right? (too coarse / too fine)
- Dependency relationships correct?
- Should any slices merge or split?
- AFK/HITL marking right?

Iterate until approved.

### 5. File parent + sub-issues with `gh`

**Parent first** (only if no source-issue parent exists). Apply the project's epic label if one exists; otherwise tag with the canonical category (`bug`, `enhancement`).

```bash
PARENT=$(gh issue create \
  --title "<feature / change name>" \
  --label "epic,needs-triage" \
  --body "$(cat <<'EOF'
## What we're building
<one-paragraph summary of the overall change>

## Sub-issues
- [ ] #TBD — <slice 1 title>
- [ ] #TBD — <slice 2 title>
- [ ] #TBD — <slice 3 title>

## Acceptance Criteria (overall)
- [ ] Every sub-issue closed
- [ ] End-to-end happy path verified
- [ ] No regressions in related features

## Out of Scope
<what this epic does NOT include>

## Test Strategy (overall)
| Category | Scenario | Outcome |
|---|---|---|
| Tracer bullet | <one E2E test that proves the feature works> | <observable> |
| Regression | Existing functionality continues to pass | All green |
EOF
)" --json number --jq .number)
```

If the source was an existing issue, **don't create a parent** — the source IS the parent. Edit it to add the `## Sub-issues` checklist:

```bash
gh issue edit <SOURCE> --add-label epic --body "$(cat <<EOF
$(gh issue view <SOURCE> --json body --jq .body)

## Sub-issues
- [ ] #TBD — <slice 1>
- [ ] #TBD — <slice 2>
EOF
)"
```

**Then file each sub** in dependency order (blockers first, so you can reference real numbers in `Blocked by`):

```bash
SUB=$(gh issue create \
  --title "<slice title>" \
  --label "<type>,<area>,needs-triage" \
  --body "$(cat <<EOF
Parent: #${PARENT}

## What to build
<concise description of this vertical slice — end-to-end behavior, not layer-by-layer impl>

## Acceptance Criteria
- [ ] <specific, testable>
- [ ] <specific, testable>
- [ ] Tracer-bullet test passes

## Blocked by
- #<N> — <why> (or "None — can start immediately")

## Type
AFK | HITL <one-line justification if HITL>

## Test Strategy
| Category | Scenario | Outcome |
|---|---|---|
| Tracer bullet | <single E2E test that proves the slice works> | <observable> |
| Happy path |  |  |
| Permission |  |  |
| Validation |  |  |
| Edge case |  |  |

Implementation must follow Pocock-style TDD (vertical slices, one test → minimal impl). See \`tdd\` skill.
EOF
)" --json number --jq .number)
```

### 6. Patch the parent with real numbers

After every sub is filed, rewrite the parent body to replace `#TBD` placeholders with the real sub numbers:

```bash
gh issue edit ${PARENT} --body "$(cat <<EOF
<parent body with real #N values>
EOF
)"
```

Do NOT close or modify any source issue beyond adding the sub-issue checklist.

## Quality bar

Before each sub is filed, verify:

- [ ] `Parent: #N` line present
- [ ] Tracer-bullet test named and observable
- [ ] AC testable by someone who didn't write the code
- [ ] `Blocked by` references real `#N` for filed dependencies (not `#TBD`)
- [ ] Test Strategy covers happy path + permissions + validation + edge case
- [ ] `needs-triage` label applied

After the parent is patched, every sub appears as a real `- [ ] #N` line.
