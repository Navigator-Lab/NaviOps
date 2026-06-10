---
name: ADR-P07-Quality-Mastery
status: Accepted
date: 2026-02-18
version: 18.0
description: Code Quality Mastery. Security sentinel, type safety enforcer, and dead code eliminator.
supersedes: ADR-P07 v17
---

# ADR-P07: Quality Mastery

<contract>
  <purpose>Enforce minimum, surgical, well-reasoned code — Karpathy discipline: state assumptions, cut speculative complexity.</purpose>
  <trigger>"simplify", "clean up", "overengineered", "review", "is this the simplest way"</trigger>
  <reads>ADR-P00 · the karpathy skill (.claude/commands/karpathy.md)</reads>
  <output>Quality findings + simplification recommendations (feed EXP backlog or applied directly)</output>
</contract>

## Context

Maintains a pristine, secure, and synchronized codebase. Called by P03 (VERIFY) as part of the Definition of Done checklist, and by P04 (Code Audit) for M2 and M5 milestones. Also callable standalone when code quality review is needed.

---

## Protocol Rules (Immutable)

### Step 0: Anchor (When Called Standalone)

```bash
view_file .agent/protocols/ADR-P00-Master-Rule.md
view_file CLAUDE.md
```

---

## Quality Gate 1: Security Sentinel

### 1A: Secrets Audit

```bash
# Scan for hardcoded secrets (source roots per project_law):
grep -rniE "secret_key\s*=\s*['\"]|password\s*=\s*['\"]" <source-root>
grep -rn "api_key\s*=\s*['\"]" . --include="*.ts" --include="*.js" --include="*.py"
grep -rn "Bearer [a-zA-Z0-9]" . --include="*.ts" --include="*.py"

# Check .env is not committed
git ls-files | grep "\.env$"
cat .gitignore | grep "\.env"
```

**Pass Criteria**: Zero hardcoded secrets. `.env` in `.gitignore`.

**If failed**: This is a CRITICAL finding. Rotate the secret immediately. Document in CLAUDE.md.

📚 **Reference**: OWASP A02:2021 Cryptographic Failures — https://owasp.org/Top10/A02_2021-Cryptographic_Failures/

### 1B: PII Protection (the project's data-protection regime)

```bash
# Find all PII field definitions (source roots per project_law)
grep -rniE "email|phone|ssn|national_id|address|personal" <source-root> -l

# Verify encryption on the data-model fields
grep -rniE "encrypt|EncryptedField|cipher" <data-model files>

# Check logging — PII must not appear in logs (source roots per project_law)
grep -rniE "log(ger)?\.(debug|info|warn|error)" <source-root> | grep -iE "email|national_id|password"
```

**Pass Criteria**: All PII fields use encryption at rest. No PII in log statements.

| PII Field | Encrypted? | Method                     | Status |
| --------- | ---------- | -------------------------- | ------ |
| email       | [Yes/No]   | [encrypted-field/hash/none] | ✅/❌  |
| national_id | [Yes/No]   | [Method]                    | ✅/❌  |
| phone       | [Yes/No]   | [Method]                    | ✅/❌  |

📚 **Reference**: the data-protection regime that applies to your project (GDPR, CCPA, HIPAA, or local law).

### 1C: Authentication & Authorization Check

```bash
# List route handlers, then flag any without an auth guard
# (guard = decorator / middleware / policy — pattern per project_law's framework):
grep -rnE "<handler-pattern>" <source-root> | grep -v "<auth-guard-pattern>"

# Check the auth / session / JWT configuration (config location per project_law):
grep -nE "JWT|SESSION|AUTH" <config-or-env>
```

**Pass Criteria**: Every endpoint either has explicit auth or is explicitly marked as public.

---

## Quality Gate 2: Type Safety (OpenAPI Contract)

### 2A: Schema Sync Check

> Applies only if the project generates a typed client from a server contract (OpenAPI/GraphQL/etc.).
> Skip with a one-line note if it doesn't.

```bash
# Regenerate the typed client from the live schema (the project's codegen command),
# write to a temp path, and diff against the committed client — expect zero diff.
<codegen command>  ->  /tmp/api_check
diff <committed client types> /tmp/api_check
```

**Pass Criteria**: Zero diff. The generated client is in sync with the server contract.
**If drift detected**: regenerate into place, then commit the synced client.

### 2B: Type / Compile Strict Check

```bash
# Full strict type/compile check using the project's own command
<strict type/compile check>   # e.g. tsc --noEmit --strict · mypy --strict · cargo check
```

**Pass Criteria**: Zero type/compile errors under strict mode.

---

## Quality Gate 3: Dead Code Patrol (Hygiene)

### 3A: Dead Code (unused exports / imports)

```bash
# Use the project's dead-code / unused-export tooling, e.g.:
#   ts-prune · knip · eslint no-unused-vars (JS/TS) · vulture · autoflake (Python) · cargo +nightly udeps
<dead-code scan>
```

**Pass Criteria**: No unused exported symbols in production code.

### 3B: Legacy-Pattern Patrol

```bash
# Find legacy/dead-code markers across the source roots (per project_law)
grep -rnE "_old|_legacy|_deprecated|TODO|FIXME|HACK" <source-roots>
```

**Pass Criteria**: No `_old` / `_legacy` functions. No critical TODO/FIXME in production paths.

### 3C: Refactoring Check

```bash
# Find over-long functions (refactor candidates) — use the project's complexity/lint tool,
# e.g.: radon cc · gocyclo · eslint complexity · clippy. Adjust the function keyword per language
# (def / func / function / fn) if scanning by hand.
<complexity / long-function scan>
```

📚 **Reference**: Clean Code principles — https://www.oreilly.com/library/view/clean-code-a/9780136083238/

---

## Quality Gate 4: API Consistency Check

```bash
# Check HTTP status codes are used consistently across responses (response helper per project_law):
grep -rnE "<response-helper>" <source-root> | grep -iE "status" | sort | uniq -c

# Verify the error response shape is consistent (error/message/detail fields):
grep -rniE "detail|message|error" <api-handlers-or-schema> | head -20
```

**Pass Criteria**: A consistent error envelope across all endpoints (e.g. `{"error": "..."}` or `{"detail": "..."}`).

---

## Definition of Done (Quality Gate Summary)

```markdown
### ✅ Quality Mastery — Definition of Done

**Security**

- [ ] Zero hardcoded secrets (Gate 1A)
- [ ] All PII fields encrypted (Gate 1B — data-protection regime)
- [ ] All endpoints have auth decorators (Gate 1C)
- [ ] No PII in log statements

**Type Safety**

- [ ] OpenAPI types in sync with backend schema (Gate 2A)
- [ ] TypeScript strict mode passes (Gate 2B)

**Code Hygiene**

- [ ] No unused exports (Gate 3A — dead-code scan)
- [ ] No legacy/dead-code markers left (Gate 3B)
- [ ] No \_old/\_legacy functions anywhere
- [ ] No critical TODO/FIXME in production paths

**API Consistency**

- [ ] Consistent error response format (Gate 4)
- [ ] HTTP status codes consistent

**Overall Quality Score**: [Green ✅ / Yellow ⚠️ / Red ❌]
```

---

## How P07 Supports Other Protocols

| Protocol             | P07 Support Role                                        |
| -------------------- | ------------------------------------------------------- |
| **P03 (VERIFY)**     | Gates 1-4 feed into VERIFY Definition of Done checklist |
| **P04 (Code Audit)** | Gate 1 (Security) feeds M2; Gate 3 (Dead Code) feeds M5 |
| **P01 (SP)**         | Quality findings → Constraints in Step 4D               |
| **P02 (EXP)**        | Security findings → Risk Lens (⚠️) content              |

---

## Changelog

- **v18.0**: Gate 4 (API Consistency) added. Data-protection PII table added. How-Protocols-Support section added. Dead-code cleanup integration added.
- **v17.0**: Initial ADR format. Security sentinel + type safety + dead code.