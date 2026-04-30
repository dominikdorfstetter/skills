---
name: resolve-issue
description: End-to-end issue resolver. Reads a GitHub issue via gh, classifies the work, gates on requirements, implements with TDD using Pocock-style vertical slices, verifies, and commits. Use when given an issue number or URL to fix.
---

# Resolve Issue

Orchestrates: `gh issue view` → analysis → TDD implementation → verification → commit.

**Coding principles** (always active): see `coding-principles` skill.
**TDD discipline** (always active): see Pocock's `tdd` skill — one test → minimal impl → repeat. **Never horizontal slicing.**

## Phase 1 — Load

```bash
gh issue view <NUMBER> --json number,title,body,labels,assignees,state,comments
gh issue view <NUMBER> --comments   # full discussion
```

If the issue has a parent, also load it:

```bash
# Parent reference is in the body — "Parent: #N"
gh issue view <PARENT> --json title,body,labels
```

Extract: title + body, labels, comment clarifications, parent context, sibling sub-issues, linked PRs. If no number was given, ask for it.

## Phase 2 — Classify

| Signal | Scope |
|---|---|
| `backend` label / handler/model/migration mentioned | `backend-only` |
| `frontend` label / page/component/hook | `frontend-only` |
| Both, or new API + new UI | `full-stack` |
| `bug` label | TDD mandatory (test reproduces the bug) |
| `enhancement` / `feature` | TDD mandatory (test demonstrates the new behavior) |
| `docs` / config-only | TDD not required (no behavior change) |

**TDD is mandatory for any change that introduces or modifies behavior.** Pure docs / formatting / config-only is the only exemption. State the classification and reasoning before continuing.

## Phase 3 — Requirement gate (HARD)

Do not proceed if the issue fails any check.

**Freshness** — Compare issue creation date to recent commits in the affected dirs (`git log --since=<date>`).

- Already implemented → `gh issue close <N> --reason "not planned" --comment "<why>"`, stop.
- Stale but salvageable → update body in-place with `gh issue edit`, continue.
- Area has grown → flag missing considerations, ask whether to extend scope.

**Completeness checklist**

| Section | When required | If missing |
|---|---|---|
| Acceptance Criteria | Always | Ask user for definition of done |
| Access Control matrix | If feature has actions | Auto-generate from role model, confirm |
| Error Cases table | If feature can fail | Auto-generate from handler/DTO, confirm |
| Test Strategy table | Always | Auto-generate, confirm — name the tracer-bullet test |
| Tracer-bullet test | Always (TDD) | Define the single test that proves the path works |
| i18n keys | If user-visible strings | Propose keys from existing namespace |
| Accessibility notes | If new UI elements | Add per component type |

For each missing section: fill from codebase analysis (and confirm) or ask one specific question. Once filled:

```bash
gh issue edit <N> --body "$(cat <<'EOF'
<updated body>
EOF
)"
```

If user explicitly says "skip the gate", note "issue incomplete, implemented per user request" in the commit and still flag what's missing.

## Phase 4 — Codebase analysis

Read only what's relevant.

- **Backend** — handler, model, DTO, existing tests, latest migration (for numbering).
- **Frontend** — page/component, affected hooks, API client method, types, existing tests.
- **Full-stack** — both. Identify the contract boundary.

Produce: root cause (bugs) or gap analysis (features), file-by-file change list (create/modify/delete), risk areas, **the list of behaviors to test in vertical-slice order** (tracer bullet first, then incremental).

## Phase 5 — TDD plan

Mandatory. State the test list before writing any code:

1. **Tracer bullet** — one end-to-end test that proves the whole path works (e.g. for an endpoint: request goes in, correct response comes out, side effect happened).
2. **Incremental tests** — ordered list of behaviors to add, each with one test.

Each test must:

- Describe behavior, not implementation.
- Use the public interface (HTTP, hook return, exported API), not internals.
- Survive an internal refactor.

If the user has scoped opinions ("skip the X test, we don't care about that path"), respect them and note in the commit.

## Phase 6 — Implementation (red → green → refactor)

For each test in the Phase 5 list, in order:

**RED** — Write the test at the right seam. Run it. Confirm it fails for the **right reason** (not a compile error, not a mock setup error, not the wrong assertion).

**GREEN** — Write the minimal code to pass. No speculative abstractions. No "while I'm here" cleanup. Run the test. Confirm green.

**REFACTOR** — Only while green. Extract duplication, deepen modules, apply SOLID where natural. Re-run after every refactor step. Never refactor with a failing test.

Move to the next test only when the current cycle is fully green.

Route to project-specific scaffolders for boilerplate (e.g. `add-backend-endpoint`, `add-admin-list-page`, `write-admin-tests`) — but keep the test-first cadence regardless.

## Phase 7 — Verification gate (HARD)

Three parts. All must pass.

**A. Full test suite** — Run the project's full check script regardless of scope. Show actual output. No summarizing.

**B. Frontend health (if any UI files changed)** — Run the project's frontend health check. Score must meet threshold. Skip with a note if backend-only.

**C. Documentation** — For features and meaningful bug fixes:

- Docs site — new endpoint / page / config / changed behavior → update before committing.
- README — new major feature, new dev workflow, changed prerequisites → update.
- Changelog — feature or non-trivial fix → add entry.

State each as: `PASSED` / `SKIPPED (reason)` / `UPDATED` / `NOT NEEDED (reason)`.

## Phase 8 — Self-review

```
□ Every acceptance criterion addressed?
□ Edge cases from comments handled?
□ TDD followed: every behavior has a test written before its implementation?
□ Tests test behavior through public interfaces, not internals?
□ No new unwrap/!/panic in production code paths
□ No over-engineering — only what the issue asks for
□ No files modified beyond Phase 4 scope
```

If gaps, fix and re-verify (re-run Phase 7 if any code changed).

## Phase 9 — Commit & link

**Always create a feature branch.** Never commit directly to `main`.

```bash
git checkout -b fix/<short-description>   # bug
git checkout -b feat/<short-description>  # feature
```

If you already committed to `main`:
1. `git checkout -b <branch>` from current HEAD
2. `git branch -f main origin/main`
3. Continue from the feature branch.

Stage specific files (never `git add -A`):

```bash
git commit -m "$(cat <<'EOF'
<type>(<scope>): <summary>

<what changed and why — connect to the issue>

Fixes #<N>
EOF
)"
```

Types: `fix`, `feat`, `refactor`, `test`, `docs`, `chore`.

If this issue has a parent, **comment on the parent** to update progress:

```bash
gh issue comment <PARENT> --body "Closed sub-issue #<N>: <summary>. Remaining: <list>."
```

Do not push or open a PR unless explicitly asked.

## Abort if

- Issue is ambiguous about what "done" means.
- Change touches shared infrastructure (auth, schema, core services) in a way that affects many endpoints.
- Migration needed — confirm migration content first.
- Tests fail for reasons unrelated to the issue.
- A test cannot be written at the right seam (the architecture is preventing the bug from being locked down) — flag this and consult `/improve-codebase-architecture`.
