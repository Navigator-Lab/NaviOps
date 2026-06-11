# EXP — Lesson Schema Integration Lenses (01.md audit + enforcement design)

**Date:** 2026-06-11 · **Mode:** EXPLAIN/RESEARCH → BUILD (docs) · **Tier:** Standard
**Protocols:** P02 (+ web research, ≥3 sources)

<success_criteria>
- `01.md`'s rules are fully accounted for: each rule is either merged into
  `CLAUDE_TEACHING_RULES.md` as an enforceable, professional addition to the existing
  Gate Rule, or identified as already covered by an existing rule.
- The merged schema is internally consistent (no duplicate/contradictory rules) and
  references real instructional-design rationale (not invented).
- Lessons 01 and 02 are retrofitted to demonstrate the new schema in practice.
</success_criteria>
<output_contract>
This EXP report (`docs/reports/EXP/EXP_REPORT_2026-06-11_Lesson-Schema-Integration-Lenses.md`)
+ edits to `CLAUDE_TEACHING_RULES.md`, `PROJECT_MISSION.md`, `LEARNING_STATE.md`, both
lesson READMEs, and the `docs/` memory files (CHANGELOG/STATUS/TODO/DECISIONS).
</output_contract>
<assumptions>
- `01.md` (repo root, untracked) is the source of the new schema requirements and is
  removed once merged (its content lives on in `CLAUDE_TEACHING_RULES.md`).
- "Enforce" means: encode as Gate Rule requirements that future lessons (and a
  retrofit of Lessons 01–02) must satisfy — not a separate document or process.
</assumptions>

---

## Phase 0 — Anchor + Scope

`01.md` contains 7 rule blocks, all about **how lessons are taught**, not new topics.
They overlap heavily with the existing 8-step Gate Rule (`CLAUDE_TEACHING_RULES.md`)
and Top-Level Rules 2 and 7. The job is to **merge, not append a parallel system** —
two competing "how to teach" documents would violate D2 (Gate Rule lives in exactly one
file).

## Phase 1 — Audit of 01.md vs existing schema

| 01.md Rule | Already covered? | Disposition |
|---|---|---|
| Bash-First & C-Aware Strategy | Partially (Top-Level Rule 1 "build NaviOps") | New Top-Level Rule 11 (`/scripts` discipline) + Lens C/D |
| Bash Integration Rule | Not covered | New **Lens C** (Step 4) |
| C Language Integration Rule | Not covered | New **Lens D** (Steps 1 & 4) |
| Systems Thinking Rule (User/SysAdmin/Kernel) | Not covered | Folded into **Lens A** Level 3 |
| Double-Explanation Rule | Not covered | New **Lens B** (Step 1) |
| Understanding Verification Rule | **Already covered** — Step 6 quiz already requires scenario-based, graded questions (D4) | Cross-referenced in Step 6, not duplicated |
| Learning Depth Rule (3 levels) | Overlaps with Systems Thinking Rule | Merged into **Lens A** (one 3-level ladder, not two) |
| NaviOps Integration Rule | **Already covered** — Top-Level Rule 2 | Reinforced in Rule 2 wording (scripts/C must serve NaviOps) |

**Key design decision:** 01.md's "Systems Thinking Rule" (User/SysAdmin/Kernel, for
process/network/storage/service/security/scheduling topics) and "Learning Depth Rule"
(Beginner/SysAdmin/Systems-Kernel, for "important concepts" generally) are the *same
ladder* applied to two overlapping trigger sets. Maintaining them as separate rules
would create ambiguity about which applies when. **Lens A** unifies them: any
"important concept" gets the 3-level treatment, and for OS/Linux-internals topics,
Level 3 *is* the C/kernel explanation (Lens D supplies its content).

## Phase 2 — Web research (best practice for enforcing this kind of schema)

1. **Bloom's Taxonomy** — progressive, sequenced levels (Remember → Understand →
   Apply → Analyze → Create → Evaluate); skipping foundational levels causes learners
   to flounder at higher levels. This validates **Lens A**'s Beginner→SysAdmin→Kernel
   ordering — each level must be earned before the next, matching the existing Gate
   Rule's "don't move on until verified" discipline.
   [Bloom's Taxonomy in Instructional Design](https://www.commlabindia.com/blog/blooms-taxonomy-in-instructional-design)
2. **Teaching C through Linux/systems programming** — established curricula (Harvard
   DCE, CU Boulder ECEA 5306, man7.org/Kerrisk) integrate C *with* OS internals
   (memory, files/pipes, processes, syscalls) rather than teaching C standalone. This
   validates **Lens D**: C appears only when it illuminates a Linux-internals concept,
   never as a separate "C curriculum."
   [C and Linux system programming](https://www.linuxkernelfoundation.com/c-and-linux-system-programming/),
   [Linux/Unix System Programming Essentials (Kerrisk)](https://man7.org/training/download/Linux_System_Programming_Essentials-mkerrisk_man7.org.pdf)
3. **Dual-coding / Feynman technique + scenario-based assessment** — pairing a
   technical explanation with a concrete analogy improves retention, and assessments
   that mirror real work environments transfer better to job performance. This
   validates **Lens B** (technical + analogy) and confirms Step 6's existing
   scenario-based quiz design is correct (Understanding Verification Rule needs no new
   mechanism).
   [Feynman Technique for coding concepts](https://thelinuxcode.com/how-to-understand-complex-coding-concepts-using-the-feynman-technique/),
   [Scenario-based assessment](https://www.questionmark.com/resources/blog/the-role-and-value-of-scenario-based-assessments/)

## Phase 3 — Enforcement design ("how to enforce")

Enforcement = the schema lives in **one file** (`CLAUDE_TEACHING_RULES.md`), as
**triggers inside existing steps** (not new steps), so:
- A future Claude session reading `CLAUDE_TEACHING_RULES.md` top-to-bottom sees the
  full schema in one pass — no second document to cross-check.
- Each lesson's Step 1/4 sections naturally show *whether* a lens fired (e.g. a
  filesystem lesson will have a Lens D C/syscall note; a quiz-only concept like
  "what is a Pull Request" won't force an irrelevant C example).
- The Gate Rule step count stays at **8** — `grep -c "^### Step"` still returns 8,
  preserving the D4 verification command and avoiding a renumbering cascade across
  future lessons.

## Phase 4 — Retrofit scorecard (Lessons 01–02)

| Lesson | Lens A (3-level) | Lens B (analogy) | Lens C (Bash automation) | Lens D (C/syscall) |
|---|---|---|---|---|
| 01 — Filesystems & Permissions | Added: Beginner rwx → SysAdmin chmod/ACL → Kernel `inode`/`open()` permission check | Added: apartment-keys analogy | Already present (Step 4); annotated as Lens C | Added: `stat()`/`chmod()`/`open()` syscalls + `struct stat st_mode` |
| 02 — Git & GitHub | Added: Beginner add/commit → SysAdmin branching/PR → Systems: `.git/objects` content-addressable store (SHA-1) | Added: "save-game / photo album" analogy | Already present (`git-health-check.sh`); annotated as Lens C | Added: brief note — Git's object store as a content-addressed filesystem (hash → blob), git itself written in C |

## Phase 5 — Backlog / follow-ups

- Lesson 03+ should be written directly against the merged schema — no further
  retrofitting needed once `CLAUDE_TEACHING_RULES.md` is the only reference.
- `01.md` is removed from the repo root after this merge (content fully absorbed).

## References

- [Bloom's Taxonomy in Instructional Design](https://www.commlabindia.com/blog/blooms-taxonomy-in-instructional-design)
- [C and Linux system programming — Linux Kernel Foundation](https://www.linuxkernelfoundation.com/c-and-linux-system-programming/)
- [Linux/Unix System Programming Essentials — man7.org (Kerrisk)](https://man7.org/training/download/Linux_System_Programming_Essentials-mkerrisk_man7.org.pdf)
- [How to Understand Complex Coding Concepts Using the Feynman Technique](https://thelinuxcode.com/how-to-understand-complex-coding-concepts-using-the-feynman-technique/)
- [The role and value of scenario-based assessments — Questionmark](https://www.questionmark.com/resources/blog/the-role-and-value-of-scenario-based-assessments/)
