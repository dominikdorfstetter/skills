---
name: security-audit
description: White-hat audit of a codebase against the OWASP Top 10. Maps the attack surface, proves vulnerabilities with PoCs, classifies severity, and files actionable issues. Use when user asks for a security review, hardening pass, vuln scan, or "audit this".
---

# Security Audit

Think like an attacker, document like an engineer. Audits a codebase, proves what's broken, files issues — never exploits production, never edits code.

## Scope flags

| Flag | Scope |
|---|---|
| (none) | Full audit |
| `--api` | Backend handlers and middleware only |
| `--frontend` | UI — XSS, CSP, client-side auth |
| `--infra` | Deployment env, headers, config |
| `--deps` | Dependency CVEs only |
| `--endpoint <path>` | Deep dive on one endpoint |

Skip phases that don't apply for scoped runs. Note the scope in the summary.

## Phase 1 — Recon

Build an attack-surface map before scanning.

- **Routes** — list every HTTP handler with method, path, auth requirement, user-input fields.
- **Public endpoints** — anything outside an auth group, or with optional/no auth extractor.
- **File uploads** — check MIME validation, size limits, path traversal, storage location.
- **Trust boundaries** — for each endpoint: where does user input land? DB (SQLi), DOM (XSS), external request (SSRF), webhook (signature)?
- **Auth model** — middleware chain, role extraction, bypasses.
- **Tenancy filter** — every query touching tenant data must filter by tenant id; missing filter = IDOR candidate.

For deployments, inspect env and recent logs for: secrets in logs, debug log levels in prod, backtraces enabled, permissive CORS, missing security headers, exposed internal ports, hardcoded secrets in non-secret env vars.

Ask before running any command that reads secrets.

## Phase 2 — Vulnerability scan (OWASP Top 10)

Walk these in order. For each, grep the patterns and reason about the result.

**A03 Injection** — SQL string interpolation; raw queries; `Command::new` / `exec` / `spawn` with user input; unsanitized HTML sinks (raw `innerHTML` writes, React's raw-HTML escape hatch); rich-text output rendered without a sanitizer like DOMPurify.

**A01 Broken Access Control** — every UUID path-param handler: does the query filter by both id AND auth context? Vertical privilege: every write/delete endpoint has an explicit role check. Horizontal: cross-tenant access. Frontend-only role checks without backend enforcement.

**A07 Auth Failures** — webhook signature verification (raw body, secret from env, verify before processing). API keys: hashed at rest, constant-time compare, rotation, revocation. Rate limiting on auth, webhooks, uploads. JWT validation: signature, exp, revocation.

**A05 Misconfiguration** — required response headers: HSTS, CSP (no `unsafe-inline` for scripts), X-Frame-Options, X-Content-Type-Options, Referrer-Policy, Permissions-Policy. CORS: specific origin, never `*` with credentials. Debug flags off in prod.

**A06 Vulnerable Deps** — run `cargo audit`, `npm audit --omit=dev`, `pip-audit`, etc. For each finding: production or dev? Exploitable in this context? Patched version available?

**A02 Crypto Failures** — secrets at rest hashed (bcrypt/Argon2). TLS enforced end-to-end. No hardcoded secrets in source or git history. Backtraces disabled in prod.

**A10 SSRF** — every URL-accepting endpoint: allowlist of domains, block `localhost`/`127.0.0.1`/`0.0.0.0`/`::1` and internal-network ranges, restrict scheme to `https://`.

## Phase 3 — Prove it

Every finding gets a PoC. "Might be vulnerable" is not a finding.

- **API** — exact `curl` with expected vulnerable vs. safe response.
- **Frontend** — numbered browser steps and the payload.
- **Infra** — the command that demonstrates the gap and the missing/wrong output.

State exploitability: authenticated or not, internet-reachable or local, theoretical or demonstrated.

**Never test against production.** Local or staging only. If neither exists, describe the PoC and ask before testing prod.

## Phase 4 — Classify

| Severity | Examples | Labels |
|---|---|---|
| Critical | Unauth RCE, auth bypass, direct DB access, secrets in logs | `bug`, `security`, `phase:1` |
| High | Authenticated privesc, IDOR across tenants, missing webhook signature, SSRF to internal | `bug`, `security`, `phase:1` |
| Medium | Missing security headers, permissive CORS, no auth rate limit, exploitable CVE | `enhancement`, `security`, `phase:2` |
| Low | Verbose errors, missing rate limit on non-critical, theoretical CVE, backtraces on | `enhancement`, `security`, `phase:2` |
| Info | Hardening, outdated-but-clean deps | `enhancement`, `security`, `phase:3` |

## Phase 5 — File parent + sub-issues with `gh`

For Medium and above, file an issue. If the audit produced multiple findings, file a **parent epic** for the audit and one **sub-issue per finding** so each fix can be tracked, reviewed, and tested independently.

Adapt labels to the project's conventions (`gh label list` first).

**Parent (audit summary)**

```bash
gh issue create \
  --title "Security audit: <date or scope>" \
  --label "security,epic" \
  --body "$(cat <<'EOF'
## Audit Summary
- Scope: <full | --api | --frontend | …>
- Findings: <N total — N Critical, N High, N Medium, N Low>

## Sub-issues
- [ ] #TBD — <Critical: title>
- [ ] #TBD — <High: title>
- [ ] #TBD — <Medium: title>

## Test Strategy (overall)
| Category | Scenario | Expected |
|---|---|---|
| Regression | Re-run every PoC after fixes | All blocked |
| Hardening | Headers/CORS/rate-limits applied | Per checklist |
EOF
)"
```

**Sub-issue per finding**

```bash
gh issue create \
  --title "fix(security): <one-line vuln>" \
  --label "bug,security,phase:1" \
  --body "$(cat <<EOF
Parent: #<parent>

## Security Finding
- Severity, OWASP category, affected file/route

## Proof of Concept
<reproduction or curl>

## Impact
<who/what is at risk>

## Recommended Fix
<specific, actionable; reference the file:line>

## Test Strategy
| Category | Scenario | Expected |
|---|---|---|
| Tracer bullet | A failing test that demonstrates the vulnerability today | 200 / leak |
| Regression | Re-run the same test after fix | 403/400, no leak |
| Authorization | Valid request with correct role | Normal 200 |
| Boundary | Adjacent attack vector (e.g. case variation, encoding) | Blocked |

The fix must be implemented Pocock-style TDD: the regression test is written first as a failing test that demonstrates the vulnerability, then the fix flips it green.
EOF
)"
```

After subs are filed, edit the parent body to replace `#TBD` placeholders.

**Never put actual secret values in issue bodies.** If a finding involves a leaked secret, describe the finding without including the value.

## Phase 6 — Hardening recommendations

After scanning, present a checklist of deployment-level fixes (log level, backtraces, headers, CORS, rate limiting, secret rotation). For each fix that requires a CLI/dashboard change, show the exact command and **ask before running**. Read-only inspection commands can run without confirmation.

## Phase 7 — Report

```
## Findings
| # | Severity | OWASP | Title | Issue |
|---|---|---|---|---|

## Hardening status
| Setting | Status |

## Clean areas
<what was checked and is fine — credit where due>

## Top 3 priorities
1. <highest-impact finding> — <one sentence why>
2. ...
```

If a layer is clean, say so. Don't pad.

## Rules

1. Never exploit production.
2. Never change code — auditor only.
3. Never store actual secrets in issue bodies.
4. Always ask before commands that modify shared state. Read-only is fine.
5. Reproduce the attack exactly; write the fix clearly enough for someone who wasn't in the audit.
