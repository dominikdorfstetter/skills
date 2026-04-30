---
name: write-component-tests
description: Write tests for UI components, pages, and hooks — language and framework agnostic. Covers semantic queries, user-journey naming, validation boundaries, RBAC, accessibility, and error-code coverage. Use when adding or improving tests for any UI codebase.
---

# Write Component Tests

Write tests that describe **what the user does and sees**, not how the component is implemented. Skill is the discipline; the project supplies the runner (Vitest / Jest / Playwright / RTL / etc.).

**Coding principles** (always active): see `coding-principles` skill — Test Quality and Test Manager mindset.
**TDD discipline** (always active): see Pocock's `tdd` skill — one test → minimal impl → repeat.

## Setup — match an existing example

Read the closest existing test file in the repo. Reuse:

- The project's render helper (wraps providers, router, query client, snackbars, mock auth/site contexts).
- The project's mock pattern for API/client modules.
- The project's mock pattern for context stores.
- The project's `beforeEach` reset convention.

If no example exists, that itself is a finding — surface it and propose a shared setup before scaffolding tests file by file.

## Test design

Activate the Test Manager mindset (see `coding-principles`):

1. What user-visible behaviors exist? Each → at least one test.
2. Permission boundaries — for each action × role, allowed succeeds, denied gets the correct error code.
3. Validation boundaries — for each validated field: valid, empty, boundary-min, boundary-max, over-boundary, wrong-format.
4. State transitions — every valid transition AND every invalid one.
5. Dependency failures — API timeout, empty response, malformed data, concurrent edits.
6. NOT worth testing — framework internals, simple getters, third-party UI library behavior.

Output a test plan (mental or in the issue) before writing code.

## Naming and structure

Name tests as **user stories**, not implementation descriptions:

```
Good:  editor can create a webhook and sees success message
       viewer cannot see the delete button
       shows validation error when URL exceeds 2048 characters

Bad:   calls apiService.createWebhook with correct params
       sets isLoading to true
       renders component without errors
```

Structure files by user journey:

```
describe('WebhookFormDialog', () => {
  describe('creating', () => { ... });
  describe('editing', () => { ... });
  describe('access control', () => { ... });
});
```

## Patterns by scenario

| Scenario | Approach |
|---|---|
| Loading | Make the API call return a never-resolving promise; assert progress role |
| Data renders | Mock resolved value; wait for the rendered text/role |
| Empty | Mock empty paginated response; assert `role="status"` |
| Error | Mock rejected value; assert `role="alert"` |
| Action menu | Click the trigger; find the menu by role; click the item |
| Dialog opens | Click the trigger; wait for `role="dialog"` |
| RBAC | Adjust the mocked auth context before render; assert hidden elements |
| API called | Assert the client method was invoked with the expected args |
| Required field | Submit empty; assert the required-validation message |
| Max length | Type over-boundary; assert max-length validation message |
| Wrong format | Type invalid format; assert format-validation message |
| Specific error code | Reject with `{code: ERR_X}`; assert the alert contains the mapped message |
| Escape closes | Press Escape; assert dialog gone |
| Enter submits | Focus submit; press Enter; assert the API call |
| Form labels | Find inputs by their accessible label |
| Reduced motion | Mock `matchMedia` to `prefers-reduced-motion: reduce`; assert no animation |

Names of APIs (`getByRole`, `findByRole`, `userEvent`, etc.) vary by runner — apply the equivalent in the project's tooling.

## Validation testing — mandatory

For every validated field, six tests:

| What | Example |
|---|---|
| Valid input | the canonical happy-path value |
| Empty / missing | required-validation error |
| Boundary min | exactly the minimum |
| Boundary max | exactly the maximum |
| Over boundary | one past the max → error |
| Wrong format | malformed input → format error |

For backend error codes, mock the rejection with the actual code shape and assert the user sees the **specific** mapped message — never let everything fall through to a generic "Something went wrong" assertion.

## Accessibility — at least one assertion per file

Prefer semantic queries (priority order):

1. By role with accessible name — interactive elements.
2. By accessible label — form fields.
3. By visible text — static content.
4. By test ID — fallback only; if you reach for it, the component probably needs better semantics.

If a test can't find an element by role, the element isn't accessible. That's a finding, not an excuse to switch to test IDs.

Cover keyboard navigation (Escape, Enter, arrow keys), focus management (dialog open/close, post-mutation focus), and reduced-motion preference where animations exist.

## File placement

Match the project's convention. Common patterns:

- Pages: `<pages>/__tests__/<Page>.test.<ext>` or `<pages>/<Page>.test.<ext>`
- Components: alongside the component or in a `__tests__` subfolder
- Hooks: alongside the hook or in `__tests__`

## Mock data shape

Mirror the real response shape exactly — including pagination envelopes (`{data, meta}` or `{items, total}` or whatever the project uses). Mismatched mocks make tests pass on imagined contracts.

## Anti-patterns

- Asserting on mock call counts as the **primary** assertion (test what the user sees, not what the impl did)
- Snapshot tests as a substitute for behavior tests (snapshots lock implementation)
- One giant `it('renders correctly')` covering everything
- Bulk-writing all tests before any implementation (horizontal slicing — see Pocock's `tdd` for why this produces crap tests)
- Test IDs sprinkled to bypass missing semantics
