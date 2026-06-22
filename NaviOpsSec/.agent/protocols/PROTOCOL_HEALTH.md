# Navi Protocol Health — v28 Snapshot
**Audit**: 2026-06-07 | **Auditor**: Navi (self-audit) | **Scope**: `.agent/` + `.claude/{commands,skills,agents}`

> History: earlier audits (v24/v25/v27) preceded this snapshot and are kept in the project's local
> backups. v28 adds the **version SSOT gate** (`.agent/scripts/check-version.sh`)
> and the **dynamic tier selector** (Lite/Standard/Enterprise) — see `navi.md` §0/§1/§3.

## Version SSOT (NEW in v28)
- **Canonical version** = the `version:` frontmatter in `.agent/workflows/navi.md`. Nothing
  else hardcodes a version.
- **`~/.claude/commands/navi.md` is now version-less** — a pointer to `navi.md`, so the
  command can never drift ahead of / behind the brain (root cause of the old v27-over-v28 load).
- **Drift detector**: `bash .agent/scripts/check-version.sh` reads the canonical version and
  asserts every live Navi file agrees (and the command carries no version). Exit 1 on drift.
  Wire it into a pre-commit / CI gate so drift cannot land.
- Dated snapshots (this file's header, `_backup_*`, `_archive/`, `docs/reports/`) are historical
  and excluded from the check.

## State

| Area | Status | Notes |
|---|---|---|
| `.agent/workflows/navi.md` | ✅ v28 | Canonical brain: boot-detection + intent taxonomy + **tier selector** + lifecycle + output-contract-first |
| `.agent/workflows/Navi-cc.md` | ✅ | Generic tool mappings; subagent + WebSearch enforcement |
| `ADR-P00-Master-Rule.md` | ✅ v28 | Constitution; **Context Economy** standards + tier-selection note |
| `ADR-P01–P14` | ✅ | Generic, XML `<contract>` headers |
| `ADR-P11-MENTOR.md` | ✅ **NEW (2026-06-15)** | Command-scoped teacher; sibling of ENUM. DRY-by-reference (P02 Phase 8/2 · P07 · P10 §5); REPORT-ONLY |
| `~/.claude/commands/navi.md` | ✅ **version-less pointer** | Boot + intent flow; no hardcoded version/boot-format |
| `.claude/skills/navi/SKILL.md` | ✅ | Natural-language auto-trigger (description version-less) |
| `.claude/agents/{navi-research,navi-audit,navi-debug}.md` | ✅ | Isolated-context subagents |
| `.agent/scripts/check-version.sh` | ✅ **NEW** | Version-drift SSOT gate |

## Deferred / Archived
- `_deferred_domain/`: `P08` (frontend-UX) · `P09` (performance/observability) — domain-specific; genericize before shipping in a release.
- `_archive/`: predecessor project-specific protocols — restore only if such a project returns.

## Known remaining limitations
1. **WebSearch is runtime-dependent** — must be enabled in CC permissions.
2. **Enforcement is protocol-level, not mechanical** — LLM instructions, mitigated by the boot
   anchor + the new version gate; the tier selector is a rubric, not code.
3. **Tier selector is advisory** — it recommends + auto-applies per the confidence×risk gate
   (`navi.md` §3); the human can always override.

*Navi v28 · Protocol Health · 2026-06-07*
