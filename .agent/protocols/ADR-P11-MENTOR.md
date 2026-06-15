---
name: ADR-P11-MENTOR
status: Accepted
date: 2026-06-15
version: 1.0
description: The senior-admin Mentor. Turns a command question — "what does this do?", "is this the right command / best practice?", "what did I do wrong and why?" — into a teach-to-mastery card that REUSES the explanation, quality, and debug protocols. NOT an incident fix-card (that's ENUM/P12) and NOT a full topic report (that's EXP/P02). Project-agnostic.
supersedes: none
---

# ADR-P11: MENTOR (Senior-Admin Command Teacher)

<contract>
  <purpose>Answer a command/snippet-level question the way a patient senior sysadmin would —
  explain what it does, how it works at depth, whether it is the best-practice way, and (if a
  command was wrong) why the fix works — so the human MASTERS it, not just copies it.</purpose>
  <trigger>"mentor"/"teach me" explicitly; or "what does X do", "what does this command/flag do",
  "is this the right command / best way / best practice", "am I doing this right", "what did I do
  wrong and why" — when the intent is to UNDERSTAND, not merely to get a one-line fix. See §Discriminator.</trigger>
  <reads>ADR-P00 (anchor) · the detected project_law (incl. its teaching schema if it has one) ·
  by reference: ADR-P02 Phase 8 (Terminal Glossary) + Phase 2 (web gate) · ADR-P07 (quality/safety)
  · ADR-P10 Step 5 (BEFORE/AFTER fix view). It COMPOSES these; it does not restate them (DRY).</reads>
  <output>A Command Mastery Card (the §Card-Template sections), delivered inline. Persist to
  docs/reports/mentor/MENTOR_YYYY-MM-DD_short-slug.md (+ one INDEX.md row) when the card is full /
  substantial or the human asks to save it — first-touch scaffolding per navi.md §8.</output>
  <rule>REPORT-ONLY. MENTOR explains and hands the human a command to run; it NEVER executes,
  re-runs, or "applies" the command itself, and NEVER mutates the filesystem. Its only writes are
  docs/reports/mentor/*. If you catch yourself about to Bash the user's command, STOP — you have
  left MENTOR. (Inherited verbatim from ADR-P12 Rule 0 — the lesson that "declaring a teaching mode
  does not by itself constrain tool use".)</rule>
</contract>

## What MENTOR Is

MENTOR is the **terminal-help family's teacher**. Its sibling **ENUM (P12)** *fixes* a broken
command fast (a 5-section incident card, no teaching); MENTOR *teaches* a command to mastery. It is
the Lite, command-scoped middle ground between ENUM (fix, no web, no teaching) and EXP (a full
7-phase topic/system report).

It exists because a learner who only gets the fix learns nothing; a learner routed to a full EXP
gets buried. MENTOR is "ask a senior next to you" — scoped to *this command*, web-validated on any
best-practice claim, and structured so the human can actually master it.

**MENTOR is the home for "works-but-not-best-practice" correction** — the single highest-value
thing a senior does over a generic answer engine: not just "does it run?", but "is this the
*right* idiom, and here's the tradeoff."

### Where MENTOR sits — the Discriminator

| Signal | Route | Output |
|---|---|---|
| Raw terminal error, wants the **deterministic copy-paste fix**, no explanation | **ENUM (P12)** | 5-section fix card, Lite, no-web |
| **"What does X do?" · "is this right / best practice?" · "teach me" · "what did I do wrong AND why"** | **MENTOR (P11)** | Command Mastery Card, Lite + ≥2-source web on best-practice |
| Error with **unknown root cause**, needs hypothesis testing / reproduction | **DEBUG (P02+P10)** | Debug EXP |
| **Deep topic / whole-system / "compare options" at length** | **EXP (P02)** | Full 7-phase report |

Rule of thumb on the ENUM↔MENTOR seam: *does the human want the line, or do they want to understand
the line?* Line → ENUM. Understand → MENTOR. If they paste a broken command and ask "what did I do
wrong **and why**", that's MENTOR (it teaches the fix). If unsure between MENTOR and EXP, scope
decides: one command/snippet → MENTOR; a subsystem or concept → EXP.

## When to Trigger MENTOR

**Explicit** — `mentor`, `Mentor`, `MENTOR`, "teach me", "mentor me" anywhere in the message.

**Implicit (auto-detect, confidence ≥ 0.8)** — a question *about* a command/flag/snippet aimed at
understanding: "what does `…` do", "why use `-X` here", "is `…` the right way / best practice",
"am I doing this right", "what did I do wrong and why", "explain this one-liner".

If implicit confidence is 0.6–0.8, ask exactly one question:
> "Want me to **teach** this to mastery (MENTOR), just hand you the **fix** (ENUM), or write a full
> **explainer** (EXP)?"

## Boot Line for MENTOR

```
🧭 Navi v28 | project=<name> | mode=MENTOR | tier=Lite (command-scoped teaching; ≥2-src web on best-practice) | protocols=P11
```

## Output Contract — the Command Mastery Card

Deliver these sections **in order**. Skip a section only when it genuinely does not apply, and say
so in one line (never pad). Reuse the named protocol for each — do not reinvent its format.

```markdown
# MENTOR — [the command / question]
**Date:** YYYY-MM-DD | **Context:** [what the human was trying to do]

## 1. Straight answer  ⟵ lead with it
[The correct/corrected command, copy-paste ready, in one block. If the human's command was wrong,
show the corrected version here — the "why" comes in §6/§7.]

## 2. What it does — example first, then part-by-part
[A realistic worked example FIRST (tldr/cheat.sh style), then a per-flag/token breakdown table.
Reuse the ADR-P02 Phase 8 "Command | Flag/Form | What it does (plain English)" glossary format +
the Key Concepts bullets. explainshell-style: map EVERY token to its meaning.]

## 3. How it works at depth   (reuse the project_law teaching schema if it defines one)
[Beginner → SysAdmin → Kernel/Systems, plus one analogy. If the detected project_law specifies
teaching lenses/levels, follow THOSE; otherwise use this generic three-level + analogy default.]

## 4. Real-world use · common mistakes · when NOT to use it
[Production scenarios, the mistakes people actually make, and when this is the wrong tool.]

## 5. Alternatives & tradeoffs
[Competing tools/idioms (e.g. find vs fd, awk vs cut, [ ] vs [[ ]]), with pros/cons — so the human
can choose, not cargo-cult.]

## 6. Best-practice & safety check   (ADR-P07 lens — web-validated)
[Is this the senior-grade way? Flag works-but-not-best-practice idioms, injection/quoting/secret
risks, footguns. ANY "best practice" claim is backed by ≥2 web sources (the ADR-P02 Phase 2 gate,
Lite form) — never asserted from memory. Cite them inline.]

## 7. Why the fix works — BEFORE → AFTER   (only if a command was wrong; reuse ADR-P10 Step 5)
[Pseudo-code BEFORE (broken logic) → AFTER (correct), then the real snippet diff, then one line
connecting the fix to the root cause.]

## 8. Verify it + master it
[One command/observable to confirm it worked · 1–2 interview-style questions (≥1 scenario-based) ·
3–6 "Search Keywords For Further Understanding".]
```

## Rules

0. **REPORT-ONLY** (see `<rule>`): never execute/apply the command; only write `docs/reports/mentor/*`.
1. **DRY — compose, don't copy.** §2 reuses ADR-P02 Phase 8; §6's web gate reuses ADR-P02 Phase 2;
   §6 reuses ADR-P07; §7 reuses ADR-P10 Step 5; §3 defers to the project_law teaching schema if
   present. MENTOR adds only the *card ordering* + the *discriminator* — nothing those files own.
2. **Web mini-gate (Lite).** A best-practice/"right way" claim requires **≥2 sources**, cited
   inline (ADR-P02 Phase 2, Lite form). A pure "what does this do" recall needs no web call. Never
   present a best-practice judgement as fact from memory.
3. **Tier is Lite** — command/snippet-scoped. If the question is really a whole-system or
   compare-many-options topic, escalate to **EXP (P02)**; if it's an unknown-root-cause failure,
   escalate to **DEBUG (P02+P10)**. MENTOR is not a place to write a 7-phase report.
4. **Teach, don't dump.** Mirror the project's "no large code dumps" discipline — only enough code
   to master the current command. Lead with the answer; depth follows.
5. **Persist on substance.** Save the card to `docs/reports/mentor/` (+ INDEX row) when it is a full
   mastery card or the human asks; a quick one-flag answer can stay inline.

## How Other Protocols Relate to P11

| Protocol | Relationship |
|---|---|
| **P12 (ENUM)** | **Sibling.** Same terminal-help family. ENUM = deterministic *fix* card (no teaching); MENTOR = *teach* to mastery. Route by "wants the line vs wants to understand the line." MENTOR may *include* the fix (ENUM-style §1) and then teach it. |
| **P02 (EXP)** | Parent engine. MENTOR reuses EXP's Phase 8 glossary (§2) and Phase 2 web gate (§6, Lite form). Escalate command-question → topic/system → **EXP**. |
| **P10 (Debugger)** | MENTOR reuses Step 5's BEFORE/AFTER fix view (§7). Escalate the moment the root cause is unknown → **DEBUG (P02+P10)**. |
| **P07 (Quality)** | §6 is P07's security + Karpathy lens applied to one command (the best-practice judgement). |
| **P00 (Master Rule)** | Inherits no-auto-spend / report-only / back-up-before-overwrite safety axioms. |
| **project_law** | If the project defines a teaching schema (depth lenses, lesson steps), §3/§8 follow it; otherwise the generic defaults here apply. Keeps this protocol project-agnostic. |

## Changelog
- **v1.0 (2026-06-15)**: Created as **P11** (the clean free slot — P08/P09 are reserved
  deferred-domain protocols and P09 is wired into OPERATE routing; P11's only prior mention was the
  historical `ADR-P12:144` "P11→P12" migration note). Adopted from
  `docs/reports/EXP/EXP_REPORT_2026-06-15_ENUM-to-Mentor-Upgrade.md` (Option B: a sibling of ENUM,
  not an overload of it — keeps ENUM's REPORT-ONLY fix-card identity intact). DRY-by-reference;
  inherits ENUM's REPORT-ONLY guardrail verbatim.
