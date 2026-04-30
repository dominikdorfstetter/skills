---
name: bug-report
description: Turn a vague bug description into a complete, actionable issue. Asks structured questions, investigates the codebase, builds reproduction steps, and files an issue with error codes and a test strategy. Use when user reports a bug informally and wants it tracked.
---

# Bug Report

Convert a fuzzy bug into a filed issue with reproduction steps, root-cause analysis, and a regression test strategy.

## Phase 1 — Capture the symptom

Ask **one question at a time**, not all at once. Required:

1. **What happened?** Observed behavior.
2. **What did you expect?** Intended behavior.
3. **Where?** Page / endpoint / feature.
4. **When?** Always or sometimes? Conditions (role, browser, data state).
5. **Who?** Which roles are affected?

## Phase 2 — Investigate

Once the symptom is captured, silently:

- Search the codebase for the affected area.
- `git log --oneline -20 -- <files>` for recent changes that may have introduced it.
- `gh issue list --search "<keywords>" --state open` for duplicates.
- Identify likely root cause or 2–3 candidates.

Report findings to the user: "I think this is in `<area>`, likely caused by `<X>`. Match what you're seeing?" If duplicate exists, offer to comment on it instead of filing new.

## Phase 3 — Reproduction

Draft numbered steps and confirm with the user before filing:

```
1. Log in as <role>
2. Navigate to <page>
3. Do <action> with <data>
4. Observe: <symptom>
5. Expected: <behavior>
```

## Phase 4 — Severity

Ask the user:

- **Critical** — broken for everyone, data loss, security
- **Major** — broken for some roles; painful workaround
- **Minor** — cosmetic / edge case
- **Trivial** — typo / alignment

Critical/Major → `phase:1`; Minor → `phase:2`; Trivial → `phase:3`. Adapt to the project's labels.

## Phase 5 — Error cases & tests

If the bug is in error handling, define the expected error shape:

| Trigger | Current | Expected code | HTTP | i18n key |
|---|---|---|---|---|

Always define the regression test strategy:

| Category | Scenario | Outcome |
|---|---|---|
| Regression | Reproduce the bug | Fix verified |
| Boundary | Adjacent edge case | Handled |
| Permission | Role-specific (if applicable) | Correct denial/allowance |

## Phase 6 — File the issue with `gh`

Show the preview before creating.

If the bug needs more than one PR to fix (e.g. backend + frontend, or multiple endpoints), file a **parent + sub-issues** instead of one issue. The single-issue template below applies for both — for the parent, replace "Reproduction Steps" with a `Sub-issues` checklist (`- [ ] #TBD — <title>`) and file each sub with `Parent: #<parent>` plus its own reproduction.

```bash
gh issue create \
  --title "fix(<scope>): <concise description>" \
  --label "bug,<area>,<phase>" \
  --body "$(cat <<'EOF'
## Bug Report
- Severity, affected roles, affected area

## Reproduction Steps
1. ...

Observed: <what>
Expected: <what>

## Root Cause Analysis
<files, likely cause, recent commits>

## Error Cases
| Trigger | Current | Expected code | HTTP | i18n key |

## Test Strategy
| Category | Scenario | Outcome |
|---|---|---|
| Tracer bullet | A single test that fails today and passes after the fix | Observable behavior |
| Regression | Reproduce the exact bug | Fix verified |
| Boundary | Adjacent edge case | Handled |
| Permission | Role-specific (if applicable) | Correct allow/deny |

The fix must be implemented Pocock-style TDD: write the regression test first (the tracer bullet), watch it fail, fix, watch it pass.

## Files Likely Affected
- path — what changes
EOF
)"
```

Report back the issue number(s). If parent + subs were filed, edit the parent body to replace `#TBD` placeholders with the real sub numbers.

## Abort

- If `main` already has the fix → tell user, don't file.
- If duplicate exists → `gh issue comment <N>` with the new repro instead.
- If user can't reproduce → mark intermittent in body, note non-deterministic-bug guidance from the `diagnose` skill.
