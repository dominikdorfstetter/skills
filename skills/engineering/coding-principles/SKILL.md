---
name: coding-principles
description: Reference document encoding the owner's coding philosophy. Loaded by other skills as a shared source of truth — not invoked directly. Covers think-first, no-duplication, functional bias, clean architecture, file focus, test quality, accessibility, error design, access-control design.
---

# Coding Principles

Applies to every file touched, regardless of which skill is active.

## Think first

Before writing a line of code:

1. What is the exact behavior needed?
2. Where does this logic belong in the existing architecture?
3. Is any part of this already implemented elsewhere — can it be reused?
4. What is the minimal change?

Produce a short mental model first. Don't write first and think later.

## No duplication

If a pattern appears in more than one place, it belongs somewhere shared. Search before adding.

- Same state-and-mutation block in two pages → extract a hook.
- Same SQL fragment in two model methods → extract a helper.
- Same authorization check across handlers → middleware/guard.
- Same UI structure twice → shared component.

Extend; don't copy.

## Functional bias

Prefer functions that take input, return output, touch nothing else. Side effects (HTTP, navigation, toasts, mutations) live in event handlers, `useEffect` with explicit deps, or mutation `onSuccess`/`onError` — never mixed into rendering or pure transforms. In Rust, propagate `Result<T, E>` with `?`; avoid hidden global state and `unwrap`.

## Clean architecture

Each file has one clear job.

**Frontend layers**: types → service (HTTP only) → hooks (data + state) → components (rendering + events) → pages (composition). Pages don't contain business logic; hooks don't import UI libraries; components don't call the API service directly.

**Backend layers**: DTO (shapes + validation) → model (DB queries as `impl` methods, no HTTP) → handler (auth → validate → model → respond, thin) → service (cross-cutting: audit, webhooks, notifications). All SQL lives in `impl Model`. Services are called by handlers, never models.

## File focus

A file is too large when you scroll to remember what's in it, two unrelated concerns share it, or a change in one area requires understanding the whole file.

Rough signals (not hard limits): React component >250 lines, page >400, hook >150, handler file >500, model file >300. Split by extracting sub-components, dedicated hooks, or sub-resource files.

## No self-attribution

Never add AI attribution to commits, PRs, issues, comments, or file headers. The owner ships the code.

## TDD always

Every behavior change is implemented with Pocock's red-green-refactor in vertical slices: one test → minimal impl → repeat. Never write all tests first. See the `tdd` skill.

## Test quality

Tests model real-life user scenarios, not implementation internals.

- Name as user stories: "admin can ban a user and sees confirmation" — not "calls mockBanUser with correct args".
- For every validated value: valid input, boundary values, at least one invalid input.
- Prefer `userEvent` over `fireEvent` — real interaction sequences.
- Assert on what the user sees or what the API receives — not on mock call counts as the primary assertion.

## Test Manager mindset

Before writing a test, ask in order:

1. What user-visible behaviors exist? Each → at least one test.
2. Permission boundaries? For each action × role: allowed roles succeed, denied roles get the correct error code.
3. Validation boundaries? For each validated field: valid, boundary, invalid.
4. State transitions? Test every valid transition AND every invalid one.
5. Dependency failures? API timeout, empty response, malformed data, concurrent edits.
6. What is NOT worth testing? Framework internals, simple getters, third-party UI library behavior.

Output: a test plan table before writing any test code.

## Internationalization

Every user-visible string goes through the project's i18n layer. Search the existing locale file for an existing key before adding a new one. Use nested namespacing (e.g. `moderation.actions.ban`, not `ban_button_text`). Don't translate literally — think native-speaker phrasing. Never hardcode user-visible English in markup.

## Accessibility — WCAG 2.1 AA mandatory

Hard gate for every frontend change.

- **Semantic HTML first**: `<button>`, `<nav>`, `<main>`, `<section>`, `<dialog>` — not `<div onClick>`. Every `<img>` has a meaningful `alt` (or `alt=""` if decorative). Headings follow logical hierarchy.
- **ARIA only when native semantics are insufficient**. Custom widgets need `role`, `aria-label`, keyboard handlers. Live regions for dynamic updates.
- **Keyboard**: every interactive element reachable; expected keys work (Enter/Space, Arrows, Escape); visible focus indicator; never `outline: none` without a replacement.
- **Color & contrast**: 4.5:1 for normal text, 3:1 for large; never convey meaning by color alone.
- **Test by role**: `getByRole`, `getByLabelText`. If a test can't find an element by role, the element isn't accessible.

## Error design

Errors are a product feature.

- Backend: every new error path gets a dedicated variant with a unique code. Codes are stable identifiers — once shipped, they don't change. Responses follow RFC 7807 (ProblemDetails) with the code in `type`.
- Frontend: error messages come from i18n keys, not hardcoded strings. Map backend codes to specific, helpful messages — not "Something went wrong". Distinguish user-fixable from system errors visually.
- In specs and issues: every feature has an Error Cases table — trigger, code, HTTP, i18n key.

## Access control design

Every user-facing feature includes an access-control design.

- Which existing role(s) gain access? Use the project's permission hierarchy.
- New capabilities are named permissions (`can_moderate`, `can_publish`), not ad-hoc role checks.
- Define error codes as part of the design, not afterthought. Format: `ERR_<DOMAIN>_<CAUSE>`. Each maps to an i18n key.
- In issues: Acceptance Criteria lists which roles can/can't do each action; Proposed Solution includes the error-code table.

## Frontend UX standards

Design for the end user, not the developer.

- Use the project's type scale consistently — no ad-hoc font sizes. Body text ≥ 16px.
- Subtle transitions on state changes (0.2–0.3s ease). Skeleton loaders where layout is predictable.
- Animations barely noticeable; respect `prefers-reduced-motion`.
- Empty states are informative and actionable. Error states explain what happened and the next step. Loading appears within 200ms — no content flash.
