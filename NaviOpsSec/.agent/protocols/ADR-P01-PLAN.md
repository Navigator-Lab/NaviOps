---
name: ADR-P01-PLAN
status: Accepted
date: 2026-06-02
version: 27.0
description: Implementation Plan Generator (project-agnostic). Converts an EXP Remediation Backlog into ordered, atomic, code-complete steps — each with BEFORE/AFTER, rollback, and an exact verify. No project hardcoded.
supersedes: ADR-P01 v21.0
---

# ADR-P01: PLAN Protocol (Implementation Plan Generator)

<contract>
  <purpose>Turn EXP findings into an ordered set of atomic, executable steps with exact code.</purpose>
  <trigger>"plan", "implement", "build", "write the code", "make it happen", PLAN()</trigger>
  <prerequisite>An EXP Report in docs/reports/EXP/. If none exists, halt and run EXP first (unless fast-path).</prerequisite>
  <reads>ADR-P00 (anchor) · the EXP Report · the detected project_law · add P04/P05/P09 if relevant</reads>
  <output>docs/reports/PLAN/PLAN_REPORT_[DATE]_[TOPIC].md — a blueprint written BEFORE execution</output>
</contract>

## Context

PLAN takes an EXP Report as its **primary input** and converts the Remediation Backlog (EXP Phase 6) into ordered, atomic steps. PLAN does **not** re-design or re-explain — it acts.

- `EXP()` = understand / audit / analyze (never touches code).
- `PLAN()` = act on EXP findings with real BEFORE/AFTER code.

**The PLAN is the SSOT execution contract** (spec-driven development — web-validated 2026): the spec, not the
code, is the source of truth for what gets built. Every step stays **machine-checkable** via its `-> verify:`
line, so a human (Axiom 6) or an agent can confirm the contract was met without re-reading the diff.

**Audience**: executable by an AI agent OR a junior dev with no extra context.

## Protocol Rules (Immutable)

<rules>
1. **Prerequisite** — an EXP Report MUST exist in `docs/reports/EXP/`. If not, halt; instruct the user to run `EXP(topic)` first. (Exception: the §Fast-Path below.)
2. **Forward-only** — a PLAN Report is ALWAYS written BEFORE execution; it is a blueprint, not a changelog. If changes are already made, do NOT write a PLAN Report — report inline. Post-hoc PLAN Reports are a protocol violation.
3. **Golden Rule** — every step states: which file, why it changes, exact code BEFORE, exact code AFTER. No "implement as needed".
4. **Atomicity** — every step is ONE command / ONE verifiable output / ONE rollback. No compound "AND" steps; no steps needing human judgment to confirm success. Two actions → two steps.
5. **Project law wins** — honor the detected project's hard rules (`navi.project.md` / CLAUDE.md); surface conflicts, never silently override.
</rules>

## Fast-Path (low-risk override)
A single-file, reversible change with an obvious fix may skip the full EXP→PLAN ceremony: state the change + rationale, back up the file, apply it, show the verify, report inline. Reserve full PLAN for risky / multi-file / irreversible / costly work.

## Execution Logic

### Step −1: Pre-Flight (generic, derive from Project Profile)
Confirm a known-good starting state before any change. Pull the real commands from the detected project (`.agent/state/active_project.json` → `test_cmd`, `env_files`, `entrypoint`):
```bash
# adapt to the detected stack
<runtime --version>                      # toolchain present
<load env; assert required keys present> # secrets present (never print values)
ls <target files this PLAN edits>        # targets exist
<test_cmd>                               # baseline green before changes
echo "=== PRE-FLIGHT COMPLETE — SAFE TO PROCEED ==="
```
If any check fails: STOP, fix it, do not proceed.

### Step 0: Plan Header
- Link the source EXP Report. Restate `<success_criteria>` + `<output_contract>`. List the backlog items (P0/P1) this PLAN addresses, in dependency order.

### Steps 1..N: Atomic Changes
Each step uses this exact shape:
```
### Step N: <imperative title>
**File**: <path>
**Why**: <1 line — ties to an EXP backlog item>
**Risk**: Low | Medium | High
**BEFORE**:
​```<lang>
<exact current code>
​```
**AFTER**:
​```<lang>
<exact new code>
​```
**Rollback**: <exact command/edit to revert this one step>
-> verify: <exact command + expected output that proves THIS step worked>
```

### Step N+1: Integration Verify
One final check proving the whole change satisfies `<success_criteria>` (run `test_cmd`, hit the endpoint, run the CLI — whatever the project defines).

## Risk & Rollback Strategy
- Order steps so each leaves the system runnable. Prefer additive-then-switch over in-place breaking edits.
- Every step's rollback is independently executable. Keep a one-shot full rollback (e.g. restore from the backup dir) at the end.
- Anything destructive, costly, or outward-facing (deploy, migration, paid API, send, `git push`) is **surfaced as a command for the user**, never auto-run (P00 Axiom 5).

## Execution Checklist (generic)
- [ ] Every step has BEFORE/AFTER, rollback, and an exact verify.
- [ ] No compound steps; each is atomic.
- [ ] Baseline tests green before; target tests green after.
- [ ] No secrets printed or committed.
- [ ] No auto-spend / auto-send introduced.
- [ ] Lint/typecheck (project's command) clean.
- [ ] Minimum diff — no speculative additions (Karpathy / P07).

## Common Failure Modes (generic)
| Symptom | Likely cause | Fix |
|---|---|---|
| `command not found` | tool not in PATH / wrong venv | activate env; use project's runner |
| missing-key error | `.env` not loaded | load project env; check `.secrets/` |
| baseline tests already red | dirty starting state | fix pre-flight before Step 1 |
| step verify fails | BEFORE didn't match actual file | re-read the file; correct the anchor |

## Changelog
- **v27.0 (2026-06-02)**: De-coupled from a domain-specific predecessor — removed the hardcoded domain-pipeline sections; generic pre-flight + failure modes now derive from the detected Project Profile. Added XML `<contract>`/`<rules>` tags, output-contract-first, and the Fast-Path.
