---
name: add-list-page
description: Scaffold a new CRUD list page in any frontend codebase — language and framework agnostic. Walks the layers (data fetch, mutations, RBAC, loading/empty/error, i18n, accessibility, UX polish), TDD-first. Use when adding a list/management page to a UI codebase.
---

# Add List Page

Scaffold a paginated CRUD list page matching the project's house style. The skill is the discipline; the project supplies the components, hooks, and idioms. **Read an existing similar page first.**

**Coding principles** (always active): see `coding-principles` skill.
**TDD discipline** (always active): see Pocock's `tdd` skill — write the page test first, build to green incrementally.

## Step 0 — Match an existing example

Find the closest analogous page in the repo (similar resource, similar shape — table or card grid, with create/edit/delete) and read it end-to-end. Mirror its layout, hooks, and idioms.

## Step 1 — Tracer-bullet test

Write a single component/page test that renders the new page with mocked data and asserts the user can see the rows. The test must fail because the page doesn't exist yet. Apply the `write-component-tests` skill for setup patterns.

## Step 2 — Walk the layers

| Artifact | Responsibility |
|---|---|
| List query | Server-side paginated fetch — use the project's data-fetching primitive (TanStack Query, RTK Query, SWR, native `fetch` + state, etc.). Match the existing pattern. |
| List state hook | Pagination + dialog/selection state. Reuse the project's shared hook if one exists; if multiple pages duplicate the same state, that is itself an extraction signal. |
| Mutation hook | Create / update / delete with cache invalidation, success toast, error surface. Reuse the project's shared mutation hook if one exists. |
| RBAC | Hide write actions behind the role/permission check that lives in the project's auth context. UI hides; backend enforces. |
| Layout | Page header, table or card grid, pagination control — using the project's shared components. |
| Loading / empty / error | Use the project's shared placeholders, not ad-hoc spinners or alerts. |
| Confirm dialog | Use the project's shared confirm dialog for destructive actions. |
| Routing | Register the new page in the project's router/route definition. |

If the project has no shared hooks for list state or mutations and you find yourself reaching for `useState` to track `page`/`perPage`/`isFormOpen`/`editing`/`deleting`, that's a duplication signal — surface it as an extraction issue rather than copying.

## Step 3 — Wire types and client

| Artifact | What to do |
|---|---|
| API types | Mirror the backend response schema exactly. If the language has discriminated unions / tagged enums, match the backend's serialization casing. |
| Typed client method | Add `getThings`, `createThing`, `updateThing`, `deleteThing` (or whatever convention this codebase uses) to the API client module. |
| Mock | Register the new client methods in any shared test mock — otherwise tests for unrelated pages will break next time setup is reused. |

## Step 4 — i18n

Every user-visible string goes through the project's translation layer.

- Search the source-of-truth locale file for an existing key first. Reuse `actions.save`, `actions.cancel`, `actions.delete`, status keys, table keys, validation keys before creating new ones.
- New keys follow the existing namespace pattern (e.g. `<resource>.title`, `<resource>.table.<column>`, `<resource>.empty`, `<resource>.form.<field>`).
- Add keys to **every** locale file the project ships. If you can't translate, leave the source-language value as a placeholder and note which locales need translation.
- Think localized — phrasing should read naturally in each target language, not literal translation.

## Step 5 — Accessibility (WCAG 2.1 AA)

- Tables: descriptive `aria-label` on the table; column headers as `<th>` (or the framework equivalent).
- Icon-only buttons: `aria-label` describing the action and target ("Open menu for <name>").
- Empty / loading: `role="status"` (and `role="alert"` for errors) so assistive tech announces state changes.
- Focus management: after create → focus new row or success alert; after delete → focus next row or empty state; dialog open → focus first input; dialog close → focus the trigger.
- Keyboard: every interactive element reachable; Escape dismisses dialogs/menus; Enter submits forms; arrow keys for menu navigation.
- Visible focus indicator on every interactive element. Never `outline: none` without a replacement.

## Step 6 — UX polish

- Skeleton placeholders for table content, not spinners — preserves layout.
- Subtle transitions on state changes (~200–300ms ease).
- Respect `prefers-reduced-motion` — disable non-essential animations when the user opts out.
- Empty states are informative AND actionable: explain what's missing and offer a "create the first one" button gated by the write permission.
- Error states explain what happened and a next step.
- Loading appears within ~200ms — no content flash.

## Step 7 — Build to green

Vertical slices: implement just enough for the tracer-bullet test to pass. Then add one test + implementation per remaining behavior (RBAC hides actions, empty state shows, validation errors render, etc.).

## Step 8 — Run checks

`run-checks` skill. Format, lint, typecheck, all tests, frontend health if the project has a tool for it (React Doctor, Lighthouse CI, accessibility lints). Show output. Fix before committing.

## Abort if

- No analogous existing page to mirror — surface this and offer to first establish a canonical example via `architect-review`.
- The project mixes patterns inconsistently — pick the most modern/canonical one and document the choice in the PR/commit.
