---
name: ADR-P03-Verification
status: Accepted
date: 2026-02-18
version: 18.0
description: Phase III Closure, Automated Verification, and Post-Mortem Discovery Protocol.
supersedes: ADR-P03 v17
---

# ADR-P03: Verification Protocol (VERIFY)

<contract>
  <purpose>Prove a change actually does what it should, by running it and observing behavior.</purpose>
  <trigger>"verify", "validate", "check", "run the tests", "does it work", "confirm the fix"</trigger>
  <reads>ADR-P00 · ADR-P02 · the detected project_law (test_cmd / run_cmd)</reads>
  <output>A VERIFY section in the EXP report (docs/reports/EXP/) with exact commands + observed results</output>
</contract>

## Context

The final quality gate. Triggered after any implementation, deployment, or SP plan execution. Ensures correctness, security, and system sync before declaring "Done". Also extracts post-mortem learning for the team.

### Two tiers (why you "rarely run verify" — Tier-0 already runs for you)
VERIFY is not one heavy ritual you must remember; it's two tiers:
- **Tier-0 — lightweight, AUTOMATIC after every BUILD.** The project's quick gate (`tsc --noEmit` / `npm run
  build` / `scan:imports`, or the detected `test_cmd`). Navi runs this itself; no user action needed. Most small
  UI/doc changes are fully covered here.
- **Tier-1 — full P03 (the gates below), AUTO-SUGGESTED, human-approved.** Reach for it when **behavior changed**
  (not just markup), when backend / PHI / auth is touched, or **before any deploy**. Navi proposes it and surfaces
  the command; the human approves (P00 Axiom 6). This is the one to invoke explicitly with "verify" / "does it work".

**Best practice:** let Tier-0 ride automatically; consciously run Tier-1 before shipping or after a behavioral fix.

**v20 Note — EXP Nucleus Integration**:

`VERIFY()` is now a shortcut for `EXP(Verify: topic)`. The EXP Nucleus (Steps 0-4 of ADR-P02)
executes automatically before running gates. The Nucleus provides contextual grounding:
Pre-Reflexion explains what was built, 6-Lens reminds you why each gate matters, External
References link to the testing/security standards being verified.

**Triggered by**: Navi.md Intent Routing — signals: "Test", "Verify", "Check", "Validate", "Deploy check", "Run tests"

---

## Protocol Rules (Immutable)

### Step 0: Constitutional Anchor (MANDATORY)

```bash
view_file .agent/protocols/ADR-P00-Master-Rule.md
view_file CLAUDE.md
```

Output: "🔒 VERIFY Protocol v18 Loaded."

---

## FULL EXECUTION LOGIC

### Step 1: Hypothesis Validation

Before running any tests, check: Did the implementation address the root cause identified in SP?

```markdown
## Hypothesis Validation

- **SP Root Cause**: [What P01 identified as the root cause]
- **Fix Applied**: [What was actually implemented]
- **Match?**: [Yes — root cause addressed / No — fix is symptomatic only]
- **If No**: Flag for P10 Debugger — the fix is incomplete
```

---

### Step 2: System Validation Checklist (The Hard Gate)

Execute in order. Each is a hard gate — failure stops progression.

#### Gate 1: Synthetic E2E Tests

```bash
# Run the project's test suites via the commands declared in project_law / its manifest.
# Cover, where they exist:
#   E2E          — <e2e command>          (e.g. Playwright, Cypress, Selenium)
#   Unit         — <unit-test command>    (e.g. the stack's test runner)
#   Integration  — <integration command>
```

**Pass Criteria**: Zero failures. If failures exist → load `ADR-P10-Debugger.md` immediately.

#### Gate 2: Type-Safety Sync (only if the project generates a typed API client)

```bash
# Regenerate the typed client from the live server schema (the project's codegen command)
<codegen command>

# Check for drift
git diff <generated client types>
```

**Pass Criteria**: Zero diff (types are in sync). If drift exists → SP issue, flag for P07 Quality Mastery.

#### Gate 3: Security Verification

```bash
# Check for hardcoded secrets
grep -r "SECRET_KEY\|password\|api_key\|token" --include="*.py" --include="*.ts" \
  --include="*.env" . | grep -v ".env.example" | grep -v "test"

# HMAC Webhook Signature Check (if applicable)
# Verify signature-header validation is active on all webhook endpoints (source roots per project_law)
grep -rniE "x-signature|hmac|verify_signature" <source-root>
```

**Pass Criteria**: No hardcoded secrets. HMAC verification active on all webhook routes.

#### Gate 4: Cross-Service Sync

```bash
# Backend service status
sudo systemctl status <service> <web-service>

# Check recent logs for errors
journalctl -u <service> --since "1 hour ago" | grep -i "error\|exception\|critical"

# Verify migrations are applied (your migration tool's "show pending" command)
<show-migrations command> | grep -i "pending\|unapplied"
```

**Pass Criteria**: Services active. No critical errors in logs. No unapplied migrations.

#### Gate 5: Data-Protection Compliance Spot-Check

> Applies only if the project handles personal data. Use the regime named in `project_law`
> (GDPR / CCPA / HIPAA / local). Skip with a one-line note if no PII is involved.

```bash
# Verify PII fields are encrypted (spot-check the user/entity model)
grep -rniE "encrypt|cipher|hash" <data-model files>
grep -rniE "email|phone|ssn|national_id|address|personal" <source-root> | grep -v test
```

**Pass Criteria**: All PII fields have encryption/hashing applied. No raw PII in logs.

#### Gate 6: Dead Code & Hygiene

```bash
# Dead code / unused imports — the project's tooling (ts-prune, knip, vulture, autoflake, …)
<dead-code scan>
```

**Pass Criteria**: No critical dead code. No `_old` / `_legacy` functions present.

---

### Step 3: The Discovery Bridge (Post-Execution Learning)

Every verification MUST end with a Discovery Keywords section — this feeds `ADR-P14-Adaptive-Improvement.md`.

````markdown
## 🔍 Discovery Bridge

### Hidden Bugs Found

[List any bugs uncovered during verification that weren't part of the original task]

- Bug: [Description]
- Root Cause: [Why/How]
- Fixed: [Yes/No — if No, create SP task]

### Terminal Mastery

[Exact commands used that are non-obvious or worth remembering]

```bash
[command that saved time or solved something non-obvious]
```
````

### Architectural Quirks

[System "gotchas" discovered — things that would surprise a new developer]

- Quirk: [What was found]
- Impact: [Why it matters]
- Documented: [CLAUDE.md updated? Yes/No]

### Pattern Updates

[Should any ADR protocol be updated based on what was learned?]

- Update needed in: [P-XX file]
- Reason: [What failed / what new pattern emerged]
- Action: Load ADR-P14 for protocol improvement

````

---

### Step 4: CLAUDE.md & docs/ Update Gate

After every verification:

1. **Update CLAUDE.md**: Log what was built, changed, or fixed.
2. **Update docs/**: If architectural decision was made, log it.
3. **Update MEMORY.md**: If personal/session patterns emerged.

```markdown
## CLAUDE.md Update Required?
- [ ] New feature built → document in CLAUDE.md
- [ ] Bug fixed → note root cause + fix approach
- [ ] Architecture decision made → add to docs/
- [ ] New dependency added → update requirements.txt / package.json docs
- [ ] PLAN executed → confirm docs/reports/PLAN/ report is saved
````

---

## Definition of Done (Hard Gate Checklist)

```markdown
### ✅ Definition of Done

**Tests** (use the project's own runners from `project_law`)

- [ ] E2E suite passed (0 failures)
- [ ] Unit tests passed (0 failures)
- [ ] Integration tests passed

**Type Safety** (if a typed stack)

- [ ] Generated API types regenerated and synced (0 diff)
- [ ] Zero type/compile errors

**Security**

- [ ] Zero hardcoded secrets
- [ ] Webhook signatures verified (if applicable)
- [ ] Data-protection PII encryption confirmed (if PII involved)

**System Health**

- [ ] All services active (systemctl)
- [ ] Zero critical errors in logs (last 1 hour)
- [ ] All migrations applied

**Hygiene**

- [ ] Dead Code Patrol passed (dead-code scan)
- [ ] No \_old/\_legacy functions
- [ ] No unused imports

**Learning**

- [ ] Discovery Keywords extracted
- [ ] CLAUDE.md updated
- [ ] docs/ updated if architecture changed
- [ ] ADR-P14 flagged if protocol improvement needed

**Report**

- [ ] VERIFY report saved to docs/reports/VERIFY/VERIFY\_[DATE].md
- [ ] notify_user triggered in IDE
```

---

## Output Format

**Save to**: `docs/reports/VERIFY/VERIFY_[YYYY-MM-DD]_[TOPIC].md`

**IDE Notification**:

```bash
notify_user "✅ Verification Complete: [TOPIC] — [PASS/FAIL] — docs/reports/VERIFY/VERIFY_[DATE]_[TOPIC].md"
```

---

## How Other Protocols Support VERIFY

| Protocol                     | VERIFY Support Role                       |
| ---------------------------- | ----------------------------------------- |
| **P04 Code Audit**           | Security and compliance spot-checks       |
| **P07 Quality Mastery**      | Dead code patrol + type safety gates      |
| **P10 Debugger**             | Activated immediately on any gate failure |
| **P14 Adaptive Improvement** | Receives Discovery Bridge findings        |

---

## Changelog

- **v18.0**: Gate 5 (Data-Protection) and Gate 6 (Dead Code) added. CLAUDE.md update gate added. Discovery Bridge formalized. notify_user added.
- **v17.0**: Initial ADR format. E2E + OpenAPI gates.