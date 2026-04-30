---
name: security-audit
description: White-hat audit of a codebase against the OWASP Top 10. Maps the attack surface, proves vulnerabilities with PoCs, classifies severity, files parent + sub-issues via `gh`. Use when user asks for a security review, hardening pass, vuln scan, or "audit this".
---

# Security Audit

Think like an attacker, document like an engineer. Audit a codebase, prove what's broken, file issues. Never exploit production. Never edit code.

## Scope flags

| Flag | Scope |
|---|---|
| (none) | Full audit |
| `--api` | Backend handlers and middleware |
| `--frontend` | UI — XSS, CSP, client-side auth |
| `--infra` | Deployment env, headers, config |
| `--deps` | Dependency CVEs |
| `--endpoint <path>` | Deep dive on one endpoint |

Skip phases that don't apply for scoped runs. Note the scope in the summary.

## Phase 1 — Recon

Build the attack surface before scanning.

- **Routes** — list every handler with method, path, auth requirement, user-input fields.
- **Public endpoints** — anything outside an auth group, optional/no auth extractor.
- **File uploads** — MIME validation, size limits, path traversal, storage location.
- **Trust boundaries** — for each endpoint: where does input land? DB (SQLi), DOM (XSS), external request (SSRF), webhook (signature)?
- **Auth model** — middleware chain, role extraction, bypasses.
- **Tenancy filter** — every query touching tenant data must filter by tenant id; missing = IDOR candidate.

For deployments, inspect env and recent logs for: secrets in logs, debug log levels in prod, backtraces enabled, permissive CORS, missing security headers, exposed internal ports, hardcoded secrets in non-secret env vars.

Ask before running any command that reads secrets.

## Phase 2 — Scan (OWASP Top 10)

For each, grep the patterns and reason about the result.

- **A03 Injection** — SQL string interpolation; raw queries; `Command::new` / `exec` / `spawn` with user input; raw HTML sinks (`innerHTML` writes, React's raw-HTML escape hatch); rich-text rendered without a sanitizer (DOMPurify or equivalent).
- **A01 Access Control** — every UUID path-param handler: filters by both id AND auth context? Vertical: every write/delete has explicit role check. Horizontal: cross-tenant access. Frontend-only role checks without backend enforcement.
- **A07 Auth Failures** — webhook signature verification (raw body, secret from env, verify before processing). API keys hashed at rest, constant-time compare, rotation, revocation. Rate limiting on auth, webhooks, uploads. JWT validation: signature, exp, revocation.
- **A05 Misconfiguration** — required headers: HSTS, CSP (no `unsafe-inline` for scripts), X-Frame-Options, X-Content-Type-Options, Referrer-Policy, Permissions-Policy. CORS: specific origin, never `*` with credentials. Debug flags off in prod.
- **A06 Vulnerable Deps** — `cargo audit` / `npm audit --omit=dev` / `pip-audit` / etc. For each: production or dev? Exploitable in this context? Patched version available?
- **A02 Crypto Failures** — secrets at rest hashed (bcrypt/Argon2). TLS end-to-end. No hardcoded secrets in source or git history. Backtraces disabled in prod.
- **A10 SSRF** — every URL-accepting endpoint: domain allowlist; block `localhost`/`127.0.0.1`/`0.0.0.0`/`::1` and internal ranges; restrict scheme to `https://`.

## Phase 3 — Prove it

Every finding gets a PoC. "Might be vulnerable" is not a finding.

- **API** — exact `curl` with expected vulnerable vs. safe response.
- **Frontend** — numbered browser steps + the payload.
- **Infra** — the command that demonstrates the gap and the missing/wrong output.

State exploitability: authenticated or not, internet-reachable or local, theoretical or demonstrated.

**Never test against production.** Local or staging only. If neither exists, describe the PoC and ask before testing prod.

## Phase 4 — Classify

| Severity | Examples | Labels |
|---|---|---|
| Critical | Unauth RCE, auth bypass, direct DB access, secrets in logs | `bug,security,phase:1` |
| High | Authenticated privesc, IDOR across tenants, missing webhook signature, SSRF to internal | `bug,security,phase:1` |
| Medium | Missing security headers, permissive CORS, no auth rate limit, exploitable CVE | `enhancement,security,phase:2` |
| Low | Verbose errors, missing non-critical rate limit, theoretical CVE, backtraces on | `enhancement,security,phase:2` |
| Info | Hardening, outdated-but-clean deps | `enhancement,security,phase:3` |

## Phase 5 — File via `gh`

For Medium and above, file an issue. Multiple findings → **parent epic + one sub per finding**. Adapt labels (`gh label list` first).

**Parent:**

```bash
PARENT=$(gh issue create \
  --title "Security audit: <date or scope>" \
  --label "security,epic" \
  --body "$(cat <<'EOF'
## Audit Summary
- Scope: <full | --api | …>
- Findings: <N total — N Critical, N High, N Medium, N Low>

## Sub-issues
- [ ] #TBD — <Critical: title>
- [ ] #TBD — <High: title>

## Test Strategy (overall)
| Category | Scenario | Expected |
|---|---|---|
| Regression | Re-run every PoC after fixes | All blocked |
| Hardening | Headers / CORS / rate-limits applied | Per checklist |
EOF
)" --json number --jq .number)
```

**Each sub:**

```bash
gh issue create \
  --title "fix(security): <one-line vuln>" \
  --label "bug,security,phase:1" \
  --body "$(cat <<EOF
Parent: #${PARENT}

## Security Finding
- Severity, OWASP category, affected file/route

## Proof of Concept
<curl or steps>

## Impact
<who/what is at risk>

## Recommended Fix
<specific, file:line>

## Test Strategy
| Category | Scenario | Expected |
|---|---|---|
| Tracer bullet | A failing test that demonstrates the vuln today | 200 / leak |
| Regression | Re-run after fix | 403/400, no leak |
| Authorization | Valid request with correct role | Normal 200 |
| Boundary | Adjacent vector (case variation, encoding) | Blocked |

Fix per Pocock-style TDD: regression test first (failing demo of the vuln), fix flips it green.
EOF
)"
```

After all subs filed, rewrite parent body replacing `#TBD` with real numbers.

**Never put actual secret values in issue bodies** — describe the leak without the value.

## Phase 6 — Hardening recommendations

Present a checklist of deployment-level fixes (log level, backtraces, headers, CORS, rate limiting, secret rotation). For each that requires a CLI/dashboard change, show the exact command and **ask before running**. Read-only inspection runs without confirmation.

## Phase 7 — Report

```
## Findings
| # | Severity | OWASP | Title | Issue |

## Hardening status
| Setting | Status |

## Clean areas
<credit where due>

## Top 3 priorities
1. <highest impact> — <one sentence>
```

If a layer is clean, say so. Don't pad.

## Rules

1. Never exploit production.
2. Never change code — auditor only.
3. Never store actual secrets in issue bodies.
4. Ask before any command that modifies shared state. Read-only is fine.
5. Reproduce the attack exactly; write the fix clearly enough for someone who wasn't in the audit.
