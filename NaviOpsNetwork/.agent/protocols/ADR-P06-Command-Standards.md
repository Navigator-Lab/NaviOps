---
name: ADR-P06-Command-Standards
status: Accepted
date: 2026-02-18
version: 18.0
description: Command execution standards. Ensures 100% reliable, repeatable command execution across all protocols.
supersedes: ADR-P06 v17
---

# ADR-P06: Command Standards

<contract>
  <purpose>Safe, correct shell usage: argv form (no shell=True with variables), quoted absolute paths, no auto-spend/auto-send.</purpose>
  <trigger>any command construction; OPERATE intent (run/deploy/start)</trigger>
  <reads>ADR-P00 (Axiom 5 safety) · the detected project_law (commands/danger zones)</reads>
  <output>Vetted commands — destructive/costly/outward-facing ones surfaced for the user, never auto-run</output>
</contract>

## Context

Ensures 100% reliable command execution. Prevents silent failures, wrong-path execution, and environment confusion. Applied by ALL protocols that execute terminal commands.

**Rule**: Every command used in any protocol MUST comply with these standards.

---

## Standard 1: Python Execution

ALWAYS run through the project's **pinned, isolated environment** — never the global/system toolchain.

```bash
# ✅ CORRECT — uses the project's isolated environment
<env-runner> <command>          # e.g. venv/bin/python … · npm run … · bundle exec … · cargo …

# ❌ WRONG — uses a global/system toolchain (wrong packages, wrong version)
<global tool> <command>
```

**Why**: a global toolchain has the wrong packages/version; the project environment isolates the correct ones.

📚 **Reference**: use your stack's environment-isolation tool (virtualenv, nvm, rbenv, asdf, Docker, …).

---

## Standard 2: Node/NPM Execution

ALWAYS use npm scripts defined in `package.json`. Never call node binaries directly.

```bash
# ✅ CORRECT — invoke the project's declared scripts/tasks (per its manifest)
#   (Node example shown — substitute the equivalent for your stack)
npm run build
npm run dev
npm run lint
npm run test

# ❌ WRONG — bypasses the project's script configuration
node_modules/.bin/<tool> build
./node_modules/.bin/eslint .
```

**Why**: npm scripts include environment variables, flags, and configuration that direct binary calls miss.

---

## Standard 3: Working Directory (No cd Rule)

NEVER use `cd` inside a command string. Always use the `cwd` argument.

```bash
# ✅ CORRECT — explicit cwd parameter (absolute path resolved from the Project Profile)
run_command(cmd="<build command>",     cwd="<absolute path to the subproject>")
run_command(cmd="<migration command>", cwd="<absolute path to the subproject>")

# ❌ WRONG — cd in command string breaks error recovery
run_command(cmd="cd <subdir> && <build command>")
```

**Why**: `cd` in command strings fails silently if the directory doesn't exist and leaves no recovery path.

---

## Standard 4: Path Mapping (Project Structure)

All paths are **resolved from the detected Project Profile** (`.agent/state/active_project.json`),
never hardcoded. The canonical shape, relative to the project root (`$ROOT`):

```
Project root:  $ROOT/                 (detected at boot — git root or pwd)
Navi core:     $ROOT/.agent/          (workflows + protocols — project-agnostic)
Runtime state: $ROOT/.agent/state/    (active_project.json — the detected profile)
Reports:       $ROOT/docs/reports/    (EXP/ · PLAN/ · DEBUG/ · VERIFY/ · REVIEW/)
Secrets:       $ROOT/.secrets/        (never print contents)
Memory:        the host's agent-memory path (e.g. .claude/.../memory/MEMORY.md)
```

---

## Standard 5: The Root-Zero Block

NEVER create documentation, reports, or logs in the project root `/`.

```bash
# ✅ CORRECT — save to docs/reports/
save_report("docs/reports/SP/SP_REPORT_2026-02-18_auth.md", content)

# ❌ WRONG — pollutes project root
save_report("./SP_REPORT.md", content)
save_report("/SP_REPORT.md", content)
```

**Exceptions**: `CLAUDE.md`, `README.md` — these belong in project root by convention.

---

## Standard 6: Safety Pre-Flight Checklist

Before executing any command, run this checklist:

```bash
# 1. Tool Check — confirm the runtime/toolchain exists (binaries per project_law's stack)
command -v <runtime>        # e.g. python3 · node · go · cargo — exists?
ls <env-runner>             # project env present? e.g. venv/bin/python · node_modules/.bin

# 2. Directory Check — confirm cwd exists
ls <absolute path to the target subproject>    # Target exists?

# 3. Permission Check — confirm write access
touch docs/reports/.write_test && rm docs/reports/.write_test   # Can write?

# 4. Service Check — confirm dependent services running (ports per project_law)
ss -tlnp | grep <app-port>    # App/API running?
ss -tlnp | grep <db-port>     # Datastore running?
```

**Loop Breaker Rule**: If any pre-flight check returns "command not found" or "directory not found":

1. STOP execution immediately
2. Log the failure reason
3. Notify user with the specific missing component
4. Load `ADR-P10-Debugger.md` to diagnose environment

---

## Standard 7: Service Management

Use the project's process manager (from `project_law`) rather than killing processes by hand.
Example for a **systemd**-managed host — substitute Docker/k8s/PaaS equivalents as needed:

```bash
# ✅ CORRECT — go through the process manager
sudo systemctl {start|stop|restart|status} <service>

# View live logs
journalctl -u <service> -f
journalctl -u <service> --since "1 hour ago"

# ❌ WRONG — never kill processes directly, bypassing the manager
kill -9 $(pgrep <process>)
```

---

## Standard 8: Database Commands (Safety Rules)

The **principle is stack-agnostic** — always run migrations in this order, using your
ORM/migration tool's equivalent commands (Rails, Prisma, Alembic, Flyway, TypeORM, …):

```
1. Show state        — list applied vs pending migrations
2. Preview (dry-run) — generate/inspect the migration WITHOUT applying
3. Apply             — run the migration
4. Backup first      — dump the datastore before ANY destructive migration
                       e.g. pg_dump <db> > ~/backups/pre_migration_$(date +%Y%m%d_%H%M%S).sql
```

❌ NEVER run destructive operations (fake-apply, squash, reset-to-zero) without a fresh backup.

📚 **Reference**: follow your migration tool's official docs for the exact command names.

---

## Standard 9: Environment Variables

```bash
# ✅ CORRECT — read from .env, never hardcode
# In Python: os.environ.get('SECRET_KEY')
# In shell: source .env

# Check .env completeness against .env.example
diff <(grep -oP '^[A-Z_]+(?==)' .env.example | sort) \
     <(grep -oP '^[A-Z_]+(?==)' .env | sort)

# ❌ WRONG — never echo or print actual secrets
echo $SECRET_KEY
print(settings.SECRET_KEY)
```

---

## Changelog

- **v18.0**: Standard 7 (Service Management), Standard 8 (Database Safety), Standard 9 (Env Vars) added. Pre-flight checklist expanded. Loop Breaker formalized.
- **v17.0**: Initial ADR format. Standards 1-6.