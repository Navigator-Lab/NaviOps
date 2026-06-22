---
name: ADR-P04-Code-Audit
status: Accepted
date: 2026-02-18
version: 18.0
description: Zero-Hallucination Analysis Protocol. Provides verified codebase facts before any planning or explanation.
supersedes: ADR-P04 v17
---

# ADR-P04: Code Audit Protocol

<contract>
  <purpose>Audit code for correctness, security, reuse, and simplicity; produce evidence-backed findings.</purpose>
  <trigger>"audit", "review the code", "is this good", "security check", "code smell"</trigger>
  <reads>ADR-P00 · ADR-P02 · ADR-P07 (quality) · the detected project_law</reads>
  <output>Findings feed the EXP scorecard + backlog (docs/reports/EXP/)</output>
</contract>

## Context

Ensures 100% verified facts before SP or EXP makes decisions or critiques. Eliminates hallucinated assumptions about what exists in the codebase. Every audit produces Code Status Blocks (ADR-P00 Standard 3) consumed by P01 and P02.

**Called by**: P01 (Step 2), P02 (Step 2), P03 (Gate security checks), P07

---

## Protocol Rules (Immutable)

### Workflow Rules

1. **Skeleton First**: Always `list_dir` before assuming structure
2. **Context Partitioning**: Audit one component at a time — never batch-read unrelated files
3. **Verify-Before-Judge**: Read file content BEFORE critiquing it
4. **State Compression**: Summarize findings every 5 files into a status block
5. **No Memory Reliance**: Never use remembered file content — always re-read live file

---

## The Audit Checklist (M1–M6 Milestones)

Each milestone produces a **Code Status Block** (ADR-P00 Standard 3).

---

### M0: BLAST-AUDIT — fix-all, never one-at-a-time (MANDATORY after any fix)

> **The fix-once rule.** Whenever a defect is found and fixed, it is **not done** until the codebase has been swept
> for **every sibling of the same class**. This stops the user having to re-report the same problem on the next
> page/file. (Pairs with P05 Dependency-Map for blast radius.)

**Workflow:**
1. **Signature** — distill the defect into a structural pattern, not a one-off. e.g. `dir="rtl"` on a page shell ·
   `text-foreground` on a `bg-<brand>` button · `setLoading` inside an async action.
2. **Enumerate** — sweep the whole repo for siblings. Prefer **structural** search; fall back to text:
   ```bash
   # Structural (AST, multi-language, dynamic to any project) — no install needed:
   npx --yes @ast-grep/cli run --pattern '<pattern>' --lang ts
   npx --yes @ast-grep/cli run --pattern '<pattern>' --rewrite '<fix>' --lang ts   # preview the fix-all
   # Fallback for trivial textual patterns:
   #   Grep tool / grep -rn '<regex>' <paths>
   ```
3. **Classify** — split hits into **real-bug** vs **benign** (intentional/edge). Quote `path:line` for each.
4. **Decide** — fix-all now, or schedule the remainder with **exact counts** (e.g. "14 shell-dir bugs: 5 fixed,
   9 scheduled Phase 4"). Surface the decision to the human (Axiom 6); never silently leave siblings unfixed.

Output a **BLAST-AUDIT block**: signature · total hits · real-bug N · benign N · fixed N · scheduled N.
This is also exposed as the `/find-similar` skill so the user can trigger it directly.

---

### M1: Structure & Dependencies

```bash
list_dir .                          # Project root structure
# Read the source roots + dependency manifest named in project_law for the detected stack:
#   Node → package.json · Python → pyproject.toml / requirements.txt · Go → go.mod
#   Rust → Cargo.toml · Java → pom.xml / build.gradle · (use whatever the project actually uses)
view_file <dependency-manifest>     # pinned versions? dev/prod split? lock file present?
```

**Check for**:

- Unpinned dependencies (security risk — a floating range vs a pinned version)
- Known vulnerable packages (flag for web search / `npm audit`, `pip-audit`, `cargo audit`, etc.)
- Dev dependencies leaking into production
- Missing lock files (`package-lock.json` / `poetry.lock` / `Cargo.lock` / `go.sum` — per stack)

**Output**:

```markdown
### 📊 M1: Structure & Dependencies

| Dimension             | Status   | Notes                    |
| --------------------- | -------- | ------------------------ |
| Dependencies Pinned   | ✅/⚠️/❌ | [unpinned packages list] |
| Lock Files Present    | ✅/⚠️/❌ | [which files found]      |
| Dev/Prod Separation   | ✅/⚠️/❌ | [any leakage?]           |
| Known Vulnerabilities | ✅/⚠️/❌ | [flag for web search]    |
```

📚 **Reference**: per-ecosystem vulnerability scanners — `npm audit`, [pip-audit](https://pypi.org/project/pip-audit/), `cargo audit`, `govulncheck`, OWASP Dependency-Check.

---

### M2: Security & Data Protection (OWASP + the project's data-protection regime)

> Substitute the project's actual config locations + the data-protection law it operates under
> (GDPR / CCPA / HIPAA / local regime) from `project_law`. Patterns below are stack-neutral.

```bash
# Check auth/secret configuration (config file location per project_law)
grep -rniE "auth|secret|allowed_hosts|cors" <config-path>

# Check PII handling — search source for personal-data fields
grep -rniE "email|phone|ssn|national_id|address|personal" <source-root> -l

# Check for hardcoded secrets
grep -rniE "secret_key|api_key|password\s*=\s*['\"]|token\s*=\s*['\"]" <source-root>
```

**Check for**:

- Hardcoded secrets (OWASP A02: Cryptographic Failures)
- PII fields without encryption (data-protection-law violation)
- CORS misconfiguration (OWASP A01: Broken Access Control)
- Missing HTTPS enforcement
- Session configuration weaknesses
- Token/JWT expiry settings

**Output**:

```markdown
### 📊 M2: Security & Data Protection

| Dimension                   | Status   | Notes                        |
| --------------------------- | -------- | ---------------------------- |
| Secrets Management          | ✅/⚠️/❌ | No hardcoded / .env only     |
| PII Encryption (data law)   | ✅/⚠️/❌ | Which fields? How encrypted? |
| CORS Configuration          | ✅/⚠️/❌ | Allowed origins list         |
| Auth/Session Config         | ✅/⚠️/❌ | Token expiry, refresh logic  |
| HTTPS Enforced              | ✅/⚠️/❌ | HSTS header? Redirect?       |
```

📚 **Reference**: OWASP Application Security Verification Standard — https://owasp.org/www-project-application-security-verification-standard/

---

### M3: Database & Business Logic

# Locate the data layer (models/schema/entities) + migration state using project_law's commands.
# Examples by stack: ORM models (Rails/SQLAlchemy/TypeORM), schema files (Prisma/Drizzle),
# raw SQL/migrations dir. Run the project's "show migrations / pending" command if it has one.

**Check for**:

- Missing indexes on frequently queried fields
- Unconstrained foreign keys (no cascade/`on_delete` rule)
- PII fields without encryption at the data-model level
- N+1 query patterns (missing eager-load / join — `select_related`, `include`, `JOIN`)
- Business logic living in controllers/views instead of services
- Unapplied / pending migrations (system health risk)

**Output**:

```markdown
### 📊 M3: Database & Business Logic

| Dimension          | Status   | Notes                       |
| ------------------ | -------- | --------------------------- |
| Model Indexes      | ✅/⚠️/❌ | Missing indexes on [fields] |
| FK Constraints     | ✅/⚠️/❌ | on_delete defined?          |
| PII at Model Level | ✅/⚠️/❌ | Encrypted fields?           |
| N+1 Risk           | ✅/⚠️/❌ | select_related used?        |
| Migration State    | ✅/⚠️/❌ | All applied?                |
```

📚 **Reference**: query-optimization (N+1, eager loading, indexing) — your ORM/query-layer's performance guide.

---

### M4: API & Integration (OpenAPI Contract)

```bash
# Locate the API surface (routes/controllers/handlers) + the schema contract per project_law.
# Read route definitions, request/response validators, and any generated client types.
# If the project has a typed client (OpenAPI/GraphQL codegen), diff it against the server contract.
```

**Check for**:

- Missing request/response validation
- Exposed internal fields (password hashes, internal IDs)
- Missing pagination on list endpoints
- OpenAPI schema drift (frontend types don't match backend)
- HMAC signature validation on webhook endpoints
- Missing rate limiting on auth endpoints
- Inconsistent HTTP status codes

**Output**:

```markdown
### 📊 M4: API & Integration

| Dimension               | Status   | Notes                       |
| ----------------------- | -------- | --------------------------- |
| Schema Drift            | ✅/⚠️/❌ | generated client in sync?   |
| Request/Response Valid. | ✅/⚠️/❌ | All fields validated?       |
| Exposed Internal Fields | ✅/⚠️/❌ | What's leaking?             |
| Pagination              | ✅/⚠️/❌ | List endpoints paginated?   |
| HMAC Webhooks           | ✅/⚠️/❌ | X-Signature validated?      |
| Rate Limiting           | ✅/⚠️/❌ | Auth endpoints protected?   |
```

📚 **Reference**: OpenAPI Specification — https://spec.openapis.org/oas/latest.html

---

### M5: UI/UX & Frontend Quality

```bash
# (Run only if the project has a UI.) Locate components/pages/views per project_law.
# Type check + dead-code scan using the project's own tooling, e.g.:
#   tsc --noEmit · ts-prune · eslint · the framework's build in strict mode
```

**Check for**:

- Type-safety holes (`any`/untyped escapes in typed languages)
- Missing loading/error states in async components
- Accessibility: missing `aria-*` labels on interactive elements
- Hardcoded API URLs (should be env vars)
- Debug/console statements left in production code
- Unused exports (dead code)

**Output**:

```markdown
### 📊 M5: UI/UX & Frontend Quality

| Dimension         | Status   | Notes                 |
| ----------------- | -------- | --------------------- |
| TypeScript Errors | ✅/⚠️/❌ | Count of errors       |
| `any` Usage       | ✅/⚠️/❌ | Files with any        |
| Error Boundaries  | ✅/⚠️/❌ | Async error handling? |
| Accessibility     | ✅/⚠️/❌ | aria labels present?  |
| Hardcoded URLs    | ✅/⚠️/❌ | Env vars used?        |
| Dead Code         | ✅/⚠️/❌ | dead-code scan result |
```

📚 **Reference**: WCAG 2.1 Accessibility Guidelines — https://www.w3.org/TR/WCAG21/

---

### M6: DevOps & Reliability

```bash
# Service health — use the project's process/orchestration manager (systemd, Docker, k8s, PaaS).
# Environment variables
view_file .env.example              # What's expected — compare against runtime config
                                    # (never print production secrets into a report)
# Reverse proxy / ingress config if applicable (nginx, Caddy, Traefik, cloud LB)
# Recent error logs — count errors over the last 24h from the project's log source
```

**Check for**:

- Missing environment variables (`.env.example` vs actual)
- Services not set to auto-restart (per the project's process manager)
- Missing backup strategy for the datastore
- Reverse-proxy / ingress misconfiguration (HTTPS redirect, security headers)
- No log rotation configured

**Output**:

```markdown
### 📊 M6: DevOps & Reliability

| Dimension              | Status   | Notes                 |
| ---------------------- | -------- | --------------------- |
| Service Auto-Restart   | ✅/⚠️/❌ | Restart=always?       |
| Env Vars Documented    | ✅/⚠️/❌ | .env.example current? |
| Proxy Security Headers | ✅/⚠️/❌ | HSTS, CSP present?    |
| Error Rate (24h)       | ✅/⚠️/❌ | Count from journalctl |
| Backup Strategy        | ✅/⚠️/❌ | DB backup configured? |
```

📚 **Reference**: 12-Factor App methodology — https://12factor.net/

---

## Audit Summary Block

After all 6 milestones, produce a summary:

```markdown
## 🔍 Audit Summary

| Milestone                    | Status   | Critical Issues |
| ---------------------------- | -------- | --------------- |
| M1: Structure & Dependencies | ✅/⚠️/❌ | [count]         |
| M2: Security & Sovereignty   | ✅/⚠️/❌ | [count]         |
| M3: Database & Logic         | ✅/⚠️/❌ | [count]         |
| M4: API & Integration        | ✅/⚠️/❌ | [count]         |
| M5: UI/UX & Frontend         | ✅/⚠️/❌ | [count]         |
| M6: DevOps & Reliability     | ✅/⚠️/❌ | [count]         |

**Total Critical Issues**: [N]
**Recommended Priority**: [List top 3 issues to fix first]
**Feed to SP?**: [Yes/No — if Yes, issues become SP task inputs]
```

---

## Changelog

- **v18.0**: M1–M6 each produce Code Status Blocks (ADR-P00 Std 3). Web refs added per milestone. Audit Summary Block added.
- **v17.0**: Initial ADR format. 6-milestone checklist.