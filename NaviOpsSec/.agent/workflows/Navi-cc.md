---
description: Navi Claude Code Adapter (v27) — project-agnostic tool mappings + web-search enforcement
---

# Navi-cc.md — Claude Code Compatibility Layer
**Version**: 7.0 (project-agnostic) | **Parent**: `.agent/workflows/navi.md` (v27)
**Purpose**: Translate Navi protocol actions into concise Claude Code tool usage, for any project.

## Tool Mapping

| Navi action | Claude Code tool | Notes |
|---|---|---|
| view file | `Read <abs-path>` | absolute paths |
| list dir | `Bash: ls "<path>"` | quote paths |
| find files | `Glob` | faster than shell find |
| search code | `Grep` | targeted paths |
| run command | `Bash` | safe, specific; never auto-spend/auto-send |
| write file | `Write` | Read first if overwriting |
| edit file | `Edit` | prefer for existing files |
| web research | `WebSearch` / `WebFetch` | **required in EXP Phase 2 for EVERY EXP** (P02 v27.1): RESEARCH ≥3 sources, local/debug/audit ≥2 |
| heavy isolated work | `Agent` (subagent) | `navi-research` (EXP Phase 2) · `navi-audit` (P04+P07) · `navi-debug` (P10) — defined in `.claude/agents/` |
| notify user | respond in chat | no separate notifier |

## Canonical Roots

```bash
ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"   # detected at boot — never hardcoded
AGENT="$ROOT/.agent"          # Navi core: workflows + protocols (project-agnostic)
PROTO="$AGENT/protocols"
STATE="$AGENT/state"          # active_project.json (runtime project profile)
REPORTS="$ROOT/docs/reports"  # EXP/ · PLAN/ · DEBUG/ · VERIFY/ · REVIEW/
SECRETS="$ROOT/.secrets"      # *.env reusable keys — never print contents
```

**Project locations are NOT hardcoded.** Resolve them from the detected Project Profile
(`$STATE/active_project.json`) or the project's own `navi.project.md`. Primary anchor reads:
- `"$PROTO/ADR-P00-Master-Rule.md"` (constitution)
- `"$PROTO/ADR-P01-PLAN.md"`, `"$PROTO/ADR-P02-Explanation-Engine.md"`, `"$PROTO/ADR-P03-Verification.md"`
- Add `P04`/`P05`/`P09`/`P10`/`P13` only when the detected intent needs them.

## Boot line (mirror of navi.md §0)
Emit `🧭 Navi v28 | project=<name> | stack=<…> | mode=<INTENT> | protocols=<P0x+P0y>` — show the active mode
(detected intent) and the protocols loaded for it. (Replaces the old `tests=… | law=…` tail.)

## Intent → Protocol (mirror of navi.md §1) — sets `mode` + `protocols` on the boot line

`EXPLAIN/RESEARCH` → `P02` · `PLAN/REFACTOR` → `P01` · `BUILD` → `P01`(+`P04`) ·
`DEBUG` → `P02`+`P10` · `ENUM` → `P12` (deterministic-fix incident card; Lite) ·
`MENTOR` → `P11` (command teacher — "what does X do / best practice / teach me / what did I do wrong and why"; Lite, REPORT-ONLY) ·
`VERIFY` → `P02`+`P03` · `REVIEW` → `P04`+`P07`+`karpathy` ·
`OPERATE` → `P06`(+`P09`). Ambiguous → ask one question (confidence-gate).

## EXP Phase 2 — Web Search Enforcement (EVERY EXP — P02 v27.1)

For **every** EXP, **call the WebSearch tool before analysis** (hard gate): RESEARCH-class ≥3 sources, local/
debug/audit ≥2 validating sources. A zero-search EXP with no tool error is non-conformant. Record results in the Phase 2 source table — never from memory. On a hard tool error: record the exact error, add a `⛔ UNVALIDATED REPORT` banner, tag findings "(unvalidated)". "I don't have web access" is not a tool error — attempt the call.

```
WebSearch("[TOPIC] best practices 2026")
WebSearch("[TOPIC] official documentation")
WebSearch("[TOPIC] pitfalls / failure modes")
# add stack-specific queries from the detected project's profile
```

**Phase 2 Gate Block** (write before Phase 3):
```markdown
### Phase 2 Gate Block
- Searches attempted: [N]   - Tool errors: [None | exact error]
- Sources populated: [N]    - Report status: [VALIDATED | ⛔ UNVALIDATED]
```

## Save reports

```bash
Write "$REPORTS/EXP/EXP_REPORT_[DATE]_[TOPIC].md"
Write "$REPORTS/PLAN/PLAN_REPORT_[DATE]_[TOPIC].md"
```

## Model Routing

| Task | Model |
|---|---|
| deep EXP / architecture audit | `claude-opus-4-8` |
| debug / code audit / web research / REVIEW | `claude-sonnet-4-6` |
| PLAN / VERIFY / targeted edits | `claude-sonnet-4-6` |
| simple append/update | `claude-haiku-4-5` |

## Constraints
- Absolute, quoted paths; no `~/`.
- Read only the protocols the active intent needs.
- **No auto-spend / no auto-send.** Confirm destructive actions; back up before overwrite.
- Persist outputs to `docs/reports/` so they survive context compaction.
