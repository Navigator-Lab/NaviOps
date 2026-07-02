---
description: Navi Claude Code Adapter (v27) — project-agnostic tool mappings + web-search enforcement
---

# Navi-cc.md — Claude Code Compatibility Layer
**Version**: 7.1 (project-agnostic) | **Parent**: `.agent/workflows/navi.md` (v27)
> v7.1 (2026-07-01): added the **Reveal report in Antigravity IDE** mechanism (single source) — ENUM/MENTOR open their card in the current IDE view after writing it.
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
| reveal report in IDE | `Bash: antigravity-ide -r <abs>` | open the just-written report in the **current** Antigravity IDE view — best-effort, non-fatal (see §Reveal report in Antigravity IDE) |
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

## Reveal report in Antigravity IDE (single source of the "open in view" mechanism)

The host editor is **Antigravity IDE** (a VS Code fork; its CLI is the standard `code`-style
wrapper). After a protocol finishes writing a report, open that file in the **active** IDE window
so the human sees it in view immediately instead of hunting for the path. **Required for ENUM (P12)
and MENTOR (P11)** after they save their card; recommended for every EXP/PLAN/DEBUG/VERIFY/REVIEW
report write.

Run **once, after the file is written** (and after the INDEX row, for ENUM/MENTOR) — call the
agent-agnostic reveal script (the single canonical entrypoint; it self-resolves the Antigravity CLI
and reveals with `-r`/reuse-window):

```bash
Bash: .agent/bin/navi-reveal.sh "$REPORT_PATH"
```

The script (`.agent/bin/navi-reveal.sh`) resolves the editor CLI (`NAVI_IDE_BIN` override → PATH →
`/opt/antigravity-ide/bin/antigravity-ide`) and reveals in the current window; it exits 0 if no CLI
is found. Same script is invoked by non-CC runtimes (Antigravity/Gemini) via `AGENTS.md`.

**Rules for the reveal call:**
- **Best-effort, non-fatal.** The report file is the deliverable; the reveal is a convenience. If
  the binary is missing or the open fails, swallow it (`|| true`) — never error the protocol.
- **`-r` (reuse-window), never a bare open** — reveal in the current view; do not spawn a new
  window. Add `-g "$REPORT_PATH:1"` only if you also want the cursor placed.
- **This is a reveal of *our own artifact*, not an action on the user's system.** It reads/opens a
  file Navi just wrote; it mutates nothing. It is therefore an explicit, allowed exception to the
  REPORT-ONLY guardrails in P11/P12 — those still forbid Bash-ing the *user's* command.
- One reveal per report; do not re-open on every edit.

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
