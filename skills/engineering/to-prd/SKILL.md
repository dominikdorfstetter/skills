---
name: to-prd
description: Synthesize the current conversation into a PRD and file it as a GitHub epic via `gh`. Does not interview — uses what you already know. Hands off to `/to-issues` to break it into sub-issues. Use when user wants to capture the discussion as a tracked plan.
---

# To PRD

Take the current conversation context and codebase understanding and produce a PRD. **Do NOT interview the user** — synthesize what you already know. The PRD is filed as a GitHub epic that `/to-issues` will later decompose into sub-issues.

**Conventions** (see top-level README): `gh` CLI only; the PRD becomes a parent epic; sub-issues link back via `Parent: #N`.

## Process

### 1. Explore (if not already)

Read the codebase to understand the current state. Use the project's domain glossary throughout the PRD; respect ADRs in the affected area.

### 2. Sketch modules

Identify the major modules to build or modify. Actively look for **deep modules** — small testable interfaces that encapsulate substantial functionality and rarely change.

Check with the user:
- Do these modules match expectations?
- Which modules want tests written?

### 3. Write the PRD body

```
## Problem Statement
<the problem from the user's perspective>

## Solution
<the solution from the user's perspective>

## User Stories
A LONG numbered list. Format: "As a <actor>, I want a <feature>, so that <benefit>."

Example: "As a mobile bank customer, I want to see balance on my accounts, so that I can make better-informed spending decisions."

The list should be extensive — cover every aspect of the feature.

## Implementation Decisions
- Modules to build/modify
- Interfaces of those modules
- Technical clarifications from the user
- Architectural decisions
- Schema changes
- API contracts
- Specific interactions

Do NOT include file paths or code snippets — they go stale fast.

## Testing Decisions
- What makes a good test (external behavior, not implementation details)
- Which modules will be tested
- Prior art for the tests in this codebase
- The tracer-bullet test that will prove the whole feature end-to-end

## Out of Scope
<what this PRD explicitly does NOT cover>

## Sub-issues (filled in by /to-issues)
- [ ] #TBD — <slice>
- [ ] #TBD — <slice>

## Further Notes
<anything else>
```

### 4. File as a parent epic via `gh`

```bash
PRD=$(gh issue create \
  --title "PRD: <feature name>" \
  --label "epic,needs-triage,prd" \
  --body "$(cat <<'EOF'
<the PRD body from step 3>
EOF
)" --json number --jq .number)
echo "PRD filed as #${PRD}"
```

### 5. Hand off to `/to-issues`

Tell the user:

> "PRD filed as #${PRD}. Run `/to-issues #${PRD}` to break it into sub-issues. The sub-issues will reference this PRD as their parent."

`/to-issues` will read this PRD as the source, decompose it into vertical slices, file each sub with `Parent: #${PRD}`, and patch the `Sub-issues` checklist with real numbers.

Do NOT decompose into sub-issues yourself — that's `/to-issues`'s job and keeps the boundary clean.
