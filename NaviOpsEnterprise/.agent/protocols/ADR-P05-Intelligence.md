---
name: ADR-P05-Intelligence
status: Accepted
date: 2026-04-18
version: 18.1
description: Unified Intelligence Protocol. Transforms raw user requests into high-fidelity analysis with blast radius mapping.
supersedes: ADR-P05 v18.0
---

# ADR-P05: Intelligence Protocol

<contract>
  <purpose>Turn a raw request into structured analysis: requirements + blast radius + environment facts.</purpose>
  <trigger>called by P01/P02 before designing; "what exists", "what will this touch"</trigger>
  <reads>ADR-P00 · ADR-P13 (dependency map) · the detected project_law</reads>
  <output>An intelligence block feeding the EXP/PLAN (paths/ports/commands resolved from the Project Profile)</output>
</contract>

## Context

Transforms raw user requests into structured, high-fidelity analysis. Provides requirement extraction, blast radius mapping, and environmental verification. Called by P01 (PLAN) and P02 (EXP) as part of their Step 2 internal audit.

**Goal**: Before any solution is designed, know exactly what exists, what will be touched, and what constraints exist.

> ⚠️ **Project-agnostic note (v27)**: any environmental-verification commands and paths in the phases
> below are **illustrative**. Resolve real paths, ports, and commands from the detected Project Profile
> (`.agent/state/active_project.json`) or the project's `navi.project.md` — never hardcode a project here.
> Save standalone output to `docs/reports/EXP/INTEL_[DATE]_[TOPIC].md`.

---

## Protocol Rules (Immutable)

### Step 0: Anchor (When Called Standalone)

```bash
view_file .agent/protocols/ADR-P00-Master-Rule.md
view_file CLAUDE.md
```

---

## FULL EXECUTION LOGIC

### Phase 1: Requirement Extraction

Parse the user request into structured requirements:

```markdown
## Requirement Matrix

### User Wants (Explicit)

[List exactly what the user said they want — no interpretation yet]

- Want 1: [Verbatim intent]
- Want 2: [Verbatim intent]

### System Needs (Implicit)

[What the system requires to deliver what the user wants]

- Need 1: [Technical prerequisite]
- Need 2: [Infrastructure requirement]

### Constraints (Discovered)

- Technical: [Framework/language/version limits]
- Business: [Compliance / data-protection regime, deadlines]
- Architectural: [Existing patterns that must be preserved]

### Success Definition

[How we know the requirement is fulfilled — measurable criteria]
```

---

### Phase 2: Internal Audit (Ground Truth)

**Codebase Awareness** — Use tools, never memory:

```bash
# Discover what actually exists (source roots per project_law)
list_dir <source-root>
find_by_name "[relevant_pattern]"   # Find related files
grep_search "[relevant_keyword]"    # Find usage patterns
```

Document every file that is relevant to the request. Note what exists vs what is missing.

**Environmental Verification**:

```bash
# Confirm OS and environment
uname -a                            # Host OS / architecture

# Toolchain — confirm the project's runtime + package manager are present (per project_law)
<runtime> --version
<package-manager> --version

# Active ports (service health — ports per project_law)
ss -tlnp | grep -E "<app-port>|<db-port>"

# Datastore connectivity — the project's DB-shell / ping command
<db connectivity check>
```

---

### Phase 3: Blast Radius Analysis

For every file/component the request will touch, map the full impact:

```markdown
## Blast Radius Map

### Direct Impact (Files that will change)

| File                      | Change Type   | Risk | Notes              |
| ------------------------- | ------------- | ---- | ------------------ |
| <data-layer>/[entity].*   | Schema change | HIGH | Migration required |
| <ui>/[component].*        | UI change     | LOW  | Visual only        |
| <api>/[entity]_schema.*   | API contract  | HIGH | Type drift risk    |

### Indirect Impact (Files that will break if direct files change incorrectly)

| File                         | Why Affected  | Risk   | Detection              |
| ---------------------------- | ------------- | ------ | ---------------------- |
| generated API client types   | Schema drift  | HIGH   | regenerate from schema |
| server-side test files       | Test breakage | MEDIUM | Test suite             |

### Service Impact

| Service           | Impact                  | Recovery          |
| ----------------- | ----------------------- | ----------------- |
| <service>         | Restart required        | restart (per project_law) |
| <web-service>     | Rebuild required        | rebuild (per project_law) |
| <external-service> | [Affected/Not affected] | re-verify integration     |

### Database Impact

| Migration            | Required? | Risk   | Rollback               |
| -------------------- | --------- | ------ | ---------------------- |
| New field on [Model] | YES       | MEDIUM | Remove field migration |
| Index addition       | YES       | LOW    | Drop index             |
```

---

### Phase 4: If/Then Resilience (Recovery Paths)

For every significant risk in the blast radius, document the recovery path:

```markdown
## If/Then Resilience Map

IF migration fails:
THEN: roll back to the previous migration with the migration tool's revert/down command

IF the generated API client drifts from the server contract:
THEN: regenerate the typed client from the live schema (the project's codegen command)

IF backend service crashes after deploy:
THEN: `journalctl -u <service> -f` → identify error → `sudo systemctl restart <service>`

IF HMAC webhook signature fails:
THEN: Verify `X-Signature` header → check shared secret in .env → re-test with curl
```

---

### Phase 5: Security Mapping

```markdown
## Security Analysis

### OWASP Concerns for This Request

| OWASP Item                  | Applicable? | Current Status        |
| --------------------------- | ----------- | --------------------- |
| A01: Broken Access Control  | [Yes/No]    | [Auth check present?] |
| A02: Cryptographic Failures | [Yes/No]    | [PII encrypted?]      |
| A03: Injection              | [Yes/No]    | [ORM/parameterized?]  |
| A07: Auth Failures          | [Yes/No]    | [Session config?]     |

### Data-Protection Assessment (the project's applicable regime)

- PII Involved: [Yes/No — which fields?]
- Encryption Applied: [Yes/No — method?]
- Data Retention: [Defined/Not defined]
- User Consent: [Captured/Missing]

### API Contract Assessment (if a typed client is generated)

- Generated client matches the server contract: [Yes/No]
- If No: regenerate the typed client before any dependent client-side change
```

📚 **Reference**: OWASP Top 10 2021 — https://owasp.org/Top10/

---

## Output Format

Intelligence findings are delivered to the calling protocol (P01 or P02) as structured blocks. Not saved as standalone reports unless called directly.

If called standalone, save to:
`docs/reports/EXP/INTEL_[DATE]_[TOPIC].md`

---

## How P05 Supports Other Protocols

| Protocol                 | How P05 Feeds It                                                                      |
| ------------------------ | ------------------------------------------------------------------------------------- |
| **P01 (PLAN)**           | Blast Radius Map → Step 3. File verification → Step 2. Resilience → Rollback Strategy |
| **P02 (EXP)**            | Blast Radius → Architect Lens. File list → Code Audit verification                    |
| **P03 (VERIFY)**         | Service Impact map → Gate 4 (Cross-Service Sync)                                      |
| **P10 (Debugger)**       | File list + environment → Step 1 (Isolate & Reproduce)                                |
| **P13 (Dependency Map)** | Shares blast radius findings — P05 is broader, P13 is deeper                          |

---

## Changelog

- **v18.0**: Phase 4 (If/Then Resilience) added. Phase 5 (Security Mapping) added. Environmental Verification expanded. Protocol support table added.
- **v17.0**: Initial ADR format. Blast radius + requirements.