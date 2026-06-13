---
name: ADR-P12-ENUM
status: Accepted
date: 2026-06-12
version: 1.1
description: Error & Incident Enumeration. A surgical 5-section incident fix-card for real-world terminal errors — the Lite-tier specialization of the fast-path. NOT an explanation (EXP). Project-agnostic.
supersedes: enum-protocol.md (root draft)
---

# ADR-P12: ENUM (Error & Incident Enumeration)

<contract>
  <purpose>Turn a concrete terminal incident (failed command, shell error, mis-applied setting, consequential typo) into a short, copy-paste-ready fix card — what broke → why → exact fix → verify.</purpose>
  <trigger>"enum"/"ENUM" explicitly; or a raw terminal error with a known, deterministic fix (auto-detect ≥0.8). See §When to Trigger and the ENUM-vs-DEBUG discriminator.</trigger>
  <reads>ADR-P00 (anchor) · the detected project_law</reads>
  <output>docs/reports/enum/ENUM_YYYY-MM-DD_short-slug.md (5 sections) + one row in docs/reports/enum/INDEX.md</output>
  <rule>ENUM is REPORT-ONLY: it writes the incident card and NEVER executes, re-runs, or "fixes" the user's command. Section 4 hands the corrected command to the user to paste. ENUM never runs the 7-phase EXP cycle. Tier is always Lite. WebSearch only if root cause is genuinely ambiguous.</rule>
</contract>

## What ENUM Is

ENUM is for real-world terminal incidents — commands that failed, shell errors, settings
that don't apply, typos with consequences. It is **not** an explanation (EXP) and **not** a
full root-cause investigation (DEBUG/P10). It is a surgical fix card saved to
`docs/reports/enum/`.

ENUM is the **Lite-tier specialization of Navi's fast-path** (`navi.md §3`): a single,
reversible, obvious fix — formalized into a fixed 5-section card so the incident + its fix are
captured, not just applied and forgotten. It adds no new tier, sub-agent, or web gate.

**ENUM ≠ EXP**

| | EXP | ENUM |
|---|---|---|
| Input | A question / concept | A terminal error or broken command |
| Lens | Teach and explain | What broke → why → exact fix |
| Output | Long 7-phase report | Short 5-section incident card |
| Folder | `docs/reports/EXP/` | `docs/reports/enum/` |

**ENUM vs DEBUG (P10) — the routing discriminator:**
- **ENUM** — the error has a *known, deterministic, copy-paste fix* (typo, wrong flag, missing
  path, unset var, wrong permission). No investigation needed. Lite card.
- **DEBUG (P10)** — the root cause is *unknown* and needs hypothesis-testing / reproduction. Full
  P02+P10 debug EXP.
If unsure which, it's DEBUG — ENUM is only for the deterministic case.

---

## When to Trigger ENUM

**Explicit** — user writes any of: `enum`, `Enum`, `ENUM` anywhere in the message.

**Implicit (auto-detect, confidence ≥ 0.8)** — message contains:
- A raw terminal error paste (`Error:`, `bash:`, `command not found`, `No such file`,
  `Permission denied`, `cannot access`, shell prompt prefix `└─$` / `$` / `#` with a failed command)
- Phrases like "why is X not working", "what did I do wrong", "it says [error]" — **and** the fix
  is deterministic (otherwise route to DEBUG/P10).
- A config/setting that doesn't apply or is silently ignored.

If implicit confidence is 0.6–0.8, ask exactly one question:
> "Should I file this as an ENUM incident card, or explain the concept (EXP)?"

---

## Boot Line for ENUM

```
🧭 Navi v28 | project=<name> | mode=ENUM | tier=Lite (incident fast-path) | protocols=P12
```

---

## Output Contract

**File:** `docs/reports/enum/ENUM_YYYY-MM-DD_short-slug.md`
**Slug:** 2–4 words, kebab-case, describing the failure.

Create `docs/reports/enum/` if it doesn't exist (same first-touch scaffolding pattern as
`navi.md §8`).

**File structure — exactly 5 sections:**

```markdown
# ENUM — [Short Description]
**Date:** YYYY-MM-DD | **Context:** [what the user was trying to do]

## 1. What Failed
[exact command or setting as the user ran it]

## 2. Error Received
[exact error message or symptom]

## 3. Root Cause (one line)
[the precise reason — no padding, no filler]

## 4. Fix
[exact corrected command(s) — copy-paste ready]

## 5. Verify
[one command or observable output that confirms it worked]
```

Optional **## 6. Note** — only if the fix alone is not self-explanatory. Max 4 lines.
Never add it just to pad the card.

---

## Rules

0. **REPORT-ONLY** — the sole deliverable is the card file (+ INDEX row). Do NOT run, re-run,
   or apply the command, and do NOT mutate the user's filesystem. Your only writes are
   `docs/reports/enum/*`. If you catch yourself about to call `Bash` on the user's command,
   STOP — you've left ENUM. (The user runs Section 4 themselves; that's why it's "copy-paste ready.")
1. No EXP phases — do NOT run the 7-phase EXP cycle.
2. No WebSearch required — the error is local and the fix is deterministic.
   Use WebSearch only if root cause is genuinely ambiguous (and if it is, you are probably in
   DEBUG/P10, not ENUM).
3. Tier is always Lite — this is a fast-path output.
4. After saving the file, append one line to `docs/reports/enum/INDEX.md`:
   `| YYYY-MM-DD | slug | one-line root cause |`
   Create INDEX.md with a table header if it doesn't exist yet.
5. Do not merge with EXP — if the user asks "why does X work?" after an ENUM,
   open a new EXP, do not extend the card.

---

## How Other Protocols Relate to P12

| Protocol | Relationship |
|---|---|
| **P10 (Debugger)** | Sibling. P10 handles unknown root causes (hypothesis engine); P12 handles the deterministic-fix subset. Escalate ENUM → P10 the moment the fix stops being obvious. |
| **P00 (Master Rule)** | ENUM is the formalized fast-path (Axiom 3); inherits the no-auto-spend / back-up-before-overwrite safety axioms. |
| **P14 (Adaptive Improvement)** | A recurring ENUM signature is a candidate pattern to feed back into project_law or P07. |

---

## Changelog
- **v1.1 (2026-06-13)**: Added the **REPORT-ONLY** guardrail (contract `<rule>` + Rule 0) after an
  agent printed `mode=ENUM` then *executed* the user's failing `mv` instead of writing the card.
  Root cause (P14): P12 forbade EXP/WebSearch/escalation but never forbade execution, so the base
  agent's action-bias won. Logged in ADR-P14 Improvement Backlog.
- **v1.0 (2026-06-12)**: Promoted from root `enum-protocol.md` draft into the protocol set as P12.
  Added frontmatter + `<contract>`, the explicit ENUM-vs-DEBUG(P10) discriminator, and the
  fast-path lineage. Boot line `protocols=P11` → `protocols=P12`.
