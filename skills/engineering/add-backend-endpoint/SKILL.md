---
name: add-backend-endpoint
description: Add a new backend HTTP endpoint following the project's existing conventions — language and framework agnostic. Walks the layers (schema → repo → handler → routing → spec → client wiring), TDD-first. Use when adding a new API route to a backend codebase.
---

# Add Backend Endpoint

Add a new HTTP endpoint matching the project's house style. The skill is the discipline; the project supplies the syntax. **Read an existing similar endpoint first.**

**Coding principles** (always active): see `coding-principles` skill.
**TDD discipline** (always active): see Pocock's `tdd` skill — test first, vertical slices, never horizontal.

## Step 0 — Match an existing example

Before writing anything, find the closest analogous endpoint in this repo (similar verb, similar resource, similar auth) and read it end-to-end. Mirror its layout, naming, and idioms. The framework, language, ORM, and serialization are whatever this codebase already uses — match it.

## Step 1 — Tracer-bullet test

Write **one** integration/HTTP test that drives the new route and asserts the expected response shape. The test must compile-fail or assertion-fail against the current code (no route yet). Confirm the failure reason is "route not found" (or equivalent) — not a setup problem.

## Step 2 — Walk the layers

For every endpoint, regardless of stack, address each artifact. Names vary; responsibilities don't.

| Artifact | Responsibility | What to add |
|---|---|---|
| Request schema / DTO | Shape + validation of incoming body, query, path params | New struct/type with the project's validation decorators; required vs optional fields explicit |
| Response schema / DTO | Shape of outgoing payload | New struct/type matching the contract you want; serialization rules per project convention |
| Repository / model method | DB or external-service access | New method on the appropriate repo/model; reuses an existing helper if one fits |
| Handler / controller | Auth → validate → call repo/service → respond | Thin function: no business logic inline, no inline data access |
| Authorization | Min-role check, tenant scoping | Use the project's existing guard/middleware; never bypass |
| Audit / observability | Side-effect logging for writes | If the project has an audit log, write to it on mutations |
| Error mapping | Failure paths return stable error codes | Each new failure path gets a code (`ERR_<DOMAIN>_<CAUSE>`) and an HTTP status |
| Routing registration | Hook the handler into the router | Add to the project's route list, route group, or attribute-based registry |
| API spec entry | Public contract document | Update OpenAPI / Swagger / API typespec / equivalent |
| Typed client method | Frontend or SDK consumer | Add the corresponding client method, mirroring the response schema |
| Test mock | Shared test setup | Register the new client method in any global mock used by component tests |

If the project doesn't have one of these artifacts (e.g. no separate DTO layer, no audit log), skip it — but note the absence in the commit so it's intentional.

## Step 3 — Implement minimally to green

Pocock-style red-green-refactor:

1. **RED** — the tracer-bullet test fails for the right reason.
2. **GREEN** — minimal handler, schema, repo method, routing entry to make the test pass. No speculative fields, no "while I'm here" cleanup.
3. **REFACTOR** — only while green. Extract duplication revealed by the new code; deepen modules.

For each additional behavior the endpoint needs (validation rules, permission denials, edge cases), add **one more test, then the code to satisfy it**, in order. Never bulk-write tests.

## Step 4 — Match conventions

Before declaring done, check that the new endpoint matches the closest existing example on:

- [ ] Naming: function, type, file, route path
- [ ] Auth: same guard/middleware pattern
- [ ] Validation: same decorators / validator usage
- [ ] Pagination (if list): same page-size param names, same response envelope
- [ ] Error envelope: same shape (RFC 7807, `{error, code}`, whatever the project uses)
- [ ] API spec: same tag, same security scheme, same param documentation style
- [ ] Client method: same naming convention (`getX`, `createX`, `updateX`, `deleteX` or whatever the codebase uses)

If any check diverges, either justify it or align with house style.

## Step 5 — Run the project's check script

Run the project's check script (see the `run-checks` skill) — formatter, linter, types, unit tests, integration tests. Show the output. Fix any failure before committing.

## Abort if

- The closest example endpoint is itself off-pattern — flag it for an `architect-review` pass, then ask the user how to proceed.
- The required behavior conflicts with the project's auth or tenancy model — surface the conflict before coding.
- The test cannot be written at the right seam — that itself is the finding (consult `diagnose` / `improve-codebase-architecture`).
