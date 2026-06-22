---
name: ADR-P10-Debugger
status: Accepted
date: 2026-02-18
version: 18.0
description: Systematic diagnosis and recovery. The Hypothesis Engine. Activated on any error, crash, or VERIFY gate failure.
supersedes: ADR-P10 v17
---

# ADR-P10: Debugger Protocol (The Recovery Engine)

<contract>
  <purpose>Reproduce, isolate root cause, and fix a defect — evidence over guessing.</purpose>
  <trigger>"bug", "error", "crash", "failing test", "broken", "why doesn't X work"</trigger>
  <reads>ADR-P00 · ADR-P02 · ADR-P05 (blast radius) · the detected project_law</reads>
  <output>Debug EXP: reproduction → root cause → fix → verify (docs/reports/EXP/)</output>
</contract>

## Context

Solves bugs systematically without guessing. Uses a strict 5-step process anchored by the Hypothesis Engine — never proceed with a single theory, never guess without evidence.

**Triggered by**: Navi.md Intent Routing — signals: Error, Bug, Crash, Exception, "Not working", Build failure, VERIFY gate failure.

---

## Protocol Rules (MANDATORY)

### Step 0: Constitutional Anchor

```bash
view_file .agent/protocols/ADR-P00-Master-Rule.md
view_file CLAUDE.md
```

Output: "🔒 Debugger Protocol v18 Loaded."

---

## THE 5-STEP RECOVERY SYSTEM

### Step 1: Isolate & Reproduce

**Goal**: Create a 100% reproducible test case. Never debug a bug you can't reproduce.

```markdown
## Bug Isolation Report

**Error Type**: [Runtime / Build / Test / Logic / Network / Auth]
**Environment**: [Local / Staging / Production — per project_law]
**Trigger**:

- URL/Endpoint: [exact URL]
- HTTP Method: [GET/POST/etc]
- Payload: [exact request body — redact PII]
- Command: [exact command run]
- User Action: [what the user did]

**Reproduction Steps**:

1. [Step 1]
2. [Step 2]
3. [Step 3]
   → **Expected**: [What should happen]
   → **Actual**: [What actually happens]

**Reproducible**: [Yes / No / Intermittent]
**Frequency**: [Always / X% of time / Only under condition Y]
```

**If not reproducible**: Document the conditions and load `ADR-P14-Adaptive-Improvement.md` to improve monitoring.

---

### Step 2: Trace the Stack (Full Stack Read)

```bash
# Server side — read the full traceback from the project's log source
journalctl -u <service> --since "30 min ago" | grep -A30 "ERROR\|Exception"   # or docker logs / file logs

# Client side — read browser/console/error-boundary output
# (User provides console output or error message)

# Build / test failures — read full output via the project's own commands
<build command> 2>&1 | tail -50
<test command>  2>&1 | tail -50
```

**Stack Analysis**:

```markdown
## Stack Trace Analysis

**Full Error**:
```

[Paste full traceback here]

```

**First User Code Frame**:
[The first line in the stack that points to YOUR code, not a library]
- File: [path]
- Line: [number]
- Function: [name]
- Code: [the actual line]

**Library Boundary**:
[Where the error crosses from your code into a library — this is a clue]

**Error Classification**:
- [ ] Syntax Error (typo, missing bracket)
- [ ] Runtime Error (null reference, type mismatch)
- [ ] Logic Error (wrong behavior, no exception)
- [ ] Network Error (timeout, connection refused)
- [ ] Auth Error (401, 403, token invalid)
- [ ] Database Error (constraint, migration, connection)
- [ ] Environment Error (missing env var, wrong path)
```

---

### Step 3: Verify Assumptions (Read the Live Code)

**MANDATORY**: Before forming any hypothesis, read the actual live file content.

```bash
# ALWAYS use view_file — never rely on memory
view_file [path_to_first_user_code_frame_file]

# Verify the related configuration (config location per project_law)
view_file <config-or-env> | grep -A10 "[relevant_setting]"

# Verify environment variables are set — check presence WITHOUT printing values, e.g.:
#   sh:     [ -n "$DB_URL" ] && echo set || echo missing
#   python: python -c "import os; print('DB_URL' in os.environ)"
```

**Never say "I think the code looks like..."** — always read it.

---

### Step 4: The Hypothesis Engine (NO GUESSING)

Formulate exactly 2 distinct, testable hypotheses. Not 1. Not 3. Exactly 2.

````markdown
## Hypothesis Engine

### Hypothesis A: [Name — Most Likely]

**Theory**: [Clear statement of what you believe is wrong and why]
**Evidence**:

- [Fact from stack trace that supports this]
- [Fact from code reading that supports this]
  **Test**:

```bash
[Exact command or code change to test this hypothesis]
```
````

**Expected result if correct**: [What changes when this is fixed]
**Confidence**: [High / Medium / Low]

### Hypothesis B: [Name — Alternative]

**Theory**: [Different root cause — not a variant of A, genuinely different]
**Evidence**:

- [Why this is also plausible]
  **Test**:

```bash
[Exact command or code change to test this hypothesis]
```

**Expected result if correct**: [What changes when this is fixed]
**Confidence**: [High / Medium / Low]

### Test Order: [A first / B first] because [reason]

````

**Testing Protocol**:
1. Test Hypothesis A (most likely first)
2. If A fails → test Hypothesis B
3. **Circuit Breaker**: If BOTH fail → STOP. Do NOT guess a Hypothesis C. Notify the user.

```markdown
## 🚨 Circuit Breaker Activated

Both hypotheses were tested and failed.
- Hypothesis A result: [What happened when tested]
- Hypothesis B result: [What happened when tested]

**Action Required from User**:
- [Specific additional information needed]
- OR: Share [specific log/config/file] for deeper analysis

**Do NOT**: Continue guessing without new evidence.
````

---

### Step 5: Fix & Clean

Once a hypothesis is confirmed:

**Apply the Fix**:

```markdown
## Fix Applied

**Hypothesis Confirmed**: [A or B]
**Root Cause**: [Clear description of what was actually wrong]
**Fix Applied**:

- File: [path]
- Change: [description — no line numbers in reports, be intent-level]
- Why this works: [Connect fix to root cause]

**Pseudo-Code View** (ADR-P00 Standard 2):
```

BEFORE: [High-level logic that was broken]
AFTER: [High-level logic that is now correct]

````

**Programmatic View**:
```[language]
# Before (broken)
[relevant code snippet]

# After (fixed)
[corrected code snippet]
````

````

**Clean Up**:
```bash
# Remove any debug statements added during investigation
grep -rn "print(\|console.log(\|debugger" [affected_files]

# Remove any temporary test endpoints
# Verify no secrets were added during debugging
grep -rn "hardcoded_key\|test_password" [affected_files]
````

**Post-Fix Verification**:

```bash
# Run the targeted test for the fixed component (the project's test runner)
<test command> <specific test selector>

# Trigger VERIFY protocol
view_file .agent/protocols/ADR-P03-Verification.md
```

---

### Step 6: Discovery Bridge (Post-Debug Learning)

````markdown
## 🔍 Debug Discovery

**Root Cause Classification**: [Environment / Logic / Schema / Config / Race Condition / Auth]
**Time to Diagnose**: [Approximate]
**What Misled Me**: [What looked like the cause but wasn't]
**Key Debugging Command**:

```bash
[The single most useful command in this debug session]
```
````

**Pattern to Prevent Recurrence**: [Should this be added to P07 Quality Mastery or P03 VERIFY?]
**CLAUDE.md Update**: [What should be documented to prevent this in future?]

```

---

## How Other Protocols Support P10

| Protocol | P10 Support Role |
|---|---|
| **P12 (ENUM)** | Sibling fast-path: handles the deterministic-fix subset. Escalate ENUM → P10 the moment the root cause stops being obvious |
| **P04 (Code Audit)** | Provides verified file content for Step 3 |
| **P05 (Intelligence)** | Provides blast radius — what else might be affected |
| **P06 (Command Standards)** | Ensures debug commands use correct paths/venv |
| **P07 (Quality Mastery)** | Post-fix: secrets check, dead code from debug removal |
| **P03 (VERIFY)** | Called after fix to confirm all gates pass |
| **P14 (Adaptive Improvement)** | Receives Discovery Bridge to improve protocols |

---

## Changelog

- **v18.0**: Circuit Breaker formalized. Discovery Bridge added. Code Explanation Standard (Pseudo + Programmatic) added. How-Protocols-Support section added.
- **v17.0**: Initial ADR format. 5-step hypothesis engine.
```