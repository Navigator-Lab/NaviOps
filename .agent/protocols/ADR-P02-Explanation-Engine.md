---
name: ADR-P02-Explanation-Engine
status: Accepted
date: 2026-06-02
version: 27.0
description: Unified EXP Protocol (project-agnostic). One comprehensive report that explains, audits, and evidences a topic — anchor, live audit, web intel, analysis lenses, scorecard, evidence, backlog, references. No project hardcoded.
supersedes: ADR-P02 v22.1
---

# ADR-P02: Explanation Engine (EXP)

<contract>
  <purpose>Understand a topic deeply and produce ONE report: education + audit + evidence + backlog.</purpose>
  <trigger>"explain", "how does X work", "research", "audit", "review", "is this good", "why"</trigger>
  <reads>ADR-P00 (anchor) · the detected project_law · add P04/P09/P10 when relevant</reads>
  <output>docs/reports/EXP/EXP_REPORT_[DATE]_[TOPIC].md</output>
  <rule>EXP never edits code. Implied-build EXPs end with "Say PLAN to implement."</rule>
</contract>

## Context
EXP is the single understanding artifact — never split education, audit, and evidence into separate reports. It is the required input to PLAN.

## Phase 0 — Anchor & Scope
- Run Boot (P00 Axiom 1); emit the boot line. State `<success_criteria>` + `<output_contract>` + `<assumptions>`.
- Define scope: what's in, what's out, what "done" means.

## Phase 1 — Live Audit
Read the actual files in the detected project (don't reason from memory). Quote `path:line`. Establish ground truth before any analysis.

## Phase 2 — Web Intelligence (MANDATORY for EVERY EXP; HARD GATE)
**Every EXP report runs WebSearch before analysis — no exceptions.** Web intel validates findings against
current best practice, surfaces pitfalls the local code can't reveal, and stops us shipping a confidently-wrong
audit. Record results in a source table — never from memory. Generic query set (adapt with the project's stack):
```
WebSearch("[TOPIC] best practices 2026")
WebSearch("[TOPIC] official documentation")
WebSearch("[TOPIC] pitfalls / failure modes")
WebSearch("<stack> [TOPIC] production pattern")
```
- **RESEARCH-class** (best-practice / "what's the right way"): ≥3 sources cited in-body, run the full query set.
- **Local-class** (explain/debug/verify/audit of this repo's code): still run **≥2** searches to validate the
  fix/diagnosis against the framework's documented behaviour and known failure modes; cite ≥2 sources. A bug
  audit is not "done" until the proposed fix is cross-checked against an external reference, not just intuition.

On a hard tool error: record the exact error, add a `⛔ UNVALIDATED REPORT` banner, tag findings "(unvalidated)".

**Phase 2 Gate Block** (must appear in every EXP): Searches attempted: N (≥2) · Tool errors: [None|err] ·
Sources: N · Status: [VALIDATED|⛔ UNVALIDATED]. An EXP with zero successful searches and no tool error is
**non-conformant** — fix it before PLAN.

## Phase 3 — Analysis Lenses (adapt to the domain)
Pick the 6 lenses that fit the topic; cite ≥3 Phase-2 sources across Phases 3–6. Default lens set:
1. **Correctness** — does it do the right thing?
2. **Security** — inputs, secrets, authz, injection surface.
3. **Performance/Cost** — hot paths, resource and API spend.
4. **Reliability** — failure modes, retries, idempotency.
5. **Maintainability** — clarity, coupling, dead code.
6. **Observability** — can you tell when it breaks, silently?
(Debug topics swap in: Reproduction · Root-cause · Blast-radius. UI topics swap in: Accessibility · Responsiveness — see P08.)
Each lens: finding + evidence (`path:line` or source) + impact.

## Phase 4 — Scorecard (8 dimensions, 0–5)
Score and justify: Correctness · Security · Performance · Reliability · Maintainability · Observability · Test coverage · Docs. Show an average.

## Phase 5 — Evidence / Bug Log
Concrete reproductions, error output, or `path:line` proof for each claimed defect. No unbacked assertions.

## Phase 6 — Remediation Backlog (PLAN's input)
Prioritized P0/P1/P2 list. Each item: what · why · effort (S/M/L) · which gap it fixes. PLAN consumes this directly.

## Phase 7 — Reference Index
Every source used (web URLs + internal `path:line`). Never fabricate URLs.

## Output Discipline
- One unified report; XML/Markdown delimiters for multi-part sections.
- Conservative estimates; cite real sources for research/cost/risk claims.
- Surgical recommendations; flag any speculative complexity (Karpathy / P07).

## Changelog
- **v27.1 (2026-06-06)**: Phase 2 WebSearch is now **mandatory for every EXP** (was RESEARCH-class only). Local/debug/audit EXPs must run ≥2 validating searches and cite ≥2 sources; a zero-search EXP is non-conformant. Reason: audits were shipping unvalidated against framework docs/best practice.
- **v27.0 (2026-06-02)**: De-coupled from a domain-specific predecessor — removed the domain-specific analysis lenses and audit greps. Generic, domain-adaptive lenses + scorecard; Phase 2 web-gate kept but scoped to RESEARCH-class topics; added XML `<contract>` tags and output-contract-first.
