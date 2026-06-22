---
name: ADR-P13-Dependency-Map
status: Accepted
date: 2026-02-18
version: 18.0
description: Dependency Mapping & Blast Radius Analysis. Automated impact analysis before any change.
supersedes: ADR-P13 v17
---

# ADR-P13: Dependency Mapping Protocol

<contract>
  <purpose>Map what depends on what, so a change's blast radius is known before editing.</purpose>
  <trigger>"what breaks if", "dependencies", "blast radius", "impact of changing X"</trigger>
  <reads>ADR-P00 · ADR-P05 · the detected project_law</reads>
  <output>Dependency/blast-radius map feeding the EXP or PLAN risk assessment</output>
</contract>

## Context

Automated impact analysis — maps every dependency of a given component to understand the full blast radius before making changes. Prevents "I changed one thing and broke five others" incidents. Called by P01 (SP) and P05 (Intelligence) for blast radius mapping.

**Triggered by**: Navi.md Intent Routing — signals: "What breaks", "Impact analysis", "Dependencies", or called internally by P01/P05.

---

## Protocol Rules (Immutable)

### Step 0: Constitutional Anchor (When Called Standalone)

```bash
view_file .agent/protocols/ADR-P00-Master-Rule.md
view_file <project_law>          # CLAUDE.md / AGENTS.md / navi.project.md — whichever the project ships
```

---

## DEPENDENCY MAPPING WORKFLOW

### Level 1: Import & Usage Mapping

**Goal**: Find every file that imports or uses the target component.

```bash
# Find every file that imports the target module/symbol (examples by stack — use the project's source roots):
#   Python:     grep -rn "from <module> import\|import <module>" <source-root> --include="*.py"
#   TypeScript: grep -rn "from '<path>'\|import .*<Symbol>" <source-root> --include="*.ts" --include="*.tsx"
#   Go:         grep -rn "\"<import-path>\"" <source-root> --include="*.go"

# Find every usage of a symbol (function/class/component) — name-grep, then narrow:
grep -rn "<SymbolName>" <source-root> -l

# UI components, if the project has a UI:
grep -rn "<ComponentName" <source-root> --include="*.tsx" --include="*.vue" --include="*.svelte"
```

**Output**:

```markdown
### 📊 Level 1: Import Dependencies for [Target]

| File                          | Import Type   | Usage               | Risk if Target Changes      |
| ----------------------------- | ------------- | ------------------- | --------------------------- |
| <api>/users/handlers.*        | Direct import | Used in 3 endpoints | HIGH — API behavior changes |
| <api>/users/schema.*          | Direct import | Field definition    | HIGH — Schema changes       |
| <ui>/components/UserCard.*    | Type import   | Props interface     | MEDIUM — Type error risk    |
| <tests>/users_test.*          | Direct import | Test fixtures       | LOW — Tests may need update |
```

---

### Level 2: API Contract Mapping

**Goal**: Find all frontend code that calls this backend endpoint, and all backend endpoints that call external services.

```bash
# Find the endpoint definition (route/controller/handler — patterns per project_law's framework):
grep -rn "<route-decorator-or-path>" <source-root> | grep "[endpoint_name]"

# Find every client call to this endpoint (HTTP client varies by stack — fetch/axios/SWR/query libs):
grep -rn "fetch\|axios\|http\.\|useQuery" <source-root> | grep "[endpoint_path]"

# Check the API schema — export it to a file (the project's schema-export command), then search it:
<export API schema to a file>
grep "[endpoint_name]" <schema file>
```

**Output**:

```markdown
### 📊 Level 2: API Contract Dependencies for [Endpoint]

| Client File              | HTTP Method | Endpoint         | What It Sends/Expects    |
| ------------------------ | ----------- | ---------------- | ------------------------ |
| <ui>/pages/users.*       | GET         | /api/users/      | Expects UserListSchema   |
| <ui>/components/UserForm.* | POST      | /api/users/      | Sends UserCreateSchema   |
| <ui>/hooks/useUser.*     | GET         | /api/users/{id}/ | Expects UserDetailSchema |

**Schema Drift Risk**: If [Endpoint]'s response schema changes, ALL above files may break.
**Type Safety Gate**: regenerate the typed API client immediately after any contract/serializer change.
```

📚 **Reference**: OpenAPI specification — https://spec.openapis.org/oas/latest.html

---

### Level 3: Database Dependencies

**Goal**: Map all database relationships and cascade effects.

```bash
# Find relationships TO this entity — foreign keys, one-to-one, many-to-many.
# Relationship keywords vary by ORM/schema language; use the project_law's data layer:
#   ORM models (e.g. ForeignKey/OneToOne/ManyToMany, belongs_to/has_many, @ManyToOne)
#   schema files (e.g. references / relation() in Prisma/Drizzle), or raw SQL FOREIGN KEY.
grep -rn "<relationship-keyword>" <data-layer-root> | grep "[EntityName]"

# Check migration ordering/dependencies (in the project's migrations dir, if it has one):
grep -rn "depends\|down_revision\|dependencies" <migrations-dir> | grep "[entity_or_module]"

# Find every query against this entity (query API varies by ORM/driver):
grep -rn "[EntityName]" <data-layer-root> -l
```

**Output**:

```markdown
### 📊 Level 3: Database Dependencies for [Model]

**Relationships** (ORM-neutral — terms map to your data layer):
| Related Entity | Relationship | on_delete rule | Cascade Effect |
|---|---|---|---|
| Order | many-to-one → User | CASCADE | Delete user → delete all orders |
| Profile | one-to-one → User | CASCADE | Delete user → delete profile |
| Group | many-to-many | N/A | No cascade — junction table |

**Migration Dependencies**:
| Migration | Depends On | Risk |
|---|---|---|
| <migration: add_encrypted_email> | <prior migration> | Must apply in order |
| <migration: add user FK> | <user table migration> | Cross-module dependency |

**Query Impact** (files that query this entity):
| File | Query Type | Performance Risk |
|---|---|---|
| <api>/orders/handlers.* | filtered + eager-load (select_related / include / JOIN) | LOW — optimized |
| <api>/reports/handlers.* | full-table scan / fetch-all | HIGH — N+1 risk on large dataset |
```

---

### Level 4: Third-Party & External Dependencies

**Goal**: Map all external API calls, services, and infrastructure dependencies.

```bash
# Find outbound HTTP calls (client lib varies by stack — requests/httpx, fetch/axios, net/http…):
grep -rn "<http-client>" <source-root> -l

# Find external service configuration (keys/URLs live in the project's config/env per project_law):
grep -rniE "stripe|sendgrid|aws|s3|redis_url|<service-name>" <config-or-env>

# Find async/background task definitions (queue varies — Celery/Sidekiq/BullMQ/cron…):
grep -rn "<task-decorator-or-registration>" <source-root>
```

**Output**:

```markdown
### 📊 Level 4: External Dependencies

| Service              | Used For        | Failure Impact           | Fallback?                  |
| -------------------- | --------------- | ------------------------ | -------------------------- |
| Inference service    | ML inference    | Tasks queue              | YES — task queue           |
| Primary database     | All data        | Complete outage          | NO — must be up            |
| Cache / queue        | Cache + tasks   | Degraded performance     | YES — graceful degradation |
| Email service        | Notifications   | Email delivery fails     | YES — retry queue          |
| Payment provider     | Payments        | Payment processing fails | NO — alert immediately     |
```

---

### Level 5: The Full Blast Radius Report

After completing Levels 1–4, produce the final blast radius:

```markdown
## 🎯 Full Blast Radius Report: [Target Component]

### Summary

**Target**: [Component/File/Endpoint being changed]
**Change Type**: [Schema / Logic / Removal / Addition]
**Total Files Affected**: [N]
**Risk Level**: [🔴 Critical / 🟡 High / 🟢 Medium / ⚪ Low]

### Immediate Impact (Must Fix Before Deploy)

| File                          | Why Affected        | Action Required        |
| ----------------------------- | ------------------- | ---------------------- |
| generated API client types    | Schema change       | Regenerate from schema |
| <api>/orders/schema.*         | Nested field change | Update related field   |

### Secondary Impact (May Break After Deploy)

| File                          | Why Potentially Affected | Monitor                 |
| ----------------------------- | ------------------------ | ----------------------- |
| <tests>/users_test.*          | Fixture assumptions      | Run test suite          |
| <ui>/hooks/useUser.*          | API response shape       | Check type errors       |

### Safe to Change (No Impact)

| File                       | Why Safe                             |
| -------------------------- | ------------------------------------ |
| <api>/analytics/handlers.* | Uses User ID only — no entity fields |

### Recommended Change Order

1. Update [target component]
2. Regenerate the typed API client → sync types
3. Update [directly dependent file]
4. Run test suite
5. Load P03 (VERIFY) for full gate check

### Rollback Trigger

If any Immediate Impact file cannot be updated before deploy → STOP. Plan separately.
```

---

## How P13 Supports Other Protocols

| Protocol               | P13 Support Role                                                      |
| ---------------------- | --------------------------------------------------------------------- | --- |
| **P01 (PLAN)**         | Full Blast Radius → Step 3 (Dependency & Order Analysis)              |     |
| **P05 (Intelligence)** | P13 provides deeper dependency detail; P05 provides broader context   |
| **P03 (VERIFY)**       | Affected files list → what to test in Gate 1 (E2E)                    |
| **P10 (Debugger)**     | Step 2 trace → which dependencies to check when tracking error source |
| **P02 (EXP)**          | Architect Lens — coupling and dependency analysis                     |

---

## Changelog

- **v18.0**: All 5 levels formalized. Full Blast Radius Report template added. How-Protocols-Support section added. Code examples for all search commands.
- **v17.0**: Initial ADR format. 4-item checklist only.