---
name: run-checks
description: Run a project's quality checks — tests, lint, typecheck, formatting, frontend health — before committing. Use when user asks to run tests, verify code quality, or pre-commit gate. Adapts to whatever toolchain is in the repo.
---

# Run Checks

Run the project's quality gates and report status. Does not silence failures — fixes them.

## Detect the toolchain

Before running anything, identify what's in the repo:

- `package.json` → npm/pnpm/yarn scripts (`test`, `lint`, `typecheck`, `format`)
- `Cargo.toml` → `cargo fmt --check`, `cargo clippy -- -D warnings`, `cargo test`
- `pyproject.toml` → `ruff`, `mypy`, `pytest`
- `go.mod` → `go test ./...`, `golangci-lint run`
- A repo-level script (`./scripts/dev-test.sh`, `./scripts/check.sh`, `Makefile`) → use it as the source of truth.
- A frontend health tool (React Doctor, Lighthouse CI) → run separately if it exists.

If the repo has a single check script, **prefer it** — it's the authoritative source matching CI.

## Run

For each layer present, run in this order. Stop and fix on first failure; don't continue past it.

| Layer | Typical command |
|---|---|
| Format check | `cargo fmt --check` / `npm run format:check` / `ruff format --check` |
| Lint | `cargo clippy -- -D warnings` / `npm run lint` / `ruff check` / `golangci-lint run` |
| Typecheck | `npm run typecheck` / `mypy` / `tsc --noEmit` |
| Unit tests | `cargo test --lib` / `npm test -- --run` / `pytest -m "not integration"` |
| Integration tests | `cargo test --test integration_tests` / `pytest -m integration` (often needs a service running) |
| Frontend health | `npm run react-doctor:online` (or equivalent) |

For integration tests, check the project's docker-compose / setup script — they often need a database or service running.

## When checks fail

| Failure | Fix |
|---|---|
| Format check | Run the formatter (`cargo fmt`, `prettier -w`, `ruff format`) — never silence |
| Lint warning | Fix the code; never `#[allow(...)]` or `// eslint-disable` without an inline justification comment |
| Typecheck | Fix the types — usually a missing generic, wrong API type, or stale return signature |
| Unit test | Read the failure; check mocks and fixtures; confirm the failure matches the expected symptom |
| Integration test | Confirm the required service is up; check connection strings and seed data |
| Frontend health below threshold | Read the report; fix flagged components (memo, useCallback, stable refs, split large components); re-run until green |

## Report

After all gates run:

```
✓ Format: PASSED
✓ Lint: PASSED (or list warnings if non-blocking)
✓ Typecheck: PASSED
✓ Unit tests: PASSED (N tests)
✓ Integration tests: PASSED | SKIPPED (reason)
✓ Frontend health: <score> | SKIPPED (no frontend changes)
```

Show actual command output for any failure. Don't summarize — paste it.

## CI parity

The repo's check script and CI workflow should run the same gates. If they diverge, that itself is an issue — flag it. CI is the source of truth for what's required to merge.
